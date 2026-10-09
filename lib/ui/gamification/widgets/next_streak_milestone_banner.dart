// lib/ui/gamification/widgets/next_streak_milestone_banner.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../config/voca_theme.dart';
import '../../../services/gamification_service.dart';
import '../../../services/i18n_service.dart';
import 'achievements_sheet.dart';

/// Clean Material 3 Banner showing the user's upcoming Streak Achievement milestone.
/// Connects daily streak activity directly to the 33-tier RPG achievement roadmap.
class NextStreakMilestoneBanner extends StatelessWidget {
  final VocaColorPalette colors;
  final GamificationService gamification;

  const NextStreakMilestoneBanner({
    super.key,
    required this.colors,
    required this.gamification,
  });

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final milestone = gamification.nextStreakMilestone.value;
      if (milestone == null) return const SizedBox.shrink();

      final currentStreak = gamification.currentStreak.value;
      final target = milestone.target;
      final progressRatio = target > 0 ? (currentStreak / target).clamp(0.0, 1.0) : 0.0;
      final daysRemaining = max(1, target - currentStreak);

      return InkWell(
        onTap: () {
          AchievementsSheet.show(
            context,
            initialCategory: AchievementCategory.streak,
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.borderColorLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Category label + XP Reward Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag_rounded, size: 14, color: colors.colorFire),
                      const SizedBox(width: 6),
                      Text(
                        context.t('streak.nextGoalLabel', null, 'Next Streak Milestone').toUpperCase(),
                        style: TextStyle(
                          color: colors.colorFire,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.colorFire.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: colors.colorFire.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      '+${milestone.xpReward} XP',
                      style: TextStyle(
                        color: colors.colorFire,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title: Milestone Name & Target Days
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${milestone.localizedTitle(context)} ($target ${context.t('streak.days', null, 'Days')})',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded, size: 18, color: colors.textMuted),
                ],
              ),
              const SizedBox(height: 8),

              // Progress Bar + Count
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 5,
                        color: colors.bgHover,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: progressRatio),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          builder: (context, animatedVal, _) {
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: animatedVal,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colors.colorFire,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$currentStreak/$target',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Subtitle encouragement
              Text(
                context.t(
                  'streak.daysRemainingHint',
                  {'days': daysRemaining},
                  '$daysRemaining more study days to ignite!',
                ),
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
