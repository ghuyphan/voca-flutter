// lib/ui/onboarding/steps/language_step.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../../widgets/voca_switch.dart';
import '../models/onboarding_models.dart';
import '../widgets/onboarding_selection_tile.dart';
import '../widgets/onboarding_step_header.dart';

/// Step 1: Learning Language Realm & Subtitle Translation Setup
class LanguageStep extends StatelessWidget {
  final String selectedLearningLanguage;
  final ValueChanged<String> onLearningLanguageChanged;
  final String selectedNativeLanguage;
  final ValueChanged<String> onNativeLanguageChanged;
  final bool showDualSubtitles;
  final ValueChanged<bool> onDualSubtitlesChanged;

  const LanguageStep({
    super.key,
    required this.selectedLearningLanguage,
    required this.onLearningLanguageChanged,
    required this.selectedNativeLanguage,
    required this.onNativeLanguageChanged,
    required this.showDualSubtitles,
    required this.onDualSubtitlesChanged,
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
            badgeText: context.t('onboarding.stageExpedition', null, 'Journey Preparation'),
            badgeIcon: Icons.explore_rounded,
            title: context.t('onboarding.realmTitle', null, 'Choose Your Language Realm'),
            subtitle: context.t(
              'onboarding.learningLanguageSubtitle',
              null,
              'Pick the language you want to study with authentic media',
            ),
          ),

          // 4 Target Learning Language Options (DRY using OnboardingSelectionTile)
          ...LearningRealmOption.all.map((realm) {
            final isSelected = selectedLearningLanguage == realm.code;
            final vibeText = context.t(realm.vibeKey, null, realm.name);

            return OnboardingSelectionTile(
              title: realm.name,
              tagChip: realm.nativeName,
              subtitle: vibeText,
              isSelected: isSelected,
              accentColor: realm.accentColor,
              onTap: () => onLearningLanguageChanged(realm.code),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: realm.accentColor.withOpacity(context.isDark ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? realm.accentColor.withOpacity(0.5)
                        : colors.borderColorLight,
                  ),
                ),
                alignment: Alignment.center,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SvgPicture.asset(
                    realm.flagAsset,
                    width: 28,
                    height: 20,
                    fit: BoxFit.cover,
                    placeholderBuilder: (_) => Text(
                      realm.flagEmoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 18),

          // Translation & Subtitles Settings Group Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.isDark ? colors.borderColor : colors.borderColorLight,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Title
                Row(
                  children: [
                    Icon(Icons.translate_rounded, size: 18, color: colors.accentPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.t('onboarding.myLanguage', null, 'My Language'),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        context.t('onboarding.myLanguageHint', null, 'Interface & subtitles'),
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Native Language Chips Row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: NativeLanguageOption.all.map((lang) {
                    final isChipSelected = selectedNativeLanguage == lang.code;

                    return GestureDetector(
                      onTap: () => onNativeLanguageChanged(lang.code),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                        decoration: BoxDecoration(
                          color: isChipSelected
                              ? colors.accentPrimary.withOpacity(context.isDark ? 0.16 : 0.1)
                              : colors.bgSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isChipSelected
                                ? colors.accentPrimary
                                : colors.borderColorLight,
                            width: isChipSelected ? 1.4 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: SvgPicture.asset(
                                lang.flagAsset,
                                width: 16,
                                height: 12,
                                fit: BoxFit.cover,
                                placeholderBuilder: (_) => Text(lang.flagEmoji, style: const TextStyle(fontSize: 14)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              lang.nativeName,
                              style: TextStyle(
                                color: isChipSelected
                                    ? colors.accentPrimary
                                    : colors.textPrimary,
                                fontSize: 12.5,
                                fontWeight: isChipSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: context.isDark ? colors.borderColorLight : colors.borderColor,
                ),
                const SizedBox(height: 14),

                // Dual Subtitles Toggle
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.t('onboarding.dualSubtitlesToggle', null, 'Translate subtitles'),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
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
                    VocaSwitch(
                      value: showDualSubtitles,
                      onChanged: onDualSubtitlesChanged,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
