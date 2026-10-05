// test/study_and_vocabulary_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voca_flutter/config/voca_theme.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/gamification_service.dart';
import 'package:voca_flutter/services/srs_service.dart';
import 'package:voca_flutter/services/supabase_service.dart';
import 'package:voca_flutter/services/voca_api_client.dart';
import 'package:voca_flutter/state/app_state.dart';
import 'package:voca_flutter/ui/study/study_deck_screen.dart';
import 'package:voca_flutter/ui/vocabulary/vocabulary_screen.dart';
import 'package:voca_flutter/ui/vocabulary/word_detail_sheet.dart';

class FakeVocaApiClient extends VocaApiClient {
  @override
  Future<Map<String, dynamic>> getDiamonds() async {
    return {'success': true, 'diamonds': 5, 'maxDiamonds': 5};
  }
}

class FakeSupabaseService extends SupabaseService {
  FakeSupabaseService() : super(SupabaseClient('https://mock.supabase.co', 'mock_anon_key'));

  final List<Flashcard> mockCards = [
    Flashcard(
      id: 'mock_1',
      userId: 'u1',
      word: '食べる',
      reading: 'たべる',
      meaning: 'to eat',
      language: 'ja',
      level: 'learning',
      contextSentence: '毎日美味しいご飯を食べる。',
      contextTranslation: 'Eat delicious meals every day.',
      srsInterval: 1,
      srsRepetition: 1,
      srsEaseFactor: 2.5,
      srsNextReviewAt: DateTime.now().subtract(const Duration(hours: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Flashcard(
      id: 'mock_2',
      userId: 'u1',
      word: '約束',
      reading: 'やくそく',
      meaning: 'promise',
      language: 'ja',
      level: 'mastered',
      contextSentence: '友達との約束を守る。',
      contextTranslation: 'Keep promise with friend.',
      srsInterval: 14,
      srsRepetition: 4,
      srsEaseFactor: 2.6,
      srsNextReviewAt: DateTime.now().subtract(const Duration(hours: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Flashcard(
      id: 'mock_3',
      userId: 'u1',
      word: '美しい',
      reading: 'うつくしい',
      meaning: 'beautiful',
      language: 'ja',
      level: 'new',
      contextSentence: '美しい景色を見る。',
      contextTranslation: 'Look at the beautiful scenery.',
      srsInterval: 0,
      srsRepetition: 0,
      srsEaseFactor: 2.5,
      srsNextReviewAt: DateTime.now().subtract(const Duration(hours: 3)),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Flashcard(
      id: 'mock_4',
      userId: 'u1',
      word: '走る',
      reading: 'はしる',
      meaning: 'to run',
      language: 'ja',
      level: 'learning',
      contextSentence: '公園を走る。',
      contextTranslation: 'Run in the park.',
      srsInterval: 2,
      srsRepetition: 1,
      srsEaseFactor: 2.5,
      srsNextReviewAt: DateTime.now().subtract(const Duration(hours: 4)),
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  @override
  User? get currentUser => null;

  @override
  Future<List<Flashcard>> getVocabularyCards({String? language}) async {
    return List.from(mockCards);
  }

  @override
  Future<void> upsertVocabularyCard(Flashcard card) async {
    final idx = mockCards.indexWhere((c) => c.id == card.id);
    if (idx >= 0) {
      mockCards[idx] = card;
    } else {
      mockCards.add(card);
    }
  }

  @override
  Future<void> deleteVocabularyCard(String id) async {
    mockCards.removeWhere((c) => c.id == id);
  }

  @override
  Future<Map<String, dynamic>?> recordStreakActivity(DateTime date) async {
    return {'streak': 1};
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
    AppState.instance.activeLanguage.value = 'ja';
  });

  group('Flashcard Model & Serialization Tests', () {
    test('Flashcard serializes and deserializes optional rich fields', () {
      final now = DateTime(2026, 10, 1, 12, 0, 0);
      final card = Flashcard(
        id: 'test_card_1',
        userId: 'user_1',
        word: '食べる',
        reading: 'たべる',
        romanization: 'taberu',
        meaning: 'to eat',
        language: 'ja',
        level: 'learning',
        partOfSpeech: 'verb',
        contextSentence: '毎日美味しいご飯を食べる。',
        contextTranslation: 'Eat delicious food every day.',
        audio: 'https://example.com/taberu.mp3',
        notes: 'Frequent JLPT N5 verb',
        srsInterval: 2,
        srsRepetition: 1,
        srsEaseFactor: 2.5,
        srsNextReviewAt: now.add(const Duration(days: 2)),
        srsLastReviewedAt: now,
        createdAt: now.subtract(const Duration(days: 1)),
      );

      final json = card.toJson();
      expect(json['word'], equals('食べる'));
      expect(json['part_of_speech'], equals('verb'));
      expect(json['context_sentence'], equals('毎日美味しいご飯を食べる。'));
      expect(json['context_translation'], equals('Eat delicious food every day.'));
      expect(json['notes'], equals('Frequent JLPT N5 verb'));

      final baseJson = card.toBaseJson();
      expect(baseJson.containsKey('part_of_speech'), isFalse);
      expect(baseJson.containsKey('context_sentence'), isFalse);
      expect(baseJson['word'], equals('食べる'));

      final restored = Flashcard.fromJson(json);
      expect(restored.word, equals('食べる'));
      expect(restored.partOfSpeech, equals('verb'));
      expect(restored.contextSentence, equals('毎日美味しいご飯を食べる。'));
      expect(restored.contextTranslation, equals('Eat delicious food every day.'));
    });

    test('Flashcard.copyWith updates fields correctly', () {
      final now = DateTime.now();
      final card = Flashcard(
        id: 'c1',
        userId: 'u1',
        word: '約束',
        meaning: 'promise',
        language: 'ja',
        srsNextReviewAt: now,
      );

      final updated = card.copyWith(
        level: 'mastered',
        srsInterval: 15,
        partOfSpeech: 'noun',
      );

      expect(updated.id, equals('c1'));
      expect(updated.word, equals('約束'));
      expect(updated.level, equals('known'));
      expect(updated.srsInterval, equals(15));
      expect(updated.partOfSpeech, equals('noun'));
    });
  });

  group('SM-2 Spaced Repetition Interval Badge Calculations', () {
    test('Calculates expected intervals for Again, Hard, Good, Easy', () {
      const currentRep = 1;
      const currentInt = 1;
      const currentEase = 2.5;

      // Again
      final againRes = SpacedRepetitionService.calculateNextReview(
        rating: SRSReviewRating.again,
        currentRepetitions: currentRep,
        currentInterval: currentInt,
        currentEaseFactor: currentEase,
      );
      expect(againRes.interval, equals(0));
      expect(againRes.repetition, equals(0));

      // Hard
      final hardRes = SpacedRepetitionService.calculateNextReview(
        rating: SRSReviewRating.hard,
        currentRepetitions: currentRep,
        currentInterval: currentInt,
        currentEaseFactor: currentEase,
      );
      expect(hardRes.interval, equals(1));
      expect(hardRes.repetition, equals(2));

      // Good
      final goodRes = SpacedRepetitionService.calculateNextReview(
        rating: SRSReviewRating.good,
        currentRepetitions: currentRep,
        currentInterval: currentInt,
        currentEaseFactor: currentEase,
      );
      expect(goodRes.interval, equals(6));
      expect(goodRes.repetition, equals(2));

      // Easy
      final easyRes = SpacedRepetitionService.calculateNextReview(
        rating: SRSReviewRating.easy,
        currentRepetitions: currentRep,
        currentInterval: currentInt,
        currentEaseFactor: currentEase,
      );
      expect(easyRes.interval, equals(8));
      expect(easyRes.repetition, equals(2));
      expect(easyRes.easeFactor, greaterThan(currentEase));
    });
  });

  group('Vocabulary Filtering and Sorting Logic', () {
    final now = DateTime(2026, 10, 1, 10, 0, 0);
    final cards = [
      Flashcard(
        id: '1',
        userId: 'u1',
        word: '食べる',
        meaning: 'to eat',
        language: 'ja',
        level: 'learning',
        srsInterval: 2,
        srsNextReviewAt: now,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Flashcard(
        id: '2',
        userId: 'u1',
        word: '約束',
        meaning: 'promise',
        language: 'ja',
        level: 'mastered',
        srsInterval: 14,
        srsNextReviewAt: now,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Flashcard(
        id: '3',
        userId: 'u1',
        word: '美しい',
        meaning: 'beautiful',
        language: 'ja',
        level: 'new',
        srsInterval: 0,
        srsNextReviewAt: now,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    test('Filters by status tab', () {
      final newCards = cards.where((c) => c.level == 'new').toList();
      expect(newCards.length, equals(1));
      expect(newCards.first.word, equals('美しい'));

      final learningCards = cards.where((c) => c.level == 'learning').toList();
      expect(learningCards.length, equals(1));
      expect(learningCards.first.word, equals('食べる'));

      final masteredCards = cards.where((c) => c.level == 'known').toList();
      expect(masteredCards.length, equals(1));
      expect(masteredCards.first.word, equals('約束'));
    });

    test('Searches by word and meaning', () {
      const queryWord = '約';
      final matchWord = cards.where((c) => c.word.contains(queryWord)).toList();
      expect(matchWord.length, equals(1));
      expect(matchWord.first.word, equals('約束'));

      const queryMeaning = 'eat';
      final matchMeaning = cards.where((c) => c.meaning.contains(queryMeaning)).toList();
      expect(matchMeaning.length, equals(1));
      expect(matchMeaning.first.word, equals('食べる'));
    });

    test('Sorts by date added and interval', () {
      final sortedByDate = List<Flashcard>.from(cards)
        ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
      expect(sortedByDate.first.word, equals('美しい')); // 1 day ago (most recent)
      expect(sortedByDate.last.word, equals('約束')); // 5 days ago

      final sortedByInterval = List<Flashcard>.from(cards)
        ..sort((a, b) => b.srsInterval.compareTo(a.srsInterval));
      expect(sortedByInterval.first.word, equals('約束')); // 14 days
      expect(sortedByInterval.last.word, equals('美しい')); // 0 days
    });
  });

  group('StudyDeckScreen Widget & Responsive Layout Tests', () {
    testWidgets('StudyDeckScreen renders on mobile and handles card flip to reveal SM-2 buttons', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const StudyDeckScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Sliding Segmented Mode Selector (Flashcard, Cloze, Quiz)
      expect(find.text('Flashcard'), findsOneWidget);
      expect(find.text('Cloze'), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);

      await tester.pumpAndSettle();

      // Verify Show Answer button is initially visible
      expect(find.text('Show Answer'), findsOneWidget);

      // Tap Show Answer to reveal back
      await tester.tap(find.text('Show Answer'));
      await tester.pumpAndSettle();

      // SM-2 rating buttons should appear: Again, Hard, Good, Easy
      expect(find.text('Again'), findsOneWidget);
      expect(find.text('Hard'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Easy'), findsOneWidget);

      // Verify interval badge <10m
      expect(find.text('<10m'), findsOneWidget);
    });

    testWidgets('StudyDeckScreen on tablet (width >= 720) centers content with max width 600', (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const StudyDeckScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find ConstrainedBox in body
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(find.byType(ConstrainedBox));
      final has600MaxWidth = constrainedBoxes.any((box) => box.constraints.maxWidth == 600.0);
      expect(has600MaxWidth, isTrue);
    });

    testWidgets('StudyDeckScreen switches to Cloze mode and Quiz mode', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const StudyDeckScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpAndSettle();

      // Tap Cloze mode pill
      await tester.tap(find.text('Cloze'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('CLOZE TEST'), findsAtLeastNWidgets(1));
      expect(find.text('Reveal Word & Context'), findsOneWidget);

      // Tap Quiz mode pill
      await tester.tap(find.text('Quiz'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Choose the correct definition:'), findsOneWidget);
    });
  });

  group('VocabularyScreen Widget & Responsive Layout Tests', () {
    testWidgets('VocabularyScreen on mobile renders 1-column list', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const VocabularyScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(VocabularyScreen), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(GridView), findsNothing);

      // Verify filter tabs
      expect(find.text('All'), findsWidgets);
      expect(find.text('New'), findsWidgets);
      expect(find.text('Learning'), findsWidgets);
      expect(find.text('Known'), findsWidgets);
    });

    testWidgets('VocabularyScreen on tablet (width >= 720) renders 2-column GridView', (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const VocabularyScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(VocabularyScreen), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('WordDetailSheet Widget Tests', () {
    testWidgets('WordDetailSheet displays word information, definitions, and SM-2 stats', (tester) async {
      final now = DateTime(2026, 10, 1);
      final card = Flashcard(
        id: 'test_c',
        userId: 'u1',
        word: '食べる',
        reading: 'たべる',
        meaning: 'to eat, to consume',
        language: 'ja',
        level: 'learning',
        partOfSpeech: 'verb',
        contextSentence: '美味しいご飯を食べる。',
        contextTranslation: 'Eat delicious food.',
        srsInterval: 3,
        srsRepetition: 2,
        srsEaseFactor: 2.5,
        srsNextReviewAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: Scaffold(
            body: WordDetailSheet(card: card),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('食べる'), findsOneWidget);
      expect(find.text('たべる'), findsOneWidget);
      expect(find.text('DEFINITIONS'), findsOneWidget);
      expect(find.text('to eat, to consume'), findsOneWidget);
      expect(find.text('VIDEO CONTEXT SENTENCE'), findsOneWidget);
      expect(find.text('美味しいご飯を食べる。'), findsOneWidget);
      expect(find.text('SPACED REPETITION (SM-2) STATS'), findsOneWidget);
      expect(find.text('Repetitions'), findsOneWidget);
      expect(find.text('Current Interval'), findsOneWidget);
      expect(find.text('SET MASTERY STAGE'), findsOneWidget);
      expect(find.text('Mark as Mastered'), findsOneWidget);
    });
  });
}
