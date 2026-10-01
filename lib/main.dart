// lib/main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/api_endpoints.dart';
import 'config/voca_theme.dart';
import 'services/voca_api_client.dart';
import 'services/supabase_service.dart';
import 'services/grammar_engine.dart';
import 'services/gamification_service.dart';
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

  // Pre-load default learning language grammar database
  await appState.grammarEngine.loadLanguage('ja');
  await appState.refreshDiamonds();

  runApp(const VocaApp());
}

class VocaApp extends StatelessWidget {
  const VocaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voca',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: VocaTheme.darkTheme,
      home: const MainShell(),
    );
  }
}
