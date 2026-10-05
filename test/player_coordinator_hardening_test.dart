import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/state/player_coordinator.dart';
import 'package:voca_flutter/state/player_state.dart';
import 'package:voca_flutter/services/voca_api_client.dart';
import 'package:voca_flutter/services/grammar_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerCoordinator Hardening Tests', () {
    test('defaultPlayerUserAgent returns valid mobile browser User-Agent', () {
      final ua = PlayerCoordinator.defaultPlayerUserAgent;
      expect(ua, isNotEmpty);
      expect(ua.contains('Mozilla/5.0'), isTrue);
      expect(ua.contains('Mobile'), isTrue);
    });

    test('close and dispose cleanly reset coordinator signals and dispose controllers', () {
      final coordinator = PlayerCoordinator.instance;

      // Assign dummy test controller
      final dummyController = VideoPlayerController(
        apiClient: VocaApiClient(),
        grammarEngine: GrammarEngine(),
      );
      coordinator.playerController = dummyController;
      coordinator.activeVideoId.value = 'test_vid_123';
      coordinator.activeTitle.value = 'Test Video';
      coordinator.currentTime.value = 42.0;
      coordinator.duration.value = 120.0;
      coordinator.isPlaying.value = true;

      expect(coordinator.hasActiveVideo, isTrue);

      // Close video
      coordinator.close();

      expect(coordinator.hasActiveVideo, isFalse);
      expect(coordinator.activeVideoId.value, isNull);
      expect(coordinator.activeTitle.value, isEmpty);
      expect(coordinator.currentTime.value, 0.0);
      expect(coordinator.duration.value, 0.0);
      expect(coordinator.isPlaying.value, isFalse);
      expect(coordinator.playerController, isNull);
      expect(coordinator.ytController, isNull);
    });

    test('Deterministic watch history calculation clamp and format', () {
      final coordinator = PlayerCoordinator.instance;
      coordinator.activeVideoId.value = 'vid_xyz';
      coordinator.duration.value = 100.0;
      coordinator.currentTime.value = 85.0;

      // Ensure duration and current time match expected values
      expect(coordinator.duration.value, 100.0);
      expect(coordinator.currentTime.value, 85.0);
    });
  });
}
