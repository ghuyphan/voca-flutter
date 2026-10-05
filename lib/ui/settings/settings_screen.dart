// lib/ui/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/audio_service.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../services/video_level_service.dart';
import '../../state/app_state.dart';
import '../auth/auth_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../sheets/voca_bottom_sheet.dart';
import '../widgets/kikyou_logo.dart';
import '../widgets/voca_confirm_dialog.dart';
import '../widgets/voca_option_picker.dart';
import '../widgets/voca_switch.dart';

/// Rebuilt SettingsScreen conforming strictly to native Inset Grouped layout.
/// Features 6 modular sections: Account, Learning & Reading Guides, Video Player,
/// Appearance, Safe Data & Cache pruning, and About & Support.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: canPop
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
                tooltip: context.t('common.back', null, 'Back'),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          context.t('settings.title', null, 'Settings'),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
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
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              // SECTION 1: ACCOUNT & PROFILE
              _buildSectionHeader(
                context.t('profile.title', null, 'Account & Profile'),
                colors,
              ),
              _buildAccountCard(context, colors, currentUser, userProfile),

              // SECTION 2: LEARNING & READING GUIDES
              _buildSectionHeader(
                context.t('settings.learningSection', null, 'Learning & Reading Guides'),
                colors,
              ),
              _buildLearningGuidesGroup(context, colors, settings, targetLang),

              // SECTION 3: VIDEO PLAYER & SUBTITLES
              _buildSectionHeader(
                context.t('settings.playerSubtitles', null, 'Video Player & Subtitles'),
                colors,
              ),
              _buildPlayerSubtitlesGroup(context, colors, settings),

              // SECTION 4: APPEARANCE & INTERFACE
              _buildSectionHeader(
                context.t('settings.appearanceInterface', null, 'Appearance & Interface'),
                colors,
              ),
              _buildAppearanceGroup(context, colors, isDarkMode),

              // SECTION 5: DATA & STORAGE
              _buildSectionHeader(
                context.t('settings.dataStorage', null, 'Data & Storage'),
                colors,
              ),
              _buildDataCacheGroup(context, colors),

              // SECTION 6: ABOUT & SUPPORT
              _buildSectionHeader(
                context.t('settings.aboutSupport', null, 'About & Support'),
                colors,
              ),
              _buildAboutGroup(context, colors),

              const SizedBox(height: 28),

              // Branded App Footer
              _buildAppFooter(colors),
            ],
          );
        }),
      ),
    );
  }

  // ===========================================================================
  // SECTION 1: ACCOUNT & PROFILE
  // ===========================================================================

  Widget _buildAccountCard(
    BuildContext context,
    VocaColorPalette colors,
    dynamic currentUser,
    UserProfile? profile,
  ) {
    final isAuthenticated = currentUser != null;

    if (!isAuthenticated) {
      // Guest Mode: Prominent Kikyou card encouraging sign in
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(colors.isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.accentPrimarySoft,
                    border: Border.all(
                      color: colors.accentPrimary.withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: KikyouLogo(size: 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('settings.signInVoca', null, 'Sign In to Voca'),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.t('settings.signInVocaHint', null, 'Sync across devices & keep your streak safe'),
                        style: TextStyle(
                          color: colors.textSecondary,
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
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.t('settings.signInRegister', null, 'Sign In / Register'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Logged In User: Inset Grouped profile row + Sign Out action
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

    return _buildGroupContainer(
      colors: colors,
      children: [
        // Profile Info Row (Tap pushes EditProfileScreen)
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    VocaAvatarWidget(
                      avatarUrl: avatarUrl,
                      size: 52,
                      border: Border.all(color: colors.accentPrimary, width: 2),
                    ),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.accentPrimary,
                        border: Border.all(color: colors.bgCard, width: 1.5),
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (countryCode != null && countryCode.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            VocaFlagWidget(countryCode: countryCode, size: 15),
                          ],
                          const SizedBox(width: 8),
                          _buildTierBadge(tier, isPro: isPro, isFounder: isFounder, colors: colors),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: TextStyle(
                          color: colors.textSecondary,
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

        _buildDivider(colors),

        // Sign Out Action Tile
        _buildActionTile(
          context: context,
          icon: Icons.logout_rounded,
          iconColor: colors.error,
          title: context.t('profile.signOut', null, 'Sign Out'),
          titleColor: colors.error,
          colors: colors,
          showChevron: false,
          onTap: () => _handleSignOut(context),
        ),
      ],
    );
  }

  Widget _buildTierBadge(
    String tier, {
    required bool isPro,
    required bool isFounder,
    required VocaColorPalette colors,
  }) {
    Color badgeBg = colors.bgSurface;
    Color badgeBorder = colors.borderColorLight;
    Color badgeText = colors.textMuted;

    if (isFounder) {
      badgeBg = colors.accentTertiary.withOpacity(0.16);
      badgeBorder = colors.accentTertiary.withOpacity(0.35);
      badgeText = colors.accentTertiary;
    } else if (isPro) {
      badgeBg = colors.accentSecondarySoft;
      badgeBorder = colors.accentSecondary.withOpacity(0.35);
      badgeText = colors.accentSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeBorder),
      ),
      child: Text(
        tier,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: badgeText,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showVocaConfirmDialog(
      context: context,
      title: context.t('profile.signOut', null, 'Sign Out'),
      message: context.t(
        'profile.signOutConfirm',
        null,
        'Are you sure you want to sign out? Your offline progress will remain saved on this device.',
      ),
      confirmText: context.t('profile.signOut', null, 'Sign Out'),
      variant: ConfirmDialogVariant.danger,
    );

    if (confirmed == true) {
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
  // SECTION 2: LEARNING & READING GUIDES
  // ===========================================================================

  Widget _buildLearningGuidesGroup(
    BuildContext context,
    VocaColorPalette colors,
    UserSettings settings,
    String targetLang,
  ) {
    final langFlag = _getLanguageCountryCode(targetLang);
    final langName = _getLanguageDisplayName(targetLang);

    // Dynamic Reading Guide Label based on active learning language
    final String readingGuideTitle;
    final String readingGuideDesc;
    switch (targetLang) {
      case 'ja':
        readingGuideTitle = context.t('settings.furiganaRuby', null, 'Furigana & Ruby');
        readingGuideDesc = 'Japanese phonetic furigana annotations';
        break;
      case 'zh':
        readingGuideTitle = context.t('settings.pinyinGuides', null, 'Pinyin Guides');
        readingGuideDesc = 'Chinese pinyin with tone mark guides';
        break;
      case 'ko':
        readingGuideTitle = context.t('settings.romajiGuides', null, 'Romaji Guides');
        readingGuideDesc = 'Korean latin romanization guides';
        break;
      case 'en':
      default:
        readingGuideTitle = context.t('settings.phonetics', null, 'Pronunciation Guides');
        readingGuideDesc = 'IPA phonetics and stress mark guides';
        break;
    }

    final readingModeLabel = _getRubyModeLabel(context, settings.rubyMode);
    final nativeLangCode = settings.nativeLanguage;
    final nativeLangName = _getLanguageDisplayName(nativeLangCode);
    final nativeLangFlag = _getLanguageCountryCode(nativeLangCode);

    return _buildGroupContainer(
      colors: colors,
      children: [
        // 1. Target Learning Language
        _buildActionTile(
          context: context,
          leadingWidget: VocaFlagWidget(countryCode: langFlag, size: 22),
          title: context.t('settings.learningLanguage', null, 'Learning Language'),
          value: langName,
          colors: colors,
          onTap: () => _pickLearningLanguage(context, targetLang),
        ),

        _buildDivider(colors),

        // 2. Dynamic Reading Guides (Furigana / Pinyin / Romaji)
        _buildActionTile(
          context: context,
          icon: Icons.subtitles_rounded,
          iconColor: colors.colorGrammar,
          title: readingGuideTitle,
          subtitle: readingGuideDesc,
          value: readingModeLabel,
          colors: colors,
          onTap: () => _pickRubyMode(context, settings.rubyMode, readingGuideTitle),
        ),

        _buildDivider(colors),

        // 3. Native / Subtitle Target Translation Language
        _buildActionTile(
          context: context,
          leadingWidget: VocaFlagWidget(countryCode: nativeLangFlag, size: 22),
          title: context.t('popup.translationLang', null, 'Translation Language'),
          subtitle: 'Dual subtitles and dictionary target definitions',
          value: nativeLangName,
          colors: colors,
          onTap: () => _pickNativeLanguage(context, nativeLangCode),
        ),

        _buildDivider(colors),

        // 4. Replay Onboarding Wizard (Hunter Prologue)
        _buildActionTile(
          context: context,
          icon: Icons.auto_awesome_rounded,
          iconColor: colors.accentPrimary,
          title: context.t('onboarding.replayTour', null, 'Replay Hunter Prologue'),
          subtitle: context.t('onboarding.replayTourDesc', null, 'Calibrate language, level, and companion guide'),
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
    );
  }

  Future<void> _pickLearningLanguage(BuildContext context, String currentLang) async {
    final selected = await showVocaOptionPicker(
      context: context,
      title: context.t('settings.learningLanguage', null, 'Learning Language'),
      selectedValue: currentLang,
      options: const [
        OptionItem(
          value: 'ja',
          label: '日本語',
          example: 'Japanese',
          leading: VocaFlagWidget(countryCode: 'jp', size: 22),
        ),
        OptionItem(
          value: 'zh',
          label: '中文',
          example: 'Chinese (Mandarin)',
          leading: VocaFlagWidget(countryCode: 'cn', size: 22),
        ),
        OptionItem(
          value: 'ko',
          label: '한국어',
          example: 'Korean',
          leading: VocaFlagWidget(countryCode: 'kr', size: 22),
        ),
        OptionItem(
          value: 'en',
          label: 'English',
          example: 'English',
          leading: VocaFlagWidget(countryCode: 'us', size: 22),
        ),
      ],
    );

    if (selected != null) {
      AppState.instance.setLanguage(selected);
    }
  }

  Future<void> _pickRubyMode(
    BuildContext context,
    RubyDisplayMode currentMode,
    String title,
  ) async {
    final selected = await showVocaOptionPicker(
      context: context,
      title: title,
      selectedValue: currentMode.name,
      options: [
        OptionItem(
          value: RubyDisplayMode.always.name,
          label: context.t('settings.alwaysShow', null, 'Always Show'),
          example: 'Display reading annotations above all words',
          iconData: Icons.visibility_rounded,
        ),
        OptionItem(
          value: RubyDisplayMode.tap.name,
          label: context.t('settings.onTapOnly', null, 'On Tap Only'),
          example: 'Reveal pronunciation when tapping a word',
          iconData: Icons.touch_app_rounded,
        ),
        OptionItem(
          value: RubyDisplayMode.never.name,
          label: context.t('settings.off', null, 'Off'),
          example: 'Hide all phonetic guides for full immersion',
          iconData: Icons.visibility_off_rounded,
        ),
      ],
    );

    if (selected != null) {
      final mode = RubyDisplayMode.values.firstWhere(
        (e) => e.name == selected,
        orElse: () => RubyDisplayMode.always,
      );
      AppState.instance.setRubyMode(mode);
    }
  }

  Future<void> _pickNativeLanguage(BuildContext context, String currentLang) async {
    final selected = await showVocaOptionPicker(
      context: context,
      title: context.t('settings.nativeLanguage', null, 'Translation Language'),
      selectedValue: currentLang,
      options: const [
        OptionItem(
          value: 'en',
          label: 'English',
          example: 'English',
          leading: VocaFlagWidget(countryCode: 'us', size: 22),
        ),
        OptionItem(
          value: 'vi',
          label: 'Tiếng Việt',
          example: 'Vietnamese',
          leading: VocaFlagWidget(countryCode: 'vn', size: 22),
        ),
        OptionItem(
          value: 'zh',
          label: '中文',
          example: 'Chinese',
          leading: VocaFlagWidget(countryCode: 'cn', size: 22),
        ),
        OptionItem(
          value: 'ja',
          label: '日本語',
          example: 'Japanese',
          leading: VocaFlagWidget(countryCode: 'jp', size: 22),
        ),
        OptionItem(
          value: 'ko',
          label: '한국어',
          example: 'Korean',
          leading: VocaFlagWidget(countryCode: 'kr', size: 22),
        ),
      ],
    );

    if (selected != null) {
      AppState.instance.setNativeLanguage(selected);
    }
  }

  // ===========================================================================
  // SECTION 3: VIDEO PLAYER & SUBTITLES
  // ===========================================================================

  Widget _buildPlayerSubtitlesGroup(
    BuildContext context,
    VocaColorPalette colors,
    UserSettings settings,
  ) {
    final sizeLabel = _getSubtitleSizeLabel(context, settings.subtitleSize);

    return _buildGroupContainer(
      colors: colors,
      children: [
        // 1. Dual Subtitles Default Toggle (VocaSwitch)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: VocaSwitch(
            value: settings.showDualSubtitles,
            leading: _buildIconBox(Icons.subtitles_outlined, colors.accentPrimary, colors),
            label: context.t('settings.dualSubtitles', null, 'Dual Subtitles'),
            subtitle: context.t(
              'settings.dualSubtitlesDesc',
              null,
              'Show translation alongside original subtitles',
            ),
            onChanged: (val) {
              AppState.instance.updateUserSettings(settings.copyWith(showDualSubtitles: val));
            },
          ),
        ),

        _buildDivider(colors),

        // 2. Subtitle Font Size Selector
        _buildActionTile(
          context: context,
          icon: Icons.format_size_rounded,
          iconColor: colors.accentSecondary,
          title: context.t('settings.subtitleFontSize', null, 'Subtitle Font Size'),
          subtitle: context.t('settings.subtitleSizeDesc', null, 'Adjust text size on video player'),
          value: sizeLabel,
          colors: colors,
          onTap: () => _pickSubtitleSize(context, settings.subtitleSize),
        ),

        _buildDivider(colors),

        // 3. Auto-Pause on Dictionary Lookup Toggle (VocaSwitch)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: VocaSwitch(
            value: settings.autoPauseOnLookup,
            leading: _buildIconBox(Icons.pause_circle_outline_rounded, colors.colorDiamond, colors),
            label: context.t('settings.autoPauseOnLookup', null, 'Auto-pause on Lookup'),
            subtitle: context.t(
              'settings.autoPauseDesc',
              null,
              'Pause video automatically when tapping words',
            ),
            onChanged: (val) {
              AppState.instance.setAutoPauseOnLookup(val);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _pickSubtitleSize(BuildContext context, SubtitleSize currentSize) async {
    final selected = await showVocaOptionPicker(
      context: context,
      title: context.t('settings.subtitleSize', null, 'Subtitle Font Size'),
      selectedValue: currentSize.name,
      options: [
        OptionItem(
          value: SubtitleSize.small.name,
          label: context.t('settings.sizeSmall', null, 'Small'),
          example: '14px compact captions',
          iconData: Icons.text_fields_rounded,
        ),
        OptionItem(
          value: SubtitleSize.medium.name,
          label: context.t('settings.sizeMedium', null, 'Medium'),
          example: '16px standard readability (recommended)',
          iconData: Icons.text_fields_rounded,
        ),
        OptionItem(
          value: SubtitleSize.large.name,
          label: context.t('settings.sizeLarge', null, 'Large'),
          example: '19px prominent captions',
          iconData: Icons.text_fields_rounded,
        ),
      ],
    );

    if (selected != null) {
      final size = SubtitleSize.values.firstWhere(
        (e) => e.name == selected,
        orElse: () => SubtitleSize.medium,
      );
      AppState.instance.setSubtitleSize(size);
    }
  }

  // ===========================================================================
  // SECTION 4: APPEARANCE & INTERFACE
  // ===========================================================================

  Widget _buildAppearanceGroup(
    BuildContext context,
    VocaColorPalette colors,
    bool isDarkMode,
  ) {
    final i18n = I18nService.instance;
    final currentUILang = i18n.currentLanguageInfo;

    return _buildGroupContainer(
      colors: colors,
      children: [
        // 1. Dark Mode Toggle (Moon / Sun with VocaSwitch)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: VocaSwitch(
            value: isDarkMode,
            leading: _buildIconBox(
              isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              isDarkMode ? colors.accentSecondary : colors.accentTertiary,
              colors,
            ),
            label: context.t('settings.darkMode', null, 'Dark Mode'),
            subtitle: context.t(
              'settings.darkModeDesc',
              null,
              'Toggle between Rich Obsidian and Crisp Porcelain',
            ),
            onChanged: (val) {
              AppState.instance.setThemeMode(val ? 'dark' : 'light');
            },
          ),
        ),

        _buildDivider(colors),

        // 2. App Interface Language Picker
        _buildActionTile(
          context: context,
          icon: Icons.language_rounded,
          iconColor: colors.accentPrimary,
          title: context.t('settings.appInterfaceLanguage', null, 'App Interface Language'),
          subtitle: 'UI buttons, dialogs, and navigation texts',
          value: '${currentUILang.flag} ${currentUILang.nativeName}',
          colors: colors,
          onTap: () => _pickUILanguage(context),
        ),
      ],
    );
  }

  Future<void> _pickUILanguage(BuildContext context) async {
    final i18n = I18nService.instance;
    final selected = await showVocaOptionPicker(
      context: context,
      title: context.t('settings.appInterfaceLanguage', null, 'App Interface Language'),
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
  }

  // ===========================================================================
  // SECTION 5: DATA & CACHE PRUNING
  // ===========================================================================

  Widget _buildDataCacheGroup(BuildContext context, VocaColorPalette colors) {
    return _buildGroupContainer(
      colors: colors,
      children: [
        _buildActionTile(
          context: context,
          icon: Icons.cleaning_services_rounded,
          iconColor: colors.colorFire,
          title: context.t('settings.clearCache', null, 'Clear Subtitle & Dict Cache'),
          subtitle: context.t(
            'settings.clearCacheDesc',
            null,
            'Free temporary subtitles & dictionary cache safely',
          ),
          colors: colors,
          onTap: () => _handleClearCache(context),
        ),
      ],
    );
  }

  Future<void> _handleClearCache(BuildContext context) async {
    final confirmed = await showVocaConfirmDialog(
      context: context,
      title: context.t('settings.clearCache', null, 'Clear Subtitle & Dict Cache'),
      message: context.t(
        'settings.clearCacheConfirm',
        null,
        'This will prune temporary subtitles and dictionary queries. Your saved vocabulary, study decks, and watch history will NEVER be affected.',
      ),
      confirmText: context.t('common.clear', null, 'Clear Cache'),
      variant: ConfirmDialogVariant.danger,
    );

    if (confirmed == true) {
      try {
        // 1. Clear in-memory service caches
        AudioService.instance.clearCache();
        VideoLevelService.instance.clearCache();

        // 2. Prune only temporary cache keys from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys().where(
          (k) => k.startsWith('cache_') || k.startsWith('voca_sub_') || k.startsWith('voca_dict_'),
        ).toList();
        for (final k in keys) {
          await prefs.remove(k);
        }

        if (context.mounted) {
          ToastService.show(
            context,
            context.t('settings.cacheCleared', null, 'Subtitle & dictionary cache cleared safely.'),
            type: ToastType.success,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ToastService.show(context, 'Cache clear error: $e', type: ToastType.error);
        }
      }
    }
  }

  // ===========================================================================
  // SECTION 6: ABOUT & SUPPORT
  // ===========================================================================

  Widget _buildAboutGroup(BuildContext context, VocaColorPalette colors) {
    return _buildGroupContainer(
      colors: colors,
      children: [
        // App Version
        _buildActionTile(
          context: context,
          icon: Icons.info_outline_rounded,
          iconColor: colors.textSecondary,
          title: context.t('settings.appVersionLabel', null, 'Version'),
          value: '1.0.0+1 (Voca Mobile)',
          showChevron: false,
          colors: colors,
        ),

        _buildDivider(colors),

        // What's New Release Notes Dialog
        _buildActionTile(
          context: context,
          icon: Icons.star_outline_rounded,
          iconColor: colors.accentTertiary,
          title: context.t('settings.whatsNew', null, "What's New"),
          subtitle: 'Recent updates & feature highlights',
          colors: colors,
          onTap: () => _showWhatsNewDialog(context),
        ),

        _buildDivider(colors),

        // Community & Discord
        _buildActionTile(
          context: context,
          icon: Icons.chat_bubble_outline_rounded,
          iconColor: colors.accentSecondary,
          title: 'Discord Community & Feedback',
          subtitle: 'Connect with language learners & team',
          trailingWidget: Icon(Icons.open_in_new_rounded, size: 16, color: colors.textMuted),
          colors: colors,
          onTap: () => _openExternalUrl('https://discord.gg/voca'),
        ),

        _buildDivider(colors),

        // Privacy Policy
        _buildActionTile(
          context: context,
          icon: Icons.privacy_tip_outlined,
          iconColor: colors.textSecondary,
          title: 'Privacy Policy',
          trailingWidget: Icon(Icons.open_in_new_rounded, size: 16, color: colors.textMuted),
          colors: colors,
          onTap: () => _openExternalUrl('https://voca.study/privacy'),
        ),

        _buildDivider(colors),

        // Terms of Service
        _buildActionTile(
          context: context,
          icon: Icons.description_outlined,
          iconColor: colors.textSecondary,
          title: 'Terms of Service',
          trailingWidget: Icon(Icons.open_in_new_rounded, size: 16, color: colors.textMuted),
          colors: colors,
          onTap: () => _openExternalUrl('https://voca.study/terms'),
        ),
      ],
    );
  }

  void _showWhatsNewDialog(BuildContext context) {
    final colors = context.vocaColors;

    showVocaBottomSheet(
      context: context,
      title: context.t('settings.whatsNew', null, "What's New"),
      subtitle: 'Version 1.0.0+1 (Voca Mobile)',
      builder: (ctx) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReleaseHighlight(
                icon: Icons.bolt_rounded,
                iconColor: colors.accentTertiary,
                title: 'Buttery-Smooth Playback',
                description:
                    'Video controls and transcript scrolling are now noticeably faster, lighter on your battery, and run at a steady 60 frames per second.',
                colors: colors,
              ),
              const SizedBox(height: 16),
              _buildReleaseHighlight(
                icon: Icons.cloud_done_rounded,
                iconColor: colors.colorDiamond,
                title: 'Rock-Solid Cloud Sync',
                description:
                    'Study anywhere with complete peace of mind. Saved vocabulary, SM-2 flashcard progress, and watch history synchronize seamlessly between offline and online.',
                colors: colors,
              ),
              const SizedBox(height: 16),
              _buildReleaseHighlight(
                icon: Icons.tune_rounded,
                iconColor: colors.accentPrimary,
                title: 'Native Inset Preferences & Avatars',
                description:
                    'Clean grouped settings, 16 companion character presets, and regional flags representing your country on global leaderboards.',
                colors: colors,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.t('common.done', null, 'Got it!'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReleaseHighlight({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required VocaColorPalette colors,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.14),
            borderRadius: BorderRadius.circular(10),
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
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
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
    );
  }

  Future<void> _openExternalUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  // ===========================================================================
  // REUSABLE INSET GROUPED CONTAINERS & TILES
  // ===========================================================================

  Widget _buildSectionHeader(String title, VocaColorPalette colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 22, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colors.textMuted,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildGroupContainer({
    required List<Widget> children,
    required VocaColorPalette colors,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildDivider(VocaColorPalette colors) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 58,
      endIndent: 0,
      color: colors.borderColorLight,
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    IconData? icon,
    Color? iconColor,
    Widget? leadingWidget,
    required String title,
    String? subtitle,
    String? value,
    Color? titleColor,
    Widget? trailingWidget,
    bool showChevron = true,
    required VocaColorPalette colors,
    VoidCallback? onTap,
  }) {
    final leading = leadingWidget ??
        (icon != null
            ? _buildIconBox(icon, iconColor ?? colors.textSecondary, colors)
            : null);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            if (leading != null) ...[
              leading,
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor ?? colors.textPrimary,
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
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (trailingWidget != null) ...[
              const SizedBox(width: 8),
              trailingWidget,
            ] else if (showChevron) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textMuted,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIconBox(IconData icon, Color iconColor, VocaColorPalette colors) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderColorLight),
      ),
      child: Icon(icon, color: iconColor, size: 18),
    );
  }

  Widget _buildAppFooter(VocaColorPalette colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const KikyouLogo(size: 16),
              const SizedBox(width: 8),
              Text(
                'VOCA Mobile',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'YouTube Language Immersion • 1.0.0+1',
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 11,
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
    switch (code) {
      case 'ja':
        return 'jp';
      case 'zh':
        return 'cn';
      case 'ko':
        return 'kr';
      case 'en':
        return 'us';
      case 'vi':
        return 'vn';
      default:
        return code.toLowerCase();
    }
  }

  static String _getRubyModeLabel(BuildContext context, RubyDisplayMode mode) {
    switch (mode) {
      case RubyDisplayMode.always:
        return context.t('settings.alwaysShow', null, 'Always');
      case RubyDisplayMode.tap:
        return context.t('settings.onTapOnly', null, 'On Tap');
      case RubyDisplayMode.never:
        return context.t('settings.off', null, 'Off');
    }
  }

  static String _getSubtitleSizeLabel(BuildContext context, SubtitleSize size) {
    switch (size) {
      case SubtitleSize.small:
        return context.t('settings.sizeSmall', null, 'Small');
      case SubtitleSize.medium:
        return context.t('settings.sizeMedium', null, 'Medium');
      case SubtitleSize.large:
        return context.t('settings.sizeLarge', null, 'Large');
    }
  }
}
