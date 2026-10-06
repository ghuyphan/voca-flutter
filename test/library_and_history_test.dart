// test/library_and_history_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voca_flutter/config/voca_theme.dart';
import 'package:voca_flutter/services/gamification_service.dart';
import 'package:voca_flutter/services/grammar_engine.dart';
import 'package:voca_flutter/services/i18n_service.dart';
import 'package:voca_flutter/services/supabase_service.dart';
import 'package:voca_flutter/services/voca_api_client.dart';
import 'package:voca_flutter/state/app_state.dart';
import 'package:voca_flutter/ui/library/library_screen.dart';
import 'package:voca_flutter/ui/shell/main_shell.dart';
import 'package:voca_flutter/ui/gamification/streak_screen.dart';
import 'package:voca_flutter/ui/gamification/achievements_hub_screen.dart';
import 'package:voca_flutter/ui/gamification/ai_credits_screen.dart';

class _FakeGoTrueClient extends GoTrueClient {
  _FakeGoTrueClient() : super(autoRefreshToken: false);
  @override
  User? get currentUser => null;
}

class _FakeSupabaseClient extends SupabaseClient {
  final _fakeAuth = _FakeGoTrueClient();
  _FakeSupabaseClient() : super('https://dummy.supabase.co', 'dummy-anon-key');
  @override
  GoTrueClient get auth => _fakeAuth;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseService supabaseService;
  late GamificationService gamificationService;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final fakeClient = _FakeSupabaseClient();
    supabaseService = SupabaseService(fakeClient);
    final apiClient = VocaApiClient();
    AppState.instance.apiClient = apiClient;
    gamificationService = GamificationService(
      apiClient: apiClient,
      supabaseService: supabaseService,
    );
    await gamificationService.init();

    AppState.instance.supabaseService = supabaseService;
    AppState.instance.gamificationService = gamificationService;
    AppState.instance.grammarEngine = GrammarEngine();

    I18nService.instance.loadTranslations('en', {
      'nav': {
        'watch': 'Watch',
        'review': 'Review',
        'vocab': 'Vocab',
        'library': 'Library',
        'personalHub': 'Personal Hub',
        'settings': 'Settings',
        'playlists': 'Playlists',
      },
      'history': {
        'title': 'Watch History',
        'clearTitle': 'Clear Watch History',
        'clearConfirm': 'Are you sure you want to remove all videos from your watch history?',
      },
      'playlist': {
        'create': 'New Playlist',
      },
      'gamification': {
        'streak': 'Daily Streak',
        'achievements': 'Level & Achievements',
        'aiCredits': 'AI Credits',
      },
      'common': {
        'clear': 'Clear All',
        'cancel': 'Cancel',
        'close': 'Close',
      },
    });
    I18nService.instance.currentLanguage.value = 'en';
  });

  group('Watch History & Resume Logic Tests', () {
    test('Guest users can save watch history to local cache without authentication', () async {
      expect(supabaseService.currentUser, isNull);

      await supabaseService.saveHistory(
        id: 'guest_test_rec_1',
        videoId: 'abc12345',
        title: 'Learn Japanese Basics',
        thumbnail: 'https://img.youtube.com/vi/abc12345/hqdefault.jpg',
        channel: 'Nihongo Channel',
        duration: 300,
        language: 'ja',
        progress: 45.0, // 45% watched
      );

      final history = await supabaseService.getHistory(limit: 10);
      expect(history, isNotEmpty);
      expect(history.first['video_id'], 'abc12345');
      expect(history.first['title'], 'Learn Japanese Basics');
      expect(history.first['duration'], 300);
      expect(history.first['progress'], 45.0);
    });

    test('Resume seconds computed accurately from progress and duration', () {
      const dur = 300;
      const progress = 45.0; // 45%
      expect(progress > 0 && progress < 95 && dur > 0, isTrue);

      final resumeSeconds = (dur * progress / 100).round();
      expect(resumeSeconds, 135);
      expect(resumeSeconds > 3, isTrue);
    });

    test('Video completion triggers gamification XP', () async {
      final initialXp = gamificationService.xp.value;
      await gamificationService.recordVideoCompleted();
      expect(gamificationService.xp.value, greaterThanOrEqualTo(initialXp + 25));
    });
  });

  group('LibraryScreen Hub Widget Tests', () {
    testWidgets('Renders Header Bar with Stats Pills and Tabs in Dark Mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const Scaffold(
            body: LibraryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check 2 Tabs: Watch History & Playlists
      expect(find.text('Watch History'), findsWidgets);
      expect(find.text('Playlists'), findsWidgets);

      // Check Settings gear icon
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      // Check History Tab Search Bar
      expect(find.byType(TextField), findsOneWidget);

      // Check Filter Pills
      expect(find.text('All'), findsWidgets);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('N5'), findsOneWidget);
    });

    testWidgets('Tapping Playlists tab switches smoothly and displays Playlists tab', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const Scaffold(
            body: LibraryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Playlists tab
      await tester.tap(find.text('Playlists').first);
      await tester.pumpAndSettle();

      // Check for New Playlist action
      expect(find.text('New Playlist'), findsOneWidget);
    });
  });

  group('MainShell 4-Tab Navigation Tests', () {
    testWidgets('MainShell renders 4 tabs with Library at index 3', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const MainShell(initialIndex: 3),
        ),
      );
      await tester.pumpAndSettle();

      // Tab 3 is active and renders LibraryScreen Watch History tab
      expect(find.text('Watch History'), findsWidgets);

      // Bottom nav labels
      expect(find.text('Watch'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Vocab'), findsOneWidget);
      expect(find.text('Library'), findsWidgets);
    });
  });

  group('Gamification Screens Widget Tests', () {
    testWidgets('StreakScreen renders with flame crest and days', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const StreakScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Daily Streak'), findsWidgets);
      expect(find.text('Days'), findsOneWidget);
    });

    testWidgets('AchievementsHubScreen renders with shield crest and level progress', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const AchievementsHubScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text("Adventurer's Hall"), findsOneWidget);
      expect(find.text('Missions'), findsOneWidget);
    });

    testWidgets('AiCreditsScreen renders with diamond crest and refresh button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const AiCreditsScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('AI Credits & Upgrades'), findsOneWidget);
      expect(find.text('How Credits Work'), findsOneWidget);
    });
  });
}
