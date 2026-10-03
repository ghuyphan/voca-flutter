// test/playlist_and_navigation_host_test.dart

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voca_flutter/config/voca_theme.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/grammar_engine.dart';
import 'package:voca_flutter/services/supabase_service.dart';
import 'package:voca_flutter/services/voca_api_client.dart';
import 'package:voca_flutter/state/app_state.dart';
import 'package:voca_flutter/state/player_coordinator.dart';
import 'package:voca_flutter/ui/sheets/playlist_queue_sheet.dart';
import 'package:voca_flutter/ui/video/playlist/mobile_playlist_bar.dart';
import 'package:voca_flutter/ui/video/video_navigation_host.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class _FakeVocaApiClient extends VocaApiClient {}

class _FakeSupabaseService extends SupabaseService {
  _FakeSupabaseService()
      : super(SupabaseClient('https://mock.supabase.co', 'mock_anon_key'));
  @override
  User? get currentUser => null;
}

class _FakeYoutubePlayerController extends Fake implements YoutubePlayerController {
  final StreamController<YoutubeVideoState> _videoStateCtrl =
      StreamController<YoutubeVideoState>.broadcast();

  @override
  Stream<YoutubeVideoState> get videoStateStream => _videoStateCtrl.stream;

  final StreamController<YoutubePlayerValue> _valueCtrl =
      StreamController<YoutubePlayerValue>.broadcast();

  @override
  StreamSubscription<YoutubePlayerValue> listen(
      void Function(YoutubePlayerValue event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _valueCtrl.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  YoutubeMetaData get metadata => const YoutubeMetaData(duration: Duration(seconds: 180));

  @override
  Future<void> loadVideoById({required String videoId, double? startSeconds, double? endSeconds}) async {}

  @override
  Future<void> cueVideoById({required String videoId, double? startSeconds, double? endSeconds}) async {}

  @override
  Future<void> playVideo() async {}

  @override
  Future<void> pauseVideo() async {}

  @override
  Future<void> close() async {}
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpRequest();
}

class _FakeHttpRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _FakeHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _FakeHttpResponse();
}

class _FakeHttpHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _FakeHttpResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream.value(kTransparentImage).listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}

final Uint8List kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
    AppState.instance.apiClient = _FakeVocaApiClient();
    AppState.instance.supabaseService = _FakeSupabaseService();
    AppState.instance.grammarEngine = GrammarEngine();
  });

  group('MobilePlaylistBar Tests', () {
    testWidgets('renders playlist badge, title, count, and chevron', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const Scaffold(
            body: MobilePlaylistBar(
              title: 'J-Pop Immersion Essentials',
              currentIndex: 2,
              totalVideos: 10,
              isOwner: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.playlist_play_rounded), findsOneWidget);
      expect(find.text('J-Pop Immersion Essentials'), findsOneWidget);
      expect(find.text('Curated • 3 / 10'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
    });

    testWidgets('displays You when isOwner is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const Scaffold(
            body: MobilePlaylistBar(
              title: 'My Custom List',
              currentIndex: 0,
              totalVideos: 5,
              isOwner: true,
            ),
          ),
        ),
      );

      expect(find.text('My Custom List'), findsOneWidget);
      expect(find.text('You • 1 / 5'), findsOneWidget);
    });
  });

  group('PlayerCoordinator Playlist Logic', () {
    final coordinator = PlayerCoordinator.instance;

    setUp(() {
      coordinator.close();
      coordinator.testYtController = _FakeYoutubePlayerController();
    });

    test('initializes playlist, navigates next and previous with loop boundary', () {
      final sampleVideos = [
        const PlaylistVideo(
          videoId: 'vid1',
          title: 'Video 1',
          thumbnail: 'https://img.youtube.com/vi/vid1/hqdefault.jpg',
        ),
        const PlaylistVideo(
          videoId: 'vid2',
          title: 'Video 2',
          thumbnail: 'https://img.youtube.com/vi/vid2/hqdefault.jpg',
        ),
        const PlaylistVideo(
          videoId: 'vid3',
          title: 'Video 3',
          thumbnail: 'https://img.youtube.com/vi/vid3/hqdefault.jpg',
        ),
      ];

      coordinator.openVideo(
        null,
        videoId: 'vid1',
        title: 'Video 1',
        playlist: sampleVideos,
        playlistTitle: 'Awesome Playlist',
        playlistIndex: 0,
      );

      expect(coordinator.hasPlaylist, isTrue);
      expect(coordinator.playlistTotal, 3);
      expect(coordinator.activePlaylistIndex.value, 0);
      expect(coordinator.canPlayPrev, isFalse);
      expect(coordinator.canPlayNext, isTrue);

      // Advance next
      coordinator.playNext();
      expect(coordinator.activePlaylistIndex.value, 1);
      expect(coordinator.activeVideoId.value, 'vid2');
      expect(coordinator.canPlayPrev, isTrue);
      expect(coordinator.canPlayNext, isTrue);

      // Advance to last
      coordinator.playNext();
      expect(coordinator.activePlaylistIndex.value, 2);
      expect(coordinator.activeVideoId.value, 'vid3');
      expect(coordinator.canPlayNext, isFalse);

      // Toggle loop -> canPlayNext becomes true at end of playlist
      coordinator.toggleLoop();
      expect(coordinator.isLooping.value, isTrue);
      expect(coordinator.canPlayNext, isTrue);

      coordinator.playNext();
      expect(coordinator.activePlaylistIndex.value, 0);
      expect(coordinator.activeVideoId.value, 'vid1');
    });

    test('toggling shuffle shuffles videos while retaining current active video', () {
      final sampleVideos = List.generate(
        10,
        (i) => PlaylistVideo(
          videoId: 'vid_$i',
          title: 'Video $i',
          thumbnail: 'thumb_$i',
        ),
      );

      coordinator.openVideo(
        null,
        videoId: 'vid_4',
        title: 'Video 4',
        playlist: sampleVideos,
        playlistIndex: 4,
      );

      coordinator.toggleShuffle();
      expect(coordinator.isShuffled.value, isTrue);
      expect(coordinator.playlistVideos.value.length, 10);
      expect(coordinator.activeVideoId.value, 'vid_4');

      // Unshuffle restores original order
      coordinator.toggleShuffle();
      expect(coordinator.isShuffled.value, isFalse);
      expect(coordinator.playlistVideos.value.first.videoId, 'vid_0');
      expect(coordinator.playlistVideos.value.last.videoId, 'vid_9');
    });
  });

  group('PlaylistQueueSheet Widget Tests', () {
    testWidgets('renders all playlist videos, title, and action buttons', (tester) async {
      final sampleVideos = [
        {
          'videoId': 'v1',
          'title': 'First Anime Track',
          'thumbnail': 'https://img.youtube.com/vi/v1/hqdefault.jpg',
          'channel': 'Anime Channel',
        },
        {
          'videoId': 'v2',
          'title': 'Second Anime Track',
          'thumbnail': 'https://img.youtube.com/vi/v2/hqdefault.jpg',
          'channel': 'Anime Channel',
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: Scaffold(
            body: PlaylistQueueSheet(
              playlistTitle: 'My Anime OSTs',
              currentVideoId: 'v1',
              currentIndex: 0,
              totalCount: 2,
              initialVideos: sampleVideos,
              onSelectVideo: (vid, title, idx) {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('First Anime Track'), findsOneWidget);
      expect(find.text('Second Anime Track'), findsOneWidget);
      expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
      expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
    });
  });

  group('VideoNavigationHost Stack Tests', () {
    final coordinator = PlayerCoordinator.instance;

    setUp(() {
      coordinator.close();
    });

    testWidgets('renders only child when no video is active', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const VideoNavigationHost(
            child: Text('Underlying App Screen'),
          ),
        ),
      );

      expect(find.text('Underlying App Screen'), findsOneWidget);
      expect(find.byType(MobilePlaylistBar), findsNothing);
    });

    testWidgets('renders docked MiniplayerBar at specified bottomNavHeight when minimized', (tester) async {
      coordinator.activeVideoId.value = 'dummy_vid';
      coordinator.activeTitle.value = 'Dummy Title';
      coordinator.activeChannel.value = 'Test Channel';
      coordinator.isMiniplayer.value = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const Scaffold(
            body: VideoNavigationHost(
              bottomNavHeight: 80.0,
              child: Text('Main Screen Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Main Screen Content'), findsOneWidget);
      expect(find.text('Dummy Title'), findsOneWidget);
      expect(find.text('Test Channel'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });
}
