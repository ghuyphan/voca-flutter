// lib/ui/onboarding/steps/pace_level_step.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../models/onboarding_models.dart';
import '../widgets/onboarding_selection_tile.dart';
import '../widgets/onboarding_step_header.dart';

/// Step 2: Difficulty Ladder Calibration & Daily Study Habit Pact
class PaceLevelStep extends StatelessWidget {
  final String selectedLevel;
  final ValueChanged<String> onLevelChanged;
  final int selectedDailyGoal;
  final ValueChanged<int> onDailyGoalChanged;

  const PaceLevelStep({
    super.key,
    required this.selectedLevel,
    required this.onLevelChanged,
    required this.selectedDailyGoal,
    required this.onDailyGoalChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingStepHeader(
            badgeText: context.t('onboarding.stageBattle', null, 'Battle Difficulty'),
            badgeIcon: Icons.shield_rounded,
            title: context.t('onboarding.chooseLevel', null, 'Calibrate Your Rank & Habit'),
            subtitle: context.t(
              'onboarding.levelSubtitle',
              null,
              'We’ll suggest videos and vocabulary tailored to your exact pace',
            ),
          ),

          // 5-Tier Level Rungs (DRY using OnboardingSelectionTile)
          ...RankLevelOption.all.map((lvl) {
            final isSelected = selectedLevel == lvl.id;
            final rankName = context.t('onboarding.ranks.${lvl.rankKey}', null, lvl.rankKey);
            final levelTitle = context.t(lvl.titleKey, null, lvl.id);
            final levelDesc = context.t(lvl.descKey, null, '');

            return OnboardingSelectionTile(
              title: '$rankName • $levelTitle',
              tagChip: lvl.examBadge,
              subtitle: levelDesc.isNotEmpty ? levelDesc : null,
              isSelected: isSelected,
              accentColor: lvl.badgeText,
              onTap: () => onLevelChanged(lvl.id),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: lvl.badgeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: lvl.badgeBorder, width: 1.2),
                ),
                child: Icon(lvl.icon, color: lvl.badgeText, size: 22),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Section 2: Daily Habit Commitment Header
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, size: 20, color: VocaTokens.colorFire),
              const SizedBox(width: 8),
              Text(
                context.t('onboarding.dailyGoalLabel', null, 'Daily Habit Pact'),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.t('onboarding.pactSubtitle', null, 'Habits build legends. Select your daily practice pace'),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 14),

          // Daily Goal Tiles (DRY using OnboardingSelectionTile)
          ...DailyGoalOption.all.map((goal) {
            final isSelected = selectedDailyGoal == goal.minutes;
            final title = context.t(goal.titleKey, null, goal.id);
            final desc = context.t(goal.descKey, null, '${goal.minutes} min/day');

            return OnboardingSelectionTile(
              title: title,
              tagChip: goal.isRecommended ? 'RECOMMENDED' : '${goal.minutes}m',
              subtitle: desc,
              isSelected: isSelected,
              accentColor: VocaTokens.colorFire,
              onTap: () => onDailyGoalChanged(goal.minutes),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? VocaTokens.colorFire.withOpacity(0.18)
                      : colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? VocaTokens.colorFire.withOpacity(0.4) : colors.borderColorLight,
                  ),
                ),
                child: Icon(
                  goal.icon,
                  color: isSelected ? VocaTokens.colorFire : colors.textSecondary,
                  size: 22,
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
