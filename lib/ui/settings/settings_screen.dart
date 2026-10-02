// lib/ui/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import '../widgets/voca_option_picker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary,
        elevation: 0,
        title: Text(
          context.t('settings.title'),
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SafeArea(
        child: Watch((context) {
          final settings = AppState.instance.userSettings.value;
          final i18n = I18nService.instance;
          final currentUILang = i18n.currentLanguageInfo;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // SECTION 1: Appearance & Theme
              _buildSectionHeader(context, context.t('settings.theme').toUpperCase(), colors),
              Material(
                color: colors.bgCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colors.borderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Theme Mode Selector
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.palette_outlined, color: colors.accentPrimary, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                context.t('settings.theme'),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.t('settings.themeDesc'),
                            style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<String>(
                            segments: [
                              ButtonSegment(
                                value: 'system',
                                icon: const Icon(Icons.brightness_auto_rounded, size: 16),
                                label: Text(context.t('settings.themeSystem')),
                              ),
                              ButtonSegment(
                                value: 'light',
                                icon: const Icon(Icons.light_mode_rounded, size: 16),
                                label: Text(context.t('settings.themeLight')),
                              ),
                              ButtonSegment(
                                value: 'dark',
                                icon: const Icon(Icons.dark_mode_rounded, size: 16),
                                label: Text(context.t('settings.themeDark')),
                              ),
                            ],
                            selected: {settings.themeMode},
                            onSelectionChanged: (newSelection) {
                              AppState.instance.setThemeMode(newSelection.first);
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                                (states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return colors.accentPrimary;
                                  }
                                  return colors.bgSecondary;
                                },
                              ),
                              foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                                (states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.white;
                                  }
                                  return colors.textSecondary;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(color: colors.borderColorLight, height: 1),

                    // App Interface Language (Locale)
                    ListTile(
                      leading: Icon(Icons.language_rounded, color: colors.accentSecondary),
                      title: Text(
                        context.t('settings.uiLanguage'),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        context.t('settings.uiLanguageDesc'),
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${currentUILang.flag} ${currentUILang.nativeName}',
                            style: TextStyle(
                              color: colors.accentPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, color: colors.textMuted, size: 20),
                        ],
                      ),
                      onTap: () async {
                        final selected = await showVocaOptionPicker(
                          context: context,
                          title: context.t('settings.uiLanguage'),
                          selectedValue: i18n.currentLanguage.value,
                          options: i18n.availableLanguages.map((l) {
                            return OptionItem(
                              value: l.code,
                              label: l.nativeName,
                              example: l.name,
                              icon: l.flag,
                            );
                          }).toList(),
                        );
                        if (selected != null) {
                          AppState.instance.setUiLanguage(selected);
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // SECTION 2: Subtitle & Annotations
              _buildSectionHeader(context, context.t('settings.subtitles').toUpperCase(), colors),
              Material(
                color: colors.bgCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colors.borderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Furigana / Ruby Mode
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.translate_rounded, color: colors.accentPrimary, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                context.t('settings.furiganaPinyin'),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.t('settings.readingDisplayDesc'),
                            style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<RubyDisplayMode>(
                            segments: [
                              ButtonSegment(
                                value: RubyDisplayMode.always,
                                label: Text(context.t('settings.alwaysShow')),
                              ),
                              ButtonSegment(
                                value: RubyDisplayMode.tap,
                                label: Text(context.t('settings.onTapOnly')),
                              ),
                              ButtonSegment(
                                value: RubyDisplayMode.never,
                                label: Text(context.t('settings.off')),
                              ),
                            ],
                            selected: {settings.rubyMode},
                            onSelectionChanged: (Set<RubyDisplayMode> newSelection) {
                              AppState.instance.setRubyMode(newSelection.first);
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                                (states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return colors.accentPrimary;
                                  }
                                  return colors.bgSecondary;
                                },
                              ),
                              foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                                (states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.white;
                                  }
                                  return colors.textSecondary;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(color: colors.borderColorLight, height: 1),

                    // Subtitle Font Size
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.format_size_rounded, color: colors.accentSecondary, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                context.t('settings.subtitleSize'),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.t('settings.subtitleSizeDesc'),
                            style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<SubtitleSize>(
                            segments: [
                              ButtonSegment(
                                value: SubtitleSize.small,
                                label: Text(context.t('settings.sizeSmall')),
                              ),
                              ButtonSegment(
                                value: SubtitleSize.medium,
                                label: Text(context.t('settings.sizeMedium')),
                              ),
                              ButtonSegment(
                                value: SubtitleSize.large,
                                label: Text(context.t('settings.sizeLarge')),
                              ),
                            ],
                            selected: {settings.subtitleSize},
                            onSelectionChanged: (Set<SubtitleSize> newSelection) {
                              AppState.instance.setSubtitleSize(newSelection.first);
                            },
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                                (states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return colors.accentPrimary;
                                  }
                                  return colors.bgSecondary;
                                },
                              ),
                              foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                                (states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.white;
                                  }
                                  return colors.textSecondary;
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // SECTION 3: Dictionary & Translation
              _buildSectionHeader(context, context.t('nav.dictionary').toUpperCase(), colors),
              Material(
                color: colors.bgCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colors.borderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Native Language
                    ListTile(
                      leading: Icon(Icons.menu_book_rounded, color: colors.accentSecondary),
                      title: Text(
                        context.t('settings.nativeLanguage'),
                        style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        context.t('settings.nativeLanguageDesc'),
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                      trailing: DropdownButton<String>(
                        value: settings.nativeLanguage,
                        dropdownColor: colors.bgCard,
                        underline: const SizedBox.shrink(),
                        icon: Icon(Icons.arrow_drop_down, color: colors.textSecondary),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('🇺🇸 English')),
                          DropdownMenuItem(value: 'vi', child: Text('🇻🇳 Tiếng Việt')),
                          DropdownMenuItem(value: 'zh', child: Text('🇨🇳 中文')),
                          DropdownMenuItem(value: 'ja', child: Text('🇯🇵 日本語')),
                          DropdownMenuItem(value: 'ko', child: Text('🇰🇷 한국어')),
                        ],
                        onChanged: (lang) {
                          if (lang != null) {
                            AppState.instance.setNativeLanguage(lang);
                          }
                        },
                      ),
                    ),

                    Divider(color: colors.borderColorLight, height: 1),

                    // Auto-pause toggle
                    SwitchListTile(
                      activeColor: colors.accentPrimary,
                      secondary: Icon(Icons.pause_circle_outline_rounded, color: colors.accentPrimary),
                      title: Text(
                        context.t('settings.autoPause'),
                        style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        context.t('settings.autoPauseDesc'),
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                      value: settings.autoPauseOnLookup,
                      onChanged: (val) {
                        AppState.instance.setAutoPauseOnLookup(val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // SECTION 4: Application Info
              _buildSectionHeader(context, context.t('settings.system').toUpperCase(), colors),
              Material(
                color: colors.bgCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colors.borderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.info_outline_rounded, color: colors.textSecondary),
                      title: Text(
                        context.t('settings.version'),
                        style: TextStyle(color: colors.textPrimary, fontSize: 15),
                      ),
                      trailing: Text(
                        '1.0.0 (Build 1)',
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      ),
                    ),
                    Divider(color: colors.borderColorLight, height: 1),
                    ListTile(
                      leading: Icon(Icons.cloud_done_rounded, color: colors.textSecondary),
                      title: Text(
                        context.t('settings.architecture', null, 'Architecture'),
                        style: TextStyle(color: colors.textPrimary, fontSize: 15),
                      ),
                      trailing: Text(
                        context.t('settings.archDesc', null, 'Edge + Supabase'),
                        style: TextStyle(color: colors.colorDiamond, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VocaColorPalette colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
