// lib/main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/api_endpoints.dart';
import 'config/voca_theme.dart';
import 'services/voca_api_client.dart';
import 'services/supabase_service.dart';
import 'services/grammar_engine.dart';
import 'services/gamification_service.dart';
import 'services/i18n_service.dart';
import 'services/toast_service.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'state/app_state.dart';
import 'ui/shell/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Backend-as-a-Service
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );

  // Initialize Global App Services
  final appState = AppState.instance;
  appState.apiClient = VocaApiClient();
  appState.supabaseService = SupabaseService(Supabase.instance.client);
  appState.grammarEngine = GrammarEngine();
  appState.gamificationService = GamificationService(
    apiClient: appState.apiClient,
    supabaseService: appState.supabaseService,
  );

  // Load persistent settings & gamification stats
  await appState.initSettingsAndGamification();

  // Initialize I18n Localization Service
  await I18nService.instance.init();

  // Pre-load default learning language grammar database
  await appState.grammarEngine.loadLanguage('ja');
  await appState.refreshDiamonds();

  runApp(const VocaApp());
}

class VocaApp extends StatelessWidget {
  final Widget? home;
  const VocaApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final lang = I18nService.instance.currentLanguage.value;
      final settings = AppState.instance.userSettings.value;
      ThemeMode themeMode;
      switch (settings.themeMode.toLowerCase()) {
        case 'light':
          themeMode = ThemeMode.light;
          break;
        case 'dark':
          themeMode = ThemeMode.dark;
          break;
        default:
          themeMode = ThemeMode.system;
          break;
      }

      return MaterialApp(
        scaffoldMessengerKey: ToastService.messengerKey,
        title: 'Voca',
        debugShowCheckedModeBanner: false,
        theme: VocaTheme.lightTheme,
        darkTheme: VocaTheme.darkTheme,
        themeMode: themeMode,
        locale: Locale(lang),
        home: home ?? const MainShell(),
      );
    });
  }
}
