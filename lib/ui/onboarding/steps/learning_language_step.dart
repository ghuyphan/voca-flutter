// lib/ui/onboarding/steps/learning_language_step.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../models/onboarding_models.dart';
import '../widgets/onboarding_primitives.dart';
import '../widgets/pressable_scale.dart';

/// Step 1: Choose target learning language.
/// Focused, uncluttered native card selector for the 4 supported immersion realms.
class LearningLanguageStep extends StatelessWidget {
  final String selectedLanguage;
  final ValueChanged<String> onSelect;

  const LearningLanguageStep({
    super.key,
    required this.selectedLanguage,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return OnboardingStepLayout(
      title: context.t('onboarding.learningLanguageTitle', null, 'I want to learn...'),
      subtitle: context.t(
        'onboarding.learningLanguageSubtitle',
        null,
        'Pick the language you want to study with authentic media',
      ),
      children: [
        for (final opt in LearningLanguageOption.all)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LanguageOptionCard(
              option: opt,
              isSelected: selectedLanguage == opt.code,
              onTap: () => onSelect(opt.code),
              colors: colors,
            ),
          ),
      ],
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  final LearningLanguageOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final VocaColorPalette colors;

  const _LanguageOptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final localizedName =
        context.t(languageNameKey(option.code), null, option.englishName);
    final vibe = context.t(option.vibeKey, null, '');

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$localizedName, ${option.nativeName}, ${option.examFramework}',
      child: PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.accentPrimary
                    .withValues(alpha: colors.isDark ? 0.12 : 0.06)
                : colors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? colors.accentPrimary : colors.borderColor,
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.accentPrimary
                          .withValues(alpha: colors.isDark ? 0.20 : 0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: colors.isDark ? 0.20 : 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Seamless Flag
              RoundFlag(
                asset: option.flagAsset,
                size: 40,
              ),
              const SizedBox(width: 14),

              // Title, Native Name, Exam Framework & Media Vibe
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            localizedName,
                            style: TextStyle(
                              color: isSelected
                                  ? colors.accentPrimary
                                  : colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Native script pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.accentPrimary.withValues(alpha: 0.14)
                                : colors.bgSurface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? colors.accentPrimary
                                      .withValues(alpha: 0.3)
                                  : colors.borderColorLight,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            option.nativeName,
                            style: TextStyle(
                              color: isSelected
                                  ? colors.accentPrimary
                                  : colors.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Exam scale pill (JLPT N5-N1, TOPIK 1-6, etc.)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.bgSurface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: colors.borderColorLight,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            option.examFramework,
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (vibe.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.play_circle_outline_rounded,
                            size: 13,
                            color: isSelected
                                ? colors.accentPrimary.withValues(alpha: 0.8)
                                : colors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              vibe,
                              style: TextStyle(
                                color: isSelected
                                    ? colors.accentPrimary
                                        .withValues(alpha: 0.85)
                                    : colors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Selection Radio Indicator
              RadioCheck(selected: isSelected, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
