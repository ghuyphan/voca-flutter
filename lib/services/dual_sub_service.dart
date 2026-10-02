// lib/services/dual_sub_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../models/voca_models.dart';
import 'voca_api_client.dart';

/// Two-Tier Dual Subtitle Streaming Service
///
/// Ported from lingua-tube/src/app/features/video/subtitle.service.ts:
/// - RULE 7 Invariant: Two-Tier Dual Subtitle Streaming (< 200ms Seek Latency)
///   - Tier 1 (Urgent seek micro-batch): Active cue + 2 lookahead cues (cues[i..i+2])
///     dispatched to POST /api/translate/batch (< 200ms display latency).
///   - Tier 2 (Progressive background stream): Streams remaining untranslated cues
///     in batches of 40-50 cues with exponential backoff on HTTP 429.
/// - Checks Cloudflare R2 cache (GET /api/dual-subtitles) on initialization.
/// - Persists completed bilingual segments back to Cloudflare R2 cache (POST /api/dual-subtitles).
class DualSubService {
  final VocaApiClient apiClient;

  // Reactive State Signals
  final isTranslatingDual = signal<bool>(false);
  final isDualSubLoading = signal<bool>(false);
  final dualSubError = signal<String?>(null);
  final targetLanguage = signal<String>('en');

  // Internal Streaming & Session Tracking
  int _currentSessionId = 0;
  String? _currentVideoId;
  String? _sourceLang;
  String? _targetLang;
  List<SubtitleCue> _cues = [];
  void Function(List<SubtitleCue>)? _onCuesUpdated;

  bool _isUrgentTranslating = false;
  bool _isBackgroundStreaming = false;
  int _lastLookaheadIndex = -1;
  int _consecutiveFailures = 0;
  Timer? _backgroundStreamTimer;
  bool _hasSavedToCache = false;

  DualSubService({required this.apiClient});

  /// Initialize dual subtitle stream for a newly loaded video
  Future<void> initializeForVideo({
    required String videoId,
    required String sourceLang,
    required String targetLang,
    required List<SubtitleCue> cues,
    required void Function(List<SubtitleCue>) onCuesUpdated,
  }) async {
    // Increment session ID to cancel any ongoing work from previous video
    _currentSessionId++;
    final sessionId = _currentSessionId;

    _backgroundStreamTimer?.cancel();
    _currentVideoId = videoId;
    _sourceLang = sourceLang;
    _targetLang = targetLang;
    _cues = cues;
    _onCuesUpdated = onCuesUpdated;
    _lastLookaheadIndex = -1;
    _consecutiveFailures = 0;
    _hasSavedToCache = false;
    targetLanguage.value = targetLang;
    dualSubError.value = null;

    if (sourceLang == targetLang || cues.isEmpty) {
      isTranslatingDual.value = false;
      isDualSubLoading.value = false;
      return;
    }

    // Step 1: Check Cloudflare R2 pre-cached whole-video translation
    isDualSubLoading.value = true;
    try {
      final cachedSegments = await apiClient.getCachedDualSubtitles(
        videoId: videoId,
        sourceLang: sourceLang,
        targetLang: targetLang,
      );

      if (sessionId != _currentSessionId) return;

      if (cachedSegments != null && cachedSegments.isNotEmpty) {
        _applyCachedSegments(cachedSegments);
        _hasSavedToCache = true;
        isDualSubLoading.value = false;
        isTranslatingDual.value = false;
        return;
      }
    } catch (e) {
      debugPrint('[DualSubService] Cache lookup error: $e');
    }

    if (sessionId != _currentSessionId) return;
    isDualSubLoading.value = false;

    // Step 2: Trigger initial micro-batch for cue 0
    onPlaybackProgress(0);
  }

  /// Change the target learning language for dual subtitles
  Future<void> setTargetLanguage(String newTargetLang) async {
    if (_targetLang == newTargetLang) return;
    _targetLang = newTargetLang;
    targetLanguage.value = newTargetLang;

    // Clear old translations from cues
    for (final cue in _cues) {
      cue.translation = null;
    }
    _onCuesUpdated?.call(_cues);

    if (_currentVideoId != null && _sourceLang != null && _onCuesUpdated != null) {
      await initializeForVideo(
        videoId: _currentVideoId!,
        sourceLang: _sourceLang!,
        targetLang: newTargetLang,
        cues: _cues,
        onCuesUpdated: _onCuesUpdated!,
      );
    }
  }

  /// Apply Cloudflare R2 cached segments directly to active cues
  void _applyCachedSegments(List<SubtitleCue> cached) {
    bool updated = false;

    // Map by index or matching timestamp
    for (int i = 0; i < _cues.length; i++) {
      if (i < cached.length && cached[i].translation != null) {
        _cues[i].translation = cached[i].translation;
        updated = true;
      } else {
        // Fallback: search by closest start timestamp (+- 0.5s)
        final match = cached.firstWhere(
          (c) => (c.start - _cues[i].start).abs() < 0.5 && c.translation != null,
          orElse: () => SubtitleCue(start: 0, duration: 0, text: ''),
        );
        if (match.translation != null && match.translation!.isNotEmpty) {
          _cues[i].translation = match.translation;
          updated = true;
        }
      }
    }

    if (updated) {
      _onCuesUpdated?.call(_cues);
    }
  }

  /// Called on playback time update or manual seek
  void onPlaybackProgress(int currentCueIndex) {
    if (_currentVideoId == null || _sourceLang == null || _targetLang == null) return;
    if (_sourceLang == _targetLang || _cues.isEmpty || currentCueIndex < 0) return;

    final diff = (_lastLookaheadIndex - currentCueIndex).abs();
    // Only re-evaluate if approaching the edge of the previous batch window
    if (_lastLookaheadIndex != -1 && diff < 4 && !_isUrgentTranslating) {
      return;
    }

    _processLookaheadStreaming(currentCueIndex);
  }

  /// Two-Tier Prioritized Streaming Engine
  Future<void> _processLookaheadStreaming(int currentIdx) async {
    final sessionId = _currentSessionId;
    final sourceLang = _sourceLang!;
    final targetLang = _targetLang!;

    const int lookaheadWindow = 20;
    final startIdx = currentIdx.clamp(0, _cues.length);
    final endIdx = (startIdx + lookaheadWindow).clamp(0, _cues.length);

    // Find cues missing translation in the active window
    final missingIndices = <int>[];
    for (int i = startIdx; i < endIdx; i++) {
      final t = _cues[i].translation;
      if (t == null || t.trim().isEmpty) {
        missingIndices.add(i);
      }
    }

    if (missingIndices.isEmpty) {
      _lastLookaheadIndex = endIdx;
      _scheduleBackgroundStreamer(500);
      return;
    }

    // =========================================================================
    // TIER 1: Urgent Seek Micro-Batch (< 200ms latency)
    // If active cue or lookahead cues (startIdx..startIdx+2) lack translations,
    // isolate them into a high-priority 1-3 cue micro-batch.
    // =========================================================================
    final urgentMissing = missingIndices.where((idx) => idx <= startIdx + 2).toList();
    final targetIndices = (urgentMissing.isNotEmpty && missingIndices.length > 4)
        ? urgentMissing
        : missingIndices;

    if (_isUrgentTranslating) return;
    _isUrgentTranslating = true;
    isTranslatingDual.value = true;
    isDualSubLoading.value = true;

    try {
      final texts = targetIndices.map((i) => _cues[i].text).toList();
      final translations = await apiClient.translateBatch(
        texts: texts,
        sourceLang: sourceLang,
        targetLang: targetLang,
      );

      if (sessionId != _currentSessionId) return;

      for (int i = 0; i < targetIndices.length && i < translations.length; i++) {
        final cueIdx = targetIndices[i];
        if (cueIdx < _cues.length) {
          final trans = translations[i].trim();
          if (trans.isNotEmpty) {
            _cues[cueIdx].translation = trans;
          }
        }
      }

      _onCuesUpdated?.call(_cues);
      _lastLookaheadIndex = targetIndices.last;
      _consecutiveFailures = 0;
      dualSubError.value = null;
    } catch (e) {
      if (sessionId != _currentSessionId) return;
      debugPrint('[DualSubService] Urgent micro-batch translation error: $e');
      _consecutiveFailures++;
      if (_consecutiveFailures >= 3) {
        dualSubError.value = 'Translation rate-limited. Retrying...';
      }
    } finally {
      if (sessionId == _currentSessionId) {
        _isUrgentTranslating = false;
        isDualSubLoading.value = false;
        isTranslatingDual.value = false;
      }
    }

    // Continue streaming remainder of current lookahead window or background video
    if (targetIndices.length < missingIndices.length) {
      _processLookaheadStreaming(currentIdx);
    } else {
      _scheduleBackgroundStreamer(800);
    }
  }

  /// Schedule progressive Tier 2 background streaming
  void _scheduleBackgroundStreamer(int delayMs) {
    _backgroundStreamTimer?.cancel();
    _backgroundStreamTimer = Timer(Duration(milliseconds: delayMs), () {
      _runBackgroundStreamChunk();
    });
  }

  /// =========================================================================
  /// TIER 2: Progressive Background Streamer (Batches of 40-50 Cues)
  /// Progressively streams 100% of the video's subtitles in the background.
  /// =========================================================================
  Future<void> _runBackgroundStreamChunk() async {
    if (_isBackgroundStreaming || _isUrgentTranslating) return;
    if (_currentVideoId == null || _sourceLang == null || _targetLang == null) return;
    final sessionId = _currentSessionId;

    // Find the first untranslated chunk across the entire video
    final missingIndices = <int>[];
    for (int i = 0; i < _cues.length; i++) {
      final t = _cues[i].translation;
      if (t == null || t.trim().isEmpty) {
        missingIndices.add(i);
        if (missingIndices.length >= 40) break; // Batch chunk size: 40 cues
      }
    }

    if (missingIndices.isEmpty) {
      // 100% of video transcript has been translated! Persist back to Cloudflare R2 cache.
      if (!_hasSavedToCache && _cues.isNotEmpty) {
        _persistToCloudflareCache();
      }
      return;
    }

    _isBackgroundStreaming = true;

    try {
      final texts = missingIndices.map((i) => _cues[i].text).toList();
      final translations = await apiClient.translateBatch(
        texts: texts,
        sourceLang: _sourceLang!,
        targetLang: _targetLang!,
      );

      if (sessionId != _currentSessionId) return;

      for (int i = 0; i < missingIndices.length && i < translations.length; i++) {
        final cueIdx = missingIndices[i];
        if (cueIdx < _cues.length) {
          final trans = translations[i].trim();
          if (trans.isNotEmpty) {
            _cues[cueIdx].translation = trans;
          }
        }
      }

      _onCuesUpdated?.call(_cues);
      _consecutiveFailures = 0;

      // Schedule next background chunk with gentle pacing (600ms) to avoid HTTP 429
      _scheduleBackgroundStreamer(600);
    } catch (e) {
      if (sessionId != _currentSessionId) return;
      debugPrint('[DualSubService] Background streamer error: $e');
      _consecutiveFailures++;
      // Exponential backoff on rate-limit (2s, 4s, 8s)
      final backoffMs = (2000 * (1 << (_consecutiveFailures.clamp(1, 3) - 1))).clamp(2000, 8000);
      _scheduleBackgroundStreamer(backoffMs);
    } finally {
      if (sessionId == _currentSessionId) {
        _isBackgroundStreaming = false;
      }
    }
  }

  /// Persist complete dual subtitles back to Cloudflare R2 / Server Cache
  Future<void> _persistToCloudflareCache() async {
    if (_currentVideoId == null || _sourceLang == null || _targetLang == null) return;
    _hasSavedToCache = true;

    final segments = _cues.map((c) => {
      'start': c.start,
      'duration': c.duration,
      'text': c.text,
      'translation': c.translation ?? '',
    }).toList();

    try {
      final success = await apiClient.saveDualSubtitles(
        videoId: _currentVideoId!,
        sourceLang: _sourceLang!,
        targetLang: _targetLang!,
        segments: segments,
      );
      if (success) {
        debugPrint('[DualSubService] Successfully persisted dual subtitles to R2 cache for $_currentVideoId');
      }
    } catch (e) {
      debugPrint('[DualSubService] Failed to save dual subtitles to cache: $e');
    }
  }

  /// Dispose service and cancel any background tasks
  void dispose() {
    _currentSessionId++;
    _backgroundStreamTimer?.cancel();
    _isUrgentTranslating = false;
    _isBackgroundStreaming = false;
    _onCuesUpdated = null;
  }
}
