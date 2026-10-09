// lib/services/gamification_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../ui/gamification/widgets/rpg_shield_crest.dart';
import 'i18n_service.dart';
import 'voca_api_client.dart';
import 'supabase_service.dart';

class DayActivity {
  final DateTime date;
  final bool isActive;
  final bool isToday;
  final String dayLabel;
  final String dayNumber;

  const DayActivity({
    required this.date,
    required this.isActive,
    required this.isToday,
    required this.dayLabel,
    required this.dayNumber,
  });
}

enum AchievementCategory {
  immersion,
  vocabulary,
  streak,
  srs,
  quiz,
}

enum AchievementTier {
  bronze,
  silver,
  gold,
  diamond,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementCategory category;
  final AchievementTier tier;
  final int target;
  final int current;
  final bool isUnlocked;
  final bool isClaimed;
  final int xpReward;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.category = AchievementCategory.immersion,
    this.tier = AchievementTier.bronze,
    required this.target,
    this.current = 0,
    this.isUnlocked = false,
    this.isClaimed = false,
    required this.xpReward,
    this.unlockedAt,
  });

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
  bool get canClaim => isUnlocked && !isClaimed;

  String localizedTitle(BuildContext context) {
    final key = id.replaceAll('_', '');
    final direct = context.t('achievements.$key.title', null, '');
    if (direct.isNotEmpty) return direct;
    final fallback = context.t('achievements.$id.title', null, title);
    return fallback;
  }

  String localizedDescription(BuildContext context) {
    final key = id.replaceAll('_', '');
    final direct = context.t('achievements.$key.desc', null, '');
    if (direct.isNotEmpty) return direct;
    final fallback = context.t('achievements.$id.desc', null, description);
    return fallback;
  }

  Achievement copyWith({
    int? current,
    bool? isUnlocked,
    bool? isClaimed,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      category: category,
      tier: tier,
      target: target,
      current: current ?? this.current,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isClaimed: isClaimed ?? this.isClaimed,
      xpReward: xpReward,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'current': current,
    'isUnlocked': isUnlocked,
    'isClaimed': isClaimed,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  factory Achievement.fromJson(Map<String, dynamic> json, Achievement template) {
    final unlocked = json['isUnlocked'] as bool? ?? false;
    final claimed = json['isClaimed'] as bool? ?? (unlocked ? true : false);
    return Achievement(
      id: template.id,
      title: template.title,
      description: template.description,
      icon: template.icon,
      category: template.category,
      tier: template.tier,
      target: template.target,
      current: (json['current'] as num?)?.toInt() ?? template.current,
      isUnlocked: unlocked,
      isClaimed: claimed,
      xpReward: template.xpReward,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.tryParse(json['unlockedAt'] as String)
          : null,
    );
  }
}

enum MissionType {
  watchVideo,
  saveWord,
  srsReview,
  completeQuiz,
  lookUpDict,
}

class DailyMission {
  final String id;
  final MissionType type;
  final String title;
  final String description;
  final IconData icon;
  final int target;
  final int progress;
  final bool isCompleted;
  final bool isClaimed;
  final int xpReward;

  const DailyMission({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    this.progress = 0,
    this.isCompleted = false,
    this.isClaimed = false,
    required this.xpReward,
  });

  double get progressRatio => target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

  String localizedTitle(BuildContext context) {
    final key = switch (id) {
      'daily_watch_1' => 'watch1',
      'daily_watch_2' => 'watch2',
      'daily_watch_3' => 'watch3',
      'daily_save_2' => 'save2',
      'daily_save_3' => 'save3',
      'daily_save_5' => 'save5',
      'daily_dict_3' => 'dict3',
      'daily_dict_5' => 'dict5',
      'daily_srs_5' => 'srs5',
      'daily_srs_10' => 'srs10',
      'daily_srs_15' => 'srs15',
      'daily_quiz_1' => 'quiz1',
      'daily_quiz_2' => 'quiz2',
      _ => id.replaceAll('daily_', ''),
    };
    return context.t('missions.$key.title', null, title);
  }

  String localizedDescription(BuildContext context) {
    final key = switch (id) {
      'daily_watch_1' => 'watch1',
      'daily_watch_2' => 'watch2',
      'daily_watch_3' => 'watch3',
      'daily_save_2' => 'save2',
      'daily_save_3' => 'save3',
      'daily_save_5' => 'save5',
      'daily_dict_3' => 'dict3',
      'daily_dict_5' => 'dict5',
      'daily_srs_5' => 'srs5',
      'daily_srs_10' => 'srs10',
      'daily_srs_15' => 'srs15',
      'daily_quiz_1' => 'quiz1',
      'daily_quiz_2' => 'quiz2',
      _ => id.replaceAll('daily_', ''),
    };
    return context.t('missions.$key.desc', null, description);
  }

  DailyMission copyWith({
    int? progress,
    bool? isCompleted,
    bool? isClaimed,
  }) {
    return DailyMission(
      id: id,
      type: type,
      title: title,
      description: description,
      icon: icon,
      target: target,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      isClaimed: isClaimed ?? this.isClaimed,
      xpReward: xpReward,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'description': description,
    'target': target,
    'progress': progress,
    'isCompleted': isCompleted,
    'isClaimed': isClaimed,
    'xpReward': xpReward,
  };

  factory DailyMission.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'watchVideo';
    final type = MissionType.values.firstWhere(
      (m) => m.name == typeName,
      orElse: () => MissionType.watchVideo,
    );

    IconData resolveIcon(MissionType t) {
      switch (t) {
        case MissionType.watchVideo:
          return Icons.play_circle_fill_rounded;
        case MissionType.saveWord:
          return Icons.bookmark_added_rounded;
        case MissionType.srsReview:
          return Icons.style_rounded;
        case MissionType.completeQuiz:
          return Icons.sports_kabaddi_rounded;
        case MissionType.lookUpDict:
          return Icons.auto_stories_rounded;
      }
    }

    return DailyMission(
      id: json['id'] as String? ?? 'mission_1',
      type: type,
      title: json['title'] as String? ?? 'Daily Quest',
      description: json['description'] as String? ?? 'Complete your daily learning goal',
      icon: resolveIcon(type),
      target: (json['target'] as num?)?.toInt() ?? 1,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isClaimed: json['isClaimed'] as bool? ?? false,
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 25,
    );
  }
}

class DailyMissionsState {
  final String date;
  final List<DailyMission> missions;
  final bool allCompletedBonusClaimed;
  final int bonusXp;

  const DailyMissionsState({
    required this.date,
    required this.missions,
    this.allCompletedBonusClaimed = false,
    this.bonusXp = 50,
  });

  DailyMissionsState copyWith({
    String? date,
    List<DailyMission>? missions,
    bool? allCompletedBonusClaimed,
    int? bonusXp,
  }) {
    return DailyMissionsState(
      date: date ?? this.date,
      missions: missions ?? this.missions,
      allCompletedBonusClaimed: allCompletedBonusClaimed ?? this.allCompletedBonusClaimed,
      bonusXp: bonusXp ?? this.bonusXp,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'missions': missions.map((m) => m.toJson()).toList(),
    'allCompletedBonusClaimed': allCompletedBonusClaimed,
    'bonusXp': bonusXp,
  };

  factory DailyMissionsState.fromJson(Map<String, dynamic> json) {
    final list = (json['missions'] as List?)
            ?.map((e) => DailyMission.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return DailyMissionsState(
      date: json['date'] as String? ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
      missions: list,
      allCompletedBonusClaimed: json['allCompletedBonusClaimed'] as bool? ?? false,
      bonusXp: (json['bonusXp'] as num?)?.toInt() ?? 50,
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String name;
  final String avatar;
  final int xp;
  final int weeklyXp;
  final int level;
  final int streak;
  final int badgesCount;
  final String country;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.avatar,
    required this.xp,
    required this.weeklyXp,
    required this.level,
    required this.streak,
    required this.badgesCount,
    required this.country,
    this.isCurrentUser = false,
  });
}

class GamificationService {
  final VocaApiClient apiClient;
  final SupabaseService supabaseService;

  GamificationService({
    required this.apiClient,
    required this.supabaseService,
  });

  // Streaks
  final currentStreak = signal<int>(0);
  final longestStreak = signal<int>(0);
  final streakFreezes = signal<int>(2);
  final activityCalendar = signal<List<DayActivity>>([]);
  bool get practicedToday => activityCalendar.value.any((d) => d.isToday && d.isActive);
  Set<String> get activeDates => Set.unmodifiable(_activeDateStrings);

  // Diamonds / AI Credits
  final diamonds = signal<int>(5);
  final maxDiamonds = signal<int>(5);

  // XP & Quadratic Leveling Curve (Canonical 50 levels)
  // Level = floor(sqrt(max(0, XP) / 75)) + 1, capped at 50
  static int calculateLevel(int xp) =>
      min(50, max(1, (sqrt(max(0, xp) / 75.0)).floor() + 1));
  static int xpForLevel(int lvl) => 75 * (lvl - 1) * (lvl - 1);
  static int xpForNextLevel(int lvl) => 75 * lvl * lvl;

  final xp = signal<int>(0);
  final weeklyXp = signal<int>(0);

  late final Computed<int> level = computed(() => calculateLevel(xp.value));
  late final Computed<int> currentLevelXp = computed(() {
    final lvl = level.value;
    if (lvl >= 50) return xp.value - xpForLevel(50);
    return max(0, xp.value - xpForLevel(lvl));
  });
  late final Computed<int> nextLevelTargetXp = computed(() {
    final lvl = level.value;
    if (lvl >= 50) return 0;
    return xpForNextLevel(lvl) - xpForLevel(lvl);
  });
  late final Computed<double> levelProgress = computed(() {
    final lvl = level.value;
    if (lvl >= 50) return 1.0;
    final cur = currentLevelXp.value;
    final needed = nextLevelTargetXp.value;
    if (needed <= 0) return 1.0;
    return (cur / needed).clamp(0.0, 1.0);
  });
  late final Computed<int> progressToNextPercent = computed(() {
    return (levelProgress.value * 100).round();
  });

  // Tier info for level
  static RpgCrestStyle getRankTier(int level) => RpgCrestStyle.forLevel(level);

  static String getRankTitle(int level) {
    final lvl = level.clamp(1, 50);
    if (lvl <= 2) return 'Novice Explorer';
    if (lvl <= 5) return 'Word Apprentice';
    if (lvl <= 8) return 'Bronze Scribe';
    if (lvl <= 10) return 'Shield Bearer';
    if (lvl <= 13) return 'Silver Scholar';
    if (lvl <= 15) return 'Grammar Knight';
    if (lvl <= 18) return 'Gold Adept';
    if (lvl <= 20) return 'Templar Linguist';
    if (lvl <= 23) return 'Platinum Voyager';
    if (lvl <= 25) return 'Lexicon Master';
    if (lvl <= 28) return 'Emerald Sentinel';
    if (lvl <= 30) return 'Polyglot Veteran';
    if (lvl <= 33) return 'Diamond Paragon';
    if (lvl <= 35) return 'Hero of Tongues';
    if (lvl <= 38) return 'Arcane Scholar';
    if (lvl <= 40) return 'Grandmaster of Voca';
    if (lvl <= 45) return 'Supreme Archon';
    return 'Mythic Sovereign';
  }

  // Daily Missions
  final dailyMissions = signal<DailyMissionsState>(
    DailyMissionsState(
      date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      missions: [],
    ),
  );

  late final Computed<int> completedMissionsCount = computed(() =>
    dailyMissions.value.missions.where((m) => m.isCompleted).length
  );
  late final Computed<int> totalMissionsCount = computed(() =>
    dailyMissions.value.missions.length
  );
  late final Computed<bool> canClaimDailyBonus = computed(() {
    final state = dailyMissions.value;
    final allDone = state.missions.isNotEmpty &&
        state.missions.every((m) => m.isCompleted);
    return allDone && !state.allCompletedBonusClaimed;
  });

  // Catalog of 33 rich achievements matching web
  static final List<Achievement> _defaultAchievements = [
    // Immersion (Videos watched)
    const Achievement(
      id: 'watch_1',
      title: 'First Video Watched',
      description: 'Watch your first interactive video lesson in Voca.',
      icon: Icons.play_arrow_rounded,
      category: AchievementCategory.immersion,
      tier: AchievementTier.bronze,
      target: 1,
      xpReward: 25,
    ),
    const Achievement(
      id: 'watch_5',
      title: 'Video Explorer',
      description: 'Complete 5 authentic video lessons.',
      icon: Icons.movie_outlined,
      category: AchievementCategory.immersion,
      tier: AchievementTier.bronze,
      target: 5,
      xpReward: 50,
    ),
    const Achievement(
      id: 'watch_15',
      title: 'Film Fanatic',
      description: 'Immerse yourself through 15 videos.',
      icon: Icons.video_collection_outlined,
      category: AchievementCategory.immersion,
      tier: AchievementTier.bronze,
      target: 15,
      xpReward: 100,
    ),
    const Achievement(
      id: 'watch_30',
      title: 'Binge Learner',
      description: 'Finish 30 video lessons in target language.',
      icon: Icons.live_tv_rounded,
      category: AchievementCategory.immersion,
      tier: AchievementTier.silver,
      target: 30,
      xpReward: 175,
    ),
    const Achievement(
      id: 'watch_60',
      title: 'Immersion Voyager',
      description: 'Watch 60 videos with interactive subtitles.',
      icon: Icons.explore_outlined,
      category: AchievementCategory.immersion,
      tier: AchievementTier.silver,
      target: 60,
      xpReward: 300,
    ),
    const Achievement(
      id: 'watch_100',
      title: 'Centennial Immersion',
      description: 'Reach 100 video lessons completed.',
      icon: Icons.wb_sunny_outlined,
      category: AchievementCategory.immersion,
      tier: AchievementTier.gold,
      target: 100,
      xpReward: 500,
    ),
    const Achievement(
      id: 'watch_250',
      title: 'Media Archon',
      description: 'Study 250 authentic native videos.',
      icon: Icons.emoji_events_outlined,
      category: AchievementCategory.immersion,
      tier: AchievementTier.diamond,
      target: 250,
      xpReward: 800,
    ),
    const Achievement(
      id: 'watch_500',
      title: 'Cinematic Sovereign',
      description: 'Achieve the pinnacle of 500 watched videos.',
      icon: Icons.military_tech_rounded,
      category: AchievementCategory.immersion,
      tier: AchievementTier.diamond,
      target: 500,
      xpReward: 1000,
    ),

    // Vocabulary Mining
    const Achievement(
      id: 'vocab_1',
      title: 'First Word Mined',
      description: 'Save your first word from video subtitles to deck.',
      icon: Icons.bookmark_add_outlined,
      category: AchievementCategory.vocabulary,
      tier: AchievementTier.bronze,
      target: 1,
      xpReward: 15,
    ),
    const Achievement(
      id: 'vocab_10',
      title: 'Lexicon Builder',
      description: 'Add 10 new vocabulary cards to your study deck.',
      icon: Icons.view_in_ar_rounded,
      category: AchievementCategory.vocabulary,
      tier: AchievementTier.bronze,
      target: 10,
      xpReward: 30,
    ),
    const Achievement(
      id: 'vocab_25',
      title: "Scribe's Quill",
      description: 'Mine 25 authentic words with sentence context.',
      icon: Icons.edit_note_rounded,
      category: AchievementCategory.vocabulary,
      tier: AchievementTier.bronze,
      target: 25,
      xpReward: 50,
    ),
    const Achievement(
      id: 'vocab_50',
      title: 'Scroll Keeper',
      description: 'Collect 50 vocabulary flashcards.',
      icon: Icons.menu_book_rounded,
      category: AchievementCategory.vocabulary,
      tier: AchievementTier.bronze,
      target: 50,
      xpReward: 100,
    ),
    const Achievement(
      id: 'vocab_100',
      title: 'Century of Words',
      description: 'Build a personalized deck of 100 words.',
      icon: Icons.diamond_outlined,
      category: AchievementCategory.vocabulary,
      tier: AchievementTier.silver,
      target: 100,
      xpReward: 200,
    ),
    const Achievement(
      id: 'vocab_250',
      title: 'Grimoire Master',
      description: 'Mine 250 words across diverse video topics.',
      icon: Icons.auto_stories_rounded,
      category: AchievementCategory.vocabulary,
      tier: AchievementTier.silver,
      target: 250,
      xpReward: 400,
    ),
    const Achievement(
      id: 'vocab_500',
      title: 'Treasure Trove',
      description: 'Curate 500 vocabulary words in your library.',
      icon: Icons.inventory_2_outlined,
      category: AchievementCategory.vocabulary,
      tier: AchievementTier.gold,
      target: 500,
      xpReward: 600,
    ),
    const Achievement(
      id: 'vocab_1000',
      title: 'Living Lexicon',
      description: 'Amass an impressive collection of 1,000 words.',
      icon: Icons.workspace_premium_rounded,
      category: AchievementCategory.vocabulary,
      tier: AchievementTier.diamond,
      target: 1000,
      xpReward: 1000,
    ),

    // Vocabulary Mastery (SRS Interval >= 21 days or Known)
    const Achievement(
      id: 'vocab_master_10',
      title: 'Solid Foundation',
      description: 'Master 10 words with high retention interval.',
      icon: Icons.verified_outlined,
      category: AchievementCategory.vocabulary,
      tier: AchievementTier.bronze,
      target: 10,
      xpReward: 100,
    ),
    const Achievement(
      id: 'vocab_master_50',
      title: 'Memory Aegis',
      description: 'Master 50 words in long-term memory.',
      icon: Icons.shield_outlined,
      category: AchievementCategory.vocabulary,
      tier: AchievementTier.silver,
      target: 50,
      xpReward: 250,
    ),
    const Achievement(
      id: 'vocab_master_100',
      title: 'Ironclad Mind',
      description: 'Reach mastery on 100 vocabulary cards.',
      icon: Icons.shield_moon_outlined,
      category: AchievementCategory.vocabulary,
      tier: AchievementTier.silver,
      target: 100,
      xpReward: 450,
    ),
    const Achievement(
      id: 'vocab_master_250',
      title: 'Crystal Recall',
      description: '250 words fully anchored in long-term memory.',
      icon: Icons.auto_awesome_rounded,
      category: AchievementCategory.vocabulary,
      tier: AchievementTier.gold,
      target: 250,
      xpReward: 700,
    ),
    const Achievement(
      id: 'vocab_master_500',
      title: 'Eternal Memory',
      description: 'Master 500 vocabulary words with spaced repetition.',
      icon: Icons.star_rounded,
      category: AchievementCategory.vocabulary,
      tier: AchievementTier.diamond,
      target: 500,
      xpReward: 1000,
    ),

    // Daily Streaks
    const Achievement(
      id: 'streak_3',
      title: 'Spark Ignited',
      description: 'Maintain a 3-day continuous practice streak.',
      icon: Icons.electric_bolt_rounded,
      category: AchievementCategory.streak,
      tier: AchievementTier.bronze,
      target: 3,
      xpReward: 30,
    ),
    const Achievement(
      id: 'streak_7',
      title: 'Week of Fire',
      description: 'Ignite your learning habit for 7 consecutive days.',
      icon: Icons.local_fire_department_rounded,
      category: AchievementCategory.streak,
      tier: AchievementTier.bronze,
      target: 7,
      xpReward: 70,
    ),
    const Achievement(
      id: 'streak_14',
      title: 'Fortnight Hearth',
      description: 'Keep your streak burning for 14 continuous days.',
      icon: Icons.fireplace_rounded,
      category: AchievementCategory.streak,
      tier: AchievementTier.silver,
      target: 14,
      xpReward: 150,
    ),
    const Achievement(
      id: 'streak_30',
      title: 'Monthly Blaze',
      description: 'Achieve a legendary 30-day streak milestone.',
      icon: Icons.whatshot_rounded,
      category: AchievementCategory.streak,
      tier: AchievementTier.silver,
      target: 30,
      xpReward: 300,
    ),
    const Achievement(
      id: 'streak_60',
      title: 'Season of Light',
      description: 'Maintain daily immersion for 60 consecutive days.',
      icon: Icons.light_mode_rounded,
      category: AchievementCategory.streak,
      tier: AchievementTier.gold,
      target: 60,
      xpReward: 500,
    ),
    const Achievement(
      id: 'streak_100',
      title: 'Century Flame',
      description: 'Reach the centennial club: 100 continuous days.',
      icon: Icons.military_tech_outlined,
      category: AchievementCategory.streak,
      tier: AchievementTier.gold,
      target: 100,
      xpReward: 800,
    ),
    const Achievement(
      id: 'streak_200',
      title: 'Unyielding Spirit',
      description: 'Defy distraction with a 200-day immersion streak.',
      icon: Icons.diamond_rounded,
      category: AchievementCategory.streak,
      tier: AchievementTier.diamond,
      target: 200,
      xpReward: 1000,
    ),
    const Achievement(
      id: 'streak_365',
      title: 'Year of Ascension',
      description: 'A full 365-day year of dedication to fluency.',
      icon: Icons.brightness_high_rounded,
      category: AchievementCategory.streak,
      tier: AchievementTier.diamond,
      target: 365,
      xpReward: 1000,
    ),

    // Study & Flashcards (SRS Reviews)
    const Achievement(
      id: 'srs_10',
      title: 'Quick Review',
      description: 'Complete 10 SM-2 flashcard review flips.',
      icon: Icons.style_outlined,
      category: AchievementCategory.srs,
      tier: AchievementTier.bronze,
      target: 10,
      xpReward: 50,
    ),
    const Achievement(
      id: 'srs_50',
      title: 'Repetition Cadet',
      description: 'Perform 50 spaced repetition card reviews.',
      icon: Icons.psychology_outlined,
      category: AchievementCategory.srs,
      tier: AchievementTier.bronze,
      target: 50,
      xpReward: 150,
    ),
    const Achievement(
      id: 'srs_100',
      title: 'Synapse Sparks',
      description: 'Complete 100 total card reviews.',
      icon: Icons.flash_on_rounded,
      category: AchievementCategory.srs,
      tier: AchievementTier.silver,
      target: 100,
      xpReward: 300,
    ),
    const Achievement(
      id: 'srs_250',
      title: 'Memory Forge',
      description: 'Reinforce recall with 250 flashcard reviews.',
      icon: Icons.build_circle_outlined,
      category: AchievementCategory.srs,
      tier: AchievementTier.silver,
      target: 250,
      xpReward: 500,
    ),
    const Achievement(
      id: 'srs_500',
      title: 'Spaced Prodigy',
      description: 'Pass 500 reviews with spaced repetition grading.',
      icon: Icons.emoji_events_rounded,
      category: AchievementCategory.srs,
      tier: AchievementTier.gold,
      target: 500,
      xpReward: 750,
    ),
    const Achievement(
      id: 'srs_1000',
      title: 'Grand Archivist',
      description: 'Review cards 1,000 times across your lifetime deck.',
      icon: Icons.hourglass_top_rounded,
      category: AchievementCategory.srs,
      tier: AchievementTier.diamond,
      target: 1000,
      xpReward: 1000,
    ),

    // Quizzes & Comprehension
    const Achievement(
      id: 'quiz_1',
      title: 'First Trial',
      description: 'Complete your first subtitle comprehension quiz.',
      icon: Icons.assignment_outlined,
      category: AchievementCategory.quiz,
      tier: AchievementTier.bronze,
      target: 1,
      xpReward: 20,
    ),
    const Achievement(
      id: 'quiz_5',
      title: 'Bullseye Apprentice',
      description: 'Successfully complete 5 subtitle quizzes.',
      icon: Icons.track_changes_rounded,
      category: AchievementCategory.quiz,
      tier: AchievementTier.bronze,
      target: 5,
      xpReward: 50,
    ),
    const Achievement(
      id: 'quiz_15',
      title: 'Trial Veteran',
      description: 'Answer 15 comprehension quizzes correctly.',
      icon: Icons.search_rounded,
      category: AchievementCategory.quiz,
      tier: AchievementTier.silver,
      target: 15,
      xpReward: 150,
    ),
    const Achievement(
      id: 'quiz_30',
      title: 'Mental Gymnast',
      description: 'Solve 30 sentence and listening quizzes.',
      icon: Icons.psychology_alt_rounded,
      category: AchievementCategory.quiz,
      tier: AchievementTier.silver,
      target: 30,
      xpReward: 300,
    ),
    const Achievement(
      id: 'quiz_60',
      title: 'Tournament Champion',
      description: 'Master 60 comprehension challenge quizzes.',
      icon: Icons.sports_kabaddi_rounded,
      category: AchievementCategory.quiz,
      tier: AchievementTier.gold,
      target: 60,
      xpReward: 500,
    ),
    const Achievement(
      id: 'quiz_100',
      title: 'Grand Inquisitor',
      description: 'Conquer 100 language comprehension quizzes.',
      icon: Icons.stars_rounded,
      category: AchievementCategory.quiz,
      tier: AchievementTier.diamond,
      target: 100,
      xpReward: 800,
    ),
  ];

  final achievements = signal<List<Achievement>>(_defaultAchievements);

  late final Computed<bool> hasClaimableRewards = computed(() {
    final hasAch = achievements.value.any((a) => a.canClaim);
    final hasMissions = dailyMissions.value.missions.any((m) => m.isCompleted && !m.isClaimed);
    return hasAch || hasMissions || canClaimDailyBonus.value;
  });

  late final Computed<int> claimableCount = computed(() {
    final achCount = achievements.value.where((a) => a.canClaim).length;
    final missionCount = dailyMissions.value.missions.where((m) => m.isCompleted && !m.isClaimed).length;
    final bonus = canClaimDailyBonus.value ? 1 : 0;
    return achCount + missionCount + bonus;
  });

  /// Computes the next upcoming, locked streak milestone achievement.
  late final Computed<Achievement?> nextStreakMilestone = computed(() {
    final list = achievements.value
        .where((a) => a.category == AchievementCategory.streak && !a.isUnlocked)
        .toList();
    if (list.isEmpty) return null;
    list.sort((a, b) => a.target.compareTo(b.target));
    return list.first;
  });

  final Set<String> _activeDateStrings = {};
  DateTime? _lastActiveDate;
  int _totalVideosWatched = 0;
  int _totalWordsSaved = 0;
  int _totalCardsReviewed = 0;
  int _totalQuizzesCompleted = 0;

  // Anti-spam lockout tracking for Cloze Quizzes (daily per-sentence deduplication & velocity cap)
  final Set<String> _todaySolvedQuizKeys = {};
  String? _lastQuizDate;
  int _todayQuizXpAwarded = 0;

  /// Initialize local state from SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      currentStreak.value = prefs.getInt('voca_current_streak') ?? 0;
      longestStreak.value = prefs.getInt('voca_longest_streak') ?? 0;
      streakFreezes.value = prefs.getInt('voca_streak_freezes') ?? 2;
      diamonds.value = prefs.getInt('voca_diamonds') ?? 5;
      maxDiamonds.value = prefs.getInt('voca_max_diamonds') ?? 5;
      xp.value = prefs.getInt('voca_xp') ?? 0;
      weeklyXp.value = prefs.getInt('voca_weekly_xp') ?? 0;

      final lastDateStr = prefs.getString('voca_last_active_date');
      if (lastDateStr != null) {
        _lastActiveDate = DateTime.tryParse(lastDateStr);
      }

      final dates = prefs.getStringList('voca_active_dates') ?? [];
      _activeDateStrings.addAll(dates);

      _totalVideosWatched = prefs.getInt('voca_total_videos_watched') ?? 0;
      _totalWordsSaved = prefs.getInt('voca_total_words_saved') ?? 0;
      _totalCardsReviewed = prefs.getInt('voca_total_cards_reviewed') ?? 0;
      _totalQuizzesCompleted = prefs.getInt('voca_total_quizzes_completed') ?? 0;

      // Restore quiz anti-spam tracking
      final lastQuizDate = prefs.getString('voca_last_quiz_date');
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (lastQuizDate == todayStr) {
        _lastQuizDate = todayStr;
        _todaySolvedQuizKeys.addAll(prefs.getStringList('voca_today_solved_quizzes') ?? []);
        _todayQuizXpAwarded = prefs.getInt('voca_today_quiz_xp') ?? 0;
      } else {
        _lastQuizDate = todayStr;
        _todaySolvedQuizKeys.clear();
        _todayQuizXpAwarded = 0;
      }

      // Load Achievements
      final achievementsJson = prefs.getString('voca_achievements_v2') ?? prefs.getString('voca_achievements');
      if (achievementsJson != null) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(achievementsJson);
          final list = _defaultAchievements.map((template) {
            final data = decoded[template.id];
            if (data is Map<String, dynamic>) {
              return Achievement.fromJson(data, template);
            }
            return template;
          }).toList();
          achievements.value = list;
        } catch (_) {}
      }

      // Load Daily Missions
      _loadOrCreateDailyMissions(prefs);

      _recomputeActivityCalendar();
    } catch (e) {
      debugPrint('[GamificationService] Error initializing: $e');
    }
  }

  /// Create or restore 3-slot daily missions matching web app logic
  void _loadOrCreateDailyMissions(SharedPreferences prefs) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final missionsJson = prefs.getString('voca_daily_missions');

    if (missionsJson != null) {
      try {
        final decoded = jsonDecode(missionsJson) as Map<String, dynamic>;
        final state = DailyMissionsState.fromJson(decoded);
        if (state.date == todayStr && state.missions.isNotEmpty) {
          dailyMissions.value = state;
          return;
        }
      } catch (_) {}
    }

    // Generate new missions for today
    dailyMissions.value = _generateDailyMissions(todayStr);
    _persist();
  }

  DailyMissionsState _generateDailyMissions(String dateStr) {
    // Generate deterministic seed from dateStr so daily missions remain stable during that day
    final seed = dateStr.hashCode.abs();
    final random = Random(seed);

    // Slot 1: Immersion Pool (Video watching / listening)
    final immersionPool = [
      const DailyMission(
        id: 'daily_watch_1',
        type: MissionType.watchVideo,
        title: 'Daily Watch',
        description: 'Watch 1 video lesson with interactive subtitles.',
        icon: Icons.play_circle_fill_rounded,
        target: 1,
        xpReward: 25,
      ),
      const DailyMission(
        id: 'daily_watch_2',
        type: MissionType.watchVideo,
        title: 'Deep Immersion',
        description: 'Complete 2 video lessons today.',
        icon: Icons.video_library_rounded,
        target: 2,
        xpReward: 35,
      ),
      const DailyMission(
        id: 'daily_watch_3',
        type: MissionType.watchVideo,
        title: 'Immersion Marathon',
        description: 'Study with 3 video lessons today.',
        icon: Icons.subscriptions_rounded,
        target: 3,
        xpReward: 40,
      ),
    ];

    // Slot 2: Mining & Vocabulary Pool
    final miningPool = [
      const DailyMission(
        id: 'daily_save_2',
        type: MissionType.saveWord,
        title: 'Word Collector',
        description: 'Save 2 new words from video subtitles.',
        icon: Icons.bookmark_add_rounded,
        target: 2,
        xpReward: 20,
      ),
      const DailyMission(
        id: 'daily_save_3',
        type: MissionType.saveWord,
        title: 'Sentence Mining',
        description: 'Save 3 new words to your vocabulary deck.',
        icon: Icons.bookmark_add_rounded,
        target: 3,
        xpReward: 25,
      ),
      const DailyMission(
        id: 'daily_save_5',
        type: MissionType.saveWord,
        title: 'Vocabulary Harvest',
        description: 'Add 5 authentic words from transcripts.',
        icon: Icons.view_in_ar_rounded,
        target: 5,
        xpReward: 35,
      ),
      const DailyMission(
        id: 'daily_dict_3',
        type: MissionType.lookUpDict,
        title: 'Word Inquiry',
        description: 'Look up 3 dictionary definitions in transcripts.',
        icon: Icons.auto_stories_rounded,
        target: 3,
        xpReward: 20,
      ),
      const DailyMission(
        id: 'daily_dict_5',
        type: MissionType.lookUpDict,
        title: 'Deep Inquirer',
        description: 'Look up 5 definitions across video transcripts.',
        icon: Icons.menu_book_rounded,
        target: 5,
        xpReward: 30,
      ),
    ];

    // Slot 3: Memory Review & Quiz Pool
    final practicePool = [
      const DailyMission(
        id: 'daily_srs_5',
        type: MissionType.srsReview,
        title: 'Quick Flashcards',
        description: 'Review 5 flashcards in your study deck.',
        icon: Icons.style_rounded,
        target: 5,
        xpReward: 20,
      ),
      const DailyMission(
        id: 'daily_srs_10',
        type: MissionType.srsReview,
        title: 'Memory Refresh',
        description: 'Review 10 flashcards in your study deck.',
        icon: Icons.style_rounded,
        target: 10,
        xpReward: 25,
      ),
      const DailyMission(
        id: 'daily_srs_15',
        type: MissionType.srsReview,
        title: 'Synapse Workout',
        description: 'Review 15 flashcards in your study deck.',
        icon: Icons.psychology_rounded,
        target: 15,
        xpReward: 35,
      ),
      const DailyMission(
        id: 'daily_quiz_1',
        type: MissionType.completeQuiz,
        title: 'Trial of Wit',
        description: 'Complete 1 comprehension quiz.',
        icon: Icons.sports_kabaddi_rounded,
        target: 1,
        xpReward: 25,
      ),
      const DailyMission(
        id: 'daily_quiz_2',
        type: MissionType.completeQuiz,
        title: 'Quiz Master',
        description: 'Complete 2 comprehension quizzes.',
        icon: Icons.emoji_events_rounded,
        target: 2,
        xpReward: 40,
      ),
    ];

    final slot1 = immersionPool[random.nextInt(immersionPool.length)];
    final slot2 = miningPool[random.nextInt(miningPool.length)];
    final slot3 = practicePool[random.nextInt(practicePool.length)];

    return DailyMissionsState(
      date: dateStr,
      missions: [slot1, slot2, slot3],
      allCompletedBonusClaimed: false,
      bonusXp: 50,
    );
  }

  /// Save current state to SharedPreferences
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('voca_current_streak', currentStreak.value);
      await prefs.setInt('voca_longest_streak', longestStreak.value);
      await prefs.setInt('voca_streak_freezes', streakFreezes.value);
      await prefs.setInt('voca_diamonds', diamonds.value);
      await prefs.setInt('voca_max_diamonds', maxDiamonds.value);
      await prefs.setInt('voca_xp', xp.value);
      await prefs.setInt('voca_weekly_xp', weeklyXp.value);
      if (_lastActiveDate != null) {
        await prefs.setString('voca_last_active_date', _lastActiveDate!.toIso8601String());
      }
      await prefs.setStringList('voca_active_dates', _activeDateStrings.toList());
      await prefs.setInt('voca_total_videos_watched', _totalVideosWatched);
      await prefs.setInt('voca_total_words_saved', _totalWordsSaved);
      await prefs.setInt('voca_total_cards_reviewed', _totalCardsReviewed);
      await prefs.setInt('voca_total_quizzes_completed', _totalQuizzesCompleted);

      // Quiz anti-spam state
      await prefs.setString('voca_last_quiz_date', _lastQuizDate ?? '');
      await prefs.setStringList('voca_today_solved_quizzes', _todaySolvedQuizKeys.toList());
      await prefs.setInt('voca_today_quiz_xp', _todayQuizXpAwarded);

      // Achievements
      final Map<String, dynamic> achMap = {};
      for (final a in achievements.value) {
        achMap[a.id] = a.toJson();
      }
      await prefs.setString('voca_achievements_v2', jsonEncode(achMap));

      // Daily Missions
      await prefs.setString('voca_daily_missions', jsonEncode(dailyMissions.value.toJson()));
    } catch (e) {
      debugPrint('[GamificationService] Error persisting: $e');
    }
  }

  /// Recompute the last 7 days activity calendar
  void _recomputeActivityCalendar() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = <DayActivity>[];
    final df = DateFormat('yyyy-MM-dd');
    final dayLabelFormat = DateFormat('E');

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dayStr = df.format(day);
      final isToday = (i == 0);
      final isActive = _activeDateStrings.contains(dayStr);
      final label = dayLabelFormat.format(day).substring(0, 1);
      final dayNumber = '${day.day}';

      days.add(DayActivity(
        date: day,
        isActive: isActive,
        isToday: isToday,
        dayLabel: label,
        dayNumber: dayNumber,
      ));
    }

    activityCalendar.value = days;
  }

  /// Record user learning activity (streak calculation, XP awarding)
  Future<void> recordActivity({DateTime? date}) async {
    final activityTime = date ?? DateTime.now();
    final today = DateTime(activityTime.year, activityTime.month, activityTime.day);
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    final alreadyActiveToday = _activeDateStrings.contains(todayStr);
    _activeDateStrings.add(todayStr);

    if (!alreadyActiveToday) {
      if (_lastActiveDate == null) {
        currentStreak.value = 1;
        longestStreak.value = max(longestStreak.value, 1);
      } else {
        final lastDay = DateTime(_lastActiveDate!.year, _lastActiveDate!.month, _lastActiveDate!.day);
        final diffDays = today.difference(lastDay).inDays;

        if (diffDays == 1) {
          currentStreak.value += 1;
          if (currentStreak.value > longestStreak.value) {
            longestStreak.value = currentStreak.value;
          }
          addXp(30, reason: 'Consecutive Day Streak!');
        } else if (diffDays > 1) {
          if (diffDays == 2 && streakFreezes.value > 0) {
            streakFreezes.value -= 1;
            currentStreak.value += 1;
            if (currentStreak.value > longestStreak.value) {
              longestStreak.value = currentStreak.value;
            }
          } else {
            currentStreak.value = 1;
          }
        }
      }

      _lastActiveDate = today;

      // Update streak achievements
      _updateAchievementCategoryProgress(AchievementCategory.streak, currentStreak.value);

      // Award daily practice XP
      addXp(20, reason: 'Daily Practice Activity');

      // Sync streak with Supabase RPC
      try {
        final remote = await supabaseService.recordStreakActivity(today);
        if (remote != null) {
          if (remote['current_streak'] is num) {
            currentStreak.value = (remote['current_streak'] as num).toInt();
          }
          if (remote['longest_streak'] is num) {
            longestStreak.value = (remote['longest_streak'] as num).toInt();
          }
          if (remote['freezes_remaining'] is num) {
            streakFreezes.value = (remote['freezes_remaining'] as num).toInt();
          }
          if (remote['activity_log'] is List) {
            for (final item in remote['activity_log']) {
              _activeDateStrings.add(item.toString());
            }
          }
        }
      } catch (e) {
        debugPrint('[GamificationService] Supabase recordStreakActivity error: $e');
      }
    }

    _recomputeActivityCalendar();
    await _persist();
  }

  /// Add XP points
  void addXp(int amount, {String? reason}) {
    if (amount <= 0) return;
    xp.value += amount;
    weeklyXp.value += amount;
    _persist();
  }

  /// Deduct XP points
  bool deductXp(int amount) {
    if (amount <= 0) return true;
    if (xp.value < amount) return false;
    xp.value -= amount;
    _persist();
    return true;
  }

  /// Replenish streak freeze using 150 XP (max 2 freezes)
  Future<bool> replenishFreeze() async {
    if (streakFreezes.value >= 2) return false;
    if (xp.value < 150) return false;

    xp.value -= 150;
    streakFreezes.value += 1;
    await _persist();

    try {
      final res = await supabaseService.spendXp(cost: 150, purpose: 'freeze_replenish');
      if (res != null && res['new_xp'] is num) {
        xp.value = (res['new_xp'] as num).toInt();
        await _persist();
      }
    } catch (e) {
      debugPrint('[GamificationService] spendXp error: $e');
    }

    return true;
  }

  /// Track progress for daily missions
  void trackMissionProgress(MissionType type, int amount) {
    final curState = dailyMissions.value;
    final updatedList = curState.missions.map((m) {
      if (m.type == type && !m.isCompleted) {
        final newProg = m.progress + amount;
        final completed = newProg >= m.target;
        return m.copyWith(
          progress: newProg,
          isCompleted: completed,
        );
      }
      return m;
    }).toList();

    dailyMissions.value = curState.copyWith(missions: updatedList);
    _persist();
  }

  /// Helper to award XP in Supabase RPC atomically in background
  Future<void> _awardRemoteXp(String activityType, int amount, [String? referenceId]) async {
    try {
      await supabaseService.awardStudyXp(
        activityType: activityType,
        amount: amount,
        referenceId: referenceId,
      );
    } catch (e) {
      debugPrint('[GamificationService] awardRemoteXp ignored: $e');
    }
  }

  /// Helper to sync unlocked achievements to Supabase remote DB
  Future<void> _syncAchievementsToRemote() async {
    try {
      final unlockedMap = <String, dynamic>{};
      final notifiedList = <String>[];
      for (final a in achievements.value) {
        if (a.isUnlocked) {
          unlockedMap[a.id] = (a.unlockedAt ?? DateTime.now()).toUtc().toIso8601String();
          notifiedList.add(a.id);
        }
      }
      if (unlockedMap.isNotEmpty) {
        await supabaseService.syncAchievements(
          unlocked: unlockedMap,
          notified: notifiedList,
        );
      }
    } catch (e) {
      debugPrint('[GamificationService] _syncAchievementsToRemote ignored: $e');
    }
  }

  /// Claim a completed mission's XP reward
  bool claimMission(String missionId) {
    final curState = dailyMissions.value;
    final idx = curState.missions.indexWhere((m) => m.id == missionId);
    if (idx == -1) return false;

    final m = curState.missions[idx];
    if (!m.isCompleted || m.isClaimed) return false;

    final updated = m.copyWith(isClaimed: true);
    final newList = [...curState.missions];
    newList[idx] = updated;

    dailyMissions.value = curState.copyWith(missions: newList);
    addXp(m.xpReward, reason: 'Mission: ${m.title}');
    _awardRemoteXp('daily_mission', m.xpReward, missionId);
    _persist();
    return true;
  }

  /// Claim the +50 XP completion bonus chest
  bool claimDailyBonus() {
    if (!canClaimDailyBonus.value) return false;

    dailyMissions.value = dailyMissions.value.copyWith(allCompletedBonusClaimed: true);
    addXp(dailyMissions.value.bonusXp, reason: 'Daily Missions Bonus Chest');
    _awardRemoteXp('daily_bonus_chest', dailyMissions.value.bonusXp, 'bonus_chest');
    _persist();
    return true;
  }

  /// Claim an unlocked achievement's reward
  bool claimAchievement(String id) {
    final list = [...achievements.value];
    final idx = list.indexWhere((a) => a.id == id);
    if (idx == -1) return false;

    final ach = list[idx];
    if (!ach.isUnlocked || ach.isClaimed) return false;

    list[idx] = ach.copyWith(isClaimed: true);
    achievements.value = list;
    addXp(ach.xpReward, reason: 'Achievement: ${ach.title}');
    _awardRemoteXp('achievement_unlocked', ach.xpReward, id);
    _syncAchievementsToRemote();
    _persist();
    return true;
  }

  /// Refresh Diamonds from API Client
  Future<void> refreshDiamonds() async {
    try {
      final info = await apiClient.getDiamonds();
      if (info['success'] == true) {
        diamonds.value = (info['diamonds'] as num?)?.toInt() ?? diamonds.value;
        maxDiamonds.value = (info['maxDiamonds'] as num?)?.toInt() ?? maxDiamonds.value;
        _persist();
      }
    } catch (e) {
      debugPrint('[GamificationService] Failed to refresh diamonds from API: $e');
    }
  }

  /// Consume a diamond for AI operations
  bool consumeDiamond([int count = 1]) {
    if (diamonds.value >= count) {
      diamonds.value -= count;
      _persist();
      return true;
    }
    return false;
  }

  /// Event: Video watched
  Future<void> onVideoWatched() async {
    _totalVideosWatched += 1;
    addXp(25, reason: 'Video Watched');
    _awardRemoteXp('video_completed', 25);
    trackMissionProgress(MissionType.watchVideo, 1);
    _updateAchievementCategoryProgress(AchievementCategory.immersion, _totalVideosWatched);
    await recordActivity();
  }

  /// Event: Video completed (reached >= 80% playback).
  Future<void> recordVideoCompleted() => onVideoWatched();

  /// Event: Word saved to flashcards
  Future<void> onWordSaved(int totalCount) async {
    _totalWordsSaved = max(_totalWordsSaved, totalCount);
    addXp(10, reason: 'Vocabulary Saved');
    _awardRemoteXp('word_saved', 10);
    trackMissionProgress(MissionType.saveWord, 1);
    _updateAchievementCategoryProgress(AchievementCategory.vocabulary, _totalWordsSaved);
    await recordActivity();
  }

  /// Event: Word looked up in dictionary
  void onWordLookedUp() {
    trackMissionProgress(MissionType.lookUpDict, 1);
  }

  /// Event: Flashcard reviewed with SM-2 SRS
  Future<void> onCardReviewed(int totalCount) async {
    _totalCardsReviewed = max(_totalCardsReviewed, totalCount);
    addXp(10, reason: 'Flashcard Reviewed');
    _awardRemoteXp('flashcard_review', 10);
    trackMissionProgress(MissionType.srsReview, 1);
    _updateAchievementCategoryProgress(AchievementCategory.srs, _totalCardsReviewed);
    await recordActivity();
  }

  void _checkQuizDayRollover() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (_lastQuizDate != todayStr) {
      _lastQuizDate = todayStr;
      _todaySolvedQuizKeys.clear();
      _todayQuizXpAwarded = 0;
    }
  }

  /// Daily quiz XP awarded today so far
  int get todayQuizXpAwarded {
    _checkQuizDayRollover();
    return _todayQuizXpAwarded;
  }

  /// Whether user has reached the daily limit for quiz XP (100 XP max per day = 5 unique sentences)
  bool get isQuizCapReachedToday {
    _checkQuizDayRollover();
    return _todayQuizXpAwarded >= 100;
  }

  /// Check whether a specific quiz key can earn fresh XP right now
  bool canEarnQuizXp(String quizKey) {
    _checkQuizDayRollover();
    return !_todaySolvedQuizKeys.contains(quizKey) && _todayQuizXpAwarded < 100;
  }

  /// Check whether a specific quiz key was already solved today for full XP
  bool isQuizSolvedToday(String quizKey) {
    _checkQuizDayRollover();
    return _todaySolvedQuizKeys.contains(quizKey);
  }

  /// Event: Quiz completed
  /// Returns `true` if fresh XP was awarded, or `false` if already completed today / daily cap reached.
  Future<bool> onQuizCompleted({String? quizKey}) async {
    _checkQuizDayRollover();

    bool isFresh = true;
    if (quizKey != null && quizKey.isNotEmpty) {
      if (_todaySolvedQuizKeys.contains(quizKey)) {
        isFresh = false;
      } else {
        _todaySolvedQuizKeys.add(quizKey);
      }
    }

    // Daily quiz XP cap check (max 100 XP from quizzes per day = 5 unique sentences)
    if (_todayQuizXpAwarded >= 100) {
      isFresh = false;
    }

    _totalQuizzesCompleted += 1;
    trackMissionProgress(MissionType.completeQuiz, 1);
    _updateAchievementCategoryProgress(AchievementCategory.quiz, _totalQuizzesCompleted);
    await recordActivity();

    if (isFresh) {
      const earned = 20;
      _todayQuizXpAwarded += earned;
      addXp(earned, reason: 'Comprehension Quiz Completed');
      _awardRemoteXp('quiz_completed', earned, quizKey);
      await _persist();
      return true;
    } else {
      await _persist();
      return false;
    }
  }

  /// Helper to update achievements by category
  void _updateAchievementCategoryProgress(AchievementCategory category, int progress) {
    final list = [...achievements.value];
    bool changed = false;

    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      if (item.category == category) {
        final newCurrent = max(item.current, progress);
        final newlyUnlocked = !item.isUnlocked && newCurrent >= item.target;

        if (newCurrent != item.current || newlyUnlocked) {
          list[i] = item.copyWith(
            current: newCurrent,
            isUnlocked: item.isUnlocked || newlyUnlocked,
            unlockedAt: newlyUnlocked ? DateTime.now() : item.unlockedAt,
          );
          changed = true;
        }
      }
    }

    if (changed) {
      achievements.value = list;
      _persist();
      _syncAchievementsToRemote();
    }
  }

  /// Leaderboard entries provider matching Adventurer's Guild podium
  List<LeaderboardEntry> getLeaderboardEntries({String period = 'weekly', String lang = 'all'}) {
    final currentLvl = level.value;
    final currentScore = period == 'weekly' ? weeklyXp.value : xp.value;

    final mockLearners = [
      const LeaderboardEntry(
        rank: 1,
        userId: 'lead_1',
        name: 'Sakura Tan',
        avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&h=100&fit=crop&crop=face',
        xp: 14850,
        weeklyXp: 2840,
        level: 42,
        streak: 84,
        badgesCount: 26,
        country: 'JP',
      ),
      const LeaderboardEntry(
        rank: 2,
        userId: 'lead_2',
        name: 'Alex Rivera',
        avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face',
        xp: 11200,
        weeklyXp: 1950,
        level: 37,
        streak: 45,
        badgesCount: 22,
        country: 'US',
      ),
      const LeaderboardEntry(
        rank: 3,
        userId: 'lead_3',
        name: 'Min-jun Kim',
        avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&h=100&fit=crop&crop=face',
        xp: 9450,
        weeklyXp: 1420,
        level: 32,
        streak: 31,
        badgesCount: 19,
        country: 'KR',
      ),
      const LeaderboardEntry(
        rank: 4,
        userId: 'lead_4',
        name: 'Elena Rostova',
        avatar: '',
        xp: 7800,
        weeklyXp: 1100,
        level: 28,
        streak: 24,
        badgesCount: 16,
        country: 'DE',
      ),
      const LeaderboardEntry(
        rank: 5,
        userId: 'lead_5',
        name: 'Chen Wei',
        avatar: '',
        xp: 6920,
        weeklyXp: 950,
        level: 25,
        streak: 19,
        badgesCount: 14,
        country: 'CN',
      ),
      const LeaderboardEntry(
        rank: 6,
        userId: 'lead_6',
        name: 'Thao Nguyen',
        avatar: '',
        xp: 5400,
        weeklyXp: 810,
        level: 21,
        streak: 12,
        badgesCount: 12,
        country: 'VN',
      ),
      LeaderboardEntry(
        rank: 7,
        userId: 'current_user',
        name: 'You',
        avatar: '',
        xp: xp.value,
        weeklyXp: currentScore,
        level: currentLvl,
        streak: currentStreak.value,
        badgesCount: achievements.value.where((a) => a.isUnlocked).length,
        country: 'VN',
        isCurrentUser: true,
      ),
    ];

    return mockLearners;
  }
}
