// lib/ui/onboarding/steps/learning_language_step.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../models/onboarding_models.dart';
import '../widgets/onboarding_primitives.dart';
import '../widgets/pressable_scale.dart';

/// Step 1: Choose target learning language.
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
      title: context.t('onboarding.realmTitle', null, 'Choose Your Language Realm'),
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
      label: '$localizedName, ${option.nativeName}',
      child: PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.accentPrimary.withValues(alpha: colors.isDark ? 0.12 : 0.06)
                : colors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? colors.accentPrimary : colors.borderColor,
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.accentPrimary
                          .withValues(alpha: colors.isDark ? 0.18 : 0.10),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              RoundFlag(asset: option.flagAsset, size: 40),
              const SizedBox(width: 14),
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
                              color: colors.textPrimary,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TagChip(
                          label: option.nativeName,
                          bg: colors.bgSurface,
                          fg: colors.textSecondary,
                          border: colors.borderColorLight,
                        ),
                      ],
                    ),
                    if (vibe.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        vibe,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              RadioCheck(selected: isSelected, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
