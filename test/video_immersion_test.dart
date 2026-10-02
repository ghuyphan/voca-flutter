// test/video_immersion_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/grammar_engine.dart';
import 'package:voca_flutter/services/voca_api_client.dart';
import 'package:voca_flutter/state/player_state.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:voca_flutter/ui/video/transcript_view.dart';
import 'package:voca_flutter/ui/widgets/interactive_subtitle_view.dart';

class FakeYoutubePlayerController extends Fake implements YoutubePlayerController {
  double? lastSeek;
  double? lastRate;

  @override
  Future<void> seekTo({required double seconds, bool allowSeekAhead = false}) async {
    lastSeek = seconds;
  }

  @override
  Future<void> setPlaybackRate(double rate) async {
    lastRate = rate;
  }

  @override
  Future<void> close() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoPlayerController controller;

  setUp(() {
    controller = VideoPlayerController(
      apiClient: VocaApiClient(),
      grammarEngine: GrammarEngine(),
    );
  });

  group('VideoPlayerController Immersion Tests', () {
    test('Jump to previous and next cues', () {
      final cue1 = SubtitleCue(start: 0.0, duration: 2.0, text: 'First sentence');
      final cue2 = SubtitleCue(start: 3.0, duration: 2.0, text: 'Second sentence');
      final cue3 = SubtitleCue(start: 6.0, duration: 2.0, text: 'Third sentence');

      controller.cues.value = [cue1, cue2, cue3];
      controller.currentTime.value = 3.5; // In cue2

      double? seekTarget;
      // Seek to next cue
      controller.seekToNextCue(onSeek: (s) => seekTarget = s);
      expect(seekTarget, equals(6.0));
      expect(controller.currentTime.value, equals(6.0));

      // Seek to previous cue from start of cue 3
      controller.currentTime.value = 6.1;
      controller.seekToPreviousCue(onSeek: (s) => seekTarget = s);
      expect(seekTarget, equals(3.0));
      expect(controller.currentTime.value, equals(3.0));
    });

    test('Loop current cue toggling', () {
      final cue = SubtitleCue(start: 5.0, duration: 3.0, text: 'Loop sentence');
      controller.cues.value = [cue];
      controller.currentTime.value = 5.5;

      expect(controller.activeCue.value, equals(cue));
      expect(controller.isLoopingCue.value, isFalse);

      controller.toggleLoopCurrentCue();
      expect(controller.isLoopingCue.value, isTrue);
      expect(controller.loopingCue.value, equals(cue));

      controller.toggleLoopCurrentCue();
      expect(controller.isLoopingCue.value, isFalse);
      expect(controller.loopingCue.value, isNull);
    });

    test('Display toggles: Furigana, Translation, Transcript Mode, Subtitle Size', () {
      expect(controller.showFurigana.value, isTrue);
      controller.toggleFurigana();
      expect(controller.showFurigana.value, isFalse);

      expect(controller.showTranslation.value, isTrue);
      controller.toggleTranslation();
      expect(controller.showTranslation.value, isFalse);

      expect(controller.isTranscriptMode.value, isFalse);
      controller.toggleTranscriptMode();
      expect(controller.isTranscriptMode.value, isTrue);

      expect(controller.subtitleSize.value, equals(SubtitleSize.medium));
      controller.cycleSubtitleSize();
      expect(controller.subtitleSize.value, equals(SubtitleSize.large));
      controller.cycleSubtitleSize();
      expect(controller.subtitleSize.value, equals(SubtitleSize.small));
      controller.cycleSubtitleSize();
      expect(controller.subtitleSize.value, equals(SubtitleSize.medium));
    });
  });

  group('InteractiveSubtitleView Widget Tests', () {
    testWidgets('Displays furigana and translation when enabled', (tester) async {
      final cue = SubtitleCue(
        start: 1.0,
        duration: 2.0,
        text: '日本語',
        translation: 'Japanese language',
        tokens: [
          Token(
            surface: '日本語',
            reading: 'にほんご',
            romanization: 'nihongo',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveSubtitleView(
              cue: cue,
              showFurigana: true,
              showTranslation: true,
              subtitleSize: SubtitleSize.medium,
              onTokenTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('日本語'), findsOneWidget);
      expect(find.text('にほんご'), findsOneWidget);
      expect(find.text('Japanese language'), findsOneWidget);
    });

    testWidgets('Hides furigana and translation when toggled off', (tester) async {
      final cue = SubtitleCue(
        start: 1.0,
        duration: 2.0,
        text: '日本語',
        translation: 'Japanese language',
        tokens: [
          Token(
            surface: '日本語',
            reading: 'にほんご',
            romanization: 'nihongo',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveSubtitleView(
              cue: cue,
              showFurigana: false,
              showTranslation: false,
              subtitleSize: SubtitleSize.medium,
              onTokenTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('日本語'), findsOneWidget);
      expect(find.text('にほんご'), findsNothing);
      expect(find.text('Japanese language'), findsNothing);
    });

    testWidgets('Falls back to cue.text if tokens are empty', (tester) async {
      final cue = SubtitleCue(
        start: 1.0,
        duration: 2.0,
        text: 'Fallback raw subtitle text',
        tokens: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveSubtitleView(
              cue: cue,
              onTokenTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Fallback raw subtitle text'), findsOneWidget);
    });
  });

  group('TranscriptView Widget Tests', () {
    testWidgets('Renders cues and filters with search', (tester) async {
      final cue1 = SubtitleCue(start: 0.0, duration: 2.0, text: 'Hello world', translation: 'Xin chào');
      final cue2 = SubtitleCue(start: 3.0, duration: 2.0, text: 'Language immersion', translation: 'Học ngoại ngữ');

      controller.cues.value = [cue1, cue2];
      controller.currentTime.value = 0.5;

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

      expect(find.text('Hello world'), findsOneWidget);
      expect(find.text('Language immersion'), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
      // Enter search query
      await tester.enterText(find.byType(TextField), 'immersion');
      await tester.pump();

      expect(find.text('Hello world'), findsNothing);
      expect(find.text('Language immersion'), findsOneWidget);
    });

    testWidgets('Tapping cue seeks playback position and repeat button sets loop', (tester) async {
      final cue1 = SubtitleCue(start: 10.0, duration: 3.0, text: 'Active target');
      controller.cues.value = [cue1];
      controller.currentTime.value = 10.5;

      double? seekTime;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptView(
              controller: controller,
              onSeek: (s) => seekTime = s,
              onTokenTap: (_) {},
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Active target'), findsOneWidget);

      // Tap cue card to seek
      await tester.tap(find.text('Active target'));
      expect(seekTime, equals(10.0));

      // Tap repeat button
      final repeatFinder = find.byIcon(Icons.replay_rounded);
      expect(repeatFinder, findsOneWidget);
      await tester.tap(repeatFinder);
      expect(controller.isLoopingCue.value, isTrue);
      expect(controller.loopingCue.value, equals(cue1));
    });
  });

}
