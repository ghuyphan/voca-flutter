// lib/ui/onboarding/models/onboarding_models.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';

/// Maps a language code to its bundled flag asset in `assets/flags/`.
String flagAssetFor(String code) {
  const map = {
    'ja': 'jp',
    'ko': 'kr',
    'zh': 'cn',
    'en': 'gb',
    'vi': 'vn',
  };
  return 'assets/flags/${map[code] ?? code}.svg';
}

/// i18n key holding the localized display name of a language (e.g. "Japanese").
String languageNameKey(String code) {
  const map = {
    'ja': 'settings.japanese',
    'ko': 'settings.korean',
    'zh': 'settings.chinese',
    'en': 'settings.english',
    'vi': 'settings.vietnamese',
  };
  return map[code] ?? code;
}

/// Target learning language.
class LearningLanguageOption {
  final String code;
  final String englishName;
  final String nativeName;
  final String defaultCompanion;

  const LearningLanguageOption({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.defaultCompanion,
  });

  String get flagAsset => flagAssetFor(code);
  String get vibeKey => 'onboarding.realmVibes.$code';
  String get featuresKey => 'onboarding.langFeatures.$code';

  String get examFramework {
    switch (code) {
      case 'ja':
        return 'JLPT N5–N1';
      case 'ko':
        return 'TOPIK 1–6';
      case 'zh':
        return 'HSK 1–6';
      case 'en':
        return 'CEFR A1–C2';
      default:
        return 'All Levels';
    }
  }

  static const List<LearningLanguageOption> all = [
    LearningLanguageOption(
      code: 'ja',
      englishName: 'Japanese',
      nativeName: '日本語',
      defaultCompanion: 'wizard',
    ),
    LearningLanguageOption(
      code: 'ko',
      englishName: 'Korean',
      nativeName: '한국어',
      defaultCompanion: 'bard',
    ),
    LearningLanguageOption(
      code: 'zh',
      englishName: 'Chinese',
      nativeName: '中文',
      defaultCompanion: 'alchemist',
    ),
    LearningLanguageOption(
      code: 'en',
      englishName: 'English',
      nativeName: 'English',
      defaultCompanion: 'ranger',
    ),
  ];

  static LearningLanguageOption byCode(String code) =>
      all.firstWhere((o) => o.code == code, orElse: () => all.first);
}

/// Interface & subtitle-translation language (matches I18nService locales).
class NativeLanguageOption {
  final String code;
  final String englishName;
  final String nativeName;

  const NativeLanguageOption({
    required this.code,
    required this.englishName,
    required this.nativeName,
  });

  String get flagAsset => flagAssetFor(code);

  static const List<NativeLanguageOption> all = [
    NativeLanguageOption(code: 'en', englishName: 'English', nativeName: 'English'),
    NativeLanguageOption(code: 'vi', englishName: 'Vietnamese', nativeName: 'Tiếng Việt'),
    NativeLanguageOption(code: 'ja', englishName: 'Japanese', nativeName: '日本語'),
    NativeLanguageOption(code: 'ko', englishName: 'Korean', nativeName: '한국어'),
    NativeLanguageOption(code: 'zh', englishName: 'Chinese', nativeName: '中文'),
  ];

  static const Set<String> supportedCodes = {'en', 'vi', 'ja', 'ko', 'zh'};

  static NativeLanguageOption byCode(String code) =>
      all.firstWhere((o) => o.code == code, orElse: () => all.first);
}

/// 5-tier proficiency ladder aligned with backend tiers.
class LevelOption {
  final String id;
  final String rankKey;
  final IconData icon;

  const LevelOption({
    required this.id,
    required this.rankKey,
    required this.icon,
  });

  String get titleKey => 'level.$id';

  String get descKey {
    const map = {
      'beginner': 'onboarding.levels.beginnerDesc',
      'elementary': 'onboarding.levels.elementaryDesc',
      'intermediate': 'onboarding.levels.intermediateDesc',
      'upper_intermediate': 'onboarding.levels.upperIntermediateDesc',
      'advanced': 'onboarding.levels.advancedDesc',
    };
    return map[id] ?? '';
  }

  String get rankNameKey => 'onboarding.ranks.$rankKey';

  /// Theme-aware level colors (keyword match on the tier id).
  LevelColorInfo colors({required bool isDark}) =>
      LevelColorInfo.forLevel(id, isDark: isDark);

  /// Exam badge for the selected learning language (port of web `getLevelExamBadge`).
  String examBadge(String lang) {
    const table = {
      'zh': ['HSK 1', 'HSK 2', 'HSK 3-4', 'HSK 5', 'HSK 6'],
      'ko': ['TOPIK 1', 'TOPIK 2', 'TOPIK 3-4', 'TOPIK 5', 'TOPIK 6'],
      'en': ['A1', 'A2', 'B1', 'B2', 'C1-C2'],
      'ja': ['JLPT N5', 'JLPT N4', 'JLPT N3', 'JLPT N2', 'JLPT N1'],
    };
    final idx = all.indexWhere((l) => l.id == id).clamp(0, 4);
    return (table[lang] ?? table['ja']!)[idx];
  }

  static const List<LevelOption> all = [
    LevelOption(id: 'beginner', rankKey: 'novice', icon: Icons.spa_rounded),
    LevelOption(id: 'elementary', rankKey: 'apprentice', icon: Icons.menu_book_rounded),
    LevelOption(id: 'intermediate', rankKey: 'adept', icon: Icons.bolt_rounded),
    LevelOption(id: 'upper_intermediate', rankKey: 'veteran', icon: Icons.shield_rounded),
    LevelOption(id: 'advanced', rankKey: 'master', icon: Icons.workspace_premium_rounded),
  ];

  static LevelOption byId(String id) =>
      all.firstWhere((o) => o.id == id, orElse: () => all.first);
}

/// Daily practice pace.
class DailyGoalOption {
  final String id;
  final int minutes;
  final bool isRecommended;

  const DailyGoalOption({
    required this.id,
    required this.minutes,
    this.isRecommended = false,
  });

  String get titleKey => 'onboarding.goals.$id';
  String get descKey => 'onboarding.goals.${id}Desc';

  static const List<DailyGoalOption> all = [
    DailyGoalOption(id: 'casual', minutes: 5),
    DailyGoalOption(id: 'regular', minutes: 10, isRecommended: true),
    DailyGoalOption(id: 'serious', minutes: 15),
    DailyGoalOption(id: 'intense', minutes: 25),
  ];

  static DailyGoalOption byMinutes(int minutes) =>
      all.firstWhere((o) => o.minutes == minutes, orElse: () => all[1]);
}

/// Companion guide archetype.
class CompanionOption {
  final String id;
  final IconData icon;
  final Color color;

  const CompanionOption({
    required this.id,
    required this.icon,
    required this.color,
  });

  String get avatarAsset => 'assets/avatars/$id.webp';
  String get nameKey => 'onboarding.companions.$id';
  String get traitKey => 'onboarding.companions.${id}Trait';
  String get quoteKey => 'onboarding.companions.${id}Quote';
  String get perkKey =>
      'onboarding.perk${id[0].toUpperCase()}${id.substring(1)}';

  static const List<CompanionOption> all = [
    CompanionOption(id: 'wizard', icon: Icons.auto_stories_rounded, color: Color(0xFF8B5CF6)), // Violet
    CompanionOption(id: 'knight', icon: Icons.shield_rounded, color: Color(0xFF0284C7)), // Cobalt Blue
    CompanionOption(id: 'shinobi', icon: Icons.flash_on_rounded, color: Color(0xFFEF4444)), // Crimson Red
    CompanionOption(id: 'ranger', icon: Icons.explore_rounded, color: Color(0xFF10B981)), // Emerald Green
    CompanionOption(id: 'miner', icon: Icons.hardware_rounded, color: Color(0xFFF97316)), // Vibrant Orange
    CompanionOption(id: 'alchemist', icon: Icons.science_rounded, color: Color(0xFF06B6D4)), // Electric Cyan
    CompanionOption(id: 'bard', icon: Icons.music_note_rounded, color: Color(0xFFEC4899)), // Magenta Pink
    CompanionOption(id: 'sovereign', icon: Icons.workspace_premium_rounded, color: Color(0xFFEAB308)), // Radiant Gold
  ];

  static int indexOf(String id) {
    final i = all.indexWhere((c) => c.id == id);
    return i < 0 ? 0 : i;
  }

  static CompanionOption byId(String id) => all[indexOf(id)];
}
