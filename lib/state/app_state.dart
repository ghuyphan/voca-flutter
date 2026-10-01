// lib/state/app_state.dart

import 'package:signals_flutter/signals_flutter.dart';
import '../services/voca_api_client.dart';
import '../services/supabase_service.dart';
import '../services/grammar_engine.dart';

class AppState {
  static final AppState instance = AppState._();
  AppState._();

  late final VocaApiClient apiClient;
  late final SupabaseService supabaseService;
  late final GrammarEngine grammarEngine;

  final activeLanguage = signal<String>('ja');
  final diamonds = signal<int>(5);
  final maxDiamonds = signal<int>(5);
  final currentStreak = signal<int>(0);
  final streakFreezes = signal<int>(2);

  void setLanguage(String lang) {
    activeLanguage.value = lang;
    grammarEngine.loadLanguage(lang);
  }

  Future<void> refreshDiamonds() async {
    try {
      final info = await apiClient.getDiamonds();
      if (info['success'] == true) {
        diamonds.value = info['diamonds'] as int? ?? diamonds.value;
        maxDiamonds.value = info['maxDiamonds'] as int? ?? maxDiamonds.value;
      }
    } catch (e) {
      print('[AppState] Failed to refresh diamonds: $e');
    }
  }
}
