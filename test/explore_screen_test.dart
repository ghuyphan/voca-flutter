// test/explore_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    ];
  }
}

void main() {
  setUpAll(() {
    AppState.instance.apiClient = FakeVocaApiClient();
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

    // Verify Discover title
    expect(find.text('Discover'), findsOneWidget);

    // Verify search bar hint
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search keyword, channel, or paste YouTube link...'), findsOneWidget);

    // Verify Category pills
    expect(find.text('All'), findsAtLeastNWidgets(1));
    expect(find.text('Trending'), findsOneWidget);
    expect(find.text('Anime & Drama'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('News'), findsOneWidget);
    expect(find.text('Vlog'), findsOneWidget);
    expect(find.text('Conversation'), findsOneWidget);

    // Verify Japanese difficulty levels
    expect(find.widgetWithText(FilterChip, 'N5'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'N4'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'N3'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'N2'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'N1'), findsOneWidget);

    // Verify video card rendered
    expect(find.text('Lemon / Kenshi Yonezu'), findsOneWidget);
    expect(find.text('kobasolo'), findsOneWidget);
    expect(find.text('Watch Now'), findsOneWidget);
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

    expect(find.widgetWithText(FilterChip, 'HSK 1'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'HSK 2'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'HSK 3'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'HSK 4'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'HSK 5'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'HSK 6'), findsOneWidget);

    // Korean
    AppState.instance.activeLanguage.value = 'ko';
    await tester.pumpWidget(
      const MaterialApp(
        home: ExploreScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilterChip, 'TOPIK 1'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'TOPIK 2'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'TOPIK 3'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'TOPIK 4'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'TOPIK 5'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'TOPIK 6'), findsOneWidget);

    // English
    AppState.instance.activeLanguage.value = 'en';
    await tester.pumpWidget(
      const MaterialApp(
        home: ExploreScreen(),
      ),
    );
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

  testWidgets('ExploreScreen bookmark button toggles state', (tester) async {
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

    // Bookmark icon should start unselected
    expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_rounded), findsNothing);

    // Tap bookmark icon
    await tester.tap(find.byIcon(Icons.bookmark_border_rounded));
    await tester.pump();

    // Now it should be bookmarked
    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
  });
}
