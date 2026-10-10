// test/fullscreen_subtitle_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/grammar_engine.dart';
import 'package:voca_flutter/services/voca_api_client.dart';
import 'package:voca_flutter/state/app_state.dart';
import 'package:voca_flutter/state/player_state.dart';
import 'package:voca_flutter/ui/sheets/dictionary_bottom_sheet.dart';
import 'package:voca_flutter/ui/video/fullscreen_subtitle.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class _FakeApiClient extends Fake implements VocaApiClient {}

class _FakeDictApiClient extends VocaApiClient {
  @override
  Future<DictionaryResult> lookupDictionary({
    required String word,
    required String from,
    required String to,
  }) async {
    return DictionaryResult(
      word: word,
      from: from,
      to: to,
      source: 'test',
      entries: const [],
    );
  }
}

class _FakeGrammarEngine extends Fake implements GrammarEngine {
  @override
  final loadedLanguages = signal<Set<String>>({});

  @override
  final loadedTranslations = signal<Set<String>>({});

  @override
  Future<void> loadLanguage(String language) async {}

  @override
  Future<Map<String, GrammarTranslation>> loadTranslation(String learningLang, String uiLang) async => {};

  @override
  GrammarPattern getLocalizedPattern(GrammarPattern pattern, String uiLang) => pattern;

  @override
  List<GrammarMatch> detectPatterns(List<Token> tokens, String language, {String? uiLang}) => [];
}

class _MockYoutubePlayerController extends Fake implements YoutubePlayerController {
  bool pauseCalled = false;
  bool playCalled = false;

  @override
  Future<void> pauseVideo() async {
    pauseCalled = true;
  }

  @override
  Future<void> playVideo() async {
    playCalled = true;
  }

  @override
  Future<void> close() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoPlayerController controller;
  late _MockYoutubePlayerController ytController;

  setUpAll(() {
    AppState.instance.apiClient = _FakeDictApiClient();
  });

  setUp(() {
    controller = VideoPlayerController(
      apiClient: _FakeApiClient(),
      grammarEngine: _FakeGrammarEngine(),
    );
    ytController = _MockYoutubePlayerController();
  });

  Widget buildTestWidget({bool areControlsVisible = false}) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            FullscreenSubtitle(
              controller: controller,
              ytController: ytController,
              areControlsVisible: areControlsVisible,
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('FullscreenSubtitle renders nothing when subtitlesVisible is false', (tester) async {
    controller.subtitlesVisible.value = false;
    controller.cues.value = [
      SubtitleCue(
        start: 0.0,
        duration: 2.0,
        text: 'こんにちは世界',
      ),
    ];
    controller.currentTime.value = 1.0;

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(find.text('こんにちは世界'), findsNothing);
  });

  testWidgets('FullscreenSubtitle renders tokens, ruby reading, and translation in card', (tester) async {
    controller.subtitlesVisible.value = true;
    controller.showFurigana.value = true;
    controller.showTranslation.value = true;

    final cue = SubtitleCue(
      start: 5.0,
      duration: 3.0,
      text: '青い空',
      translation: 'Bầu trời xanh',
      tokens: [
        Token(
          surface: '青い',
          rubyParts: const [RubyPart(text: '青い', reading: 'あおい')],
          level: 'new',
        ),
        Token(
          surface: '空',
          rubyParts: const [RubyPart(text: '空', reading: 'そら')],
          level: 'learning',
        ),
      ],
    );

    controller.cues.value = [cue];
    controller.currentTime.value = 6.0;

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    // Verify token surface text and ruby readings
    expect(find.text('青い'), findsOneWidget);
    expect(find.text('あおい'), findsOneWidget);
    expect(find.text('空'), findsOneWidget);
    expect(find.text('そら'), findsOneWidget);

    // Verify secondary translation
    expect(find.text('Bầu trời xanh'), findsOneWidget);
  });

  testWidgets('FullscreenSubtitle toggles between bottom and top dock on handle tap', (tester) async {
    controller.subtitlesVisible.value = true;
    final cue = SubtitleCue(
      start: 0.0,
      duration: 5.0,
      text: 'テスト字幕',
    );
    controller.cues.value = [cue];
    controller.currentTime.value = 1.0;

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    // Find Align
    Align align = tester.widget<Align>(find.byKey(const Key('fullscreen_subtitle_align')));
    // Default dock is bottom (align.alignment.y == 1.0)
    expect((align.alignment as Alignment).y, equals(1.0));

    // Tap the drag handle to toggle dock to top
    final handleGesture = find.byType(GestureDetector).first;
    await tester.tap(handleGesture);
    await tester.pumpAndSettle();

    align = tester.widget<Align>(find.byKey(const Key('fullscreen_subtitle_align')));
    // Now docked to top (align.alignment.y == -1.0)
    expect((align.alignment as Alignment).y, equals(-1.0));

    // Tap again to toggle back to bottom
    await tester.tap(handleGesture);
    await tester.pumpAndSettle();

    align = tester.widget<Align>(find.byKey(const Key('fullscreen_subtitle_align')));
    expect((align.alignment as Alignment).y, equals(1.0));
  });

  testWidgets('FullscreenSubtitle adapts clearance when controls are visible', (tester) async {
    controller.subtitlesVisible.value = true;
    final cue = SubtitleCue(
      start: 0.0,
      duration: 5.0,
      text: 'クリアランステスト',
    );
    controller.cues.value = [cue];
    controller.currentTime.value = 1.0;

    // Controls hidden: bottom padding is 20.0
    await tester.pumpWidget(buildTestWidget(areControlsVisible: false));
    await tester.pump();

    AnimatedPadding padding = tester.widget<AnimatedPadding>(find.byType(AnimatedPadding));
    expect((padding.padding as EdgeInsets).bottom, equals(20.0));

    // Controls visible: bottom lifts to 82.0 to clear bottom scrub & bar
    await tester.pumpWidget(buildTestWidget(areControlsVisible: true));
    await tester.pump();

    padding = tester.widget<AnimatedPadding>(find.byType(AnimatedPadding));
    expect((padding.padding as EdgeInsets).bottom, equals(82.0));
  });

  testWidgets('FullscreenSubtitle supports vertical drag gesture to change dock', (tester) async {
    controller.subtitlesVisible.value = true;
    final cue = SubtitleCue(
      start: 0.0,
      duration: 5.0,
      text: 'ドラッグテスト',
    );
    controller.cues.value = [cue];
    controller.currentTime.value = 1.0;

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    final handleGesture = find.byType(GestureDetector).first;

    // Fling up towards top
    await tester.fling(handleGesture, const Offset(0, -250), 1000.0);
    await tester.pumpAndSettle();

    final align = tester.widget<Align>(find.byKey(const Key('fullscreen_subtitle_align')));
    // Should have snapped to top dock (y == -1.0)
    expect((align.alignment as Alignment).y, equals(-1.0));
  });

  testWidgets('FullscreenSubtitle tapping word token pauses player via acquirePauseLock', (tester) async {
    controller.subtitlesVisible.value = true;
    controller.isPlaying.value = true;
    final cue = SubtitleCue(
      start: 0.0,
      duration: 5.0,
      text: '青い、空',
      tokens: [
        Token(surface: '青い', level: 'new'),
        Token(surface: '、', isPunctuation: true),
        Token(surface: '空', level: 'learning'),
      ],
    );
    controller.cues.value = [cue];
    controller.currentTime.value = 1.0;

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    // Verify punctuation '、' is present
    expect(find.text('、'), findsOneWidget);

    // Verify word '青い' is tappable
    final wordFinder = find.text('青い');
    expect(wordFinder, findsOneWidget);

    expect(ytController.pauseCalled, isFalse);
    await tester.tap(wordFinder);
    await tester.pump();

    // Player should have been paused
    expect(ytController.pauseCalled, isTrue);

    // Dismiss bottom sheet cleanly
    final sheetFinder = find.byType(DictionaryBottomSheet);
    if (sheetFinder.evaluate().isNotEmpty) {
      Navigator.of(tester.element(sheetFinder)).pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('FullscreenSubtitle card fits its content and does not expand to screen width', (tester) async {
    controller.subtitlesVisible.value = true;
    final cue = SubtitleCue(
      start: 0.0,
      duration: 5.0,
      text: 'はい',
      tokens: [
        Token(surface: 'はい', level: 'known'),
      ],
    );
    controller.cues.value = [cue];
    controller.currentTime.value = 1.0;

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    final cardFinder = find.byType(ClipRRect);
    expect(cardFinder, findsOneWidget);
    final size = tester.getSize(cardFinder);
    // Card should hug the single word + padding, well below full screen width (800)
    expect(size.width, lessThan(200.0));
  });
}
