// lib/state/app_state.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../models/voca_models.dart';
import '../services/voca_api_client.dart';
import '../services/supabase_service.dart';
import '../services/grammar_engine.dart';
import '../services/gamification_service.dart';

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

  void setLanguage(String lang) {
    activeLanguage.value = lang;
    grammarEngine.loadLanguage(lang);
  }

  Future<void> initSettingsAndGamification() async {
    // 1. Initialize Gamification
    await gamificationService.init();

    // 2. Load User Settings
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('voca_user_settings');
      if (settingsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(settingsJson);
        userSettings.value = UserSettings.fromJson(decoded);
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

  Future<void> refreshDiamonds() async {
    await gamificationService.refreshDiamonds();
  }
}
