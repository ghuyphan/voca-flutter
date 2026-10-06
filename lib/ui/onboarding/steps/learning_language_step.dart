// lib/ui/onboarding/steps/learning_language_step.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../../widgets/voca_switch.dart';
import '../models/onboarding_models.dart';
import '../widgets/onboarding_primitives.dart';
import '../widgets/pressable_scale.dart';

/// Step 1: Choose target learning language & configure UI locale / subtitles (1:1 with lingua-tube).
class LearningLanguageStep extends StatelessWidget {
  final String selectedLanguage;
  final ValueChanged<String> onSelect;
  final String nativeLanguage;
  final ValueChanged<String> onSelectNativeLanguage;
  final bool showDualSubtitles;
  final ValueChanged<bool> onToggleDualSubtitles;

  const LearningLanguageStep({
    super.key,
    required this.selectedLanguage,
    required this.onSelect,
    required this.nativeLanguage,
    required this.onSelectNativeLanguage,
    required this.showDualSubtitles,
    required this.onToggleDualSubtitles,
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
        const SizedBox(height: 10),
        _buildNativeLanguageCard(context, colors),
      ],
    );
  }

  Widget _buildNativeLanguageCard(BuildContext context, VocaColorPalette colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.t('onboarding.myLanguage', null, 'My Language'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  context.t('onboarding.myLanguageHint', null, 'Interface & subtitles'),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: colors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 5-Column UI Language Selector Row
          Row(
            children: [
              for (final opt in NativeLanguageOption.all)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _UiLangChip(
                      option: opt,
                      isSelected: nativeLanguage == opt.code,
                      onTap: () => onSelectNativeLanguage(opt.code),
                      colors: colors,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Toggle Row
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.borderColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('onboarding.dualSubtitlesToggle', null, 'Translate subtitles'),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
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
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: colors.textMuted,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                VocaSwitch(
                  value: showDualSubtitles,
                  onChanged: onToggleDualSubtitles,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UiLangChip extends StatelessWidget {
  final NativeLanguageOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final VocaColorPalette colors;

  const _UiLangChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accentPrimary.withValues(alpha: colors.isDark ? 0.14 : 0.08)
              : colors.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.accentPrimary : colors.borderColor,
            width: isSelected ? 1.6 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.accentPrimary.withValues(alpha: 0.20),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RoundFlag(asset: option.flagAsset, size: 20),
            const SizedBox(height: 5),
            Text(
              option.nativeName,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? colors.accentPrimary : colors.textSecondary,
                height: 1.15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Circular Flag with depth & subtle border
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.bgSurface,
                  border: Border.all(
                    color: isSelected ? colors.accentPrimary.withValues(alpha: 0.4) : colors.borderColor,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: colors.isDark ? 0.25 : 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: RoundFlag(asset: option.flagAsset, size: 36),
                ),
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
                              color: isSelected ? colors.accentPrimary : colors.textPrimary,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Native script pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.accentPrimary.withValues(alpha: 0.14)
                                : colors.bgSurface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? colors.accentPrimary.withValues(alpha: 0.3)
                                  : colors.borderColorLight,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            option.nativeName,
                            style: TextStyle(
                              color: isSelected ? colors.accentPrimary : colors.textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Exam scale pill (JLPT N5-N1, TOPIK 1-6, etc.)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                                    ? colors.accentPrimary.withValues(alpha: 0.85)
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
