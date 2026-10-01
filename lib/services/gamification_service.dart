// lib/services/gamification_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';
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

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int target;
  final int current;
  final bool isUnlocked;
  final int xpReward;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    this.current = 0,
    this.isUnlocked = false,
    required this.xpReward,
    this.unlockedAt,
  });

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

  Achievement copyWith({
    int? current,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      target: target,
      current: current ?? this.current,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      xpReward: xpReward,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'current': current,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  factory Achievement.fromJson(Map<String, dynamic> json, Achievement template) {
    return Achievement(
      id: template.id,
      title: template.title,
      description: template.description,
      icon: template.icon,
      target: template.target,
      current: (json['current'] as num?)?.toInt() ?? template.current,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      xpReward: template.xpReward,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.tryParse(json['unlockedAt'] as String)
          : null,
    );
  }
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

  // Diamonds / AI Credits
  final diamonds = signal<int>(5);
  final maxDiamonds = signal<int>(5);

  // XP & Leveling
  final xp = signal<int>(0);
  late final Computed<int> level = computed(() => (xp.value ~/ 100) + 1);
  late final Computed<int> currentLevelXp = computed(() => xp.value % 100);
  late final Computed<int> nextLevelTargetXp = computed(() => 100);
  late final Computed<double> levelProgress = computed(() => (xp.value % 100) / 100.0);

  // Achievements
  static final List<Achievement> _defaultAchievements = [
    const Achievement(
      id: 'first_video',
      title: 'First Video Watched',
      description: 'Watch your first interactive video lesson in Voca.',
      icon: Icons.play_circle_fill_rounded,
      target: 1,
      xpReward: 50,
    ),
    const Achievement(
      id: 'words_10',
      title: '10 Words Saved',
      description: 'Add 10 new vocabulary cards to your study deck.',
      icon: Icons.bookmark_added_rounded,
      target: 10,
      xpReward: 100,
    ),
    const Achievement(
      id: 'streak_7',
      title: '7-Day Streak',
      description: 'Maintain your learning immersion for 7 consecutive days.',
      icon: Icons.local_fire_department_rounded,
      target: 7,
      xpReward: 250,
    ),
    const Achievement(
      id: 'vocab_master',
      title: 'Vocab Master',
      description: 'Review and master 50 vocabulary flashcards with SRS.',
      icon: Icons.military_tech_rounded,
      target: 50,
      xpReward: 500,
    ),
  ];

  final achievements = signal<List<Achievement>>(_defaultAchievements);

  final Set<String> _activeDateStrings = {};
  DateTime? _lastActiveDate;
  int _totalVideosWatched = 0;
  int _totalWordsSaved = 0;
  int _totalCardsReviewed = 0;

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

      final lastDateStr = prefs.getString('voca_last_active_date');
      if (lastDateStr != null) {
        _lastActiveDate = DateTime.tryParse(lastDateStr);
      }

      final dates = prefs.getStringList('voca_active_dates') ?? [];
      _activeDateStrings.addAll(dates);

      _totalVideosWatched = prefs.getInt('voca_total_videos_watched') ?? 0;
      _totalWordsSaved = prefs.getInt('voca_total_words_saved') ?? 0;
      _totalCardsReviewed = prefs.getInt('voca_total_cards_reviewed') ?? 0;

      // Load Achievements
      final achievementsJson = prefs.getString('voca_achievements');
      if (achievementsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(achievementsJson);
        final list = _defaultAchievements.map((template) {
          final data = decoded[template.id];
          if (data is Map<String, dynamic>) {
            return Achievement.fromJson(data, template);
          }
          return template;
        }).toList();
        achievements.value = list;
      }

      _recomputeActivityCalendar();
    } catch (e) {
      debugPrint('[GamificationService] Error initializing: $e');
    }
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
      if (_lastActiveDate != null) {
        await prefs.setString('voca_last_active_date', _lastActiveDate!.toIso8601String());
      }
      await prefs.setStringList('voca_active_dates', _activeDateStrings.toList());
      await prefs.setInt('voca_total_videos_watched', _totalVideosWatched);
      await prefs.setInt('voca_total_words_saved', _totalWordsSaved);
      await prefs.setInt('voca_total_cards_reviewed', _totalCardsReviewed);

      final Map<String, dynamic> achMap = {};
      for (final a in achievements.value) {
        achMap[a.id] = a.toJson();
      }
      await prefs.setString('voca_achievements', jsonEncode(achMap));
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
    final dayLabelFormat = DateFormat('E'); // Mon, Tue, etc.

    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dayStr = df.format(day);
      final isToday = (i == 0);
      final isActive = _activeDateStrings.contains(dayStr);
      final label = dayLabelFormat.format(day).substring(0, 1); // Single letter M, T, W...
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
          // Consecutive active day
          currentStreak.value += 1;
          if (currentStreak.value > longestStreak.value) {
            longestStreak.value = currentStreak.value;
          }
          addXp(30, reason: 'Consecutive Day Streak!');
        } else if (diffDays > 1) {
          // Missed at least one day
          if (diffDays == 2 && streakFreezes.value > 0) {
            // Protected by freeze
            streakFreezes.value -= 1;
            currentStreak.value += 1;
            if (currentStreak.value > longestStreak.value) {
              longestStreak.value = currentStreak.value;
            }
          } else {
            // Streak reset
            currentStreak.value = 1;
          }
        }
      }

      _lastActiveDate = today;

      // Check 7-Day Streak achievement
      _updateAchievementProgress('streak_7', currentStreak.value);

      // Award daily activity XP
      addXp(20, reason: 'Daily Practice Activity');

      // Sync streak with Supabase RPC if authenticated
      try {
        await supabaseService.recordStreakActivity(today);
      } catch (e) {
        debugPrint('[GamificationService] Supabase recordStreakActivity ignored: $e');
      }
    }

    _recomputeActivityCalendar();
    await _persist();
  }

  /// Add XP points
  void addXp(int amount, {String? reason}) {
    if (amount <= 0) return;
    xp.value += amount;
    _persist();
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

  /// Consume a diamond for AI operations (Whisper / Tokenize)
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
    _updateAchievementProgress('first_video', _totalVideosWatched);
    await recordActivity();
  }

  /// Event: Word saved to flashcards
  Future<void> onWordSaved(int totalCount) async {
    _totalWordsSaved = max(_totalWordsSaved, totalCount);
    addXp(10, reason: 'Vocabulary Saved');
    _updateAchievementProgress('words_10', _totalWordsSaved);
    await recordActivity();
  }

  /// Event: Flashcard reviewed with SM-2 SRS
  Future<void> onCardReviewed(int totalCount) async {
    _totalCardsReviewed = max(_totalCardsReviewed, totalCount);
    addXp(10, reason: 'Flashcard Reviewed');
    _updateAchievementProgress('vocab_master', _totalCardsReviewed);
    await recordActivity();
  }

  /// Helper to update achievement progress & award unlocking rewards
  void _updateAchievementProgress(String id, int progress) {
    final list = [...achievements.value];
    final idx = list.indexWhere((a) => a.id == id);
    if (idx != -1) {
      final item = list[idx];
      final newCurrent = max(item.current, progress);
      final newlyUnlocked = !item.isUnlocked && newCurrent >= item.target;

      list[idx] = item.copyWith(
        current: newCurrent,
        isUnlocked: item.isUnlocked || newlyUnlocked,
        unlockedAt: newlyUnlocked ? DateTime.now() : item.unlockedAt,
      );

      if (newlyUnlocked) {
        addXp(item.xpReward, reason: 'Achievement Unlocked: ${item.title}');
      }

      achievements.value = list;
    }
  }
}
