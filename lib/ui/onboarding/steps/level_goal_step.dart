// lib/ui/onboarding/steps/level_goal_step.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../models/onboarding_models.dart';
import '../widgets/onboarding_primitives.dart';
import '../widgets/pressable_scale.dart';

/// Step 2: Difficulty ladder & daily study habit commitment.
class LevelGoalStep extends StatelessWidget {
  final String learningLanguage;
  final String selectedLevel;
  final ValueChanged<String> onSelectLevel;
  final int selectedDailyGoal;
  final ValueChanged<int> onSelectDailyGoal;

  const LevelGoalStep({
    super.key,
    required this.learningLanguage,
    required this.selectedLevel,
    required this.onSelectLevel,
    required this.selectedDailyGoal,
    required this.onSelectDailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;

    return OnboardingStepLayout(
      title: context.t('onboarding.chooseLevel', null, 'Choose your level'),
      subtitle: context.t(
        'onboarding.levelSubtitle',
        null,
        "We'll suggest videos suited to your pace",
      ),
      children: [
        // 5-Tier Level Rungs
        for (final lvl in LevelOption.all)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LevelRungTile(
              level: lvl,
              learningLanguage: learningLanguage,
              isSelected: selectedLevel == lvl.id,
              onTap: () => onSelectLevel(lvl.id),
              isDark: isDark,
              colors: colors,
            ),
          ),

        const SizedBox(height: 20),

        // Section: Daily Habit Pact
        SectionLabel(
          context.t('onboarding.dailyGoalLabel', null, 'Daily Habit Pact'),
        ),

        // 4 Horizontal segmented goal pills
        Row(
          children: [
            for (var i = 0; i < DailyGoalOption.all.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _DailyGoalPill(
                  option: DailyGoalOption.all[i],
                  isSelected: selectedDailyGoal == DailyGoalOption.all[i].minutes,
                  onTap: () => onSelectDailyGoal(DailyGoalOption.all[i].minutes),
                  colors: colors,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _LevelRungTile extends StatelessWidget {
  final LevelOption level;
  final String learningLanguage;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final VocaColorPalette colors;

  const _LevelRungTile({
    required this.level,
    required this.learningLanguage,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final levelColors = level.colors(isDark: isDark);
    final rankName = context.t(level.rankNameKey, null, level.rankKey);
    final levelTitle = context.t(level.titleKey, null, level.id);
    final levelDesc = context.t(level.descKey, null, '');
    final examBadge = level.examBadge(learningLanguage);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$rankName, $levelTitle, $examBadge',
      child: PressableScale(
        onTap: onTap,
        pressedScale: 0.98,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? levelColors.bg.withValues(alpha: isDark ? 0.22 : 0.40)
                : colors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? levelColors.border : colors.borderColor,
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Level Tier Emblem
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: levelColors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: levelColors.border, width: 1.2),
                ),
                child: Icon(level.icon, size: 20, color: levelColors.text),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '$rankName • $levelTitle',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TagChip(
                          label: examBadge,
                          bg: levelColors.bg,
                          fg: levelColors.text,
                          border: levelColors.border,
                        ),
                      ],
                    ),
                    if (levelDesc.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        levelDesc,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              RadioCheck(selected: isSelected, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyGoalPill extends StatelessWidget {
  final DailyGoalOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final VocaColorPalette colors;

  const _DailyGoalPill({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final localizedLabel = context.t(
      'onboarding.minutesPerDay',
      {'minutes': option.minutes},
      '${option.minutes} min/day',
    );

    return Semantics(
      button: true,
      selected: isSelected,
      label: localizedLabel,
      child: PressableScale(
        onTap: onTap,
        pressedScale: 0.95,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.colorFire.withValues(alpha: colors.isDark ? 0.20 : 0.12)
                : colors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? colors.colorFire : colors.borderColor,
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 15,
                    color: isSelected ? colors.colorFire : colors.textMuted,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${option.minutes}m',
                    style: TextStyle(
                      color: isSelected ? colors.colorFire : colors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                option.isRecommended
                    ? context.t('onboarding.goalBest', null, 'BEST')
                    : context.t('onboarding.goalDay', null, 'DAILY'),
                style: TextStyle(
                  color: isSelected
                      ? colors.colorFire
                      : (option.isRecommended
                          ? colors.accentPrimary
                          : colors.textTertiary),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
