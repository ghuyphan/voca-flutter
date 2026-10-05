// lib/ui/onboarding/models/onboarding_models.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';

/// Supported target learning language option in Voca
class LearningRealmOption {
  final String code;
  final String name;
  final String nativeName;
  final String flagEmoji;
  final String vibeKey;
  final String defaultCompanion;
  final Color accentColor;

  const LearningRealmOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flagEmoji,
    required this.vibeKey,
    required this.defaultCompanion,
    required this.accentColor,
  });

  String get flagAsset => 'assets/flags/${code == 'en' ? 'gb' : code}.svg';

  static const List<LearningRealmOption> all = [
    LearningRealmOption(
      code: 'ja',
      name: 'Japanese',
      nativeName: '日本語',
      flagEmoji: '🇯🇵',
      vibeKey: 'onboarding.realmVibes.ja',
      defaultCompanion: 'wizard',
      accentColor: Color(0xFFFF6B82),
    ),
    LearningRealmOption(
      code: 'ko',
      name: 'Korean',
      nativeName: '한국어',
      flagEmoji: '🇰🇷',
      vibeKey: 'onboarding.realmVibes.ko',
      defaultCompanion: 'bard',
      accentColor: Color(0xFFA78BFA),
    ),
    LearningRealmOption(
      code: 'zh',
      name: 'Chinese',
      nativeName: '中文',
      flagEmoji: '🇨🇳',
      vibeKey: 'onboarding.realmVibes.zh',
      defaultCompanion: 'alchemist',
      accentColor: Color(0xFFFBBF24),
    ),
    LearningRealmOption(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flagEmoji: '🇬🇧',
      vibeKey: 'onboarding.realmVibes.en',
      defaultCompanion: 'ranger',
      accentColor: Color(0xFF38BDF8),
    ),
  ];
}

/// Interface & subtitle translation language option
class NativeLanguageOption {
  final String code;
  final String name;
  final String nativeName;
  final String flagEmoji;

  const NativeLanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flagEmoji,
  });

  String get flagAsset => 'assets/flags/${code == 'en' ? 'gb' : code}.svg';

  static const List<NativeLanguageOption> all = [
    NativeLanguageOption(code: 'en', name: 'English', nativeName: 'English', flagEmoji: '🇬🇧'),
    NativeLanguageOption(code: 'vi', name: 'Vietnamese', nativeName: 'Tiếng Việt', flagEmoji: '🇻🇳'),
    NativeLanguageOption(code: 'ja', name: 'Japanese', nativeName: '日本語', flagEmoji: '🇯🇵'),
    NativeLanguageOption(code: 'ko', name: 'Korean', nativeName: '한국어', flagEmoji: '🇰🇷'),
    NativeLanguageOption(code: 'zh', name: 'Chinese', nativeName: '中文', flagEmoji: '🇨🇳'),
  ];
}

/// 5-tier proficiency ladder aligned with standard exams
class RankLevelOption {
  final String id;
  final String rankKey;
  final String titleKey;
  final String descKey;
  final String examBadge;
  final IconData icon;
  final Color badgeBg;
  final Color badgeText;
  final Color badgeBorder;

  const RankLevelOption({
    required this.id,
    required this.rankKey,
    required this.titleKey,
    required this.descKey,
    required this.examBadge,
    required this.icon,
    required this.badgeBg,
    required this.badgeText,
    required this.badgeBorder,
  });

  static const List<RankLevelOption> all = [
    RankLevelOption(
      id: 'beginner',
      rankKey: 'novice',
      titleKey: 'levels.beginner',
      descKey: 'levels.beginnerDesc',
      examBadge: 'JLPT N5 • HSK 1 • A1',
      icon: Icons.wb_twilight_rounded,
      badgeBg: VocaTokens.levelBeginnerBg,
      badgeText: VocaTokens.levelBeginnerText,
      badgeBorder: VocaTokens.levelBeginnerBorder,
    ),
    RankLevelOption(
      id: 'elementary',
      rankKey: 'apprentice',
      titleKey: 'levels.elementary',
      descKey: 'levels.elementaryDesc',
      examBadge: 'JLPT N4 • HSK 2 • A2',
      icon: Icons.filter_drama_rounded,
      badgeBg: VocaTokens.levelElementaryBg,
      badgeText: VocaTokens.levelElementaryText,
      badgeBorder: VocaTokens.levelElementaryBorder,
    ),
    RankLevelOption(
      id: 'intermediate',
      rankKey: 'adept',
      titleKey: 'levels.intermediate',
      descKey: 'levels.intermediateDesc',
      examBadge: 'JLPT N3 • HSK 3-4 • B1',
      icon: Icons.bolt_rounded,
      badgeBg: VocaTokens.levelIntermediateBg,
      badgeText: VocaTokens.levelIntermediateText,
      badgeBorder: VocaTokens.levelIntermediateBorder,
    ),
    RankLevelOption(
      id: 'upper_intermediate',
      rankKey: 'veteran',
      titleKey: 'levels.upperIntermediate',
      descKey: 'levels.upperIntermediateDesc',
      examBadge: 'JLPT N2 • HSK 5 • B2',
      icon: Icons.shield_rounded,
      badgeBg: VocaTokens.levelUpperBg,
      badgeText: VocaTokens.levelUpperText,
      badgeBorder: VocaTokens.levelUpperBorder,
    ),
    RankLevelOption(
      id: 'advanced',
      rankKey: 'master',
      titleKey: 'levels.advanced',
      descKey: 'levels.advancedDesc',
      examBadge: 'JLPT N1 • HSK 6 • C1-C2',
      icon: Icons.workspace_premium_rounded,
      badgeBg: VocaTokens.levelAdvancedBg,
      badgeText: VocaTokens.levelAdvancedText,
      badgeBorder: VocaTokens.levelAdvancedBorder,
    ),
  ];
}

/// Daily commitment pace options
class DailyGoalOption {
  final String id;
  final int minutes;
  final String titleKey;
  final String descKey;
  final IconData icon;
  final bool isRecommended;

  const DailyGoalOption({
    required this.id,
    required this.minutes,
    required this.titleKey,
    required this.descKey,
    required this.icon,
    this.isRecommended = false,
  });

  static const List<DailyGoalOption> all = [
    DailyGoalOption(
      id: 'casual',
      minutes: 5,
      titleKey: 'onboarding.goals.casual',
      descKey: 'onboarding.goals.casualDesc',
      icon: Icons.timer_outlined,
    ),
    DailyGoalOption(
      id: 'regular',
      minutes: 10,
      titleKey: 'onboarding.goals.regular',
      descKey: 'onboarding.goals.regularDesc',
      icon: Icons.local_fire_department_rounded,
      isRecommended: true,
    ),
    DailyGoalOption(
      id: 'serious',
      minutes: 15,
      titleKey: 'onboarding.goals.serious',
      descKey: 'onboarding.goals.seriousDesc',
      icon: Icons.military_tech_rounded,
    ),
    DailyGoalOption(
      id: 'intense',
      minutes: 25,
      titleKey: 'onboarding.goals.intense',
      descKey: 'onboarding.goals.intenseDesc',
      icon: Icons.stars_rounded,
    ),
  ];
}

/// 8 Companion Spirit Guide Archetypes
class CompanionSpiritOption {
  final String id;
  final String nameKey;
  final String traitKey;
  final String quoteKey;
  final IconData icon;
  final Color color;
  final String perkKey;

  const CompanionSpiritOption({
    required this.id,
    required this.nameKey,
    required this.traitKey,
    required this.quoteKey,
    required this.icon,
    required this.color,
    required this.perkKey,
  });

  String get avatarAsset => 'assets/avatars/$id.webp';

  static const List<CompanionSpiritOption> all = [
    CompanionSpiritOption(
      id: 'wizard',
      nameKey: 'onboarding.companions.wizard',
      traitKey: 'onboarding.companions.wizardTrait',
      quoteKey: 'onboarding.companions.wizardQuote',
      icon: Icons.auto_stories_rounded,
      color: Color(0xFFA78BFA),
      perkKey: 'onboarding.perkWizard',
    ),
    CompanionSpiritOption(
      id: 'knight',
      nameKey: 'onboarding.companions.knight',
      traitKey: 'onboarding.companions.knightTrait',
      quoteKey: 'onboarding.companions.knightQuote',
      icon: Icons.shield_rounded,
      color: Color(0xFF38BDF8),
      perkKey: 'onboarding.perkKnight',
    ),
    CompanionSpiritOption(
      id: 'shinobi',
      nameKey: 'onboarding.companions.shinobi',
      traitKey: 'onboarding.companions.shinobiTrait',
      quoteKey: 'onboarding.companions.shinobiQuote',
      icon: Icons.flash_on_rounded,
      color: Color(0xFFFF6B82),
      perkKey: 'onboarding.perkShinobi',
    ),
    CompanionSpiritOption(
      id: 'ranger',
      nameKey: 'onboarding.companions.ranger',
      traitKey: 'onboarding.companions.rangerTrait',
      quoteKey: 'onboarding.companions.rangerQuote',
      icon: Icons.explore_rounded,
      color: Color(0xFF34D399),
      perkKey: 'onboarding.perkRanger',
    ),
    CompanionSpiritOption(
      id: 'miner',
      nameKey: 'onboarding.companions.miner',
      traitKey: 'onboarding.companions.minerTrait',
      quoteKey: 'onboarding.companions.minerQuote',
      icon: Icons.hardware_rounded,
      color: Color(0xFFF59E0B),
      perkKey: 'onboarding.perkMiner',
    ),
    CompanionSpiritOption(
      id: 'alchemist',
      nameKey: 'onboarding.companions.alchemist',
      traitKey: 'onboarding.companions.alchemistTrait',
      quoteKey: 'onboarding.companions.alchemistQuote',
      icon: Icons.science_rounded,
      color: Color(0xFFFBBF24),
      perkKey: 'onboarding.perkAlchemist',
    ),
    CompanionSpiritOption(
      id: 'bard',
      nameKey: 'onboarding.companions.bard',
      traitKey: 'onboarding.companions.bardTrait',
      quoteKey: 'onboarding.companions.bardQuote',
      icon: Icons.music_note_rounded,
      color: Color(0xFFEC4899),
      perkKey: 'onboarding.perkBard',
    ),
    CompanionSpiritOption(
      id: 'sovereign',
      nameKey: 'onboarding.companions.sovereign',
      traitKey: 'onboarding.companions.sovereignTrait',
      quoteKey: 'onboarding.companions.sovereignQuote',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFFEAB308),
      perkKey: 'onboarding.perkSovereign',
    ),
  ];
}

/// Starter supply cache rewards
class StarterLootItem {
  final String titleKey;
  final String descKey;
  final IconData icon;
  final Color iconColor;
  final Color bgTint;

  const StarterLootItem({
    required this.titleKey,
    required this.descKey,
    required this.icon,
    required this.iconColor,
    required this.bgTint,
  });

  static const List<StarterLootItem> all = [
    StarterLootItem(
      titleKey: 'onboarding.starterLoot.diamonds',
      descKey: 'onboarding.starterLoot.diamondsDesc',
      icon: Icons.diamond_rounded,
      iconColor: Color(0xFF38BDF8),
      bgTint: Color(0x1F38BDF8),
    ),
    StarterLootItem(
      titleKey: 'onboarding.starterLoot.xp',
      descKey: 'onboarding.starterLoot.xpDesc',
      icon: Icons.auto_awesome_rounded,
      iconColor: Color(0xFFFF6B82),
      bgTint: Color(0x1FFF6B82),
    ),
    StarterLootItem(
      titleKey: 'onboarding.starterLoot.hearth',
      descKey: 'onboarding.starterLoot.hearthDesc',
      icon: Icons.local_fire_department_rounded,
      iconColor: Color(0xFFFB923C),
      bgTint: Color(0x1FFB923C),
    ),
    StarterLootItem(
      titleKey: 'onboarding.starterLoot.freeze',
      descKey: 'onboarding.starterLoot.freezeDesc',
      icon: Icons.ac_unit_rounded,
      iconColor: Color(0xFF818CF8),
      bgTint: Color(0x1F818CF8),
    ),
  ];
}
