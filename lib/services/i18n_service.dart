import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

class UILanguageInfo {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const UILanguageInfo({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}

class I18nService {
  static final I18nService instance = I18nService._();
  I18nService._();

  static const String storageKey = 'voca_ui_language';
  static const List<String> supportedLanguageCodes = ['en', 'vi', 'ja', 'ko', 'zh'];

  final List<UILanguageInfo> availableLanguages = const [
    UILanguageInfo(code: 'en', name: 'English', nativeName: 'English', flag: '🇬🇧'),
    UILanguageInfo(code: 'vi', name: 'Vietnamese', nativeName: 'Tiếng Việt', flag: '🇻🇳'),
    UILanguageInfo(code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
    UILanguageInfo(code: 'ko', name: 'Korean', nativeName: '한국어', flag: '🇰🇷'),
    UILanguageInfo(code: 'zh', name: 'Chinese', nativeName: '中文', flag: '🇨🇳'),
  ];

  final currentLanguage = signal<String>('en');
  final Map<String, Map<String, dynamic>> _translations = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Loads all language files from assets/i18n and restores saved user language preference.
  Future<void> init([AssetBundle? bundle]) async {
    final assetBundle = bundle ?? rootBundle;

    for (final code in supportedLanguageCodes) {
      try {
        assetBundle.evict('assets/i18n/$code.json');
        final jsonStr = await assetBundle.loadString('assets/i18n/$code.json');
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          _translations[code] = decoded;
        }
      } catch (e) {
        debugPrint('[I18nService] Could not load assets/i18n/$code.json: $e');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(storageKey);
      if (saved != null && supportedLanguageCodes.contains(saved)) {
        currentLanguage.value = saved;
      } else {
        final sysCode = PlatformDispatcher.instance.locale.languageCode;
        if (supportedLanguageCodes.contains(sysCode)) {
          currentLanguage.value = sysCode;
        }
      }
    } catch (e) {
      debugPrint('[I18nService] Error loading saved UI language: $e');
    }

    _isInitialized = true;
  }

  /// Reloads translations from assets on runtime hot-reload / dev changes.
  Future<void> reload() async {
    for (final code in supportedLanguageCodes) {
      try {
        rootBundle.evict('assets/i18n/$code.json');
        final jsonStr = await rootBundle.loadString('assets/i18n/$code.json');
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          _translations[code] = decoded;
        }
      } catch (e) {
        debugPrint('[I18nService] Could not reload assets/i18n/$code.json: $e');
      }
    }
  }

  /// Synchronously or directly load translations map (useful for unit tests)
  void loadTranslations(String langCode, Map<String, dynamic> data) {
    _translations[langCode] = data;
    _isInitialized = true;
  }

  /// Get a translated string by dot-separated key path (e.g., 'nav.video', 'settings.theme')
  /// Supports interpolation: t('app.updateSuccess', {'version': '1.2.0'}) -> "Updated to v1.2.0!"
  String t(String key, [Map<String, dynamic>? params, String? fallback]) {
    String? resolve(Map<String, dynamic>? map) {
      if (map == null) return null;
      final parts = key.split('.');
      dynamic current = map;
      for (int i = 0; i < parts.length; i++) {
        final part = parts[i];
        if (current is Map<String, dynamic>) {
          if (i + 1 < parts.length &&
              (!current.containsKey(part) || current[part] is! Map<String, dynamic>) &&
              current.containsKey(parts[i + 1])) {
            // Support virtual prefix such as explore.topic.topicAll -> explore.topicAll
            current = current[parts[i + 1]];
            i++;
          } else if (current.containsKey(part)) {
            current = current[part];
          } else {
            return null;
          }
        } else {
          return null;
        }
      }
      return current is String ? current : null;
    }

    final activeLang = currentLanguage.value;
    String? val = resolve(_translations[activeLang]) ?? resolve(_translations['en']);

    String result = val ?? fallback ?? key;

    if (params != null && params.isNotEmpty) {
      params.forEach((paramKey, paramVal) {
        final replacement = paramVal?.toString() ?? '';
        // Replaces both {{key}} and {key}
        result = result.replaceAll('{{$paramKey}}', replacement);
        result = result.replaceAll('{$paramKey}', replacement);
      });
    }

    return result;
  }

  /// Switch the active UI language and persist preference
  Future<void> setLanguage(String langCode) async {
    if (!supportedLanguageCodes.contains(langCode)) return;
    currentLanguage.value = langCode;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, langCode);
    } catch (e) {
      debugPrint('[I18nService] Error saving UI language: $e');
    }
  }

  UILanguageInfo get currentLanguageInfo {
    return availableLanguages.firstWhere(
      (l) => l.code == currentLanguage.value,
      orElse: () => availableLanguages.first,
    );
  }
}

/// Ergonomic extension for BuildContext
extension I18nBuildContextExtension on BuildContext {
  String t(String key, [Map<String, dynamic>? params, String? fallback]) =>
      I18nService.instance.t(key, params, fallback);
}
