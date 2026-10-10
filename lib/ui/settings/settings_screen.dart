// lib/ui/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../auth/auth_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../sheets/voca_bottom_sheet.dart';
import 'offline_translation_screen.dart';
import 'setting_sub_screens.dart';
import '../widgets/kikyou_logo.dart';
import '../widgets/voca_back_button.dart';
import '../widgets/voca_confirm_dialog.dart';

const String kAppVersion = '1.2.4';
const String kBuildDate = '2026-09-30';

/// Material 3 Settings Screen for VOCA Mobile:
/// 1. Account Hero Card (Profile row when logged in, or calm Guest Sync card with Google sign-in)
/// 2. Learning & Display Group (Learning Language, Interface Language, Reading Display, Replay Onboarding)
/// 3. Appearance Group (Dark Mode native M3 switch)
/// 4. About & Updates Group (Version with What's New modal, Live Check for Updates, Discord Community)
/// 5. Sign Out Action (when authenticated) & Simplified Clean Footer
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isCheckingUpdate = false;
  String _updateStatusText = 'v$kAppVersion';

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        leadingWidth: 68,
        leading: canPop
            ? Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: VocaBackButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              )
            : null,
        titleSpacing: 8,
        title: Text(
          context.t('settings.title', null, 'Settings'),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Watch((context) {
              final settings = AppState.instance.userSettings.value;
              final userProfile = AppState.instance.userProfile.value;
              dynamic currentUser;
              try {
                currentUser = AppState.instance.supabaseService.currentUser;
              } catch (_) {}
              final targetLang = AppState.instance.activeLanguage.value;
              final isDarkMode = AppState.instance.isDarkMode;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 8, bottom: 48),
                children: [
                  // 1. TOP ACCOUNT HERO CARD
                  _buildAccountCard(context, colors, currentUser, userProfile),

                  // 2. LEARNING & DISPLAY GROUP
                  _buildSectionHeader(
                    context.t('settings.learningSection', null, 'Learning & Display'),
                    colors,
                  ),
                  _buildLearningDisplayGroup(context, colors, settings, targetLang),

                  // 3. APPEARANCE GROUP
                  _buildSectionHeader(
                    context.t('settings.appearance', null, 'Appearance'),
                    colors,
                  ),
                  _buildAppearanceGroup(context, colors, settings, isDarkMode),

                  // 4. ABOUT & UPDATES GROUP
                  _buildSectionHeader(
                    context.t('settings.about', null, 'About & Updates'),
                    colors,
                  ),
                  _buildAboutGroup(context, colors),

                  // 5. SIGN OUT ACTION (When authenticated)
                  if (currentUser != null) ...[
                    const SizedBox(height: 16),
                    _buildSignOutTile(context, colors),
                  ],

                  const SizedBox(height: 32),

                  // 6. SIMPLIFIED CLEAN FOOTER
                  _buildAppFooter(colors),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. TOP ACCOUNT HERO CARD
  // ===========================================================================

  Widget _buildAccountCard(
    BuildContext context,
    VocaColorPalette colors,
    dynamic currentUser,
    UserProfile? profile,
  ) {
    final isAuthenticated = currentUser != null;

    if (!isAuthenticated) {
      // Guest Mode: Material 3 Outlined Card
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card.outlined(
          color: colors.bgCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.accentPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(Icons.cloud_outlined, color: colors.accentPrimary, size: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.t('settings.syncVocab', null, 'Sync vocabulary across devices'),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.t(
                              'settings.syncVocabHint',
                              null,
                              'Sign in to save your flashcards, streak, and history',
                            ),
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12.5,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: colors.bgSurface,
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login_rounded, size: 18, color: colors.accentPrimary),
                        const SizedBox(width: 8),
                        Text(
                          context.t('settings.signInOrRegister', null, 'Log in or Sign up'),
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Logged In: Tappable Material 3 Outlined Profile Card
    final meta = currentUser.userMetadata;
    final displayName = profile?.name ??
        (meta?['name'] ?? meta?['full_name']) as String? ??
        (currentUser.email != null ? currentUser.email!.split('@').first : 'Learner');
    final email = currentUser.email ?? '';
    final avatarUrl = profile?.avatarUrl ?? (meta?['avatar_url'] ?? meta?['picture']) as String?;
    final countryCode = profile?.country;
    final tier = (profile?.subscriptionTier ?? 'free').toUpperCase();
    final isPro = tier == 'PRO';
    final isFounder = tier == 'FOUNDER' || tier == 'PREMIUM';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card.outlined(
        color: colors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    VocaAvatarWidget(
                      avatarUrl: avatarUrl,
                      size: 48,
                      border: Border.all(color: colors.borderColor, width: 1.5),
                    ),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.accentPrimary,
                        border: Border.all(color: colors.bgCard, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (countryCode != null && countryCode.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            VocaFlagWidget(countryCode: countryCode, size: 14),
                          ],
                          const SizedBox(width: 8),
                          _buildTierChip(tier, isPro: isPro, isFounder: isFounder, colors: colors),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 12.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTierChip(
    String tier, {
    required bool isPro,
    required bool isFounder,
    required VocaColorPalette colors,
  }) {
    Color chipBg = colors.bgSurface;
    Color chipBorder = colors.borderColorLight;
    Color chipText = colors.textMuted;

    if (isFounder) {
      chipBg = colors.accentTertiary.withValues(alpha: 0.18);
      chipBorder = colors.accentTertiary.withValues(alpha: 0.4);
      chipText = colors.accentTertiary;
    } else if (isPro) {
      chipBg = colors.accentSecondarySoft;
      chipBorder = colors.accentSecondary.withValues(alpha: 0.4);
      chipText = colors.accentSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: chipBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: chipBorder),
      ),
      child: Text(
        tier,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: chipText,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. LEARNING & DISPLAY GROUP
  // ===========================================================================

  Widget _buildLearningDisplayGroup(
    BuildContext context,
    VocaColorPalette colors,
    UserSettings settings,
    String targetLang,
  ) {
    final langFlag = _getLanguageCountryCode(targetLang);
    final langName = _getLanguageDisplayName(targetLang);

    final i18n = I18nService.instance;
    final currentUILang = i18n.currentLanguageInfo;
    final uiLangCountryCode = _getLanguageCountryCode(currentUILang.code);

    // Dynamic Reading Guide Label based on active learning language
    final String readingGuideTitle;
    switch (targetLang) {
      case 'ja':
        readingGuideTitle = context.t('settings.furiganaAndRuby', null, 'Furigana & Ruby');
        break;
      case 'zh':
        readingGuideTitle = context.t('settings.pinyinGuides', null, 'Pinyin Guides');
        break;
      case 'ko':
        readingGuideTitle = context.t('settings.romajiGuides', null, 'Romaji Guides');
        break;
      case 'en':
      default:
        readingGuideTitle = context.t('settings.phonetics', null, 'Pronunciation Guides');
        break;
    }

    final readingModeLabel = _getRubyModeLabel(context, settings.rubyMode);

    return _buildCardGroup(
      colors: colors,
      children: [
        // 1. Target Learning Language (Circle Flag Leading)
        _buildSettingTile(
          context: context,
          leading: _buildFlagLeading(langFlag, colors),
          title: context.t('settings.learningLanguage', null, 'Learning Language'),
          subtitle: langName,
          colors: colors,
          onTap: () => _pickLearningLanguage(context),
        ),

        _buildDivider(colors),

        // 2. App Interface Language (Circle Flag Leading)
        _buildSettingTile(
          context: context,
          leading: _buildFlagLeading(uiLangCountryCode, colors),
          title: context.t('settings.interfaceLanguage', null, 'Interface Language'),
          subtitle: currentUILang.nativeName,
          colors: colors,
          onTap: () => _pickUILanguage(context),
        ),

        _buildDivider(colors),

        // 3. Reading Display Mode (Furigana / Pinyin / Romaji / Off)
        _buildSettingTile(
          context: context,
          leading: _buildM3IconBox(Icons.subtitles_outlined, colors),
          title: readingGuideTitle,
          subtitle: readingModeLabel,
          colors: colors,
          onTap: () => _pickRubyMode(context),
        ),

        _buildDivider(colors),

        // 4. On-Device Subtitle Translation (Google ML Kit on-device models)
        _buildSettingTile(
          context: context,
          leading: _buildM3IconBox(Icons.download_for_offline_outlined, colors),
          title: context.t('settings.offlineTranslation', null, 'On-Device Translation'),
          subtitle: settings.offlineTranslationEnabled
              ? context.t('settings.onDeviceActive', null, 'On-Device ML Kit Active')
              : context.t('settings.cloudOnly', null, 'Cloud Only'),
          colors: colors,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OfflineTranslationScreen()),
            );
          },
        ),

        _buildDivider(colors),

        // 5. Onboarding & Setup (allows checking/replaying onboarding without clearing app state)
        _buildSettingTile(
          context: context,
          leading: _buildM3IconBox(Icons.explore_outlined, colors),
          title: context.t('settings.replayOnboarding', null, 'Replay Onboarding'),
          subtitle: context.t('settings.replayOnboardingDesc', null, 'Tour & Setup'),
          colors: colors,
          onTap: () => _openOnboarding(context),
        ),
      ],
    );
  }

  void _openOnboarding(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnboardingScreen(
          onFinish: () => Navigator.of(context).pop(),
          isReplay: false,
        ),
      ),
    );
  }

  void _pickLearningLanguage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LearningLanguageSettingsScreen()),
    );
  }

  void _pickRubyMode(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ReadingGuidesSettingsScreen(),
      ),
    );
  }

  void _pickUILanguage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InterfaceLanguageSettingsScreen()),
    );
  }

  // ===========================================================================
  // 3. APPEARANCE GROUP (Theme & Haptic Feedback)
  // ===========================================================================

  Widget _buildAppearanceGroup(
    BuildContext context,
    VocaColorPalette colors,
    UserSettings settings,
    bool isDarkMode,
  ) {
    final currentThemeMode = settings.themeMode.toLowerCase();
    final String themeSubtitle;
    final IconData themeIcon;

    switch (currentThemeMode) {
      case 'light':
        themeSubtitle = context.t('settings.themeLight', null, 'Light');
        themeIcon = Icons.light_mode_outlined;
        break;
      case 'dark':
        themeSubtitle = context.t('settings.themeDark', null, 'Dark');
        themeIcon = Icons.dark_mode_outlined;
        break;
      case 'system':
      default:
        themeSubtitle = context.t('settings.themeSystem', null, 'System');
        themeIcon = Icons.brightness_auto_outlined;
        break;
    }

    final hapticSubtitle = settings.hapticFeedbackEnabled
        ? context.t('settings.on', null, 'On')
        : context.t('settings.off', null, 'Off');

    return _buildCardGroup(
      colors: colors,
      children: [
        _buildSettingTile(
          context: context,
          leading: _buildM3IconBox(
            themeIcon,
            colors,
            iconColor: colors.accentPrimary,
          ),
          title: context.t('settings.theme', null, 'Theme'),
          subtitle: themeSubtitle,
          colors: colors,
          onTap: () => _pickThemeMode(context),
        ),
        _buildDivider(colors),
        _buildSettingTile(
          context: context,
          leading: _buildM3IconBox(Icons.vibration_rounded, colors),
          title: context.t('settings.hapticFeedback', null, 'Haptic Feedback'),
          subtitle: hapticSubtitle,
          colors: colors,
          onTap: () => _openHapticSettings(context),
        ),
      ],
    );
  }

  void _pickThemeMode(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
    );
  }

  void _openHapticSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HapticSettingsScreen()),
    );
  }

  // ===========================================================================
  // 4. ABOUT & UPDATES GROUP (Version, Live Updates, Discord)
  // ===========================================================================

  Widget _buildAboutGroup(BuildContext context, VocaColorPalette colors) {
    return _buildCardGroup(
      colors: colors,
      children: [
        // 1. Version & Release Notes Modal
        _buildSettingTile(
          context: context,
          leading: _buildM3IconBox(Icons.info_outline_rounded, colors),
          title: context.t('settings.appVersion', null, 'Version'),
          subtitle: 'v$kAppVersion',
          trailingWidget: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 13, color: colors.accentPrimary),
                const SizedBox(width: 4),
                Text(
                  context.t('settings.whatsNew', null, "What's New"),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: colors.accentPrimary,
                  ),
                ),
              ],
            ),
          ),
          showChevron: false,
          colors: colors,
          onTap: () => _showWhatsNewDialog(context),
        ),

        _buildDivider(colors),

        // 2. Real Live Check for Updates (Queries Cloudflare API)
        Semantics(
          liveRegion: true,
          child: _buildSettingTile(
            context: context,
            leading: _buildM3IconBox(
              _isCheckingUpdate ? Icons.hourglass_top_rounded : Icons.refresh_rounded,
              colors,
            ),
            title: context.t('settings.checkForUpdates', null, 'Check for Updates'),
            subtitle: _isCheckingUpdate ? context.t('settings.checkingUpdates', null, 'Checking...') : _updateStatusText,
            trailingWidget: _isCheckingUpdate
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.accentPrimary),
                  )
                : null,
            showChevron: false,
            colors: colors,
            onTap: _isCheckingUpdate ? null : _handleCheckForUpdates,
          ),
        ),

        _buildDivider(colors),

        // 3. Discord Community & Feedback
        _buildSettingTile(
          context: context,
          leading: _buildM3IconBox(Icons.forum_outlined, colors),
          title: context.t('settings.discordCommunity', null, 'Discord Community'),
          subtitle: context.t('settings.discordDesc', null, 'Join community & report issues'),
          trailingIcon: Icons.open_in_new_rounded,
          colors: colors,
          onTap: () async {
            final uri = Uri.parse('https://discord.gg/voca');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ],
    );
  }

  Future<void> _handleCheckForUpdates() async {
    setState(() => _isCheckingUpdate = true);
    try {
      final info = await AppState.instance.apiClient.fetchVersionInfo();
      if (!mounted) return;

      final serverVersion = (info?['version'] as String?) ?? kAppVersion;
      setState(() {
        _isCheckingUpdate = false;
        _updateStatusText = context.t('settings.upToDateVersion', {'version': serverVersion}, 'v$serverVersion (Up to date)');
      });

      ToastService.show(
        context,
        context.t('settings.latestVersionToast', {'version': serverVersion}, 'You are running the latest version (v$serverVersion)'),
        type: ToastType.info,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCheckingUpdate = false;
        _updateStatusText = context.t('settings.upToDateVersion', {'version': kAppVersion}, 'v$kAppVersion (Up to date)');
      });
      ToastService.show(
        context,
        context.t('settings.latestVersionToast', {'version': kAppVersion}, 'You are running the latest version (v$kAppVersion)'),
        type: ToastType.info,
      );
    }
  }

  void _showWhatsNewDialog(BuildContext context) {
    final colors = context.vocaColors;
    showVocaBottomSheet(
      context: context,
      title: context.t('settings.whatsNew', null, "What's New"),
      subtitle: '${context.t('settings.appVersion', null, 'Version')} $kAppVersion • $kBuildDate',
      builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReleaseHighlight(
                icon: Icons.bolt_rounded,
                title: context.t('settings.whatsNewSmoothTitle', null, 'Buttery-Smooth Playback'),
                description: context.t(
                  'settings.whatsNewSmoothDesc',
                  null,
                  'Video controls and transcript scrolling run noticeably faster at a steady 60 frames per second.',
                ),
                colors: colors,
              ),
              const SizedBox(height: 12),
              _buildReleaseHighlight(
                icon: Icons.cloud_done_rounded,
                title: context.t('settings.whatsNewSyncTitle', null, 'Rock-Solid Cloud Sync'),
                description: context.t(
                  'settings.whatsNewSyncDesc',
                  null,
                  'Saved vocabulary, flashcard progress, and watch history synchronize seamlessly between offline and online.',
                ),
                colors: colors,
              ),
              const SizedBox(height: 12),
              _buildReleaseHighlight(
                icon: Icons.tune_rounded,
                title: context.t('settings.whatsNewScreensTitle', null, 'Rock-Steady Screens'),
                description: context.t(
                  'settings.whatsNewScreensDesc',
                  null,
                  'Opening settings, level sheets, and word popups is seamless without layout jumping or flickering.',
                ),
                colors: colors,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    context.t('common.done', null, 'Done'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReleaseHighlight({
    required IconData icon,
    required String title,
    required String description,
    required VocaColorPalette colors,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colors.accentPrimary, size: 22),
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
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. SIGN OUT ACTION & DIALOG
  // ===========================================================================

  Widget _buildSignOutTile(BuildContext context, VocaColorPalette colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card.outlined(
        color: colors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: _buildM3IconBox(
            Icons.logout_rounded,
            colors,
            iconColor: colors.error,
            bgColor: colors.error.withValues(alpha: 0.12),
          ),
          title: Text(
            context.t('header.signOut', null, 'Sign Out'),
            style: TextStyle(
              color: colors.error,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            context.t('settings.signOutDesc', null, 'Sign out of your account on this device'),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 13,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          onTap: () => _showSignOutDialog(context, colors),
        ),
      ),
    );
  }

  Future<void> _showSignOutDialog(BuildContext context, VocaColorPalette colors) async {
    final confirmed = await showVocaConfirmDialog(
      context: context,
      title: context.t('settings.signOutConfirmTitle', null, 'Sign Out?'),
      message: context.t(
        'settings.signOutConfirmMessage',
        null,
        "Saved words stay on this device, but won't sync until you sign back in.",
      ),
      confirmText: context.t('header.signOut', null, 'Sign Out'),
      variant: ConfirmDialogVariant.danger,
    );

    if (confirmed == true && context.mounted) {
      await AppState.instance.supabaseService.signOut();
      if (context.mounted) {
        ToastService.show(
          context,
          context.t('auth.signedOut', null, 'Signed out successfully'),
          type: ToastType.info,
        );
      }
    }
  }

  // ===========================================================================
  // REUSABLE M3 ROW TILES & HEADERS
  // ===========================================================================

  Widget _buildSectionHeader(String title, VocaColorPalette colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildCardGroup({
    required List<Widget> children,
    required VocaColorPalette colors,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card.outlined(
        color: colors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  Widget _buildDivider(VocaColorPalette colors) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 70,
      endIndent: 16,
      color: colors.borderColorLight.withValues(alpha: 0.6),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required Widget leading,
    required String title,
    String? subtitle,
    Color? titleColor,
    IconData? trailingIcon,
    Widget? trailingWidget,
    bool showChevron = true,
    required VocaColorPalette colors,
    VoidCallback? onTap,
  }) {
    Widget? trailing;
    if (trailingWidget != null) {
      trailing = trailingWidget;
    } else if (trailingIcon != null) {
      trailing = Icon(trailingIcon, size: 18, color: colors.textMuted);
    } else if (showChevron && onTap != null) {
      trailing = Icon(Icons.chevron_right_rounded, size: 20, color: colors.textMuted);
    }

    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? colors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: (subtitle != null && subtitle.isNotEmpty)
          ? Text(
              subtitle,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      minLeadingWidth: 38,
      onTap: onTap,
    );
  }


  Widget _buildM3IconBox(
    IconData icon,
    VocaColorPalette colors, {
    Color? iconColor,
    Color? bgColor,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bgColor ?? colors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.7)),
      ),
      child: Center(
        child: Icon(icon, size: 20, color: iconColor ?? colors.textSecondary),
      ),
    );
  }

  Widget _buildFlagLeading(String countryCode, VocaColorPalette colors) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.7)),
      ),
      child: Center(
        child: ClipOval(
          child: VocaFlagWidget(countryCode: countryCode, size: 22),
        ),
      ),
    );
  }

  Widget _buildAppFooter(VocaColorPalette colors) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const KikyouLogo(size: 16),
          const SizedBox(width: 8),
          Text(
            'VOCA MOBILE • v$kAppVersion',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  static String _getLanguageDisplayName(String code) {
    switch (code) {
      case 'ja':
        return '日本語 (Japanese)';
      case 'zh':
        return '中文 (Chinese)';
      case 'ko':
        return '한국어 (Korean)';
      case 'en':
        return 'English (English)';
      case 'vi':
        return 'Tiếng Việt (Vietnamese)';
      default:
        return code.toUpperCase();
    }
  }

  static String _getLanguageCountryCode(String code) {
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

  static String _getRubyModeLabel(BuildContext context, RubyDisplayMode mode) {
    switch (mode) {
      case RubyDisplayMode.always:
        return context.t('settings.alwaysShow', null, 'Always Show');
      case RubyDisplayMode.tap:
        return context.t('settings.onTapOnly', null, 'On Tap Only');
      case RubyDisplayMode.never:
        return context.t('settings.off', null, 'Off');
    }
  }
}
