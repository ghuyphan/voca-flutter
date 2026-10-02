// test/player_controls_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/ui/video/center_controls.dart';
import 'package:voca_flutter/ui/video/video_progress_bar.dart';
import 'package:voca_flutter/ui/video/video_bottom_bar.dart';

void main() {
  group('video_format_utils', () {
    test('formatVideoTime formats seconds correctly into m:ss and h:mm:ss', () {
      expect(formatVideoTime(null), '0:00');
      expect(formatVideoTime(-10), '0:00');
      expect(formatVideoTime(0), '0:00');
      expect(formatVideoTime(5), '0:05');
      expect(formatVideoTime(65), '1:05');
      expect(formatVideoTime(754), '12:34');
      expect(formatVideoTime(3600), '1:00:00');
      expect(formatVideoTime(3725), '1:02:05');
      // Test padMinutes
      expect(formatVideoTime(0, padMinutes: true), '00:00');
      expect(formatVideoTime(5, padMinutes: true), '00:05');
      expect(formatVideoTime(65, padMinutes: true), '01:05');
    });
  });

  group('CenterControls', () {
    testWidgets('renders play icon when paused', (tester) async {
      bool playPauseClicked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CenterControls(
              isPlaying: false,
              onPlayPause: () => playPauseClicked = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);
      expect(find.byIcon(Icons.replay_rounded), findsNothing);

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      expect(playPauseClicked, isTrue);
    });

    testWidgets('renders pause icon when playing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CenterControls(
              isPlaying: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('renders spinning loader when buffering and playing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CenterControls(
              isPlaying: true,
              isBuffering: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);
    });

    testWidgets('renders replay icon when video ended', (tester) async {
      bool replayClicked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CenterControls(
              isPlaying: false,
              isEnded: true,
              onReplay: () => replayClicked = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.replay_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.replay_rounded));
      expect(replayClicked, isTrue);
    });

    testWidgets('renders playlist prev/next buttons when hasPlaylist is true', (tester) async {
      bool prevClicked = false;
      bool nextClicked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CenterControls(
              isPlaying: true,
              hasPlaylist: true,
              canPlayPrev: true,
              canPlayNext: true,
              onPrev: () => prevClicked = true,
              onNext: () => nextClicked = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.skip_previous_rounded));
      expect(prevClicked, isTrue);

      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      expect(nextClicked, isTrue);
    });

    testWidgets('renders gesture seek preview HUD with delta calculation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CenterControls(
              isPlaying: true,
              gestureSeekActive: true,
              gestureSeekTime: 90.0,
              currentTime: 60.0,
            ),
          ),
        ),
      );

      expect(find.text('1:30'), findsOneWidget);
      expect(find.text('+0:30'), findsOneWidget);
    });

    testWidgets('renders negative delta on gesture seek preview HUD', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CenterControls(
              isPlaying: true,
              gestureSeekActive: true,
              gestureSeekTime: 45.0,
              currentTime: 60.0,
            ),
          ),
        ),
      );

      expect(find.text('0:45'), findsOneWidget);
      expect(find.text('-0:15'), findsOneWidget);
    });

    testWidgets('renders feedback pop overlay when playPauseFeedback is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CenterControls(
              isPlaying: true,
              playPauseFeedback: true,
              playPauseFeedbackIcon: Icons.play_arrow_rounded,
            ),
          ),
        ),
      );

      // Feedback pop renders icon
      expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);
    });
  });

  group('VideoProgressBar', () {
    testWidgets('renders progress bar tracks and handle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: VideoProgressBar(
                currentTime: 30.0,
                duration: 100.0,
                bufferedFraction: 0.5,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(VideoProgressBar), findsOneWidget);
    });

    testWidgets('triggers onSeekStarted, onSeekUpdate, onSeekEnded on horizontal drag', (tester) async {
      bool seekStarted = false;
      double? seekUpdated;
      double? seekEnded;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: VideoProgressBar(
                  currentTime: 0.0,
                  duration: 100.0,
                  onSeekStarted: () => seekStarted = true,
                  onSeekUpdate: (t) => seekUpdated = t,
                  onSeekEnded: (t) => seekEnded = t,
                ),
              ),
            ),
          ),
        ),
      );

      final barFinder = find.byType(VideoProgressBar);

      // Drag across bar
      await tester.timedDrag(
        barFinder,
        const Offset(60, 0),
        const Duration(milliseconds: 300),
      );
      await tester.pumpAndSettle();

      expect(seekStarted, isTrue);
      expect(seekUpdated, isNotNull);
      expect(seekEnded, isNotNull);
    });
  });

  group('VideoBottomBar', () {
    testWidgets('renders play/pause and time display with tabular figures', (tester) async {
      bool playPauseToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoBottomBar(
              isPlaying: true,
              currentTime: 65.0,
              duration: 180.0,
              onPlayPause: () => playPauseToggled = true,
            ),
          ),
        ),
      );

      // Play/Pause button (shows pause icon when playing)
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.pause_rounded));
      expect(playPauseToggled, isTrue);

      // Time display: 1:05 / 3:00
      expect(find.text('1:05'), findsOneWidget);
      expect(find.text('/'), findsOneWidget);
      expect(find.text('3:00'), findsOneWidget);
    });

    testWidgets('renders CC subtitles and Settings and Miniplayer buttons', (tester) async {
      bool ccTapped = false;
      bool settingsTapped = false;
      bool miniplayerTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoBottomBar(
              isPlaying: false,
              currentTime: 0.0,
              duration: 120.0,
              subtitlesVisible: true,
              onToggleSubtitles: () => ccTapped = true,
              onOpenSettings: () => settingsTapped = true,
              onToggleMiniplayer: () => miniplayerTapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.closed_caption_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.byIcon(Icons.picture_in_picture_alt_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.closed_caption_rounded));
      expect(ccTapped, isTrue);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      expect(settingsTapped, isTrue);

      await tester.tap(find.byIcon(Icons.picture_in_picture_alt_rounded));
      expect(miniplayerTapped, isTrue);
    });

    testWidgets('renders AI subtitle icon when isAISubtitle is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoBottomBar(
              isPlaying: true,
              isAISubtitle: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
      expect(find.byIcon(Icons.closed_caption_rounded), findsNothing);
    });

    testWidgets('renders Dual Subtitles button only when isCJKLanguage is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoBottomBar(
              isPlaying: true,
              isCJKLanguage: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.translate_rounded), findsNothing);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoBottomBar(
              isPlaying: true,
              isCJKLanguage: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.translate_rounded), findsOneWidget);
    });

    testWidgets('fullscreen button is explicitly absent per requirement', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoBottomBar(
              isPlaying: true,
              currentTime: 10.0,
              duration: 100.0,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.fullscreen_rounded), findsNothing);
      expect(find.byIcon(Icons.fullscreen_exit_rounded), findsNothing);
      expect(find.byIcon(Icons.fullscreen), findsNothing);
    });

    testWidgets('renders fullscreen button when onToggleFullscreen callback is provided', (tester) async {
      bool fullscreenTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoBottomBar(
              isPlaying: true,
              currentTime: 10.0,
              duration: 100.0,
              onToggleFullscreen: () => fullscreenTapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.fullscreen_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.fullscreen_rounded));
      expect(fullscreenTapped, isTrue);
    });
  });
}
