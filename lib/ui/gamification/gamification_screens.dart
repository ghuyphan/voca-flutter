// lib/ui/gamification/gamification_screens.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../sheets/gamification_dialogs.dart';

/// Full-screen Daily Streak Hub matching lingua-tube design system
class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final gamification = AppState.instance.gamificationService;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary,
        elevation: 0,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          context.t('gamification.streak', null, 'Daily Streak'),
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                // Flame Crest Header
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colors.colorFire.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.colorFire.withOpacity(0.4), width: 2.5),
                  ),
                  child: const Center(
                    child: Text('🔥', style: TextStyle(fontSize: 42)),
                  ),
                ),
                const SizedBox(height: 16),

                // Streak count
                Text(
                  '$currentStreak',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  context.t('gamification.streak', null, 'Day Streak'),
                  style: TextStyle(
                    color: colors.colorFire,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),

                // Motivation message
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    practicedToday
                        ? context.t('streak.practicedToday', null, 'Practiced today! Keep up the momentum!')
                        : context.t('streak.keepStreak', null, 'Watch a video or review cards today to keep your streak!'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 7-day calendar row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: colors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last 7 Days',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: last7Days.map((d) {
                          final isToday = d['isToday'] as bool;
                          final isActive = d['isActive'] as bool;
                          final day = d['day'] as String;

                          return Column(
                            children: [
                              Text(
                                day,
                                style: TextStyle(
                                  color: isToday ? colors.colorFire : colors.textMuted,
                                  fontSize: 12,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? colors.colorFire
                                      : (isToday ? colors.colorFire.withOpacity(0.12) : colors.bgSecondary),
                                  shape: BoxShape.circle,
                                  border: isToday
                                      ? Border.all(color: colors.colorFire, width: 2)
                                      : Border.all(color: colors.borderColor),
                                ),
                                child: Center(
                                  child: isActive
                                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                                      : (isToday
                                          ? Text('🔥', style: TextStyle(fontSize: 16, color: colors.colorFire))
                                          : const SizedBox()),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stats row (Longest Streak & Freezes)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('⚡', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  'Best Streak',
                                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$longestStreak days',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('🧊', style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  'Streak Freezes',
                                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$freezes available',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Full-screen Achievements & Level Hub matching lingua-tube design system
class AchievementsHubScreen extends StatelessWidget {
  const AchievementsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final gamification = AppState.instance.gamificationService;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary,
        elevation: 0,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          context.t('gamification.achievements', null, 'Level & Achievements'),
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Watch((context) {
            final level = gamification.level.value;
            final xp = gamification.xp.value;
            final curLevelXp = gamification.currentLevelXp.value;
            final targetXp = gamification.nextLevelTargetXp.value;
            final progress = gamification.levelProgress.value;
            final achievements = gamification.achievements.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                // Shield Crest Header
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: colors.accentTertiary.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.accentTertiary.withOpacity(0.4), width: 2.5),
                  ),
                  child: const Center(
                    child: Text('🛡️', style: TextStyle(fontSize: 38)),
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  'Level $level Learner',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$xp Total XP',
                  style: TextStyle(
                    color: colors.accentTertiary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),

                // Progress Bar Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.t('profile.levelProgress', null, 'Level Progress'),
                            style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '$curLevelXp / $targetXp XP',
                            style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: colors.bgSecondary,
                          valueColor: AlwaysStoppedAnimation<Color>(colors.accentTertiary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Achievements List Header
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${context.t('gamification.achievements', null, 'Achievements')} (${achievements.where((a) => a.isUnlocked).length}/${achievements.length})',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                ...achievements.map((a) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: a.isUnlocked ? colors.accentTertiary.withOpacity(0.35) : colors.borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          a.icon,
                          size: 26,
                          color: a.isUnlocked ? colors.accentTertiary : colors.textMuted,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: TextStyle(
                                  color: a.isUnlocked ? colors.textPrimary : colors.textMuted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                a.description,
                                style: TextStyle(color: colors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: a.isUnlocked
                                ? colors.accentTertiary.withOpacity(0.15)
                                : colors.bgSecondary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${a.xpReward} XP',
                            style: TextStyle(
                              color: a.isUnlocked ? colors.accentTertiary : colors.textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// Full-screen AI Credits Screen matching lingua-tube design system
class AiCreditsScreen extends StatelessWidget {
  const AiCreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final gamification = AppState.instance.gamificationService;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary,
        elevation: 0,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          context.t('gamification.aiCredits', null, 'AI Credits'),
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Watch((context) {
            final diamonds = gamification.diamonds.value;
            final maxDiamonds = gamification.maxDiamonds.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                // Diamond Crest Header
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colors.colorDiamond.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.colorDiamond.withOpacity(0.4), width: 2.5),
                  ),
                  child: const Center(
                    child: Text('💎', style: TextStyle(fontSize: 40)),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  '$diamonds / $maxDiamonds',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  context.t('gamification.aiCredits', null, 'AI Credits Available'),
                  style: TextStyle(
                    color: colors.colorDiamond,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  context.t(
                    'aiCredits.explanation',
                    null,
                    'AI Credits power furigana/ruby generation, grammar breakdowns, and contextual AI dictionary explanations.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Daily Refill notice card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: colors.colorDiamond, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.t('aiCredits.refillNotice', null, 'Free daily refill of 5 AI credits every 24 hours.'),
                          style: TextStyle(color: colors.textPrimary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Refresh Button
                ElevatedButton.icon(
                  onPressed: () async {
                    await gamification.refreshDiamonds();
                    if (context.mounted) {
                      ToastService.success(
                        context,
                        context.t('aiCredits.refreshed', null, 'AI Credits refreshed!'),
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(context.t('aiCredits.refresh', null, 'Refresh Credits')),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: colors.colorDiamond,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),

                // Pro Upgrade Prompt
                OutlinedButton.icon(
                  onPressed: () => showProUpgradeDialog(context),
                  icon: const Text('👑', style: TextStyle(fontSize: 16)),
                  label: const Text('Get Unlimited with VOCA Pro'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: BorderSide(color: colors.accentPrimary.withOpacity(0.5)),
                    foregroundColor: colors.accentPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
