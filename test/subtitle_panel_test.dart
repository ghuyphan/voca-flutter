// test/subtitle_panel_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/grammar_engine.dart';
import 'package:voca_flutter/services/voca_api_client.dart';
import 'package:voca_flutter/state/player_state.dart';
import 'package:voca_flutter/ui/video/subtitle_panel.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class _FakeApiClient extends Fake implements VocaApiClient {}

class _FakeGrammarEngine extends Fake implements GrammarEngine {
  @override
  List<GrammarMatch> detectPatterns(List<Token> tokens, String language) => [];
}

class FakeYoutubePlayerController extends Fake implements YoutubePlayerController {
  @override
  Future<void> pauseVideo() async {}
  @override
  Future<void> close() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoPlayerController controller;
  late FakeYoutubePlayerController ytController;

  setUp(() {
    controller = VideoPlayerController(
      apiClient: _FakeApiClient(),
      grammarEngine: _FakeGrammarEngine(),
    );
    ytController = FakeYoutubePlayerController();
  });

  Widget buildTestWidget({void Function(double)? onSeek}) {
    return MaterialApp(
      home: Scaffold(
        body: SubtitlePanel(
          controller: controller,
          ytController: ytController,
          onSeek: onSeek ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('SubtitlePanel renders 4-pill bottom toolbar buttons', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    // 1. Loop button
    expect(find.text('Lặp câu'), findsOneWidget);
    // 2. Added words button
    expect(find.text('Đã lưu'), findsOneWidget);
    // 3. Quiz button
    expect(find.text('Luyện tập'), findsOneWidget);
    // 4. Options button
    expect(find.text('Tùy chọn'), findsOneWidget);
  });

  testWidgets('SubtitlePanel renders active cue tokens with ruby and translation', (tester) async {
    final cue = SubtitleCue(
      start: 20.0,
      duration: 3.0,
      text: '只留下了一条街的眼眸',
      translation: 'Chỉ để lại một đường mắt',
      tokens: [
        Token(
          surface: '只留下',
          rubyParts: [RubyPart(text: '只留下', reading: 'zhī liú xià')],
        ),
        Token(
          surface: '一条',
          rubyParts: [RubyPart(text: '一条', reading: 'yī tiáo')],
        ),
        Token(
          surface: '街',
          rubyParts: [RubyPart(text: '街', reading: 'jiē')],
        ),
        Token(
          surface: '的',
          rubyParts: [RubyPart(text: '的', reading: 'de')],
        ),
        Token(
          surface: '眼眸',
          rubyParts: [RubyPart(text: '眼眸', reading: 'yǎnmóu')],
        ),
      ],
    );

    controller.cues.value = [cue];
    controller.currentTime.value = 21.0;

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    // Tokens rendered
    expect(find.text('只留下'), findsAtLeastNWidgets(1));
    expect(find.text('zhī liú xià'), findsOneWidget);
    expect(find.text('de'), findsOneWidget);

    // Translation rendered
    expect(find.text('Chỉ để lại một đường mắt'), findsAtLeastNWidgets(1));

    // Monospace timestamp in list
    expect(find.text('0:20'), findsOneWidget);
  });

  testWidgets('SubtitlePanel triggers onSeek callback when tapping a cue item', (tester) async {
    double? seekTarget;
    final cue1 = SubtitleCue(start: 5.0, duration: 2.0, text: 'Hello');
    final cue2 = SubtitleCue(start: 15.0, duration: 2.0, text: 'World');

    controller.cues.value = [cue1, cue2];
    controller.currentTime.value = 0.0;

    await tester.pumpWidget(buildTestWidget(
      onSeek: (seconds) => seekTarget = seconds,
    ));
    await tester.pump();

    expect(find.text('World'), findsOneWidget);
    await tester.tap(find.text('World'));
    await tester.pump();

    expect(seekTarget, equals(15.0));
  });
}
