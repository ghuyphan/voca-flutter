// lib/services/on_device_translation_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../models/voca_models.dart';
import '../utils/language_utils.dart';

/// On-Device Translation Service powered by Google ML Kit
///
/// Ported from lingua-tube/src/app/services/translation.service.ts:
/// - Provides instant (<50ms) on-device bilingual translation for dual subtitles.
/// - Manages offline model lifecycle via OnDeviceTranslatorModelManager.
/// - Implements in-flight download locking to avoid redundant network tasks.
/// - Monitors translation latency (>300ms triggers automatic cloud fallback).
/// - Single active translator instance with warm-up capability to hide cold-start delays.
class OnDeviceTranslationService {
  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  // Reactive State Signals (RULE 5)
  final downloadedLanguages = signal<Set<String>>({'en'});
  final downloadingLanguages = signal<Set<String>>({});
  final downloadErrors = signal<Map<String, String>>({});
  final isSlowDevice = signal<bool>(false);

  // In-flight download deduplication
  final Map<String, Future<bool>> _inFlightDownloads = {};

  // Single active translator instance cache
  OnDeviceTranslator? _activeTranslator;
  String? _activeTranslatorKey;
  bool _isWarmingUp = false;

  // Latency watchdog tracking
  int _consecutiveSlowTranslations = 0;

  OnDeviceTranslationService() {
    refreshDownloadedModels();
  }

  /// Scan which language models are currently installed on the device
  Future<void> refreshDownloadedModels() async {
    final downloaded = <String>{'en'}; // English is built-in
    for (final lang in kSupportedSubtitleLanguages) {
      if (lang.isBuiltIn) continue;
      try {
        final isDownloaded = await _modelManager.isModelDownloaded(lang.code);
        if (isDownloaded) {
          downloaded.add(lang.code);
        }
      } catch (e) {
        debugPrint('[OnDeviceTranslation] Error checking model for ${lang.code}: $e');
      }
    }
    downloadedLanguages.value = downloaded;
  }

  /// Whether on-device translation is ready for the given language pair
  bool canTranslate(String sourceLang, String targetLang, {UserSettings? settings}) {
    if (isSlowDevice.value) return false;
    if (settings != null && !settings.offlineTranslationEnabled) return false;

    final srcNorm = normalizeLanguageCode(sourceLang);
    final tgtNorm = normalizeLanguageCode(targetLang);

    if (srcNorm == tgtNorm || srcNorm.isEmpty || tgtNorm.isEmpty) return false;

    final downloaded = downloadedLanguages.value;
    return downloaded.contains(srcNorm) && downloaded.contains(tgtNorm);
  }

  /// Download a language model with in-flight deduplication and Wi-Fi checking
  Future<bool> downloadModel(
    String langCode, {
    bool? isWifiRequired,
  }) async {
    final normCode = normalizeLanguageCode(langCode);
    if (normCode == 'en' || normCode.isEmpty) return true;

    // Return existing future if already in progress
    if (_inFlightDownloads.containsKey(normCode)) {
      return _inFlightDownloads[normCode]!;
    }

    final downloading = Set<String>.from(downloadingLanguages.value)..add(normCode);
    downloadingLanguages.value = downloading;

    final errors = Map<String, String>.from(downloadErrors.value)..remove(normCode);
    downloadErrors.value = errors;

    final downloadFuture = () async {
      try {
        final success = await _modelManager.downloadModel(
          normCode,
          isWifiRequired: isWifiRequired ?? true,
        );
        if (success) {
          final updated = Set<String>.from(downloadedLanguages.value)..add(normCode);
          downloadedLanguages.value = updated;
          debugPrint('[OnDeviceTranslation] Successfully downloaded model for $normCode');
        } else {
          final errs = Map<String, String>.from(downloadErrors.value)
            ..[normCode] = 'settings.downloadWaitingWifi';
          downloadErrors.value = errs;
        }
        return success;
      } on MissingPluginException {
        debugPrint('[OnDeviceTranslation] MissingPluginException for $normCode: App restart required.');
        final errs = Map<String, String>.from(downloadErrors.value)
          ..[normCode] = 'settings.restartRequired';
        downloadErrors.value = errs;
        return false;
      } catch (e) {
        debugPrint('[OnDeviceTranslation] Download exception for $normCode: $e');
        final isMissing = e.toString().contains('MissingPluginException');
        final errs = Map<String, String>.from(downloadErrors.value)
          ..[normCode] = isMissing ? 'settings.restartRequired' : e.toString();
        downloadErrors.value = errs;
        return false;
      } finally {
        _inFlightDownloads.remove(normCode);
        final currentDownloading = Set<String>.from(downloadingLanguages.value)
          ..remove(normCode);
        downloadingLanguages.value = currentDownloading;
      }
    }();

    _inFlightDownloads[normCode] = downloadFuture;
    return downloadFuture;
  }

  /// Delete an offline model to free device storage
  Future<bool> deleteModel(String langCode) async {
    final normCode = normalizeLanguageCode(langCode);
    if (normCode == 'en' || normCode.isEmpty) return false;

    try {
      final success = await _modelManager.deleteModel(normCode);
      if (success) {
        final updated = Set<String>.from(downloadedLanguages.value)..remove(normCode);
        downloadedLanguages.value = updated;

        // If the deleted model belonged to the active translator, close it
        if (_activeTranslatorKey != null &&
            (_activeTranslatorKey!.startsWith('$normCode:') ||
                _activeTranslatorKey!.endsWith(':$normCode'))) {
          await releaseActiveTranslator();
        }
        debugPrint('[OnDeviceTranslation] Deleted model for $normCode');
      }
      return success;
    } catch (e) {
      debugPrint('[OnDeviceTranslation] Error deleting model for $normCode: $e');
      return false;
    }
  }

  /// Warm up the translator for a pair before video starts
  Future<void> warmUp(String sourceLang, String targetLang) async {
    if (_isWarmingUp) return;
    final srcNorm = normalizeLanguageCode(sourceLang);
    final tgtNorm = normalizeLanguageCode(targetLang);
    if (!canTranslate(srcNorm, tgtNorm)) return;

    _isWarmingUp = true;
    try {
      final translator = await _getOrCreateTranslator(srcNorm, tgtNorm);
      if (translator != null) {
        // Translate a minimal throwaway string to initialize native neural graph
        await translator.translateText(' ');
      }
    } catch (_) {
      // Warm-up failure is non-fatal
    } finally {
      _isWarmingUp = false;
    }
  }

  /// Translate a batch of texts on-device (<50ms per cue)
  Future<List<String?>> translateBatch(
    List<String> texts,
    String sourceLang,
    String targetLang,
  ) async {
    if (texts.isEmpty) return [];

    final srcNorm = normalizeLanguageCode(sourceLang);
    final tgtNorm = normalizeLanguageCode(targetLang);

    if (!canTranslate(srcNorm, tgtNorm)) {
      return List<String?>.filled(texts.length, null);
    }

    final translator = await _getOrCreateTranslator(srcNorm, tgtNorm);
    if (translator == null) {
      return List<String?>.filled(texts.length, null);
    }

    final results = <String?>[];
    final stopwatch = Stopwatch()..start();

    for (final text in texts) {
      final trimmed = text.trim();
      if (trimmed.isEmpty) {
        results.add(null);
        continue;
      }

      try {
        final translated = await translator.translateText(trimmed);
        final cleanTrans = translated.trim();

        // Reject if empty or identical to original text (needs cloud fallback)
        if (cleanTrans.isEmpty ||
            (srcNorm != tgtNorm && cleanTrans.toLowerCase() == trimmed.toLowerCase())) {
          results.add(null);
        } else {
          results.add(cleanTrans);
        }
      } catch (e) {
        debugPrint('[OnDeviceTranslation] Failed translating "$trimmed": $e');
        results.add(null);
      }
    }

    stopwatch.stop();

    // Latency Watchdog: Evaluate average cue translation time
    if (texts.isNotEmpty) {
      final avgLatencyMs = stopwatch.elapsedMilliseconds / texts.length;
      if (avgLatencyMs > 300) {
        _consecutiveSlowTranslations++;
        if (_consecutiveSlowTranslations >= 3) {
          debugPrint(
            '[OnDeviceTranslation] Device too slow ($avgLatencyMs ms/cue). Switching to cloud.',
          );
          isSlowDevice.value = true;
        }
      } else {
        _consecutiveSlowTranslations = 0;
      }
    }

    return results;
  }

  /// Acquire or instantiate the single active translator
  Future<OnDeviceTranslator?> _getOrCreateTranslator(
    String srcCode,
    String tgtCode,
  ) async {
    final key = '$srcCode:$tgtCode';
    if (_activeTranslatorKey == key && _activeTranslator != null) {
      return _activeTranslator;
    }

    final srcLang = _toTranslateLanguage(srcCode);
    final tgtLang = _toTranslateLanguage(tgtCode);

    if (srcLang == null || tgtLang == null) {
      debugPrint('[OnDeviceTranslation] Unsupported language pair: $key');
      return null;
    }

    await releaseActiveTranslator();

    try {
      _activeTranslator = OnDeviceTranslator(
        sourceLanguage: srcLang,
        targetLanguage: tgtLang,
      );
      _activeTranslatorKey = key;
      return _activeTranslator;
    } catch (e) {
      debugPrint('[OnDeviceTranslation] Failed creating translator for $key: $e');
      _activeTranslator = null;
      _activeTranslatorKey = null;
      return null;
    }
  }

  /// Release active translator to free memory
  Future<void> releaseActiveTranslator() async {
    if (_activeTranslator != null) {
      try {
        await _activeTranslator!.close();
      } catch (e) {
        debugPrint('[OnDeviceTranslation] Error closing translator: $e');
      }
      _activeTranslator = null;
      _activeTranslatorKey = null;
    }
  }

  /// Reset the slow-device flag (e.g., when requested in Settings)
  void resetPerformanceState() {
    isSlowDevice.value = false;
    _consecutiveSlowTranslations = 0;
  }

  /// Helper to convert normalized BCP-47 code to TranslateLanguage
  TranslateLanguage? _toTranslateLanguage(String code) {
    try {
      return TranslateLanguage.values.firstWhere((e) => e.bcpCode == code);
    } catch (_) {
      return null;
    }
  }

  /// Dispose service resources
  Future<void> dispose() async {
    await releaseActiveTranslator();
    _inFlightDownloads.clear();
  }
}
