// lib/ui/settings/setting_sub_screens.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/haptic_service.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import '../profile/edit_profile_screen.dart';
import '../widgets/voca_back_button.dart';
import '../widgets/voca_option_picker.dart';
import '../widgets/voca_switch.dart';

/// Shared layout scaffold for Settings sub-screens, matching the On-Device Translation
/// screen design:
/// 1. AppBar with VocaBackButton and title
/// 2. Top Informational Header Card (36x36 soft accent icon + title + description)
/// 3. Uppercase Section Header + Rounded Card Group of options/controls
class VocaSettingSubScreenLayout extends StatelessWidget {
  final String title;
  final IconData headerIcon;
  final String headerTitle;
  final String headerDescription;
  final String sectionTitle;
  final Widget cardChild;

  const VocaSettingSubScreenLayout({
    super.key,
    required this.title,
    required this.headerIcon,
    required this.headerTitle,
    required this.headerDescription,
    required this.sectionTitle,
    required this.cardChild,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 68,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: VocaBackButton(),
          ),
        ),
        titleSpacing: 8,
        title: Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. Informational Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: colors.accentPrimarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            headerIcon,
                            color: colors.accentPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              headerTitle,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              headerDescription,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Section Header
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    sectionTitle.toUpperCase(),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),

                // 3. Rounded Card Container
                Container(
                  decoration: BoxDecoration(
                    color: colors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.borderColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: cardChild,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable option list card for single-selection setting sub-screens.
class VocaSettingOptionCardList extends StatelessWidget {
  final List<OptionItem> options;
  final String selectedValue;
  final ValueChanged<String> onSelect;

  const VocaSettingOptionCardList({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        indent: 68,
        endIndent: 16,
        color: colors.borderColorLight.withValues(alpha: 0.6),
      ),
      itemBuilder: (context, index) {
        final item = options[index];
        final isSelected = item.value == selectedValue;

        return Semantics(
          button: true,
          selected: isSelected,
          label: item.label,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticService.selection();
                onSelect(item.value);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    if (item.leading != null) ...[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.accentPrimarySoft
                              : colors.bgSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? colors.accentPrimary.withValues(alpha: 0.35)
                                : colors.borderColor.withValues(alpha: 0.7),
                          ),
                        ),
                        child: Center(
                          child: ClipOval(child: item.leading!),
                        ),
                      ),
                      const SizedBox(width: 14),
                    ] else if (item.iconData != null) ...[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.accentPrimarySoft
                              : colors.bgSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? colors.accentPrimary.withValues(alpha: 0.35)
                                : colors.borderColor.withValues(alpha: 0.7),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            item.iconData,
                            size: 20,
                            color: isSelected
                                ? colors.accentPrimary
                                : colors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 15,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                          if (item.example != null &&
                              item.example!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.example!,
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (item.description != null &&
                              item.description!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.description!,
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected
                          ? colors.accentPrimary
                          : colors.textMuted.withValues(alpha: 0.35),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 1. Learning Language Sub-Screen
class LearningLanguageSettingsScreen extends StatelessWidget {
  const LearningLanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final _ = I18nService.instance.currentLanguage.value;
      final currentLang = AppState.instance.activeLanguage.value;

      return VocaSettingSubScreenLayout(
        title: context.t('settings.learningLanguage', null, 'Learning Language'),
        headerIcon: Icons.school_rounded,
        headerTitle: context.t(
          'settings.learningLanguageDescTitle',
          null,
          'Target Immersion Language',
        ),
        headerDescription: context.t(
          'settings.learningLanguageDescBody',
          null,
          'Choose the language you are studying. Video feeds, grammar analysis, and vocabulary decks adapt to your target language.',
        ),
        sectionTitle: context.t('settings.preferences', null, 'PREFERENCES'),
        cardChild: VocaSettingOptionCardList(
          selectedValue: currentLang,
          onSelect: (selected) {
            if (selected != currentLang) {
              AppState.instance.setLanguage(selected);
            }
          },
          options: [
            OptionItem(
              value: 'ja',
              label: '日本語',
              example: context.t('settings.japanese', null, 'Japanese'),
              leading: const VocaFlagWidget(countryCode: 'jp', size: 22),
            ),
            OptionItem(
              value: 'zh',
              label: '中文',
              example: context.t('settings.chinese', null, 'Chinese (Mandarin)'),
              leading: const VocaFlagWidget(countryCode: 'cn', size: 22),
            ),
            OptionItem(
              value: 'ko',
              label: '한국어',
              example: context.t('settings.korean', null, 'Korean'),
              leading: const VocaFlagWidget(countryCode: 'kr', size: 22),
            ),
            OptionItem(
              value: 'en',
              label: 'English',
              example: context.t('settings.english', null, 'English'),
              leading: const VocaFlagWidget(countryCode: 'us', size: 22),
            ),
          ],
        ),
      );
    });
  }
}

/// 2. Interface Language Sub-Screen
class InterfaceLanguageSettingsScreen extends StatelessWidget {
  const InterfaceLanguageSettingsScreen({super.key});

  static String _countryCodeForLang(String code) {
    switch (code.toLowerCase()) {
      case 'ja':
      case 'jp':
        return 'jp';
      case 'zh':
      case 'cn':
        return 'cn';
      case 'ko':
      case 'kr':
        return 'kr';
      case 'en':
      case 'us':
        return 'us';
      case 'vi':
      case 'vn':
        return 'vn';
      default:
        return code.toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = I18nService.instance;

    return Watch((context) {
      final currentCode = i18n.currentLanguage.value;

      return VocaSettingSubScreenLayout(
        title: context.t('settings.interfaceLanguage', null, 'Interface Language'),
        headerIcon: Icons.language_rounded,
        headerTitle: context.t(
          'settings.interfaceLanguageDescTitle',
          null,
          'App Display Language',
        ),
        headerDescription: context.t(
          'settings.interfaceLanguageDescBody',
          null,
          'Select the language used for menus, buttons, grammar explanations, and study instructions across the app.',
        ),
        sectionTitle: context.t('settings.preferences', null, 'PREFERENCES'),
        cardChild: VocaSettingOptionCardList(
          selectedValue: currentCode,
          onSelect: (selected) {
            if (selected != currentCode) {
              AppState.instance.setUiLanguage(selected);
            }
          },
          options: i18n.availableLanguages.map((l) {
            return OptionItem(
              value: l.code,
              label: l.nativeName,
              example: l.name,
              leading: VocaFlagWidget(
                countryCode: _countryCodeForLang(l.code),
                size: 22,
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}

/// 3. Reading Display / Pronunciation Guides Sub-Screen
class ReadingGuidesSettingsScreen extends StatelessWidget {
  const ReadingGuidesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final _ = I18nService.instance.currentLanguage.value;
      final targetLang = AppState.instance.activeLanguage.value;
      final settings = AppState.instance.userSettings.value;

      final String readingGuideTitle;
      switch (targetLang) {
        case 'ja':
          readingGuideTitle =
              context.t('settings.furiganaAndRuby', null, 'Furigana & Ruby');
          break;
        case 'zh':
          readingGuideTitle =
              context.t('settings.pinyinGuides', null, 'Pinyin Guides');
          break;
        case 'ko':
          readingGuideTitle =
              context.t('settings.romajiGuides', null, 'Romaji Guides');
          break;
        case 'en':
        default:
          readingGuideTitle =
              context.t('settings.phonetics', null, 'Pronunciation Guides');
          break;
      }

      return VocaSettingSubScreenLayout(
        title: readingGuideTitle,
        headerIcon: Icons.subtitles_outlined,
        headerTitle: context.t(
          'settings.readingGuideDescTitle',
          null,
          'Phonetic Reading Annotations',
        ),
        headerDescription: context.t(
          'settings.readingGuideDescBody',
          null,
          'Control how pronunciation guides appear above words in video subtitles and vocabulary flashcards.',
        ),
        sectionTitle: context.t('settings.preferences', null, 'PREFERENCES'),
        cardChild: VocaSettingOptionCardList(
          selectedValue: settings.rubyMode.name,
          onSelect: (selected) {
            final mode = RubyDisplayMode.values.firstWhere(
              (e) => e.name == selected,
              orElse: () => RubyDisplayMode.always,
            );
            AppState.instance.setRubyMode(mode);
          },
          options: [
            OptionItem(
              value: RubyDisplayMode.always.name,
              label: context.t('settings.alwaysShow', null, 'Always Show'),
              example: context.t(
                'settings.alwaysShowDesc',
                null,
                'Display reading annotations above all words',
              ),
              iconData: Icons.visibility_rounded,
            ),
            OptionItem(
              value: RubyDisplayMode.tap.name,
              label: context.t('settings.onTapOnly', null, 'On Tap Only'),
              example: context.t(
                'settings.onTapOnlyDesc',
                null,
                'Reveal pronunciation when tapping a word',
              ),
              iconData: Icons.touch_app_rounded,
            ),
            OptionItem(
              value: RubyDisplayMode.never.name,
              label: context.t('settings.off', null, 'Off'),
              example: context.t(
                'settings.offDesc',
                null,
                'Hide all phonetic guides for full immersion',
              ),
              iconData: Icons.visibility_off_rounded,
            ),
          ],
        ),
      );
    });
  }
}

/// 4. Theme Sub-Screen
class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final _ = I18nService.instance.currentLanguage.value;
      final settings = AppState.instance.userSettings.value;
      final currentMode = settings.themeMode.toLowerCase();

      return VocaSettingSubScreenLayout(
        title: context.t('settings.theme', null, 'Theme'),
        headerIcon: Icons.palette_outlined,
        headerTitle: context.t(
          'settings.themeDescTitle',
          null,
          'App Appearance',
        ),
        headerDescription: context.t(
          'settings.themeDescBody',
          null,
          'Choose between Rich Obsidian dark mode, Crisp Porcelain light mode, or automatic synchronization with your device settings.',
        ),
        sectionTitle: context.t('settings.preferences', null, 'PREFERENCES'),
        cardChild: VocaSettingOptionCardList(
          selectedValue: currentMode,
          onSelect: (selected) {
            if (selected != currentMode) {
              AppState.instance.setThemeMode(selected);
            }
          },
          options: [
            OptionItem(
              value: 'system',
              label: context.t('settings.themeSystem', null, 'System'),
              example: context.t(
                'settings.themeSystemDesc',
                null,
                'Follow device appearance',
              ),
              iconData: Icons.brightness_auto_rounded,
            ),
            OptionItem(
              value: 'light',
              label: context.t('settings.themeLight', null, 'Light'),
              example: context.t(
                'settings.themeLightDesc',
                null,
                'Light theme',
              ),
              iconData: Icons.light_mode_rounded,
            ),
            OptionItem(
              value: 'dark',
              label: context.t('settings.themeDark', null, 'Dark'),
              example: context.t(
                'settings.themeDarkDesc',
                null,
                'Dark theme',
              ),
              iconData: Icons.dark_mode_rounded,
            ),
          ],
        ),
      );
    });
  }
}

/// 5. Haptic Feedback Sub-Screen
class HapticSettingsScreen extends StatelessWidget {
  const HapticSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final _ = I18nService.instance.currentLanguage.value;
      final settings = AppState.instance.userSettings.value;

      return VocaSettingSubScreenLayout(
        title: context.t('settings.hapticFeedback', null, 'Haptic Feedback'),
        headerIcon: Icons.vibration_rounded,
        headerTitle: context.t(
          'settings.hapticDescTitle',
          null,
          'Tactile Touch Feedback',
        ),
        headerDescription: context.t(
          'settings.hapticDescBody',
          null,
          'Feel subtle vibrations when flipping flashcards, swiping study cards, tapping controls, and claiming rewards.',
        ),
        sectionTitle: context.t('settings.preferences', null, 'PREFERENCES'),
        cardChild: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: VocaSwitch(
            value: settings.hapticFeedbackEnabled,
            label: context.t(
              'settings.enableHaptics',
              null,
              'Enable Haptic Feedback',
            ),
            subtitle: context.t(
              'settings.enableHapticsSub',
              null,
              'Vibrate on interactions, gestures, and notifications',
            ),
            onChanged: (val) {
              AppState.instance.setHapticFeedback(val);
            },
          ),
        ),
      );
    });
  }
}
