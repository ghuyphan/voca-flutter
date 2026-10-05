// lib/ui/onboarding/steps/native_language_step.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../../widgets/voca_switch.dart';
import '../models/onboarding_models.dart';
import '../widgets/onboarding_primitives.dart';
import '../widgets/pressable_scale.dart';

/// Step 2: Choose native language & configure dual subtitles.
class NativeLanguageStep extends StatelessWidget {
  final String selectedLanguage;
  final ValueChanged<String> onSelect;
  final bool showDualSubtitles;
  final ValueChanged<bool> onToggleDualSubtitles;

  const NativeLanguageStep({
    super.key,
    required this.selectedLanguage,
    required this.onSelect,
    required this.showDualSubtitles,
    required this.onToggleDualSubtitles,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return OnboardingStepLayout(
      title: context.t('onboarding.myLanguage', null, 'My Language'),
      subtitle: context.t(
        'onboarding.myLanguageHint',
        null,
        'Interface language & subtitle translations',
      ),
      children: [
        // Grouped list of languages
        GroupedCard(
            dividerIndent: 68,
            children: [
              for (final opt in NativeLanguageOption.all)
                _NativeLanguageRow(
                  option: opt,
                  isSelected: selectedLanguage == opt.code,
                  onTap: () => onSelect(opt.code),
                  colors: colors,
                ),
            ],
        ),

        const SizedBox(height: 28),

        // Subtitle preferences section
        SectionLabel(
          context.t('onboarding.dualSubtitlesToggle', null, 'Translate subtitles'),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.accentPrimary.withValues(alpha: colors.isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.subtitles_outlined,
                  size: 20,
                  color: colors.accentPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('onboarding.dualSubtitlesToggle', null, 'Translate subtitles'),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.t(
                        'onboarding.dualSubtitlesHint',
                        null,
                        'Show translations below video captions',
                      ),
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              VocaSwitch(
                value: showDualSubtitles,
                onChanged: onToggleDualSubtitles,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NativeLanguageRow extends StatelessWidget {
  final NativeLanguageOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final VocaColorPalette colors;

  const _NativeLanguageRow({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final localizedName =
        context.t(languageNameKey(option.code), null, option.englishName);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${option.nativeName}, $localizedName',
      child: PressableScale(
        onTap: onTap,
        pressedScale: 0.98,
        child: Container(
          color: isSelected
              ? colors.accentPrimary.withValues(alpha: colors.isDark ? 0.08 : 0.04)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              RoundFlag(asset: option.flagAsset, size: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.nativeName,
                      style: TextStyle(
                        color: isSelected ? colors.accentPrimary : colors.textPrimary,
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      localizedName,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              RadioCheck(selected: isSelected, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
