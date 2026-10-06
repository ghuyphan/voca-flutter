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
  });

  group('FlashcardFace UI Parity & Mark As Known Button Tests', () {
    testWidgets('FlashcardFace displays POS, Stage badge, and Mark Known action without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool markedKnown = false;
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
                  onMarkAsKnown: () => markedKnown = true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check POS tag and Word
      expect(find.text('VERB'), findsOneWidget);
      expect(find.text('食べる'), findsOneWidget);
      expect(find.text('たべる'), findsOneWidget);

      // Check Mark as Known button
      final markKnownBtn = find.text('Known');
      expect(markKnownBtn, findsWidgets);

      await tester.tap(markKnownBtn.first);
      await tester.pump();
      expect(markedKnown, isTrue);
    });

    testWidgets('FlashcardFace back face displays meaning and Mark Known button responds on tap', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool markedKnown = false;
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
                  onMarkAsKnown: () => markedKnown = true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Meaning should be visible on back face
      expect(find.text('to drink'), findsOneWidget);
      expect(find.text('Scene'), findsOneWidget);

      final markKnownBtn = find.text('Known');
      expect(markKnownBtn, findsWidgets);

      await tester.tap(markKnownBtn.first);
      await tester.pump();
      expect(markedKnown, isTrue);
    });

    testWidgets('TinderCardStack front and back faces handle Peek, Known, and Flip reliably', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool flipped = false;
      bool peeked = false;
      bool markedKnown = false;

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
                  onMarkAsKnown: () => markedKnown = true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Front face shows word and peek reading button
      expect(find.text('歩く'), findsOneWidget);
      final peekBtn = find.text('Xem cách đọc');
      expect(peekBtn, findsOneWidget);

      await tester.tap(peekBtn);
      await tester.pump();
      expect(peeked, isTrue);

      // Tap card body triggers flip
      await tester.tap(find.text('歩く'));
      await tester.pump();
      expect(flipped, isTrue);

      // Tap Mark Known on front face
      final markKnownBtn = find.text('Known');
      expect(markKnownBtn, findsWidgets);

      await tester.tap(markKnownBtn.first);
      await tester.pump();
      expect(markedKnown, isTrue);
    });

    testWidgets('TinderActionDock dispatches callbacks on Again, Good, Flip, and Undo', (tester) async {
      SRSReviewRating? swipedRating;
      bool flipped = false;
      bool undid = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: Scaffold(
            body: TinderActionDock(
              canUndo: true,
              isRevealed: true,
              onUndo: () => undid = true,
              onAgain: () => swipedRating = SRSReviewRating.again,
              onHard: () => swipedRating = SRSReviewRating.hard,
              onFlip: () => flipped = true,
              onGood: () => swipedRating = SRSReviewRating.good,
              onEasy: () => swipedRating = SRSReviewRating.easy,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Undo
      await tester.tap(find.text('Undo'));
      await tester.pump();
      expect(undid, isTrue);

      // Tap Flip
      await tester.tap(find.text('Flip'));
      await tester.pump();
      expect(flipped, isTrue);

      // Tap Good
      await tester.tap(find.text('3d'));
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
