// test/video_player_layout_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/grammar_engine.dart';
import 'package:voca_flutter/services/voca_api_client.dart';
import 'package:voca_flutter/state/app_state.dart';
import 'package:voca_flutter/state/player_state.dart';
import 'package:voca_flutter/ui/sheets/playlist_queue_sheet.dart';
import 'package:voca_flutter/ui/sheets/practice_sheet.dart';
import 'package:voca_flutter/ui/sheets/subtitle_options_sheet.dart';
import 'package:voca_flutter/ui/video/subtitle_panel.dart';
import 'package:voca_flutter/ui/video/video_header.dart';
import 'package:voca_flutter/ui/video/video_more_feed.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class FakeYoutubeController extends Fake implements YoutubePlayerController {
  double? lastSeek;
  double? lastRate;
  bool isPlaying = false;

  @override
  Future<void> playVideo() async {
    isPlaying = true;
  }

  @override
  Future<void> pauseVideo() async {
    isPlaying = false;
  }

  @override
  Future<void> seekTo({required double seconds, bool allowSeekAhead = false}) async {
    lastSeek = seconds;
  }

  @override
  Future<void> setPlaybackRate(double rate) async {
    lastRate = rate;
  }
}

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
    return [
      {
        'videoId': 'v1',
        'title': 'Song 1',
        'channel': 'Artist 1',
      },
      {
        'videoId': 'v2',
        'title': 'Song 2',
        'channel': 'Artist 2',
      },
    ];
  }
}

void main() {
  setUpAll(() {
    AppState.instance.apiClient = FakeVocaApiClient();
    AppState.instance.grammarEngine = GrammarEngine();
  });

  late VideoPlayerController controller;
  late FakeYoutubeController ytController;

  setUp(() {
    AppState.instance.activeLanguage.value = 'ja';
    controller = VideoPlayerController(
      apiClient: AppState.instance.apiClient,
      grammarEngine: AppState.instance.grammarEngine,
    );
    ytController = FakeYoutubeController();
  });

  group('SubtitleOptionsSheet Tests', () {
    testWidgets('Renders font size options, playback speed, furigana toggle, and dual subtitles toggle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubtitleOptionsSheet(
              controller: controller,
              ytController: ytController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Font size options
      expect(find.text('Small'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Large'), findsOneWidget);

      // Playback speed options
      expect(find.text('0.75x'), findsOneWidget);
      expect(find.text('1.0x'), findsOneWidget);
      expect(find.text('1.25x'), findsOneWidget);
      expect(find.text('1.5x'), findsOneWidget);

      // Furigana toggle
      expect(find.text('Furigana'), findsOneWidget);

      // Secondary Subtitles toggle
      expect(find.text('Secondary Subtitles'), findsOneWidget);

      // Tap speed 1.25x
      await tester.tap(find.text('1.25x'));
      await tester.pumpAndSettle();
      expect(ytController.lastRate, equals(1.25));
    });
  });

  group('PracticeSheet Tests', () {
    testWidgets('Renders Shadowing mode and allows starting cue loop', (tester) async {
      final cue = SubtitleCue(
        start: 1.0,
        duration: 2.5,
        text: 'こんにちは世界',
        translation: 'Xin chào thế giới',
        tokens: [
          Token(surface: 'こんにちは', reading: 'こんにちは'),
          Token(surface: '世界', reading: 'せかい'),
        ],
      );
      controller.cues.value = [cue];
      controller.currentTime.value = 1.5; // active cue

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PracticeSheet(
              controller: controller,
              ytController: ytController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify modes
      expect(find.text('Shadowing'), findsOneWidget);
      expect(find.text('Cloze Quiz'), findsOneWidget);

      // Verify sentence display
      expect(find.text('こんにちは世界'), findsOneWidget);
      expect(find.text('Xin chào thế giới'), findsOneWidget);

      // Tap loop cue button
      await tester.tap(find.text('Loop Sentence'));
      await tester.pumpAndSettle();
      expect(controller.isLoopingCue.value, isTrue);

      // Verify inline segmented speed chips exist
      expect(find.text('0.75x'), findsOneWidget);
      expect(find.text('0.85x'), findsOneWidget);
      expect(find.text('1.0x'), findsOneWidget);
      expect(find.text('1.25x'), findsOneWidget);

      // Tap 0.85x speed chip directly
      await tester.tap(find.text('0.85x'));
      await tester.pumpAndSettle();
      expect(controller.playbackRate.value, equals(0.85));

      // Switch to Cloze Quiz tab
      await tester.tap(find.text('Cloze Quiz'));
      await tester.pumpAndSettle();
      expect(find.text('Choose the missing word in the sentence above:'), findsOneWidget);

      // When sheet is disposed, playback rate is restored to initial 1.0x
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox.shrink())));
      await tester.pumpAndSettle();
      expect(controller.playbackRate.value, equals(1.0));
    });
  });

  group('PlaylistQueueSheet Tests', () {
    testWidgets('Renders playlist videos and invokes callback on tap', (tester) async {
      String? selectedId;
      String? selectedTitle;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaylistQueueSheet(
              playlistTitle: 'Anime Hits',
              currentVideoId: 'v1',
              onSelectVideo: (id, title, index) {
                selectedId = id;
                selectedTitle = title;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Videos
      expect(find.text('Song 1'), findsOneWidget);
      expect(find.text('Song 2'), findsOneWidget);

      // Tap second video
      await tester.tap(find.text('Song 2'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(selectedId, equals('v2'));
      expect(selectedTitle, equals('Song 2'));
    });
  });

  group('VideoMoreFeed Tests', () {
    testWidgets('Renders recommended videos excluding current video and triggers onVideoTap', (tester) async {
      String? tappedId;
      String? tappedTitle;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: VideoMoreFeed(
                currentVideoId: 'v1',
                language: 'ja',
                onVideoTap: (vidId, title, channel, level) {
                  tappedId = vidId;
                  tappedTitle = title;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Current video 'v1' is filtered out
      expect(find.text('Song 1'), findsNothing);
      // 'v2' is displayed
      expect(find.text('Song 2'), findsOneWidget);

      await tester.tap(find.text('Song 2'));
      await tester.pumpAndSettle();

      expect(tappedId, equals('v2'));
      expect(tappedTitle, equals('Song 2'));
    });
  });

  group('SubtitlePanel Compact Mode Tests', () {
    testWidgets('Renders compact 3-line subtitle panel without transcript button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubtitlePanel(
              controller: controller,
              ytController: ytController,
              isCompact: true,
              onSeek: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify transcript button [Bản ghi] does NOT exist
      expect(find.text('Bản ghi'), findsNothing);
    });
  });

  group('VideoHeader Swipe Down Tests', () {
    testWidgets('Triggers onVerticalDragDown when dragged down in loaded state', (tester) async {
      bool draggedDown = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoHeader(
              title: 'Test Song',
              channel: 'Test Artist',
              videoId: 'test_123',
              onVerticalDragDown: () {
                draggedDown = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Song'), findsOneWidget);
      await tester.drag(find.text('Test Song'), const Offset(0, 100));
      await tester.pumpAndSettle();

      expect(draggedDown, isTrue);
    });

    testWidgets('Triggers onVerticalDragDown when dragged down in skeleton state', (tester) async {
      bool draggedDown = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoHeader(
              title: '',
              channel: '',
              videoId: 'test_123',
              onVerticalDragDown: () {
                draggedDown = true;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const ValueKey('skeleton_header')), findsOneWidget);
      await tester.drag(find.byKey(const ValueKey('skeleton_header')), const Offset(0, 100), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 50));

      expect(draggedDown, isTrue);
    });
  });
}

