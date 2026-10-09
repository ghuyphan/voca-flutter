// lib/utils/language_utils.dart
// 1:1 port of ../lingua-tube/src/app/shared/utils/language.utils.ts

import 'package:flutter/widgets.dart';
import '../models/voca_models.dart';
import '../services/i18n_service.dart';

/// Unicode ranges for language detection
class UnicodeRanges {
  // Japanese
  static final RegExp hiragana = RegExp(r'[\u3040-\u309F]');
  static final RegExp katakana = RegExp(r'[\u30A0-\u30FF]');
  static final RegExp japanese = RegExp(r'[\u3040-\u309F\u30A0-\u30FF]');

  // Korean
  static final RegExp hangul = RegExp(r'[\uAC00-\uD7AF]');
  static final RegExp hangulJamo = RegExp(r'[\u1100-\u11FF\u3130-\u318F]');
  static final RegExp korean = RegExp(r'[\uAC00-\uD7AF\u1100-\u11FF\u3130-\u318F]');

  // Chinese / Kanji (CJK Unified Ideographs)
  static final RegExp hanzi = RegExp(r'[\u4E00-\u9FFF]');

  // Basic Latin
  static final RegExp latin = RegExp(r'[a-zA-Z]');
}

/// Comprehensive punctuation pattern for CJK + Western
final RegExp punctuationRegex = RegExp(
  r'''^[\s\p{P}\p{S}【】「」『』（）〔〕［］｛｝〈〉《》〖〗〘〙〚〛｟｠、。・ー〜～！？：；，．"'…—–*]+$''',
  unicode: true,
);

/// Normalize language codes from YouTube, Gladia, or external providers to canonical 2-letter codes.
/// Handles null/empty safely, splits on '-' and '_', and maps STT aliases (cmn, mandarin, yue -> zh).
String normalizeLanguageCode(String? lang) {
  if (lang == null || lang.trim().isEmpty) return '';
  final clean = lang.trim().toLowerCase().split('-')[0].split('_')[0];
  if (clean == 'ja' || clean == 'japanese' || clean == 'jpn') return 'ja';
  if (clean == 'ko' || clean == 'korean' || clean == 'kor') return 'ko';
  if (clean == 'zh' || clean == 'chinese' || clean == 'cmn' || clean == 'mandarin' || clean == 'yue' || clean == 'zho' || clean == 'chi') {
    return 'zh';
  }
  if (clean == 'en' || clean == 'english' || clean == 'eng') return 'en';
  return clean;
}

/// Detect language from text based on character types.
/// Context-aware: When pure Hanzi/Kanji is encountered, checks contextLanguage to distinguish Japanese Kanji from Chinese.
String detectLanguage(String text, [String? contextLanguage]) {
  if (text.trim().isEmpty) return 'en';

  // Check for Korean (Hangul)
  if (UnicodeRanges.korean.hasMatch(text)) {
    return 'ko';
  }

  // Check for Japanese-specific kana (Hiragana/Katakana)
  if (UnicodeRanges.hiragana.hasMatch(text) || UnicodeRanges.katakana.hasMatch(text)) {
    return 'ja';
  }

  // Check for CJK ideographs (Kanji/Hanzi)
  if (UnicodeRanges.hanzi.hasMatch(text)) {
    final normContext = normalizeLanguageCode(contextLanguage);
    if (normContext == 'ja' || normContext == 'zh') {
      return normContext;
    }
    return 'zh';
  }

  // Default to English
  return 'en';
}

/// Detect language of a subtitle cue list by sampling non-empty cues (1:1 port of lingua-tube).
String detectSubtitleLanguage(List<SubtitleCue> cues, [String? preferredLang]) {
  if (cues.isEmpty) {
    final norm = normalizeLanguageCode(preferredLang);
    return (norm == 'ja' || norm == 'zh' || norm == 'ko' || norm == 'en') ? norm : 'en';
  }
  final sample = cues.take(15).map((c) => c.text).where((t) => t.isNotEmpty).join(' ');
  if (sample.trim().isEmpty) {
    final norm = normalizeLanguageCode(preferredLang);
    return (norm == 'ja' || norm == 'zh' || norm == 'ko' || norm == 'en') ? norm : 'en';
  }
  return detectLanguage(sample, preferredLang);
}

/// Check if text is punctuation/whitespace (CJK + Western)
bool isPunctuation(String text) {
  if (text.isEmpty) return false;
  return punctuationRegex.hasMatch(text);
}

/// Unified descriptor for supported subtitle and on-device translation languages
class SubtitleLanguageOption {
  final String code;
  final String name;
  final String flag;
  final bool isBuiltIn;

  const SubtitleLanguageOption({
    required this.code,
    required this.name,
    required this.flag,
    this.isBuiltIn = false,
  });

  /// Returns localized language name according to current app locale,
  /// falling back to endonym [name].
  String getLocalizedName(BuildContext context) {
    switch (code) {
      case 'en':
        return context.t('settings.english', null, name);
      case 'vi':
        return context.t('settings.vietnamese', null, name);
      case 'ja':
        return context.t('settings.japanese', null, name);
      case 'zh':
        return context.t('settings.chinese', null, name);
      case 'ko':
        return context.t('settings.korean', null, name);
      case 'es':
        return context.t('settings.spanish', null, name);
      case 'fr':
        return context.t('settings.french', null, name);
      case 'de':
        return context.t('settings.german', null, name);
      default:
        return name;
    }
  }

  static SubtitleLanguageOption? findByCode(String? code) {
    if (code == null) return null;
    final normalized = normalizeLanguageCode(code);
    return kSupportedSubtitleLanguages.firstWhere(
      (opt) => opt.code == normalized || opt.code == code,
      orElse: () => SubtitleLanguageOption(
        code: code,
        name: code.toUpperCase(),
        flag: '🌐',
      ),
    );
  }
}

/// Single immutable source of truth for supported dual subtitle languages across the entire app
const List<SubtitleLanguageOption> kSupportedSubtitleLanguages = [
  SubtitleLanguageOption(code: 'en', name: 'English', flag: '🇺🇸', isBuiltIn: true),
  SubtitleLanguageOption(code: 'vi', name: 'Tiếng Việt', flag: '🇻🇳'),
  SubtitleLanguageOption(code: 'ja', name: '日本語', flag: '🇯🇵'),
  SubtitleLanguageOption(code: 'zh', name: '中文', flag: '🇨🇳'),
  SubtitleLanguageOption(code: 'ko', name: '한국어', flag: '🇰🇷'),
  SubtitleLanguageOption(code: 'es', name: 'Español', flag: '🇪🇸'),
  SubtitleLanguageOption(code: 'fr', name: 'Français', flag: '🇫🇷'),
  SubtitleLanguageOption(code: 'de', name: 'Deutsch', flag: '🇩🇪'),
];
