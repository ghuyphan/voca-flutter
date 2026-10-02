// lib/state/app_state.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../models/voca_models.dart';
import '../services/voca_api_client.dart';
import '../services/supabase_service.dart';
import '../services/grammar_engine.dart';
import '../services/gamification_service.dart';
import '../services/i18n_service.dart';

class AppState {
  static final AppState instance = AppState._();
  AppState._();

  late VocaApiClient apiClient;
  late SupabaseService supabaseService;
  late GrammarEngine grammarEngine;
  late GamificationService gamificationService;

  final activeLanguage = signal<String>('ja');
  final userSettings = signal<UserSettings>(UserSettings());

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
    grammarEngine.loadLanguage(lang);
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

  Future<void> refreshDiamonds() async {
    await gamificationService.refreshDiamonds();
  }
}
