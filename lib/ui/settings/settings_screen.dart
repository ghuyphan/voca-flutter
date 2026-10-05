// lib/ui/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../library/library_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../profile/profile_screen.dart';
import '../sheets/gamification_dialogs.dart';
import '../widgets/voca_confirm_dialog.dart';
import '../widgets/voca_option_picker.dart';

/// Unified Settings & Personal Hub Screen for Voca.
/// Fully conforms to Material 3 design standards with grouped surface cards,
/// seamless Dark/Light theming, zero duplicate preferences, and an immersive
/// headerless layout aligned with the explore & video screens.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final i18n = I18nService.instance;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: Watch((context) {
          final settings = AppState.instance.userSettings.value;
          final currentUILang = i18n.currentLanguageInfo;
          final targetLang = AppState.instance.activeLanguage.value;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Adaptive back button if pushed as a sub-route (hidden on bottom nav tab)
              if (canPop)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
                      tooltip: context.t('common.back', null, 'Back'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),

              // 1. User Profile & Account Banner
              _buildProfileCard(context, colors),

              const SizedBox(height: 14),

              // 2. Daily Motivation & Stats Bar (Streak, Level, AI Credits)
              _buildGamificationHero(context, colors),

              const SizedBox(height: 22),

              // 3. My Library (Playlists, History, Achievements)
              _buildSectionHeader(
                context,
                context.t('nav.library', null, 'LIBRARY').toUpperCase(),
                colors,
              ),
              _buildGroupContainer(
                colors: colors,
                children: [
                  _buildActionTile(
                    context: context,
                    icon: Icons.playlist_play_rounded,
                    iconColor: const Color(0xFF38BDF8),
                    title: context.t('nav.playlists', null, 'Playlists'),
                    subtitle: context.t('explore.collections', null, 'Organized study collections'),
                    colors: colors,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LibraryScreen(initialTabIndex: 1),
                        ),
                      );
                    },
                  ),
                  _buildDivider(colors),
                  _buildActionTile(
                    context: context,
                    icon: Icons.history_rounded,
                    iconColor: const Color(0xFFA78BFA),
                    title: context.t('history.title', null, 'History'),
                    subtitle: context.t('history.subtitle', null, 'Recently watched lessons'),
                    colors: colors,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LibraryScreen(initialTabIndex: 0),
                        ),
                      );
                    },
                  ),
                  _buildDivider(colors),
                  _buildActionTile(
                    context: context,
                    icon: Icons.emoji_events_rounded,
                    iconColor: const Color(0xFFFBBF24),
                    title: context.t('gamification.achievements', null, 'Achievements & Badges'),
                    subtitle: context.t('gamification.xpProgress', null, 'Track learning milestones'),
                    colors: colors,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                  ),
                  _buildDivider(colors),
                  _buildActionTile(
                    context: context,
                    icon: Icons.explore_rounded,
                    iconColor: colors.accentPrimary,
                    title: context.t('onboarding.guildCharter', null, 'Guild Charter & Onboarding'),
                    subtitle: context.t('onboarding.pactSubtitle', null, 'Replay learning wizard & companion setup'),
                    colors: colors,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OnboardingScreen(
                            isReplay: true,
                            onFinish: () => Navigator.of(context).pop(),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // 4. Appearance & Theme (Material 3 Segmented Control)
              _buildSectionHeader(
                context,
                context.t('settings.theme', null, 'APPEARANCE').toUpperCase(),
                colors,
              ),
              _buildGroupContainer(
                colors: colors,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colors.bgSecondary,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: colors.borderColorLight),
                              ),
                              child: Icon(Icons.palette_outlined, color: colors.accentPrimary, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.t('settings.theme', null, 'Theme Mode'),
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    context.t('settings.themeDesc', null, 'Choose your preferred visual style'),
                                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<String>(
                            segments: [
                              ButtonSegment(
                                value: 'system',
                                icon: const Icon(Icons.brightness_auto_rounded, size: 16),
                                label: Text(context.t('settings.themeSystem', null, 'System')),
                              ),
                              ButtonSegment(
                                value: 'light',
                                icon: const Icon(Icons.light_mode_rounded, size: 16),
                                label: Text(context.t('settings.themeLight', null, 'Light')),
                              ),
                              ButtonSegment(
                                value: 'dark',
                                icon: const Icon(Icons.dark_mode_rounded, size: 16),
                                label: Text(context.t('settings.themeDark', null, 'Dark')),
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // 5. Languages & Regional Section
              _buildSectionHeader(
                context,
                context.t('settings.languages', null, 'LANGUAGES').toUpperCase(),
                colors,
              ),
              _buildGroupContainer(
                colors: colors,
                children: [
                  // Target Learning Language
                  _buildActionTile(
                    context: context,
                    icon: Icons.translate_rounded,
                    iconColor: colors.colorGrammar,
                    title: context.t('settings.learningLanguage', null, 'Learning Language'),
                    subtitle: '${_languageFlag(targetLang)} ${_languageName(targetLang)}',
                    colors: colors,
                    onTap: () async {
                      final selected = await showVocaOptionPicker(
                        context: context,
                        title: context.t('settings.learningLanguage', null, 'Learning Language'),
                        selectedValue: targetLang,
                        options: const [
                          OptionItem(value: 'ja', label: '日本語', example: 'Japanese', icon: '🇯🇵'),
                          OptionItem(value: 'zh', label: '中文', example: 'Chinese', icon: '🇨🇳'),
                          OptionItem(value: 'ko', label: '한국어', example: 'Korean', icon: '🇰🇷'),
                          OptionItem(value: 'en', label: 'English', example: 'English', icon: '🇺🇸'),
                        ],
                      );
                      if (selected != null) {
                        AppState.instance.setLanguage(selected);
                      }
                    },
                  ),
                  _buildDivider(colors),

                  // Native / Translation Definition Language
                  _buildActionTile(
                    context: context,
                    icon: Icons.menu_book_rounded,
                    iconColor: colors.accentSecondary,
                    title: context.t('settings.nativeLanguage', null, 'Translation Language'),
                    subtitle: '${_languageFlag(settings.nativeLanguage)} ${_languageName(settings.nativeLanguage)}',
                    colors: colors,
                    onTap: () async {
                      final selected = await showVocaOptionPicker(
                        context: context,
                        title: context.t('settings.nativeLanguage', null, 'Translation Language'),
                        selectedValue: settings.nativeLanguage,
                        options: const [
                          OptionItem(value: 'en', label: 'English', example: 'English', icon: '🇺🇸'),
                          OptionItem(value: 'vi', label: 'Tiếng Việt', example: 'Vietnamese', icon: '🇻🇳'),
                          OptionItem(value: 'zh', label: '中文', example: 'Chinese', icon: '🇨🇳'),
                          OptionItem(value: 'ja', label: '日本語', example: 'Japanese', icon: '🇯🇵'),
                          OptionItem(value: 'ko', label: '한국어', example: 'Korean', icon: '🇰🇷'),
                        ],
                      );
                      if (selected != null) {
                        AppState.instance.setNativeLanguage(selected);
                      }
                    },
                  ),
                  _buildDivider(colors),

                  // App Interface Language (Locale)
                  _buildActionTile(
                    context: context,
                    icon: Icons.language_rounded,
                    iconColor: colors.accentPrimary,
                    title: context.t('settings.uiLanguage', null, 'App Language'),
                    subtitle: '${currentUILang.flag} ${currentUILang.nativeName}',
                    colors: colors,
                    onTap: () async {
                      final selected = await showVocaOptionPicker(
                        context: context,
                        title: context.t('settings.uiLanguage', null, 'App Language'),
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

              const SizedBox(height: 22),

              // 6. Subtitles & Player
              _buildSectionHeader(
                context,
                context.t('settings.subtitles', null, 'SUBTITLES & PLAYER').toUpperCase(),
                colors,
              ),
              _buildGroupContainer(
                colors: colors,
                children: [
                  // Furigana / Ruby Mode
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colors.bgSecondary,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: colors.borderColorLight),
                              ),
                              child: Icon(Icons.subtitles_rounded, color: colors.accentPrimary, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.t('settings.furiganaPinyin', null, 'Furigana & Pinyin'),
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    context.t('settings.readingDisplayDesc', null, 'Pronunciation ruby guides above text'),
                                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<RubyDisplayMode>(
                            segments: [
                              ButtonSegment(
                                value: RubyDisplayMode.always,
                                label: Text(context.t('settings.alwaysShow', null, 'Always')),
                              ),
                              ButtonSegment(
                                value: RubyDisplayMode.tap,
                                label: Text(context.t('settings.onTapOnly', null, 'On Tap')),
                              ),
                              ButtonSegment(
                                value: RubyDisplayMode.never,
                                label: Text(context.t('settings.off', null, 'Off')),
                              ),
                            ],
                            selected: {settings.rubyMode},
                            onSelectionChanged: (newSelection) {
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
                        ),
                      ],
                    ),
                  ),
                  _buildDivider(colors),

                  // Subtitle Font Size
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colors.bgSecondary,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: colors.borderColorLight),
                              ),
                              child: Icon(Icons.format_size_rounded, color: colors.accentSecondary, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.t('settings.subtitleSize', null, 'Subtitle Font Size'),
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    context.t('settings.subtitleSizeDesc', null, 'Adjust text size on video player'),
                                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<SubtitleSize>(
                            segments: [
                              ButtonSegment(
                                value: SubtitleSize.small,
                                label: Text(context.t('settings.sizeSmall', null, 'Small')),
                              ),
                              ButtonSegment(
                                value: SubtitleSize.medium,
                                label: Text(context.t('settings.sizeMedium', null, 'Medium')),
                              ),
                              ButtonSegment(
                                value: SubtitleSize.large,
                                label: Text(context.t('settings.sizeLarge', null, 'Large')),
                              ),
                            ],
                            selected: {settings.subtitleSize},
                            onSelectionChanged: (newSelection) {
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
                        ),
                      ],
                    ),
                  ),
                  _buildDivider(colors),

                  // Auto-Pause on Lookup Switch
                  SwitchListTile(
                    secondary: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.bgSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.borderColorLight),
                      ),
                      child: Icon(Icons.pause_circle_outline_rounded, color: colors.accentPrimary, size: 20),
                    ),
                    title: Text(
                      context.t('settings.autoPause', null, 'Auto-pause on Lookup'),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      context.t('settings.autoPauseDesc', null, 'Pause video automatically when tapping words'),
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                    value: settings.autoPauseOnLookup,
                    onChanged: (val) {
                      AppState.instance.setAutoPauseOnLookup(val);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // 7. Data & Storage
              _buildSectionHeader(
                context,
                context.t('settings.storage', null, 'DATA & STORAGE').toUpperCase(),
                colors,
              ),
              _buildGroupContainer(
                colors: colors,
                children: [
                  _buildActionTile(
                    context: context,
                    icon: Icons.cleaning_services_rounded,
                    iconColor: colors.colorFire,
                    title: context.t('settings.clearCache', null, 'Clear Local Cache'),
                    subtitle: context.t('settings.clearCacheDesc', null, 'Free temporary subtitles & dictionary cache'),
                    colors: colors,
                    onTap: () => _showClearCacheDialog(context),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // 8. Application Information & Settings Section
              _buildSectionHeader(
                context,
                context.t('settings.title', null, 'Settings'),
                colors,
              ),
              _buildGroupContainer(
                colors: colors,
                children: [
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.bgSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.borderColorLight),
                      ),
                      child: Icon(Icons.info_outline_rounded, color: colors.textSecondary, size: 20),
                    ),
                    title: Text(
                      context.t('settings.version', null, 'Version'),
                      style: TextStyle(color: colors.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      '1.2.4 (Build 1)',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  _buildDivider(colors),
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.bgSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.borderColorLight),
                      ),
                      child: Icon(Icons.cloud_done_rounded, color: colors.colorDiamond, size: 20),
                    ),
                    title: Text(
                      context.t('settings.architecture', null, 'Architecture'),
                      style: TextStyle(color: colors.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      'Edge + Supabase',
                      style: TextStyle(color: colors.colorDiamond, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Footer Branding
              Center(
                child: Text(
                  'VOCA Mobile • Learn Languages with YouTube',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
        }),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, VocaColorPalette colors) {
    return Watch((context) {
      final supabase = AppState.instance.supabaseService;
      final currentUser = supabase.currentUser;
      final isAuthenticated = currentUser != null;

      final email = isAuthenticated
          ? (currentUser.email ?? context.t('profile.learner', null, 'Learner'))
          : context.t('profile.guestLearner', null, 'Guest Learner');
      final avatarUrl = isAuthenticated ? (currentUser.userMetadata?['avatar_url'] as String?) : null;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderColor),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: colors.accentPrimarySoft,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Icon(Icons.person_rounded, size: 28, color: colors.accentPrimary)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('profile.title', null, 'Account & Profile'),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAuthenticated ? colors.success : colors.warning,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          isAuthenticated
                              ? context.t('profile.cloudSynced', null, 'Cloud Synced')
                              : context.t('profile.guestMode', null, 'Guest Mode (Local)'),
                          style: TextStyle(
                            color: isAuthenticated ? colors.success : colors.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isAuthenticated)
              OutlinedButton(
                onPressed: () => _showSignOutDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.error,
                  side: BorderSide(color: colors.error.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                child: Text(
                  context.t('profile.signOut', null, 'Sign Out'),
                  style: const TextStyle(fontSize: 12),
                ),
              )
            else
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  context.t('profile.signIn', null, 'Sign In'),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildGamificationHero(BuildContext context, VocaColorPalette colors) {
    return Watch((context) {
      int streak = 0;
      int level = 1;
      int diamonds = 5;
      int maxDiamonds = 5;

      try {
        final gamification = AppState.instance.gamificationService;
        streak = gamification.currentStreak.value;
        level = gamification.level.value;
        diamonds = gamification.diamonds.value;
        maxDiamonds = gamification.maxDiamonds.value;
      } catch (_) {}

      return Row(
        children: [
          // 1. Streak Card
          Expanded(
            child: _buildHeroStatCard(
              context: context,
              icon: '🔥',
              value: '$streak',
              label: context.t('streak.title', null, 'Day Streak'),
              colors: colors,
              onTap: () => showStreakDialog(context),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Level Card
          Expanded(
            child: _buildHeroStatCard(
              context: context,
              icon: '🛡️',
              value: '$level',
              label: context.t('gamification.level', null, 'Level'),
              colors: colors,
              onTap: () => showAchievementsDialog(context),
            ),
          ),
          const SizedBox(width: 8),

          // 3. AI Credits Card
          Expanded(
            child: _buildHeroStatCard(
              context: context,
              icon: '💎',
              value: '$diamonds/$maxDiamonds',
              label: context.t('credits.title', null, 'AI Credits'),
              colors: colors,
              onTap: () => showAiCreditsDialog(context),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildHeroStatCard({
    required BuildContext context,
    required String icon,
    required String value,
    required String label,
    required VocaColorPalette colors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: colors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: colors.accentPrimarySoft,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11,
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

  Widget _buildSectionHeader(BuildContext context, String title, VocaColorPalette colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: colors.textMuted,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildGroupContainer({
    required VocaColorPalette colors,
    required List<Widget> children,
  }) {
    return Material(
      color: colors.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VocaColorPalette colors,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: colors.accentPrimarySoft,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.bgSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.borderColorLight),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
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

  Widget _buildDivider(VocaColorPalette colors) {
    return Divider(
      color: colors.borderColorLight,
      height: 1,
      thickness: 0.8,
      indent: 64,
    );
  }

  Future<void> _showSignOutDialog(BuildContext context) async {
    final confirmed = await showVocaConfirmDialog(
      context: context,
      title: context.t('profile.signOut', null, 'Sign Out'),
      message: context.t('profile.signOutConfirm', null, 'Are you sure you want to sign out from your account?'),
      confirmText: context.t('profile.signOut', null, 'Sign Out'),
      variant: ConfirmDialogVariant.danger,
    );
    if (confirmed == true) {
      await AppState.instance.supabaseService.signOut();
      if (context.mounted) {
        ToastService.show(context, 'Signed out successfully');
      }
    }
  }

  Future<void> _showClearCacheDialog(BuildContext context) async {
    final confirmed = await showVocaConfirmDialog(
      context: context,
      title: context.t('settings.clearCache', null, 'Clear Cache'),
      message: context.t('settings.clearCacheConfirm', null, 'This will clear temporary subtitle caches and cached dictionary queries. Your saved words and history will not be affected.'),
      confirmText: context.t('common.clear', null, 'Clear Cache'),
      variant: ConfirmDialogVariant.danger,
    );
    if (confirmed == true) {
      try {
        await Hive.deleteFromDisk();
      } catch (_) {}
      if (context.mounted) {
        ToastService.show(context, 'Cache cleared successfully');
      }
    }
  }

  static String _languageName(String code) {
    switch (code) {
      case 'ja':
        return 'Japanese';
      case 'zh':
        return 'Chinese';
      case 'ko':
        return 'Korean';
      case 'en':
        return 'English';
      case 'vi':
        return 'Vietnamese';
      default:
        return code.toUpperCase();
    }
  }

  static String _languageFlag(String code) {
    switch (code) {
      case 'ja':
        return '🇯🇵';
      case 'zh':
        return '🇨🇳';
      case 'ko':
        return '🇰🇷';
      case 'en':
        return '🇺🇸';
      case 'vi':
        return '🇻🇳';
      default:
        return '🌐';
    }
  }
}
