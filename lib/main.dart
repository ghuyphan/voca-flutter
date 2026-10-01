// lib/main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/api_endpoints.dart';
import 'services/voca_api_client.dart';
import 'services/supabase_service.dart';
import 'services/grammar_engine.dart';
import 'state/app_state.dart';
import 'ui/shell/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Backend-as-a-Service
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Initialize Global App Services
  final appState = AppState.instance;
  appState.apiClient = VocaApiClient();
  appState.supabaseService = SupabaseService(Supabase.instance.client);
  appState.grammarEngine = GrammarEngine();

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
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF38BDF8),
          surface: Color(0xFF1E293B),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFF1F5F9)),
        ),
      ),
      home: const MainShell(),
    );
  }
}
