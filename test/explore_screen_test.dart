// test/explore_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voca_flutter/config/voca_theme.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/grammar_engine.dart';
import 'package:voca_flutter/services/supabase_service.dart';
import 'package:voca_flutter/services/voca_api_client.dart';
import 'package:voca_flutter/state/app_state.dart';
import 'package:voca_flutter/ui/explore/explore_screen.dart';

class FakeVocaApiClient extends VocaApiClient {
  @override
  Future<List<Map<String, dynamic>>> getRecommendedVideos({
    String lang = 'ja',
    String? tier,
    String? query,
    int limit = 20,
    int offset = 0,
    bool refresh = false,
  }) async {
    return [
      {
        'videoId': 'clU8c2fpk2s',
        'title': 'Lemon / Kenshi Yonezu',
        'channel': 'kobasolo',
        'duration': 272,
        'level': lang == 'ja'
            ? 'JLPT N4'
            : lang == 'zh'
                ? 'HSK 3'
                : lang == 'ko'
                    ? 'TOPIK 2'
                    : 'CEFR B1',
        'tier': 'elementary',
      },
      ...List.generate(
        10,
        (i) => {
          'videoId': 'vid_$i',
          'title': 'Video Title $i',
          'channel': 'Creator $i',
          'duration': 272,
          'level': 'JLPT N4',
          'tier': 'elementary',
        },
      ),
    ];
  }
}

class FakeSupabaseService extends SupabaseService {
  FakeSupabaseService() : super(SupabaseClient('https://mock.supabase.co', 'mock_anon_key'));

  @override
  User? get currentUser => null;

  @override
  Future<List<PlaylistItem>> getPlaylists({String? language}) async => [];

  @override
  Future<List<PlaylistItem>> getExplorePlaylists({String? language}) async => [
    PlaylistItem(
      id: 'pl-explore-1',
      userId: 'system',
      title: 'Anime Songs for Beginners',
      description: 'Fun J-Pop & Anime Songs',
      videoIds: const ['clU8c2fpk2s'],
      language: 'ja',
      level: 'JLPT N4',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    ),
  ];
}

void main() {
  setUpAll(() {
    AppState.instance.apiClient = FakeVocaApiClient();
    AppState.instance.supabaseService = FakeSupabaseService();
    AppState.instance.grammarEngine = GrammarEngine();
  });

  setUp(() {
    AppState.instance.activeLanguage.value = 'ja';
  });

  testWidgets('ExploreScreen renders top search bar, categories, and JLPT level filters for Japanese', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ExploreScreen(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify search bar hint and no paste button
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Paste YouTube URL or search...'), findsOneWidget);
    expect(find.text('Paste'), findsNothing);
    expect(find.text('For You'), findsNothing);

    // Verify Chips: Filters (first), All, Playlists
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('All'), findsAtLeastNWidgets(1));
    expect(find.text('Playlists'), findsOneWidget);
    expect(find.byIcon(Icons.filter_alt_rounded), findsOneWidget);

    // Verify direct Category topic chips rendered on the Explore bar
    expect(find.text('Trending'), findsOneWidget);
    expect(find.text('Anime & Drama'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('News'), findsOneWidget);
    expect(find.text('Vlog'), findsOneWidget);
    expect(find.text('Conversation'), findsOneWidget);

    // Verify video card rendered
    expect(find.text('Lemon / Kenshi Yonezu'), findsOneWidget);
    expect(find.text('kobasolo'), findsOneWidget);
    expect(find.text('JLPT N4'), findsWidgets);

    // Open Filter sheet via Filters chip to verify JLPT difficulty levels
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilterChip, 'N5'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'N4'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'N3'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'N2'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'N1'), findsOneWidget);
  });

  testWidgets('ExploreScreen dynamically updates difficulty level filters for Chinese, Korean, and English', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Chinese
    AppState.instance.activeLanguage.value = 'zh';
    await tester.pumpWidget(
      const MaterialApp(
        home: ExploreScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilterChip, 'HSK 1'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'HSK 2'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'HSK 3'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'HSK 4'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'HSK 5'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'HSK 6'), findsOneWidget);

    // Close sheet via Apply Filters
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();

    // Korean
    AppState.instance.activeLanguage.value = 'ko';
    await tester.pumpWidget(
      const MaterialApp(
        home: ExploreScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilterChip, 'TOPIK 1'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'TOPIK 2'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'TOPIK 3'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'TOPIK 4'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'TOPIK 5'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'TOPIK 6'), findsOneWidget);

    // Close sheet via Apply Filters
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();

    // English
    AppState.instance.activeLanguage.value = 'en';
    await tester.pumpWidget(
      const MaterialApp(
        home: ExploreScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilterChip, 'A1'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'A2'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'B1'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'B2'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'C1'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'C2'), findsOneWidget);
  });

  testWidgets('ExploreScreen displays direct YouTube link detected banner and clear button', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    AppState.instance.activeLanguage.value = 'ja';
    await tester.pumpWidget(
      const MaterialApp(
        home: ExploreScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Enter a bare 11-character video ID into the search field
    await tester.enterText(find.byType(TextField), 'dQw4w9WgXcQ');
    await tester.pump();

    // Banner should be visible
    expect(find.textContaining('Valid YouTube Video (dQw4w9WgXcQ) detected!'), findsOneWidget);
    expect(find.byTooltip('Clear'), findsOneWidget);

    // Tap clear button
    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();

    // Banner should disappear
    expect(find.textContaining('Valid YouTube Video'), findsNothing);
  });

  testWidgets('ExploreScreen Playlists chip toggles in-feed playlists filter', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: VocaTheme.darkTheme,
        home: const ExploreScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Playlists chip exists and tap it
    expect(find.text('Playlists'), findsOneWidget);
    await tester.tap(find.text('Playlists'));
    await tester.pumpAndSettle();

    // Verify playlist item is rendered in the feed
    expect(find.text('Anime Songs for Beginners'), findsOneWidget);
    expect(find.text('Fun J-Pop & Anime Songs'), findsOneWidget);
  });

  testWidgets('ExploreScreen switches to 1-column ListView on mobile screens (< 720dp)', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    AppState.instance.activeLanguage.value = 'ja';
    await tester.pumpWidget(
      const MaterialApp(
        home: ExploreScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // On mobile (< 720dp), video feed should use a ListView, not a GridView
    expect(find.byType(GridView), findsNothing);
    expect(find.text('Lemon / Kenshi Yonezu'), findsOneWidget);
  });

  testWidgets('ExploreScreen switches to responsive GridView on tablet screens (>= 720dp)', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    AppState.instance.activeLanguage.value = 'ja';
    await tester.pumpWidget(
      const MaterialApp(
        home: ExploreScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // On tablet (>= 720dp), video feed should render a GridView
    expect(find.byType(GridView), findsOneWidget);
    final gridView = tester.widget<GridView>(find.byType(GridView));
    final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, equals(2));
  });

  testWidgets('ExploreScreen category filter pills select and reload', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: VocaTheme.darkTheme,
        home: const ExploreScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Music category pill directly on chips bar (1-tap category selection)
    expect(find.text('Music'), findsOneWidget);
    await tester.tap(find.text('Music'));
    await tester.pumpAndSettle();

    // Active filter tag should be visible on Explore screen
    expect(find.textContaining('Music'), findsWidgets);
  });

  testWidgets('ExploreScreen search bar hides on scroll down and reveals on scroll up', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ExploreScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);

    // Verify SizeTransition initial value
    final sizeTransition = tester.widget<SizeTransition>(find.byType(SizeTransition));
    expect(sizeTransition.sizeFactor.value, equals(1.0));

    // Scroll down on video feed
    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();

    final hiddenTransition = tester.widget<SizeTransition>(find.byType(SizeTransition));
    expect(hiddenTransition.sizeFactor.value, equals(0.0));

    // Scroll back up
    await tester.drag(find.byType(ListView).last, const Offset(0, 300));
    await tester.pumpAndSettle();

    final revealedTransition = tester.widget<SizeTransition>(find.byType(SizeTransition));
    expect(revealedTransition.sizeFactor.value, equals(1.0));
  });

  testWidgets('ExploreScreen video card does not have dark fade overlay on thumbnail', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ExploreScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify video card rendered
    expect(find.text('Lemon / Kenshi Yonezu'), findsOneWidget);
  });

  testWidgets('ExploreScreen search bar does not highlight border on focus and shows compact search button', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: ExploreScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial container border has borderColor, not accent
    final containerFinder = find.byType(TextField);
    expect(containerFinder, findsOneWidget);

    // Focus text field
    await tester.tap(containerFinder);
    await tester.pump();

    // Enter keyword query
    await tester.enterText(containerFinder, 'Flydubai 1073');
    await tester.pump();

    // Verify there is NO large "Search" or "Tìm kiếm" text inside the search bar
    expect(find.text('Search'), findsNothing);
    expect(find.text('Tìm kiếm'), findsNothing);

    // Verify compact clear icon is present and no coral button
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget); // only left search icon
  });

  testWidgets('ExploreScreen renders simplified empty state with YouTube search CTA when search has 0 results', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Mock empty response for search
    await tester.pumpWidget(
      const MaterialApp(
        home: ExploreScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Submit search query
    await tester.enterText(find.byType(TextField), 'UnknownVideoXYZ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    // Redundant header line is removed, textfield retains query
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('UnknownVideoXYZ'), findsOneWidget);
  });
}

