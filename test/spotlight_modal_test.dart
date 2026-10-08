// test/spotlight_modal_test.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voca_flutter/services/gamification_service.dart';
import 'package:voca_flutter/services/grammar_engine.dart';
import 'package:voca_flutter/services/supabase_service.dart';
import 'package:voca_flutter/services/voca_api_client.dart';
import 'package:voca_flutter/state/app_state.dart';
import 'package:voca_flutter/ui/widgets/spotlight_modal.dart';

class FakeVocaApiClient extends VocaApiClient {
  @override
  Future<List<Map<String, dynamic>>> getRecommendedVideos({
    String lang = 'ja',
    String? tier,
    String? category,
    String? query,
    int limit = 20,
    int offset = 0,
    bool refresh = false,
  }) async {
    if (query != null && query.toLowerCase().contains('lemon')) {
      return [
        {
          'videoId': 'clU8c2fpk2s',
          'title': 'Lemon - Kenshi Yonezu',
          'channel': 'Kenshi Yonezu',
          'duration': 275,
          'level': 'JLPT N4',
          'tier': 'elementary',
        },
      ];
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> getDiamonds() async {
    return {'success': true, 'diamonds': 5, 'maxDiamonds': 5};
  }
}

class FakeSupabaseService extends SupabaseService {
  FakeSupabaseService() : super(SupabaseClient('https://mock.supabase.co', 'mock_anon_key'));
  @override
  User? get currentUser => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final fakeApi = FakeVocaApiClient();
    final fakeSupabase = FakeSupabaseService();
    AppState.instance.apiClient = fakeApi;
    AppState.instance.supabaseService = fakeSupabase;
    AppState.instance.grammarEngine = GrammarEngine();
    AppState.instance.gamificationService = GamificationService(
      apiClient: fakeApi,
      supabaseService: fakeSupabase,
    );
    await AppState.instance.initSettingsAndGamification();
    AppState.instance.activeLanguage.value = 'ja';
  });

  group('SpotlightModal Tests', () {
    testWidgets('Renders spotlight bar, empty Quick Navigation list, and Cancel button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SpotlightModal.show(context),
                child: const Text('Open Spotlight'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Spotlight'));
      await tester.pumpAndSettle();

      // Top bar elements
      expect(find.text('Paste YouTube link or search...'), findsOneWidget);
      expect(find.byKey(const Key('spotlight-paste-btn')), findsOneWidget);
      expect(find.byKey(const Key('spotlight-cancel-btn')), findsOneWidget);

      // Header and Quick Navigation tiles
      expect(find.text('QUICK NAVIGATION'), findsOneWidget);
      expect(find.text('Watch & Learn'), findsOneWidget);
      expect(find.text('Review Flashcards'), findsOneWidget);
      expect(find.text('Vocabulary Notebook'), findsOneWidget);
      expect(find.text('Playlists'), findsOneWidget);
      expect(find.text('Watch History'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Quick Navigation tile invokes onNavigateTab callback and closes dialog', (tester) async {
      int? tappedTab;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SpotlightModal.show(
                  context,
                  onNavigateTab: (tabIndex) => tappedTab = tabIndex,
                ),
                child: const Text('Open Spotlight'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Spotlight'));
      await tester.pumpAndSettle();

      // Tap Review Flashcards (index 1)
      await tester.tap(find.text('Review Flashcards'));
      await tester.pumpAndSettle();

      expect(tappedTab, 1);
      // Dialog should now be closed
      expect(find.text('Paste YouTube link or search...'), findsNothing);
    });

    testWidgets('Detects YouTube URL, displays high-priority card, and allows instant launch', (tester) async {
      String? selectedVideoId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SpotlightModal.show(
                  context,
                  onVideoSelected: (id) => selectedVideoId = id,
                ),
                child: const Text('Open Spotlight'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Spotlight'));
      await tester.pumpAndSettle();

      // Enter full YouTube URL
      await tester.enterText(
        find.byType(TextField),
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );
      await tester.pumpAndSettle();

      // Header switches to YOUTUBE VIDEO
      expect(find.text('YOUTUBE VIDEO'), findsOneWidget);
      expect(find.text('▶ Load YouTube Video: dQw4w9WgXcQ'), findsOneWidget);
      expect(find.text('Start Learning'), findsOneWidget);
      expect(find.byKey(const Key('spotlight-clear-btn')), findsOneWidget);
      expect(find.byKey(const Key('spotlight-submit-btn')), findsOneWidget);

      // Tapping the card triggers callback
      await tester.tap(find.byKey(const Key('spotlight-youtube-card')));
      await tester.pumpAndSettle();

      expect(selectedVideoId, 'dQw4w9WgXcQ');
      expect(find.text('YOUTUBE VIDEO'), findsNothing);
    });

    testWidgets('Performs catalog search when typing query text and allows opening search result', (tester) async {
      String? selectedVideoId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SpotlightModal.show(
                  context,
                  onVideoSelected: (id) => selectedVideoId = id,
                ),
                child: const Text('Open Spotlight'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Spotlight'));
      await tester.pumpAndSettle();

      // Type query matching our mock
      await tester.enterText(find.byType(TextField), 'lemon');
      // Wait for debounce timer (280ms)
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('SEARCH RESULTS'), findsOneWidget);
      expect(find.text('Lemon - Kenshi Yonezu'), findsOneWidget);

      // Tapping the search result item navigates to video
      await tester.tap(find.text('Lemon - Kenshi Yonezu'));
      await tester.pumpAndSettle();

      expect(selectedVideoId, 'clU8c2fpk2s');
    });

    testWidgets('Empty search result shows helpful empty state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SpotlightModal.show(context),
                child: const Text('Open Spotlight'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Spotlight'));
      await tester.pumpAndSettle();

      // Type query with no matches
      await tester.enterText(find.byType(TextField), 'nonexistent query 12345');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('No results found'), findsOneWidget);
      expect(find.text('Try a different command or paste a YouTube link'), findsOneWidget);

      // Clear text
      await tester.tap(find.byKey(const Key('spotlight-clear-btn')));
      await tester.pumpAndSettle();

      // Back to Quick Navigation
      expect(find.text('QUICK NAVIGATION'), findsOneWidget);
      expect(find.text('Watch & Learn'), findsOneWidget);
    });

    testWidgets('Clipboard paste button pastes content into text field', (tester) async {
      // Mock clipboard with a video ID
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.getData') {
            return {'text': 'https://youtu.be/9bZkp7q19f0'};
          }
          return null;
        },
      );

      String? selectedVideoId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SpotlightModal.show(
                  context,
                  onVideoSelected: (id) => selectedVideoId = id,
                ),
                child: const Text('Open Spotlight'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Spotlight'));
      await tester.pumpAndSettle();

      // Tap paste button
      await tester.tap(find.byKey(const Key('spotlight-paste-btn')));
      await tester.pumpAndSettle();

      // YouTube ID detected and launched!
      expect(selectedVideoId, '9bZkp7q19f0');
    });

    testWidgets('Tapping Cancel button dismisses modal without action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SpotlightModal.show(context),
                child: const Text('Open Spotlight'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Spotlight'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.byKey(const Key('spotlight-cancel-btn')));
      await tester.pumpAndSettle();

      expect(find.text('Paste YouTube link or search...'), findsNothing);
    });
  });
}
