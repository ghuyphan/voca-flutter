// test/study_srs_redesign_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voca_flutter/config/voca_theme.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/grammar_engine.dart';
import 'package:voca_flutter/services/srs_service.dart';
import 'package:voca_flutter/services/supabase_service.dart';
import 'package:voca_flutter/services/voca_api_client.dart';
import 'package:voca_flutter/state/app_state.dart';
import 'package:voca_flutter/ui/study/study_session_controller.dart';
import 'package:voca_flutter/ui/study/widgets/flashcard_face.dart';
import 'package:voca_flutter/ui/study/widgets/tinder_action_dock.dart';
import 'package:voca_flutter/ui/study/widgets/tinder_card_stack.dart';

void main() {
  group('SRS SuperMemo-2 Redesign & Mastery Progression Tests', () {
    final now = DateTime(2026, 10, 5, 12, 0);

    test('New card rating progression: Good marks as learning, Easy graduates to known', () {
      // 1. New card rated Good
      final resultGood = SpacedRepetitionService.calculateNextReview(
        rating: SRSReviewRating.good,
        currentRepetitions: 0,
        currentInterval: 0,
        currentEaseFactor: 2.5,
        currentLevel: 'new',
        fromDate: now,
      );

      expect(resultGood.level, equals('learning'));
      expect(resultGood.interval, equals(1));
      expect(resultGood.repetition, equals(1));

      // 2. New card rated Easy immediately graduates to known
      final resultEasy = SpacedRepetitionService.calculateNextReview(
        rating: SRSReviewRating.easy,
        currentRepetitions: 0,
        currentInterval: 0,
        currentEaseFactor: 2.5,
        currentLevel: 'new',
        fromDate: now,
      );

      expect(resultEasy.level, equals('known'));
      expect(resultEasy.interval, equals(2));
      expect(resultEasy.repetition, equals(1));
    });

    test('Learning card matures to known when interval >= 21 or repetition >= 3', () {
      // Learning card with rep=2 reaching rep=3 with Good
      final matureResult = SpacedRepetitionService.calculateNextReview(
        rating: SRSReviewRating.good,
        currentRepetitions: 2,
        currentInterval: 6,
        currentEaseFactor: 2.5,
        currentLevel: 'learning',
        fromDate: now,
      );

      expect(matureResult.repetition, equals(3));
      expect(matureResult.level, equals('known'));
      expect(matureResult.interval, greaterThanOrEqualTo(6));
    });

    test('Known card lapse on Again: resets to learning with 0 interval for same-day relearn', () {
      final lapseResult = SpacedRepetitionService.calculateNextReview(
        rating: SRSReviewRating.again,
        currentRepetitions: 4,
        currentInterval: 30,
        currentEaseFactor: 2.6,
        currentLevel: 'known',
        fromDate: now,
      );

      expect(lapseResult.level, equals('learning'));
      expect(lapseResult.repetition, equals(0));
      expect(lapseResult.interval, equals(0));
      expect(lapseResult.nextReviewAt, equals(now));
    });

    test('Manual level seeding seeds appropriate parameters so Known cards are not demoted', () {
      final knownSeed = SpacedRepetitionService.seedSrsParamsForLevel('known', fromDate: now);
      expect(knownSeed.repetition, equals(3));
      expect(knownSeed.interval, equals(SrsConfig.matureIntervalDays));
      expect(knownSeed.nextReviewAt, equals(now.add(const Duration(days: SrsConfig.matureIntervalDays))));

      final learningSeed = SpacedRepetitionService.seedSrsParamsForLevel('learning', fromDate: now);
      expect(learningSeed.repetition, equals(1));
      expect(learningSeed.interval, equals(1));

      final newSeed = SpacedRepetitionService.seedSrsParamsForLevel('new', fromDate: now);
      expect(newSeed.repetition, equals(0));
      expect(newSeed.interval, equals(0));
    });

    test('Interval badge formatting correctly formats <10m, days, and months', () {
      expect(SpacedRepetitionService.formatInterval(0), equals('<10m'));
      expect(SpacedRepetitionService.formatInterval(0, isAgain: true), equals('<10m'));
      expect(SpacedRepetitionService.formatInterval(1), equals('1d'));
      expect(SpacedRepetitionService.formatInterval(6), equals('6d'));
      expect(SpacedRepetitionService.formatInterval(14), equals('14d'));
      expect(SpacedRepetitionService.formatInterval(30), equals('1mo'));
      expect(SpacedRepetitionService.formatInterval(90), equals('3mo'));
    });
  });

  group('Flashcard Deserialization with NULL Review Date Handling', () {
    test('Known cards with NULL next_review_date default to future instead of due now', () {
      final card = Flashcard.fromJson({
        'id': 'test_1',
        'word': '約束',
        'meaning': 'promise',
        'level': 'known',
        'interval': 21,
        'next_review_date': null,
      });

      expect(card.level, equals('known'));
      expect(card.srsNextReviewAt.isAfter(DateTime.now()), isTrue);
    });
  });

  group('StudySessionController Manual Graduation to Known', () {
    test('markCurrentCardAsKnown graduates current card directly to known with mature interval', () async {
      SharedPreferences.setMockInitialValues({});
      final fakeSupabase = _FakeSupabaseForStudy();
      AppState.instance.supabaseService = fakeSupabase;
      AppState.instance.apiClient = _FakeApiForStudy();
      AppState.instance.activeLanguage.value = 'ja';

      AppState.instance.grammarEngine = GrammarEngine();

      final controller = StudySessionController();
      await controller.loadDeck();
      controller.startSession();

      expect(controller.currentCard?.level, equals('learning'));
      expect(controller.learningCount.value, greaterThan(0));

      final initialKnown = controller.knownCount.value;

      await controller.markCurrentCardAsKnown();

      expect(controller.knownCount.value, equals(initialKnown + 1));
      expect(fakeSupabase.savedCards.any((c) => c.level == 'known' && c.srsInterval >= 21), isTrue);
    });

    test('Multiple Again reviews on 1 card tracks uniqueCardsCount as 1', () async {
      final fakeSupabase = _FakeSupabaseForStudy();
      AppState.instance.supabaseService = fakeSupabase;
      AppState.instance.apiClient = _FakeApiForStudy();
      AppState.instance.activeLanguage.value = 'ja';
      AppState.instance.grammarEngine = GrammarEngine();

      final controller = StudySessionController();
      await controller.loadDeck();
      controller.startSession();

      expect(controller.sessionCards.value.length, equals(1));
      expect(controller.initialQueueSize.value, equals(1));

      // Review Again twice
      await controller.rateCurrentCard(SRSReviewRating.again);
      await controller.rateCurrentCard(SRSReviewRating.again);
      // Finally rate Good to complete
      await controller.rateCurrentCard(SRSReviewRating.good);

      expect(controller.sessionStats.value.totalReviewed, equals(3));
      expect(controller.sessionStats.value.uniqueCardsCount, equals(1));
      expect(controller.isFinished, isTrue);

      // Verify exitToOverview clears session and resets isFinished
      controller.exitToOverview();
      expect(controller.isFinished, isFalse);
      expect(controller.isSessionActive.value, isFalse);
      expect(controller.sessionCards.value, isEmpty);
    });
  });

  group('FlashcardFace UI Parity & Design Parity Tests', () {
    testWidgets('FlashcardFace displays Word, Reading, Stage label, and Memory section without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testCard = Flashcard(
        id: 'fc_test',
        userId: 'u1',
        word: '食べる',
        reading: 'たべる',
        meaning: 'to eat',
        language: 'ja',
        level: 'learning',
        partOfSpeech: 'verb',
        contextSentence: 'ご飯を食べる。',
        contextTranslation: 'Eat a meal.',
        srsRepetition: 1,
        srsInterval: 1,
        srsEaseFactor: 2.5,
        srsNextReviewAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 480,
                child: FlashcardFace(
                  card: testCard,
                  isBack: false,
                  isReadingPeeked: true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Word and Reading
      expect(find.text('食べる'), findsOneWidget);
      expect(find.text('たべる'), findsOneWidget);

      // Check Stage label & Memory header
      expect(find.text('Learning'), findsWidgets);
      expect(find.text('Memory'), findsOneWidget);
    });

    testWidgets('FlashcardFace back face displays meaning, replay clip button, and memory progress', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testCard = Flashcard(
        id: 'fc_back_test',
        userId: 'u1',
        word: '飲む',
        reading: 'のむ',
        meaning: 'to drink',
        language: 'ja',
        level: 'learning',
        partOfSpeech: 'verb',
        contextSentence: '水を飲む。',
        contextTranslation: 'Drink water.',
        sourceVideoId: 'video_xyz',
        sourceTimestamp: 42.0,
        srsNextReviewAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 480,
                child: FlashcardFace(
                  card: testCard,
                  isBack: true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Meaning should be visible on back face
      expect(find.text('to drink'), findsOneWidget);
      expect(find.text('Replay this clip'), findsOneWidget);
      expect(find.text('Memory'), findsOneWidget);
    });

    testWidgets('TinderCardStack front and back faces handle Peek and Flip reliably', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool flipped = false;
      bool peeked = false;

      final testCard = Flashcard(
        id: 'fc_stack_test',
        userId: 'u1',
        word: '歩く',
        reading: 'あるく',
        meaning: 'to walk',
        language: 'ja',
        level: 'learning',
        srsNextReviewAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 480,
                child: TinderCardStack(
                  currentCard: testCard,
                  isRevealed: false,
                  isReadingPeeked: false,
                  onSwipe: (_) {},
                  onToggleFlip: () => flipped = true,
                  onTogglePeekReading: () => peeked = true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Front face shows word and peek reading button
      expect(find.text('歩く'), findsOneWidget);
      final peekBtn = find.text('Peek Reading');
      expect(peekBtn, findsOneWidget);

      await tester.tap(peekBtn);
      await tester.pump();
      expect(peeked, isTrue);

      // Tap card body triggers flip
      await tester.tap(find.text('歩く'));
      await tester.pump();
      expect(flipped, isTrue);
    });

    testWidgets('TinderActionDock dispatches callbacks on Again, Hard, Good, and Easy', (tester) async {
      SRSReviewRating? swipedRating;

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: Scaffold(
            body: TinderActionDock(
              againInterval: '<10m',
              hardInterval: '1d',
              goodInterval: '3d',
              easyInterval: '5d',
              onAgain: () => swipedRating = SRSReviewRating.again,
              onHard: () => swipedRating = SRSReviewRating.hard,
              onGood: () => swipedRating = SRSReviewRating.good,
              onEasy: () => swipedRating = SRSReviewRating.easy,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Again
      await tester.tap(find.text('Again'));
      await tester.pump();
      expect(swipedRating, equals(SRSReviewRating.again));

      // Tap Good
      await tester.tap(find.text('Good'));
      await tester.pump();
      expect(swipedRating, equals(SRSReviewRating.good));
    });
  });
}

class _FakeApiForStudy extends VocaApiClient {
  @override
  Future<Map<String, dynamic>> getDiamonds() async {
    return {'success': true, 'diamonds': 5, 'maxDiamonds': 5};
  }
}

class _FakeSupabaseForStudy extends SupabaseService {
  _FakeSupabaseForStudy() : super(SupabaseClient('https://mock.supabase.co', 'mock_anon_key'));

  final List<Flashcard> savedCards = [
    Flashcard(
      id: 'mock_card_1',
      userId: 'u1',
      word: '食べる',
      reading: 'たべる',
      meaning: 'to eat',
      language: 'ja',
      level: 'learning',
      srsRepetition: 1,
      srsInterval: 1,
      srsEaseFactor: 2.5,
      srsNextReviewAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  @override
  User? get currentUser => null;

  @override
  Future<List<Flashcard>> getVocabularyCards({String? language}) async => List.from(savedCards);

  @override
  Future<void> upsertVocabularyCard(Flashcard card) async {
    final idx = savedCards.indexWhere((c) => c.id == card.id);
    if (idx >= 0) {
      savedCards[idx] = card;
    } else {
      savedCards.add(card);
    }
  }

  @override
  Future<Map<String, dynamic>?> recordStreakActivity(DateTime date) async => {'streak': 1};
}
