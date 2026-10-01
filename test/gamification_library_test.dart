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
    return [
      {
        'id': 'h1',
        'video_id': 'test_video_1',
        'title': 'Test Japanese Lesson',
        'channel': 'Japanese 101',
        'duration': 300,
        'progress': 0.5,
        'language': 'ja',
        'watched_at': DateTime.now().toIso8601String(),
      }
    ];
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
    return [];
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
      expect(g.nextLevelTargetXp.value, 100);
      expect(g.achievements.value.length, 4);
    });

    test('XP and Level calculation progresses accurately', () {
      final g = AppState.instance.gamificationService;
      g.addXp(60);
      expect(g.xp.value, 60);
      expect(g.level.value, 1);
      expect(g.currentLevelXp.value, 60);
      expect(g.levelProgress.value, closeTo(0.60, 0.001));

      // Level up
      g.addXp(50);
      expect(g.xp.value, 110);
      expect(g.level.value, 2);
      expect(g.currentLevelXp.value, 10);
      expect(g.levelProgress.value, closeTo(0.10, 0.001));
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
      final firstVid = g.achievements.value.firstWhere((a) => a.id == 'first_video');
      expect(firstVid.isUnlocked, false);

      await g.onVideoWatched();
      final updatedFirstVid = g.achievements.value.firstWhere((a) => a.id == 'first_video');
      expect(updatedFirstVid.isUnlocked, true);
      expect(g.xp.value, greaterThan(0));

      // 10 words saved
      await g.onWordSaved(10);
      final wordsAch = g.achievements.value.firstWhere((a) => a.id == 'words_10');
      expect(wordsAch.isUnlocked, true);

      // Vocab Master 50 reviews
      await g.onCardReviewed(50);
      final vocabMasterAch = g.achievements.value.firstWhere((a) => a.id == 'vocab_master');
      expect(vocabMasterAch.isUnlocked, true);
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
    testWidgets('Mobile layout has Watch, Review, +, Vocab, More, and opens sheets', (tester) async {
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
      expect(find.byKey(const Key('bottom-nav__item--create')), findsOneWidget);
      expect(find.text('Vocab'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);

      // Tapping Review
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(find.text('SRS Study Deck'), findsOneWidget);

      // Tapping Vocab
      await tester.tap(find.text('Vocab'));
      await tester.pumpAndSettle();
      expect(find.text('Vocabulary Notebook'), findsOneWidget);

      // Tapping Center + New Video button opens NewVideoSheet
      await tester.tap(find.byKey(const Key('bottom-nav__item--create')));
      await tester.pumpAndSettle();
      expect(find.text('Learn from Any Video'), findsOneWidget);
      expect(find.text('Start Learning'), findsOneWidget);

      // Dismiss NewVideoSheet
      await tester.tap(find.text('Start Learning'));
      await tester.pumpAndSettle();
      // Should show validation error for empty input
      expect(find.text('Please enter a YouTube link or video ID'), findsOneWidget);

      // Close NewVideoSheet
      Navigator.of(tester.element(find.text('Learn from Any Video'))).pop();
      await tester.pumpAndSettle();

      // Tapping More opens MoreSheet
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();

      expect(find.text('Day Streak'), findsOneWidget);
      expect(find.text('Level'), findsOneWidget);
      expect(find.text('AI Credits'), findsOneWidget);
      expect(find.text('Playlists'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Account & Profile'), findsOneWidget);

      // Tapping Playlists from More
      await tester.tap(find.text('Playlists'));
      await tester.pumpAndSettle();
      expect(find.text('Playlists / Saved'), findsOneWidget);
    });

    testWidgets('Tablet layout (>= 720dp) has sidebar with brand, elevated + New Video, nav items, and bottom stats', (tester) async {
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
      expect(find.text('Playlists'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);

      // Bottom controls
      expect(find.text('🇯🇵 Japanese'), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      // Tapping History item in sidebar
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('Watch History'), findsOneWidget);

      // Tapping Playlists item in sidebar
      await tester.tap(find.text('Playlists'));
      await tester.pumpAndSettle();
      expect(find.text('Playlists / Saved'), findsOneWidget);

      // Tapping + New Video button in sidebar
      await tester.tap(find.text('+ New Video'));
      await tester.pumpAndSettle();
      expect(find.text('Learn from Any Video'), findsOneWidget);
    });
  });
}
