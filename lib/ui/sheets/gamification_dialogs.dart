// lib/ui/sheets/gamification_dialogs.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../state/app_state.dart';
import '../profile/profile_screen.dart';

/// Shows authentic Streak Dialog matching lingua-tube's StreakDialogComponent.
Future<void> showStreakDialog(BuildContext context) {
  final gamification = AppState.instance.gamificationService;

  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: VocaTokens.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: VocaTokens.borderColor),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Watch((context) {
            final currentStreak = gamification.currentStreak.value;
            final longestStreak = gamification.longestStreak.value;
            final freezes = gamification.streakFreezes.value;
            final practicedToday = gamification.practicedToday;
            final activityDates = gamification.activeDates;

            // Generate last 7 days
            final now = DateTime.now();
            final last7Days = List.generate(7, (i) {
              final d = now.subtract(Duration(days: 6 - i));
              final dateKey = DateFormat('yyyy-MM-dd').format(d);
              final isToday = (i == 6);
              final isActive = activityDates.contains(dateKey);
              final dayName = DateFormat('E').format(d).substring(0, 1);
              return {
                'day': dayName,
                'isToday': isToday,
                'isActive': isActive,
              };
            });

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Flame Crest Header
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: VocaTokens.colorFire.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: VocaTokens.colorFire.withOpacity(0.4), width: 2),
                  ),
                  child: const Center(
                    child: Text('🔥', style: TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(height: 12),

                // Streak count
                Text(
                  '$currentStreak',
                  style: const TextStyle(
                    color: VocaTokens.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'Day Streak',
                  style: TextStyle(
                    color: VocaTokens.colorFire,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Motivation message
                Text(
                  practicedToday
                      ? 'Practiced today! Keep up the momentum!'
                      : 'Watch a video or review cards today to keep your streak!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: VocaTokens.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),

                // 7-Day Calendar Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: VocaTokens.bgSecondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: VocaTokens.borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: last7Days.map((d) {
                      final isActive = d['isActive'] as bool;
                      final isToday = d['isToday'] as bool;
                      final dayLetter = d['day'] as String;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            dayLetter,
                            style: TextStyle(
                              color: isToday ? VocaTokens.accentPrimary : VocaTokens.textMuted,
                              fontSize: 12,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? VocaTokens.colorFire
                                  : (isToday ? VocaTokens.bgHover : Colors.white10),
                              border: isToday
                                  ? Border.all(color: VocaTokens.accentPrimary, width: 1.5)
                                  : null,
                            ),
                            child: Center(
                              child: isActive
                                  ? const Text('🔥', style: TextStyle(fontSize: 13))
                                  : (isToday
                                      ? Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: VocaTokens.accentPrimary,
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                      : null),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: VocaTokens.bgSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: VocaTokens.borderColor),
                        ),
                        child: Column(
                          children: [
                            const Text('Best Streak', style: TextStyle(color: VocaTokens.textMuted, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(
                              '$longestStreak days',
                              style: const TextStyle(color: VocaTokens.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: VocaTokens.bgSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: VocaTokens.borderColor),
                        ),
                        child: Column(
                          children: [
                            const Text('Freezes Left', style: TextStyle(color: VocaTokens.textMuted, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(
                              '🛡️ $freezes',
                              style: const TextStyle(color: VocaTokens.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: VocaTokens.borderColor),
                          foregroundColor: VocaTokens.textPrimary,
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ProfileScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VocaTokens.accentPrimary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Full Stats'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      );
    },
  );
}

/// Shows authentic Level & Achievements Dialog matching lingua-tube.
Future<void> showAchievementsDialog(BuildContext context) {
  final gamification = AppState.instance.gamificationService;

  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: VocaTokens.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: VocaTokens.borderColor),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Watch((context) {
            final level = gamification.level.value;
            final xp = gamification.xp.value;
            final curLevelXp = gamification.currentLevelXp.value;
            final targetXp = gamification.nextLevelTargetXp.value;
            final progress = gamification.levelProgress.value;
            final achievements = gamification.achievements.value;

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Shield Crest Header
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: VocaTokens.accentTertiary.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: VocaTokens.accentTertiary.withOpacity(0.4), width: 2),
                    ),
                    child: const Center(
                      child: Text('🛡️', style: TextStyle(fontSize: 30)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Level $level Learner',
                    style: const TextStyle(
                      color: VocaTokens.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$xp Total XP',
                    style: const TextStyle(
                      color: VocaTokens.accentTertiary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Level Progress', style: TextStyle(color: VocaTokens.textMuted, fontSize: 12)),
                          Text('$curLevelXp / $targetXp XP', style: const TextStyle(color: VocaTokens.textSecondary, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: VocaTokens.bgSecondary,
                          valueColor: const AlwaysStoppedAnimation<Color>(VocaTokens.accentTertiary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Achievements List
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Achievements (${achievements.where((a) => a.isUnlocked).length}/${achievements.length})',
                      style: const TextStyle(
                        color: VocaTokens.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  ...achievements.map((a) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: VocaTokens.bgSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: a.isUnlocked ? VocaTokens.accentTertiary.withOpacity(0.3) : VocaTokens.borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            a.icon,
                            size: 22,
                            color: a.isUnlocked ? VocaTokens.accentTertiary : VocaTokens.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.title,
                                  style: TextStyle(
                                    color: a.isUnlocked ? VocaTokens.textPrimary : VocaTokens.textMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  a.description,
                                  style: const TextStyle(color: VocaTokens.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: a.isUnlocked ? VocaTokens.accentTertiary.withOpacity(0.15) : Colors.white10,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+${a.xpReward} XP',
                              style: TextStyle(
                                color: a.isUnlocked ? VocaTokens.accentTertiary : VocaTokens.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      side: const BorderSide(color: VocaTokens.borderColor),
                      foregroundColor: VocaTokens.textPrimary,
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          }),
        ),
      );
    },
  );
}

/// Shows authentic AI Credits Dialog matching lingua-tube.
Future<void> showAiCreditsDialog(BuildContext context) {
  final gamification = AppState.instance.gamificationService;

  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: VocaTokens.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: VocaTokens.borderColor),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Watch((context) {
            final diamonds = gamification.diamonds.value;
            final maxDiamonds = gamification.maxDiamonds.value;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Diamond Icon Header
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: VocaTokens.colorDiamond.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: VocaTokens.colorDiamond.withOpacity(0.4), width: 2),
                  ),
                  child: const Center(
                    child: Text('💎', style: TextStyle(fontSize: 30)),
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  '$diamonds / $maxDiamonds',
                  style: const TextStyle(
                    color: VocaTokens.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'AI Credits Available',
                  style: TextStyle(
                    color: VocaTokens.colorDiamond,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'AI Credits power furigana/ruby generation, grammar breakdowns, and contextual AI dictionary explanations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: VocaTokens.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: VocaTokens.bgSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: VocaTokens.borderColor),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: VocaTokens.colorDiamond, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Free daily refill of 5 AI credits every 24 hours.',
                          style: TextStyle(color: VocaTokens.textPrimary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Refresh Button
                ElevatedButton.icon(
                  onPressed: () async {
                    await gamification.refreshDiamonds();
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('AI Credits refreshed!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh Credits'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: VocaTokens.colorDiamond,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    side: const BorderSide(color: VocaTokens.borderColor),
                    foregroundColor: VocaTokens.textPrimary,
                  ),
                  child: const Text('Close'),
                ),
              ],
            );
          }),
        ),
      );
    },
  );
}
