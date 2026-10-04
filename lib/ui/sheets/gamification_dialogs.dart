// lib/ui/sheets/gamification_dialogs.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../profile/profile_screen.dart';

/// Shows authentic Streak Dialog matching lingua-tube's StreakDialogComponent.
Future<void> showStreakDialog(BuildContext context) {
  final gamification = AppState.instance.gamificationService;

  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final colors = ctx.vocaColors;

      return Dialog(
        backgroundColor: colors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.borderColor),
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
                    color: colors.colorFire.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.colorFire.withOpacity(0.4), width: 2),
                  ),
                  child: const Center(
                    child: Text('🔥', style: TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(height: 12),

                // Streak count
                Text(
                  '$currentStreak',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  ctx.t('gamification.streak', null, 'Day Streak'),
                  style: TextStyle(
                    color: colors.colorFire,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                // Motivation message
                Text(
                  practicedToday
                      ? ctx.t('streak.practicedToday', null, 'Practiced today! Keep up the momentum!')
                      : ctx.t('streak.keepStreak', null, 'Watch a video or review cards today to keep your streak!'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),

                // 7-Day Calendar Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.bgSecondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.borderColor),
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
                              color: isToday ? colors.accentPrimary : colors.textMuted,
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
                                  ? colors.colorFire
                                  : (isToday ? colors.bgHover : (colors.isDark ? Colors.white10 : Colors.black12)),
                              border: isToday
                                  ? Border.all(color: colors.accentPrimary, width: 1.5)
                                  : null,
                            ),
                            child: Center(
                              child: isActive
                                  ? const Text('🔥', style: TextStyle(fontSize: 13))
                                  : (isToday
                                      ? Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: colors.accentPrimary,
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
                          color: colors.bgSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: Column(
                          children: [
                            Text(
                              ctx.t('streak.bestStreak', null, 'Best Streak'),
                              style: TextStyle(color: colors.textMuted, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$longestStreak days',
                              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
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
                          color: colors.bgSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: Column(
                          children: [
                            Text(
                              ctx.t('streak.freezesLeft', null, 'Freezes Left'),
                              style: TextStyle(color: colors.textMuted, fontSize: 11),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '🛡️ $freezes',
                              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15),
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
                          side: BorderSide(color: colors.borderColor),
                          foregroundColor: colors.textPrimary,
                        ),
                        child: Text(ctx.t('common.close', null, 'Close')),
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
                          backgroundColor: colors.accentPrimary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(ctx.t('streak.fullStats', null, 'Full Stats')),
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
      final colors = ctx.vocaColors;

      return Dialog(
        backgroundColor: colors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.borderColor),
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
                      color: colors.accentTertiary.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.accentTertiary.withOpacity(0.4), width: 2),
                    ),
                    child: const Center(
                      child: Text('🛡️', style: TextStyle(fontSize: 30)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Level $level Learner',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$xp Total XP',
                    style: TextStyle(
                      color: colors.accentTertiary,
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
                          Text(ctx.t('profile.levelProgress', null, 'Level Progress'), style: TextStyle(color: colors.textMuted, fontSize: 12)),
                          Text('$curLevelXp / $targetXp XP', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: colors.bgSecondary,
                          valueColor: AlwaysStoppedAnimation<Color>(colors.accentTertiary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Achievements List
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${ctx.t('gamification.achievements', null, 'Achievements')} (${achievements.where((a) => a.isUnlocked).length}/${achievements.length})',
                      style: TextStyle(
                        color: colors.textPrimary,
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
                        color: colors.bgSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: a.isUnlocked ? colors.accentTertiary.withOpacity(0.3) : colors.borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            a.icon,
                            size: 22,
                            color: a.isUnlocked ? colors.accentTertiary : colors.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.title,
                                  style: TextStyle(
                                    color: a.isUnlocked ? colors.textPrimary : colors.textMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  a.description,
                                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: a.isUnlocked ? colors.accentTertiary.withOpacity(0.15) : (colors.isDark ? Colors.white10 : Colors.black12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+${a.xpReward} XP',
                              style: TextStyle(
                                color: a.isUnlocked ? colors.accentTertiary : colors.textMuted,
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
                      side: BorderSide(color: colors.borderColor),
                      foregroundColor: colors.textPrimary,
                    ),
                    child: Text(ctx.t('common.close', null, 'Close')),
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
      final colors = ctx.vocaColors;

      return Dialog(
        backgroundColor: colors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.borderColor),
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
                    color: colors.colorDiamond.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.colorDiamond.withOpacity(0.4), width: 2),
                  ),
                  child: const Center(
                    child: Text('💎', style: TextStyle(fontSize: 30)),
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  '$diamonds / $maxDiamonds',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  ctx.t('gamification.aiCredits', null, 'AI Credits Available'),
                  style: TextStyle(
                    color: colors.colorDiamond,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  ctx.t(
                    'aiCredits.explanation',
                    null,
                    'AI Credits power furigana/ruby generation, grammar breakdowns, and contextual AI dictionary explanations.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bgSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: colors.colorDiamond, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ctx.t('aiCredits.refillNotice', null, 'Free daily refill of 5 AI credits every 24 hours.'),
                          style: TextStyle(color: colors.textPrimary, fontSize: 12),
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
                      ToastService.success(
                        ctx,
                        ctx.t('aiCredits.refreshed', null, 'AI Credits refreshed!'),
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(ctx.t('aiCredits.refresh', null, 'Refresh Credits')),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: colors.colorDiamond,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    side: BorderSide(color: colors.borderColor),
                    foregroundColor: colors.textPrimary,
                  ),
                  child: Text(ctx.t('common.close', null, 'Close')),
                ),
              ],
            );
          }),
        ),
      );
    },
  );
}

/// Shows authentic Pro Upgrade Dialog matching lingua-tube's ProUpgradeDialogComponent.
Future<void> showProUpgradeDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final colors = ctx.vocaColors;

      return Dialog(
        backgroundColor: colors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.borderColor),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Crown Crest Header
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.accentPrimary.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.accentPrimary.withOpacity(0.4), width: 2),
                ),
                child: const Center(
                  child: Text('👑', style: TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'VOCA Pro',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Unlock Unlimited Language Immersion',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Feature bullets
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.bgSecondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Column(
                  children: [
                    _buildProFeatureRow(colors, ctx.t('pro.featureUnlimitedTranscribe', null, '💎 Unlimited AI Whisper & Transcription')),
                    const SizedBox(height: 8),
                    _buildProFeatureRow(colors, ctx.t('pro.featureSrsDecks', null, '⚡ Infinite Spaced Repetition SRS Decks')),
                    const SizedBox(height: 8),
                    _buildProFeatureRow(colors, ctx.t('pro.featureGrammarRules', null, '📚 2,400+ Grammar Rules & Breakdown')),
                    const SizedBox(height: 8),
                    _buildProFeatureRow(colors, ctx.t('pro.featureSync', null, '☁️ Seamless Cross-Platform Sync')),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ToastService.info(
                    context,
                    ctx.t('pro.checkoutComingSoon', null, 'Pro subscription checkout coming soon!'),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: Colors.white,
                ),
                child: Text(ctx.t('pro.upgradeToPro', null, 'Upgrade to Pro'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),

              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  side: BorderSide(color: colors.borderColor),
                  foregroundColor: colors.textPrimary,
                ),
                child: Text(ctx.t('common.maybeLater', null, 'Maybe Later')),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildProFeatureRow(VocaColorPalette colors, String text) {
  return Row(
    children: [
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}
