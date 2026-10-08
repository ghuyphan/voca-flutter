// test/gamification_library_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/gamification_service.dart';
import 'package:voca_flutter/services/supabase_service.dart';
import 'package:voca_flutter/services/voca_api_client.dart';
import 'package:voca_flutter/state/app_state.dart';
import 'package:voca_flutter/ui/shell/main_shell.dart';
import 'package:voca_flutter/ui/library/library_screen.dart';
import 'package:voca_flutter/ui/study/study_deck_screen.dart';
import 'package:voca_flutter/ui/vocabulary/vocabulary_screen.dart';

// Simple mock for VocaApiClient
class FakeVocaApiClient extends VocaApiClient {
  @override
  Future<Map<String, dynamic>> getDiamonds() async {
    return {
      'success': true,
      'diamonds': 5,
      'maxDiamonds': 5,
    };
  }

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
    return List.generate(
      15,
      (i) => {
        'videoId': 'vid_$i',
        'title': 'Video Title $i',
        'channel': 'Creator $i',
        'duration': 272,
        'level': 'JLPT N4',
        'tier': 'elementary',
      },
    );
  }
}

// Simple mock for SupabaseService
class FakeSupabaseService extends SupabaseService {
  FakeSupabaseService() : super(SupabaseClient('https://mock.supabase.co', 'mock_anon_key'));

  @override
  User? get currentUser => null;

  @override
  Future<Map<String, dynamic>?> recordStreakActivity(DateTime date) async {
    return {'streak': 1};
  }

  @override
  Future<List<Map<String, dynamic>>> getHistory({int limit = 20}) async {
    return List.generate(
      15,
      (i) => {
        'id': 'h$i',
        'video_id': 'test_video_$i',
        'title': 'Test Japanese Lesson $i',
        'channel': 'Japanese 101',
        'duration': 300,
        'progress': 0.5,
        'language': 'ja',
        'watched_at': DateTime.now().subtract(Duration(hours: i)).toIso8601String(),
      },
    );
  }

  @override
  Future<List<PlaylistItem>> getPlaylists({String? language}) async {
    return [
      PlaylistItem(
        id: 'default_saved',
        userId: 'guest',
        title: 'Saved Videos',
        description: 'Favorites',
        language: 'all',
        videoCount: 2,
        videoIds: ['vid1', 'vid2'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<List<Flashcard>> getVocabularyCards({String? language}) async {
    return List.generate(
      25,
      (i) => Flashcard(
        id: 'card_$i',
        userId: 'test_user',
        word: 'Word $i',
        reading: 'reading $i',
        meaning: 'meaning $i',
        language: 'ja',
        level: 'N5',
        srsInterval: 1,
        srsRepetition: 1,
        srsEaseFactor: 2.5,
        srsNextReviewAt: DateTime.now(),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final fakeApi = FakeVocaApiClient();
    final fakeSupabase = FakeSupabaseService();
    AppState.instance.apiClient = fakeApi;
    AppState.instance.supabaseService = fakeSupabase;
    AppState.instance.gamificationService = GamificationService(
      apiClient: fakeApi,
      supabaseService: fakeSupabase,
    );
    await AppState.instance.initSettingsAndGamification();
  });

  group('GamificationService Unit Tests', () {
    test('Initial stats start at clean defaults', () {
      final g = AppState.instance.gamificationService;
      expect(g.currentStreak.value, 0);
      expect(g.longestStreak.value, 0);
      expect(g.streakFreezes.value, 2);
      expect(g.diamonds.value, 5);
      expect(g.xp.value, 0);
      expect(g.level.value, 1);
      expect(g.currentLevelXp.value, 0);
      expect(g.nextLevelTargetXp.value, 75);
      expect(g.achievements.value.length, 41);
    });

    test('XP and Level calculation progresses accurately', () {
      final g = AppState.instance.gamificationService;
      g.addXp(60);
      expect(g.xp.value, 60);
      expect(g.level.value, 1);
      expect(g.currentLevelXp.value, 60);
      expect(g.levelProgress.value, closeTo(0.80, 0.001));

      // Level up (75 XP threshold)
      g.addXp(50);
      expect(g.xp.value, 110);
      expect(g.level.value, 2);
      expect(g.currentLevelXp.value, 35);
      expect(g.levelProgress.value, closeTo(35.0 / 225.0, 0.001));
    });

    test('Streak activity consecutive recording and freeze protection', () async {
      final g = AppState.instance.gamificationService;
      final day1 = DateTime(2026, 10, 1);
      final day2 = DateTime(2026, 10, 2);

      await g.recordActivity(date: day1);
      expect(g.currentStreak.value, 1);
      expect(g.longestStreak.value, 1);

      // Same day activity does not duplicate streak count
      await g.recordActivity(date: day1);
      expect(g.currentStreak.value, 1);

      // Consecutive next day increases streak
      await g.recordActivity(date: day2);
      expect(g.currentStreak.value, 2);
      expect(g.longestStreak.value, 2);

      // Missed 1 day (day 4 after day 2) uses streak freeze
      final day4 = DateTime(2026, 10, 4);
      await g.recordActivity(date: day4);
      expect(g.streakFreezes.value, 1); // consumed 1 freeze
      expect(g.currentStreak.value, 3);
    });

    test('Diamonds consumption and refresh', () async {
      final g = AppState.instance.gamificationService;
      expect(g.diamonds.value, 5);

      final consumed = g.consumeDiamond(2);
      expect(consumed, true);
      expect(g.diamonds.value, 3);

      final overConsumed = g.consumeDiamond(5);
      expect(overConsumed, false);
      expect(g.diamonds.value, 3);

      await g.refreshDiamonds();
      expect(g.diamonds.value, 5);
    });

    test('Achievements update on video watched and flashcard review', () async {
      final g = AppState.instance.gamificationService;
      final firstVid = g.achievements.value.firstWhere((a) => a.id == 'watch_1');
      expect(firstVid.isUnlocked, false);

      await g.onVideoWatched();
      final updatedFirstVid = g.achievements.value.firstWhere((a) => a.id == 'watch_1');
      expect(updatedFirstVid.isUnlocked, true);
      expect(g.xp.value, greaterThan(0));

      // 10 words saved
      await g.onWordSaved(10);
      final wordsAch = g.achievements.value.firstWhere((a) => a.id == 'vocab_10');
      expect(wordsAch.isUnlocked, true);

      // 50 reviews
      await g.onCardReviewed(50);
      final srsAch = g.achievements.value.firstWhere((a) => a.id == 'srs_50');
      expect(srsAch.isUnlocked, true);
    });
  });

  group('UserSettings Serialization Tests', () {
    test('Serializes and deserializes UserSettings correctly', () {
      final settings = UserSettings(
        rubyMode: RubyDisplayMode.tap,
        subtitleSize: SubtitleSize.large,
        nativeLanguage: 'vi',
        autoPauseOnLookup: false,
        playbackRate: 1.25,
      );

      final json = settings.toJson();
      expect(json['rubyMode'], 'tap');
      expect(json['subtitleSize'], 'large');
      expect(json['nativeLanguage'], 'vi');
      expect(json['autoPauseOnLookup'], false);
      expect(json['playbackRate'], 1.25);

      final deserialized = UserSettings.fromJson(json);
      expect(deserialized.rubyMode, RubyDisplayMode.tap);
      expect(deserialized.subtitleSize, SubtitleSize.large);
      expect(deserialized.nativeLanguage, 'vi');
      expect(deserialized.autoPauseOnLookup, false);
      expect(deserialized.playbackRate, 1.25);
    });
  });

  group('MainShell Navigation Tests', () {
    testWidgets('Mobile layout has Watch, Review, Vocab, Library, and opens hubs', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShell(),
        ),
      );
      await tester.pump();

      // Mobile bottom nav destinations
      expect(find.text('Watch'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Vocab'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);

      // Tapping Review
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(find.byType(StudyDeckScreen), findsOneWidget);

      // Tapping Vocab
      await tester.tap(find.text('Vocab'));
      await tester.pumpAndSettle();
      expect(find.byType(VocabularyScreen), findsOneWidget);

      // Tapping Library opens LibraryScreen
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();

      expect(find.text('History'), findsWidgets);
      expect(find.text('Playlists'), findsWidgets);
      expect(find.byType(LibraryScreen), findsOneWidget);
    });

    testWidgets('Tablet layout (>= 720dp) has sidebar with brand, elevated + New Video, and nav items', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShell(),
        ),
      );
      await tester.pump();

      // Brand title & header
      expect(find.text('VOCA'), findsOneWidget);
      expect(find.text('+ New Video'), findsOneWidget);

      // Navigation items in sidebar
      expect(find.text('Watch'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Vocab'), findsOneWidget);
      expect(find.text('Library'), findsAtLeastNWidgets(1));

      // Bottom controls
      expect(find.text('Japanese'), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      // Tapping Library item in sidebar
      await tester.tap(find.text('Library').first);
      await tester.pumpAndSettle();
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Playlists'), findsOneWidget);

      // Tapping + New Video button in sidebar
      await tester.tap(find.text('+ New Video'));
      await tester.pumpAndSettle();
      expect(find.text('Learn from Any Video'), findsOneWidget);
    });

    testWidgets('Tapping the currently active tab in bottom nav scrolls the active view to top', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MainShell(),
        ),
      );
      await tester.pumpAndSettle();

      // Find the feed ListView in Explore tab (Watch tab is index 0)
      final feedListFinder = find.byType(ListView).last;
      expect(feedListFinder, findsOneWidget);

      final scrollableState = tester.state<ScrollableState>(
        find.descendant(of: feedListFinder, matching: find.byType(Scrollable)).first,
      );

      // Drag feed up (scrolling down)
      await tester.drag(feedListFinder, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(scrollableState.position.pixels, greaterThan(0));

      // Re-tap 'Watch' in bottom nav (already active tab)
      await tester.tap(find.text('Watch'));
      await tester.pumpAndSettle();

      // Verify that the view has smoothly scrolled back to top
      expect(scrollableState.position.pixels, equals(0.0));

      // 2. Test Vocab tab active tab scroll-to-top
      await tester.tap(find.text('Vocab'));
      await tester.pumpAndSettle();

      final vocabListFinder = find.byType(ListView).first;
      final vocabScrollable = tester.state<ScrollableState>(
        find.descendant(of: vocabListFinder, matching: find.byType(Scrollable)).first,
      );

      await tester.drag(vocabListFinder, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(vocabScrollable.position.pixels, greaterThan(0));

      // Re-tap 'Vocab' in bottom nav
      await tester.tap(find.text('Vocab'));
      await tester.pumpAndSettle();
      expect(vocabScrollable.position.pixels, equals(0.0));

      // 3. Test Library tab active tab scroll-to-top
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();

      final libraryScrollFinder = find.byType(CustomScrollView).first;
      final libraryScrollable = tester.state<ScrollableState>(
        find.descendant(of: libraryScrollFinder, matching: find.byType(Scrollable)).first,
      );

      await tester.drag(libraryScrollFinder, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(libraryScrollable.position.pixels, greaterThan(0));

      // Re-tap 'Library' in bottom nav
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      expect(libraryScrollable.position.pixels, equals(0.0));
    });
  });
}
