// test/video_immersion_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/grammar_engine.dart';
import 'package:voca_flutter/services/voca_api_client.dart';
import 'package:voca_flutter/state/player_state.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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
}
