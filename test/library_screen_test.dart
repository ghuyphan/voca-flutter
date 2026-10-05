// test/library_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voca_flutter/config/voca_theme.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/gamification_service.dart';
import 'package:voca_flutter/services/grammar_engine.dart';
import 'package:voca_flutter/services/i18n_service.dart';
import 'package:voca_flutter/services/supabase_service.dart';
import 'package:voca_flutter/services/voca_api_client.dart';
import 'package:voca_flutter/state/app_state.dart';
import 'package:voca_flutter/ui/library/widgets/history_video_card.dart';
import 'package:voca_flutter/ui/library/widgets/library_playlist_card.dart';
import 'package:voca_flutter/ui/library/widgets/library_top_bar.dart';

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

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final fakeClient = _FakeSupabaseClient();
    supabaseService = SupabaseService(fakeClient);
    final apiClient = VocaApiClient();
    AppState.instance.apiClient = apiClient;
    final gamificationService = GamificationService(
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
        'playlists': 'Playlists',
      },
      'history': {
        'title': 'Watch History',
        'searchHistory': 'Search watch history...',
        'all': 'All',
        'favorites': 'Favorites',
        'clearAll': 'Clear History',
        'videoSingular': 'video',
        'videoPlural': 'videos',
      },
      'playlist': {
        'create': 'New Playlist',
        'newPlaylist': 'New Playlist',
        'allLanguages': 'All Languages',
        'playAll': 'Play All',
      },
      'common': {
        'delete': 'Delete',
        'cancel': 'Cancel',
      },
    });
    I18nService.instance.currentLanguage.value = 'en';
  });

  group('HistoryVideoCard Unit Tests', () {
    test('Format duration formats mm:ss and hh:mm:ss properly', () {
      expect(HistoryVideoCard.formatDuration(0), '0:00');
      expect(HistoryVideoCard.formatDuration(75), '1:15');
      expect(HistoryVideoCard.formatDuration(3665), '1:01:05');
    });

    test('Format relative time formats recent dates', () {
      final now = DateTime.now();
      expect(HistoryVideoCard.formatRelativeTime(now), 'Just now');
      final fiveMinsAgo = now.subtract(const Duration(minutes: 5));
      expect(HistoryVideoCard.formatRelativeTime(fiveMinsAgo), '5m ago');
      final twoHoursAgo = now.subtract(const Duration(hours: 2));
      expect(HistoryVideoCard.formatRelativeTime(twoHoursAgo), '2h ago');
    });

    testWidgets('Renders HistoryVideoCard with duration badge, progress, and metadata', (tester) async {
      final item = {
        'video_id': 'xyz123',
        'title': 'Japanese Immersion Practice',
        'channel': 'Tokyo Vibes',
        'duration': 240,
        'progress': 50.0,
        'language': 'ja',
        'level': 'N4',
        'watched_at': DateTime.now().toIso8601String(),
      };

      bool favToggled = false;
      bool removed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: Scaffold(
            body: HistoryVideoCard(
              item: item,
              isFavorite: false,
              onToggleFavorite: () => favToggled = true,
              onRemove: () => removed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Japanese Immersion Practice'), findsOneWidget);
      expect(find.textContaining('Tokyo Vibes'), findsOneWidget);
      expect(find.text('4:00'), findsOneWidget); // 240s duration
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('JA'), findsOneWidget);

      // Tap favorite icon
      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      expect(favToggled, isTrue);

      // Tap delete icon
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      expect(removed, isTrue);
    });
  });

  group('LibraryTopBar Tests', () {
    testWidgets('Renders top bar and responds to tab change', (tester) async {
      int activeTab = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: Scaffold(
            body: LibraryTopBar(
              currentTab: activeTab,
              onTabChanged: (i) => activeTab = i,
              onSettingsPressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Watch History'), findsOneWidget);
      expect(find.text('Playlists'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      await tester.tap(find.text('Playlists'));
      expect(activeTab, 1);
    });
  });

  group('LibraryPlaylistCard Tests', () {
    testWidgets('Renders hydrated playlist card with video count and title', (tester) async {
      final playlist = PlaylistItem(
        id: 'test_pl_1',
        userId: 'guest',
        title: 'JLPT N3 Grammar Videos',
        description: 'Comprehensive study playlist',
        language: 'ja',
        level: 'N3',
        videoIds: const ['vid1', 'vid2', 'vid3'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: Scaffold(
            body: LibraryPlaylistCard(
              playlist: playlist,
              onTap: () {},
              onRefresh: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('JLPT N3 Grammar Videos'), findsOneWidget);
      expect(find.text('Comprehensive study playlist'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // 3 videos count badge
      expect(find.text('JA'), findsOneWidget);
    });
  });
}
