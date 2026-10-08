// lib/ui/onboarding/steps/ready_step.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../models/onboarding_models.dart';
import '../widgets/onboarding_primitives.dart';
import '../widgets/pressable_scale.dart';

/// Step 4: Personalized Plan Summary & Starter Loot Rewards.
/// Confirms learner's choices with a polished pass card, presents
/// initial starter loot, and provides appearance theme personalization.
class ReadyStep extends StatelessWidget {
  final String learningLanguage;
  final String selectedLevel;
  final String selectedCompanion;
  final int dailyGoal;
  final String themeMode;
  final ValueChanged<String>? onThemeChanged;

  const ReadyStep({
    super.key,
    required this.learningLanguage,
    required this.selectedLevel,
    required this.selectedCompanion,
    required this.dailyGoal,
    required this.themeMode,
    this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;

    final langOpt = LearningLanguageOption.byCode(learningLanguage);
    final levelOpt = LevelOption.byId(selectedLevel);
    final compOpt = CompanionOption.byId(selectedCompanion);

    final langName = context.t(languageNameKey(langOpt.code), null, langOpt.englishName);
    final rankName = context.t(levelOpt.rankNameKey, null, levelOpt.rankKey);
    final levelTitle = context.t(levelOpt.titleKey, null, levelOpt.id);
    final compName = context.t(compOpt.nameKey, null, compOpt.id);
    final compTrait = context.t(compOpt.traitKey, null, '');
    final goalMinutes = context.t(
      'onboarding.minutesPerDay',
      {'minutes': dailyGoal},
      '$dailyGoal min/day',
    );

    final effectiveTheme =
        (themeMode == 'light' || themeMode == 'dark') ? themeMode : 'system';

    return OnboardingStepLayout(
      title: context.t('onboarding.starterTitle', null, 'Ready to Learn'),
      subtitle: context.t(
        'onboarding.starterSubtitle',
        null,
        'Your personalized immersion plan',
      ),
      children: [
        // 1. Personalized Learning Plan Pass Card
        Container(
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.borderColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // Card Header Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                  border: Border(
                    bottom: BorderSide(color: colors.borderColorLight),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: 16,
                      color: colors.accentPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.t('onboarding.planSummary', null, 'Learning Plan'),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.success.withValues(alpha: isDark ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        context.t('onboarding.planReady', null, 'Ready'),
                        style: TextStyle(
                          color: colors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Plan Item Rows
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    // Target Language
                    _PlanItemRow(
                      iconWidget: RoundFlag(asset: langOpt.flagAsset, size: 22),
                      title: langName,
                      subtitle: langOpt.examFramework,
                      trailingBadge: langOpt.nativeName,
                      colors: colors,
                    ),
                    const SizedBox(height: 10),

                    // Level
                    _PlanItemRow(
                      iconWidget: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: levelOpt.colors(isDark: isDark).bg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          levelOpt.icon,
                          size: 13,
                          color: levelOpt.colors(isDark: isDark).text,
                        ),
                      ),
                      title: '$rankName • $levelTitle',
                      subtitle: levelOpt.examBadge(learningLanguage),
                      colors: colors,
                    ),
                    const SizedBox(height: 10),

                    // Companion Guide
                    _PlanItemRow(
                      iconWidget: ClipOval(
                        child: Image.asset(
                          compOpt.avatarAsset,
                          width: 22,
                          height: 22,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            compOpt.icon,
                            size: 16,
                            color: compOpt.color,
                          ),
                        ),
                      ),
                      title: compName,
                      subtitle: compTrait,
                      trailingBadge: 'Lv.1',
                      colors: colors,
                    ),
                    const SizedBox(height: 10),

                    // Daily Goal
                    _PlanItemRow(
                      iconWidget: Icon(
                        Icons.local_fire_department_rounded,
                        size: 20,
                        color: colors.colorFire,
                      ),
                      title: goalMinutes,
                      subtitle: context.t('onboarding.dailyGoalLabel', null, 'Daily Habit'),
                      colors: colors,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Starter Loot Cache Grid
        SectionLabel(
          context.t('onboarding.starterBonusTitle', null, 'New Learner Starter Pack'),
        ),
        Row(
          children: [
            Expanded(
              child: _LootCard(
                icon: Icons.diamond_rounded,
                iconColor: colors.colorDiamond,
                title: context.t('onboarding.starterLoot.diamonds', null, '5 AI Captions'),
                desc: context.t('onboarding.starterLoot.diamondsDesc', null, 'AI voice sync & translation'),
                colors: colors,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _LootCard(
                icon: Icons.auto_awesome_rounded,
                iconColor: colors.accentSecondary,
                title: context.t('onboarding.starterLoot.xp', null, '+50 Starter XP'),
                desc: context.t('onboarding.starterLoot.xpDesc', null, 'Jumpstart to Level 1'),
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _LootCard(
                icon: Icons.local_fire_department_rounded,
                iconColor: colors.colorFire,
                title: context.t('onboarding.starterLoot.hearth', null, 'Day 1 Streak'),
                desc: context.t('onboarding.starterLoot.hearthDesc', null, 'Start your learning habit'),
                colors: colors,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _LootCard(
                icon: Icons.ac_unit_rounded,
                iconColor: colors.colorDiamond,
                title: context.t('onboarding.starterLoot.freeze', null, 'Streak Freeze'),
                desc: context.t('onboarding.starterLoot.freezeDesc', null, 'Keep streak safe when busy'),
                colors: colors,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 3. Appearance & Theme Selection
        SectionLabel(
          context.t('onboarding.appearance', null, 'Appearance'),
        ),
        Row(
          children: [
            _ThemeOptionTile(
              icon: Icons.brightness_auto_outlined,
              label: context.t('onboarding.themeSystem', null, 'System'),
              subtitle: context.t('onboarding.themeSystemDesc', null, 'Auto'),
              isSelected: effectiveTheme == 'system',
              onTap: () => onThemeChanged?.call('system'),
            ),
            const SizedBox(width: 8),
            _ThemeOptionTile(
              icon: Icons.light_mode_outlined,
              label: context.t('onboarding.themeLight', null, 'Light'),
              subtitle: context.t('onboarding.themeLightDesc', null, 'Light theme'),
              isSelected: effectiveTheme == 'light',
              onTap: () => onThemeChanged?.call('light'),
            ),
            const SizedBox(width: 8),
            _ThemeOptionTile(
              icon: Icons.dark_mode_outlined,
              label: context.t('onboarding.themeDark', null, 'Dark'),
              subtitle: context.t('onboarding.themeDarkDesc', null, 'Dark theme'),
              isSelected: effectiveTheme == 'dark',
              onTap: () => onThemeChanged?.call('dark'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlanItemRow extends StatelessWidget {
  final Widget iconWidget;
  final String title;
  final String subtitle;
  final String? trailingBadge;
  final VocaColorPalette colors;

  const _PlanItemRow({
    required this.iconWidget,
    required this.title,
    required this.subtitle,
    this.trailingBadge,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 24, height: 24, child: Center(child: iconWidget)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (trailingBadge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colors.borderColorLight, width: 1.0),
            ),
            child: Text(
              trailingBadge!,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _LootCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String desc;
  final VocaColorPalette colors;

  const _LootCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.desc,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = colors.isDark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderColor, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = context.isDark;

    final border = isSelected
        ? Border.all(color: colors.accentPrimary, width: 1.6)
        : Border.all(color: colors.borderColorLight, width: 1.0);

    final bg = isSelected
        ? colors.accentPrimary.withValues(alpha: isDark ? 0.20 : 0.08)
        : colors.bgCard;

    final textColor = isSelected ? colors.accentPrimary : colors.textPrimary;
    final iconColor = isSelected ? colors.accentPrimary : colors.textSecondary;

    return Expanded(
      child: PressableScale(
        haptic: true,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: border,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: isSelected
                      ? colors.accentPrimary.withValues(alpha: 0.8)
                      : colors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
