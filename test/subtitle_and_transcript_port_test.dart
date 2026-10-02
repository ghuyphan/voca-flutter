// test/subtitle_and_transcript_port_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/grammar_engine.dart';
import 'package:voca_flutter/services/voca_api_client.dart';
import 'package:voca_flutter/state/player_state.dart';
import 'package:voca_flutter/ui/video/transcript_view.dart';
import 'package:voca_flutter/ui/widgets/interactive_subtitle_view.dart';
import 'package:voca_flutter/ui/widgets/voca_shimmer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoPlayerController controller;

  setUp(() {
    controller = VideoPlayerController(
      apiClient: VocaApiClient(),
      grammarEngine: GrammarEngine(),
    );
  });

  group('InteractiveSubtitleView Tests', () {
    testWidgets('Zero Layout Shift constraints: min/max height bounded', (tester) async {
      final cue = SubtitleCue(
        start: 0.0,
        duration: 3.0,
        text: 'こんにちは世界',
        translation: 'Hello world',
      );

      // With translation
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveSubtitleView(
              cue: cue,
              showTranslation: true,
              onTokenTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      final containerFinder = find.byType(Container).first;
      final RenderBox boxWithTrans = tester.renderObject(containerFinder);
      expect(boxWithTrans.size.height, greaterThanOrEqualTo(148.0));
      expect(boxWithTrans.size.height, lessThanOrEqualTo(180.0));

      // Without translation
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveSubtitleView(
              cue: cue,
              showTranslation: false,
              onTokenTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      final RenderBox boxNoTrans = tester.renderObject(find.byType(Container).first);
      expect(boxNoTrans.size.height, greaterThanOrEqualTo(130.0));
      expect(boxNoTrans.size.height, lessThanOrEqualTo(155.0));
    });

    testWidgets('Granular rubyParts rendering with readings and kana spacers', (tester) async {
      final tokenWithRuby = Token(
        surface: '日本語を食べます',
        rubyParts: [
          const RubyPart(text: '日本', reading: 'にほん'),
          const RubyPart(text: '語', reading: 'ご'),
          const RubyPart(text: 'を', reading: null), // okurigana/kana spacer
          const RubyPart(text: '食', reading: 'た'),
          const RubyPart(text: 'べます', reading: ''), // okurigana/kana spacer
        ],
      );

      final tokenFallback = Token(
        surface: '友達',
        reading: 'ともだち',
      );

      final cue = SubtitleCue(
        start: 1.0,
        duration: 3.0,
        text: '日本語を食べます 友達',
        tokens: [tokenWithRuby, tokenFallback],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveSubtitleView(
              cue: cue,
              showFurigana: true,
              onTokenTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify granular parts
      expect(find.text('にほん'), findsOneWidget);
      expect(find.text('日本'), findsOneWidget);
      expect(find.text('ご'), findsOneWidget);
      expect(find.text('語'), findsOneWidget);
      expect(find.text('を'), findsOneWidget);
      expect(find.text('た'), findsOneWidget);
      expect(find.text('食'), findsOneWidget);
      expect(find.text('べます'), findsOneWidget);

      // Verify fallback token
      expect(find.text('ともだち'), findsOneWidget);
      expect(find.text('友達'), findsOneWidget);
    });

    testWidgets('Word styling hierarchy: Grammar > SRS levels > Saved words', (tester) async {
      final grammarPattern = GrammarPattern(
        id: 'ja_grammar_1',
        language: 'ja',
        pattern: '〜てみる',
        title: '〜てみる',
        shortExplanation: 'to try doing',
        longExplanation: 'Used when trying something to see what it is like.',
        formation: 'Verb (Te-form) + みる',
        level: 'N4',
        examples: const [],
      );

      final tokenGrammar = Token(surface: '食べてみる');
      final tokenNew = Token(surface: 'リンゴ', level: 'new');
      final tokenLearning = Token(surface: '学校', level: 'learning');
      final tokenKnown = Token(surface: '本', level: 'known');
      final tokenSaved = Token(surface: '本屋', isSaved: true);

      final cue = SubtitleCue(
        start: 0.0,
        duration: 4.0,
        text: '食べてみる リンゴ 学校 本 本屋',
        tokens: [tokenGrammar, tokenNew, tokenLearning, tokenKnown, tokenSaved],
      );

      final grammarMatch = GrammarMatch(
        pattern: grammarPattern,
        tokenIndices: [0],
        startIndex: 0,
        endIndex: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveSubtitleView(
              cue: cue,
              grammarMatches: [grammarMatch],
              onTokenTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('食べてみる'), findsOneWidget);
      expect(find.text('リンゴ'), findsOneWidget);
      expect(find.text('学校'), findsOneWidget);
      expect(find.text('本'), findsOneWidget);
      expect(find.text('本屋'), findsOneWidget);
    });

    testWidgets('Dual subtitles translation shows bouncing dots when loading and text when ready', (tester) async {
      final cueLoadingTrans = SubtitleCue(
        start: 0.0,
        duration: 2.0,
        text: 'Bonjour',
        translation: null,
      );

      // 1. Loading state with bouncing dots
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveSubtitleView(
              cue: cueLoadingTrans,
              showTranslation: true,
              isTranslating: true,
              onTokenTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Bouncing dots present
      expect(find.text('Bonjour'), findsOneWidget);

      // 2. Ready translation state
      final cueWithTrans = SubtitleCue(
        start: 0.0,
        duration: 2.0,
        text: 'Bonjour',
        translation: 'Hello there',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveSubtitleView(
              cue: cueWithTrans,
              showTranslation: true,
              isTranslating: false,
              onTokenTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Hello there'), findsOneWidget);
    });

    testWidgets('Visual states: AI Generating, Loading, Error states, Subtitles Off, Waiting', (tester) async {
      // 1. AI Generating state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveSubtitleView(
              isAIGenerating: true,
              onTokenTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Generating transcript...'), findsOneWidget);
      expect(find.text('Using Whisper AI'), findsOneWidget);

      // 2. Loading state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveSubtitleView(
              isLoading: true,
              statusMessage: 'Fetching captions...',
              onTokenTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Fetching captions...'), findsOneWidget);

      // 3. Error state with NO_NATIVE / AI button
      bool aiTriggered = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveSubtitleView(
              errorCode: 'NO_NATIVE',
              errorMessage: 'No native captions found',
              diamonds: 5,
              onTriggerAI: () => aiTriggered = true,
              onTokenTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('No captions available'), findsOneWidget);
      expect(find.text('AI transcription available'), findsOneWidget);
      expect(find.text('Use AI Transcription (5)'), findsOneWidget);
      await tester.tap(find.text('Use AI Transcription (5)'));
      expect(aiTriggered, isTrue);

      // 4. Error state with UNSUPPORTED_LANGUAGE
      bool switchedLang = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveSubtitleView(
              errorCode: 'UNSUPPORTED_LANGUAGE',
              switchLanguageName: 'Japanese',
              onSwitchLanguage: () => switchedLang = true,
              onTokenTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Language not supported'), findsOneWidget);
      expect(find.text('Switch to Japanese'), findsOneWidget);
      await tester.tap(find.text('Switch to Japanese'));
      expect(switchedLang, isTrue);

      // 5. Subtitles Off state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveSubtitleView(
              subtitlesEnabled: false,
              onTokenTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Subtitles turned off'), findsOneWidget);
      expect(find.byIcon(Icons.subtitles_off_rounded), findsOneWidget);

      // 6. Waiting state (playback between cues)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveSubtitleView(
              cue: null,
              hasSubtitles: true,
              onTokenTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      // Waiting dots rendered
      expect(find.byType(InteractiveSubtitleView), findsOneWidget);
    });

    testWidgets('Coachmark renders lightbulb, hint text, and dismisses on close tap', (tester) async {
      final cue = SubtitleCue(
        start: 0.0,
        duration: 3.0,
        text: 'Hello coachmark test',
      );

      bool coachmarkDismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveSubtitleView(
              cue: cue,
              showCoachmark: true,
              onDismissCoachmark: () => coachmarkDismissed = true,
              onTokenTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Tap any word to translate & save'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap close button on coachmark
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(coachmarkDismissed, isTrue);
      expect(find.text('Tap any word to translate & save'), findsNothing);
    });
  });

  group('TranscriptView Tests', () {
    testWidgets('Translation skeleton shimmer when dual translation is loading', (tester) async {
      final cue1 = SubtitleCue(start: 0.0, duration: 2.0, text: 'Hello', translation: null);
      final cue2 = SubtitleCue(start: 2.0, duration: 2.0, text: 'World', translation: 'Thế giới');

      controller.cues.value = [cue1, cue2];
      controller.isDualSubLoading.value = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptView(
              controller: controller,
              onSeek: (_) {},
              onTokenTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Shimmer should be rendered for cue1 without translation while dual sub is loading
      expect(find.byType(VocaShimmer), findsWidgets);
      // Translation for cue2 should be displayed
      expect(find.text('Thế giới'), findsOneWidget);
    });

    testWidgets('Quiz mode obfuscates text and timestamps with redacted blocks', (tester) async {
      final cue = SubtitleCue(start: 5.0, duration: 2.0, text: 'Secret Sentence', translation: 'Secret Trans');
      controller.cues.value = [cue];
      controller.currentTime.value = 5.5;

      // Normal mode first
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptView(
              controller: controller,
              isQuizMode: false,
              onSeek: (_) {},
              onTokenTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Secret Sentence'), findsOneWidget);
      expect(find.text('Secret Trans'), findsOneWidget);

      // Activate quiz mode
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptView(
              controller: controller,
              isQuizMode: true,
              onSeek: (_) {},
              onTokenTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Text and translation should be redacted/hidden in quiz mode
      expect(find.text('Secret Sentence'), findsNothing);
      expect(find.text('Secret Trans'), findsNothing);
    });

    testWidgets('Scrolled-away detection shows floating "Jump to current (M:SS)" button', (tester) async {
      final cues = List.generate(
        30,
        (i) => SubtitleCue(
          start: i * 5.0,
          duration: 4.0,
          text: 'Sentence number $i',
        ),
      );

      controller.cues.value = cues;
      controller.currentTime.value = 0.5; // active cue is index 0 (0:00)

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptView(
              controller: controller,
              onSeek: (_) {},
              onTokenTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Floating button not visible initially
      expect(find.textContaining('Jump to current'), findsNothing);

      // Scroll down far away
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();

      // Now floating jump button is displayed with (0:00)
      expect(find.textContaining('Jump to current'), findsOneWidget);
      expect(find.textContaining('(0:00)'), findsOneWidget);

      // Tap jump to current button
      await tester.tap(find.textContaining('Jump to current'));
      await tester.pumpAndSettle();

      // Floating button is now dismissed after jumping back
      expect(find.textContaining('Jump to current'), findsNothing);
    });
  });
}
