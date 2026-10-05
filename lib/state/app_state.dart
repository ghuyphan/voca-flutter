// lib/state/app_state.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../models/voca_models.dart';
import '../services/voca_api_client.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../services/grammar_engine.dart';
import '../services/gamification_service.dart';
import '../services/i18n_service.dart';

class AppState {
  static final AppState instance = AppState._();
  AppState._();

  late VocaApiClient apiClient;
  late SupabaseService supabaseService;
  AuthService? _authService;
  AuthService get authService {
    if (_authService == null) {
      try {
        _authService = AuthService(supabaseService: supabaseService);
      } catch (_) {}
    }
    return _authService!;
  }
  set authService(AuthService s) => _authService = s;
  late GrammarEngine grammarEngine;
  late GamificationService gamificationService;

  final activeLanguage = signal<String>('ja');
  final userSettings = signal<UserSettings>(UserSettings());
  final Signal<UserProfile?> _fallbackUserProfile = signal<UserProfile?>(null);
  Signal<UserProfile?> get userProfile {
    try {
      return authService.userProfile;
    } catch (_) {
      return _fallbackUserProfile;
    }
  }

  // Convenience proxies to gamification signals for backwards compatibility
  Signal<int> get diamonds => gamificationService.diamonds;
  Signal<int> get maxDiamonds => gamificationService.maxDiamonds;
  Signal<int> get currentStreak => gamificationService.currentStreak;
  Signal<int> get streakFreezes => gamificationService.streakFreezes;

  // Theme & Locale helpers
  ThemeMode get themeMode {
    switch (userSettings.value.themeMode.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  bool get isDarkMode {
    final mode = themeMode;
    if (mode == ThemeMode.dark) return true;
    if (mode == ThemeMode.light) return false;
    try {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    } catch (_) {
      return true;
    }
  }

  void setLanguage(String lang) {
    activeLanguage.value = lang;
    try {
      grammarEngine.loadLanguage(lang);
      final uiLang = I18nService.instance.currentLanguage.value;
      if (uiLang != 'en') {
        grammarEngine.loadTranslation(lang, uiLang);
      }
    } catch (_) {}
  }

  Future<void> initSettingsAndGamification() async {
    // 1. Initialize Gamification
    await gamificationService.init();

    // 2. Initialize i18n localization service
    await I18nService.instance.init();

    // 3. Load User Settings
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('voca_user_settings');
      if (settingsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(settingsJson);
        final loadedSettings = UserSettings.fromJson(decoded);
        userSettings.value = loadedSettings;
        if (loadedSettings.uiLanguage.isNotEmpty) {
          I18nService.instance.currentLanguage.value = loadedSettings.uiLanguage;
        }
      }
    } catch (e) {
      debugPrint('[AppState] Error loading user settings: $e');
    }

    // 4. Initialize Auth Service & Load Cached Profile
    try {
      if (_authService != null) {
        await _authService!.init();
      } else {
        try {
          await authService.init();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[AppState] Auth initialization skipped or failed: $e');
    }
  }

  Future<void> refreshUserProfile() async {
    try {
      await authService.init();
    } catch (_) {}
  }

  Future<bool> updateUserProfile({
    String? name,
    String? avatarUrl,
    String? country,
  }) async {
    try {
      return await authService.updateUserProfile(
        name: name,
        avatarUrl: avatarUrl,
        country: country,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> updateUserSettings(UserSettings newSettings) async {
    userSettings.value = newSettings;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('voca_user_settings', jsonEncode(newSettings.toJson()));
    } catch (e) {
      debugPrint('[AppState] Error saving user settings: $e');
    }
  }

  void setThemeMode(String mode) {
    updateUserSettings(userSettings.value.copyWith(themeMode: mode));
  }

  void setUiLanguage(String lang) {
    updateUserSettings(userSettings.value.copyWith(uiLanguage: lang));
    I18nService.instance.setLanguage(lang);
  }

  void setReadingDisplayMode(String mode) {
    updateUserSettings(userSettings.value.copyWith(readingDisplayMode: mode));
  }

  void setRubyMode(RubyDisplayMode mode) {
    updateUserSettings(userSettings.value.copyWith(rubyMode: mode));
  }

  void setSubtitleSize(SubtitleSize size) {
    updateUserSettings(userSettings.value.copyWith(subtitleSize: size));
  }

  void setNativeLanguage(String lang) {
    updateUserSettings(userSettings.value.copyWith(nativeLanguage: lang));
  }

  void setAutoPauseOnLookup(bool autoPause) {
    updateUserSettings(userSettings.value.copyWith(autoPauseOnLookup: autoPause));
  }

  void markSubtitleCoachmarkSeen() {
    updateUserSettings(userSettings.value.copyWith(hasSeenSubtitleCoachmark: true));
  }

  String applyCompanionPerk(String companionId) {
    switch (companionId) {
      case 'knight':
        gamificationService.streakFreezes.value = 2;
        return I18nService.instance.t(
          'onboarding.perkKnight',
          null,
          'Guardian Knight: Frost Ward Streak Shield activated!',
        );
      case 'wizard':
        return I18nService.instance.t(
          'onboarding.perkWizard',
          null,
          'Scholar Mage: Grammar & Syntax Insights turned ON!',
        );
      case 'alchemist':
        gamificationService.addXp(25, reason: 'alchemist_word_mining_bonus');
        return I18nService.instance.t(
          'onboarding.perkAlchemist',
          null,
          'Vocab Alchemist: +25 Extra Bonus XP transmuted!',
        );
      case 'ranger':
        return I18nService.instance.t(
          'onboarding.perkRanger',
          null,
          'Immersion Ranger: Dual Subtitles enabled for real talk!',
        );
      case 'bard':
        setReadingDisplayMode('annotated');
        return I18nService.instance.t(
          'onboarding.perkBard',
          null,
          'Minstrel Bard: Phonetic Pronunciation guides enabled!',
        );
      case 'miner':
        gamificationService.addXp(35, reason: 'miner_word_mining_bonus');
        return I18nService.instance.t(
          'onboarding.perkMiner',
          null,
          'Sentence Miner: Word-mining radar calibrated! +35 Miner XP discovered!',
        );
      case 'sovereign':
        return I18nService.instance.t(
          'onboarding.perkSovereign',
          null,
          'Mythic Sovereign: Polyglot Mantle bestowed! Dual Subtitles & Grammar Insights active!',
        );
      case 'shinobi':
      default:
        return I18nService.instance.t(
          'onboarding.perkShinobi',
          null,
          'Shadow Shinobi: Rapid native immersion calibrated!',
        );
    }
  }

  Future<String> completeOnboarding({
    required String learningLanguage,
    required String companionClass,
    required String preferredLevel,
    required String nativeLanguage,
    required bool showDualSubtitles,
    int dailyGoalMinutes = 10,
    bool isReplay = false,
  }) async {
    setLanguage(learningLanguage);

    final perkMsg = applyCompanionPerk(companionClass);

    final effectiveDualSubtitles = (companionClass == 'ranger' || companionClass == 'sovereign')
        ? true
        : showDualSubtitles;

    final updated = userSettings.value.copyWith(
      hasCompletedOnboarding: true,
      nativeLanguage: nativeLanguage,
      dualSubtitleTargetLang: nativeLanguage,
      showDualSubtitles: effectiveDualSubtitles,
      preferredLevel: preferredLevel,
      companionClass: companionClass,
      dailyGoalMinutes: dailyGoalMinutes,
    );
    await updateUserSettings(updated);

    if (!isReplay) {
      try {
        gamificationService.addXp(50, reason: 'onboarding_starter_pack');
        await gamificationService.recordActivity();
        if (companionClass == 'knight') {
          gamificationService.streakFreezes.value = 2;
        } else {
          gamificationService.streakFreezes.value = 1;
        }
      } catch (_) {}
    }

    try {
      final user = supabaseService.client.auth.currentUser;
      if (user != null) {
        await supabaseService.client.from('profiles').update({
          'target_lang': learningLanguage,
          'companion_class': companionClass,
          'preferred_level': preferredLevel,
        }).eq('id', user.id);
      }
    } catch (e) {
      debugPrint('[AppState] Profile sync skipped: $e');
    }

    return perkMsg;
  }

  Future<void> refreshDiamonds() async {
    await gamificationService.refreshDiamonds();
  }
}
