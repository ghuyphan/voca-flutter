// lib/ui/sheets/more_sheet.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import '../library/library_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../widgets/circle_flag.dart';
import '../widgets/voca_option_picker.dart';
import 'gamification_dialogs.dart';
import 'voca_bottom_sheet.dart';

/// Authentic More Bottom Sheet matching lingua-tube.
class MoreSheet extends StatelessWidget {
  final VoidCallback? onOpenPlaylists;
  final VoidCallback? onOpenHistory;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenProfile;

  const MoreSheet({
    super.key,
    this.onOpenPlaylists,
    this.onOpenHistory,
    this.onOpenSettings,
    this.onOpenProfile,
  });

  /// Displays the MoreSheet as a native modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onOpenPlaylists,
    VoidCallback? onOpenHistory,
    VoidCallback? onOpenSettings,
    VoidCallback? onOpenProfile,
  }) {
    return showVocaBottomSheet(
      context: context,
      title: context.t('nav.more'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      builder: (ctx) => MoreSheet(
        onOpenPlaylists: onOpenPlaylists,
        onOpenHistory: onOpenHistory,
        onOpenSettings: onOpenSettings,
        onOpenProfile: onOpenProfile,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gamification = AppState.instance.gamificationService;
    final colors = context.vocaColors;
    final i18n = I18nService.instance;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Quick Bar: 3 Interactive Stat Cards
          Watch((context) {
            final streak = gamification.currentStreak.value;
            final level = gamification.level.value;
            final diamonds = gamification.diamonds.value;
            final maxDiamonds = gamification.maxDiamonds.value;

            return Row(
              children: [
                // 1. Streak Card
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    icon: '🔥',
                    value: '$streak',
                    label: context.t('streak.title', null, 'Day Streak'),
                    onTap: () => showStreakDialog(context),
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 8),

                // 2. Level Card
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    icon: '🛡️',
                    value: '$level',
                    label: context.t('gamification.level', null, 'Level'),
                    onTap: () => showAchievementsDialog(context),
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 8),

                // 3. AI Credits Card
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    icon: '💎',
                    value: '$diamonds/$maxDiamonds',
                    label: context.t('credits.title', null, 'AI Credits'),
                    onTap: () => showAiCreditsDialog(context),
                    colors: colors,
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 16),
          Divider(color: colors.borderColorLight, height: 1),
          const SizedBox(height: 8),

          // Action Rows
          _buildActionRow(
            context: context,
            icon: Icons.playlist_play_rounded,
            iconColor: colors.colorDiamond,
            title: context.t('nav.playlists', null, 'Playlists'),
            colors: colors,
            onTap: () {
              Navigator.of(context).pop();
              if (onOpenPlaylists != null) {
                onOpenPlaylists!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LibraryScreen(initialTabIndex: 1),
                  ),
                );
              }
            },
          ),
          _buildActionRow(
            context: context,
            icon: Icons.history_rounded,
            iconColor: colors.accentSecondary,
            title: context.t('history.title', null, 'History'),
            colors: colors,
            onTap: () {
              Navigator.of(context).pop();
              if (onOpenHistory != null) {
                onOpenHistory!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LibraryScreen(initialTabIndex: 0),
                  ),
                );
              }
            },
          ),

          // Theme Quick Switch
          Watch((context) {
            final isDark = context.isDarkMode;
            final settings = AppState.instance.userSettings.value;
            final currentMode = settings.themeMode.toLowerCase();
            final String themeLabel;
            final IconData themeIcon;

            switch (currentMode) {
              case 'light':
                themeLabel = context.t('settings.themeLight');
                themeIcon = Icons.light_mode_rounded;
                break;
              case 'dark':
                themeLabel = context.t('settings.themeDark');
                themeIcon = Icons.dark_mode_rounded;
                break;
              case 'system':
              default:
                themeLabel = context.t('settings.themeSystem');
                themeIcon = Icons.brightness_auto_rounded;
                break;
            }

            final iconColor = isDark ? colors.accentTertiary : colors.accentSecondary;

            return _buildActionRow(
              context: context,
              icon: themeIcon,
              iconColor: iconColor,
              title: '${context.t('settings.theme')}: $themeLabel',
              colors: colors,
              onTap: () async {
                await showVocaOptionPicker(
                  context: context,
                  title: context.t('settings.theme'),
                  selectedValue: currentMode,
                  options: [
                    OptionItem(
                      value: 'system',
                      label: context.t('settings.themeSystem'),
                      example: context.t('settings.themeSystemDesc', null, 'Follow device appearance'),
                      iconData: Icons.brightness_auto_rounded,
                    ),
                    OptionItem(
                      value: 'light',
                      label: context.t('settings.themeLight'),
                      example: context.t('settings.themeLightDesc', null, 'Light theme'),
                      iconData: Icons.light_mode_rounded,
                    ),
                    OptionItem(
                      value: 'dark',
                      label: context.t('settings.themeDark'),
                      example: context.t('settings.themeDarkDesc', null, 'Dark theme'),
                      iconData: Icons.dark_mode_rounded,
                    ),
                  ],
                  onSelect: (selected) {
                    if (selected != currentMode) {
                      AppState.instance.setThemeMode(selected);
                    }
                  },
                );
              },
            );
          }),

          // App Language Quick Switch
          Watch((context) {
            final currentLang = i18n.currentLanguageInfo;

            return _buildActionRow(
              context: context,
              icon: Icons.language_rounded,
              iconColor: colors.accentSecondary,
              title: '${context.t('settings.uiLanguage')}: ${currentLang.nativeName}',
              trailingWidget: CircleFlag(code: currentLang.code, size: 20),
              colors: colors,
              onTap: () async {
                await showVocaOptionPicker(
                  context: context,
                  title: context.t('settings.uiLanguage'),
                  selectedValue: i18n.currentLanguage.value,
                  options: i18n.availableLanguages.map((l) {
                    return OptionItem(
                      value: l.code,
                      label: l.nativeName,
                      example: l.name,
                      leading: CircleFlag(code: l.code, size: 22),
                    );
                  }).toList(),
                  onSelect: (selected) {
                    if (selected != i18n.currentLanguage.value) {
                      AppState.instance.setUiLanguage(selected);
                    }
                  },
                );
              },
            );
          }),

          _buildActionRow(
            context: context,
            icon: Icons.settings_outlined,
            iconColor: colors.textSecondary,
            title: context.t('settings.title'),
            colors: colors,
            onTap: () {
              Navigator.of(context).pop();
              if (onOpenSettings != null) {
                onOpenSettings!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              }
            },
          ),
          _buildActionRow(
            context: context,
            icon: Icons.person_outline_rounded,
            iconColor: colors.accentPrimary,
            title: context.t('profile.title', null, 'Account & Profile'),
            colors: colors,
            onTap: () {
              Navigator.of(context).pop();
              if (onOpenProfile != null) {
                onOpenProfile!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String icon,
    required String value,
    required String label,
    required VoidCallback onTap,
    required VocaColorPalette colors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: colors.bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderColor),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailingWidget,
    required VoidCallback onTap,
    required VocaColorPalette colors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.bgSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.borderColorLight),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailingWidget != null) ...[
                trailingWidget,
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
