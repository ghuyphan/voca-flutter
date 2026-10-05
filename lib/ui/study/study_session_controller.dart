// lib/ui/study/study_session_controller.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_tokens.dart';
import '../../models/study_session_models.dart';
import '../../models/voca_models.dart';
import '../../services/srs_service.dart';
import '../../state/app_state.dart';

enum StudyMode {
  flashcard,
  cloze,
  quiz;
}

class StudySessionController {
  final isLoading = signal<bool>(true);
  final isSessionActive = signal<bool>(true);
  final currentMode = signal<StudyMode>(StudyMode.flashcard);

  // Cards & Queues
  final allCards = signal<List<Flashcard>>([]);
  final sessionCards = signal<List<Flashcard>>([]);
  final currentIndex = signal<int>(0);

  // Card interaction state
  final isCardRevealed = signal<bool>(false);

  // Quiz state
  final quizOptions = signal<List<String>>([]);
  final selectedQuizOption = signal<int?>(null);
  final isQuizAnswered = signal<bool>(false);

  // Stats & History
  final sessionStats = signal<SessionStats>(const SessionStats());
  final undoStack = signal<List<ReviewEvent>>([]);
  final lastRatingFeedback = signal<({SRSReviewRating rating, String label, String newLevel, String interval})?>(null);
  Timer? _feedbackTimer;

  // Deck metrics for overview
  final dueCount = signal<int>(0);
  final newCount = signal<int>(0);
  final learningCount = signal<int>(0);
  final knownCount = signal<int>(0);

  bool _rewardClaimed = false;

  Flashcard? get currentCard {
    final list = sessionCards.value;
    final idx = currentIndex.value;
    if (idx >= 0 && idx < list.length) {
      return list[idx];
    }
    return null;
  }

  Flashcard? get nextCard {
    final list = sessionCards.value;
    final idx = currentIndex.value + 1;
    if (idx < list.length) {
      return list[idx];
    }
    return null;
  }

  bool get isFinished =>
      !isLoading.value &&
      sessionCards.value.isNotEmpty &&
      currentIndex.value >= sessionCards.value.length;

  bool get canUndo => undoStack.value.isNotEmpty;

  Future<void> loadDeck({bool practiceAnyway = false}) async {
    isLoading.value = true;
    final supabase = AppState.instance.supabaseService;
    final lang = AppState.instance.activeLanguage.value;

    try {
      final cards = await supabase.getVocabularyCards(language: lang);
      final now = DateTime.now();

      int due = 0;
      int fresh = 0;
      int learning = 0;
      int known = 0;

      final dueCardsList = <Flashcard>[];
      final newCardsList = <Flashcard>[];
      final otherCardsList = <Flashcard>[];

      for (final card in cards) {
        final norm = WordLevels.normalize(card.level);
        if (norm == WordLevels.isNew) {
          fresh++;
          newCardsList.add(card);
        } else if (norm == WordLevels.learning) {
          learning++;
          if (card.srsNextReviewAt.isBefore(now) || card.srsNextReviewAt.isAtSameMomentAs(now)) {
            due++;
            dueCardsList.add(card);
          } else {
            otherCardsList.add(card);
          }
        } else if (norm == WordLevels.known || norm == 'mastered') {
          known++;
          if (card.srsNextReviewAt.isBefore(now) || card.srsNextReviewAt.isAtSameMomentAs(now)) {
            due++;
            dueCardsList.add(card);
          } else {
            otherCardsList.add(card);
          }
        }
      }

      dueCount.value = due;
      newCount.value = fresh;
      learningCount.value = learning;
      knownCount.value = known;
      allCards.value = cards;

      // Build structured session queue
      final cappedNew = newCardsList.take(SrsConfig.defaultDailyNewLimit).toList();
      List<Flashcard> queue;

      if (practiceAnyway || (dueCardsList.isEmpty && cappedNew.isEmpty)) {
        // If learner requests practice or deck has no due cards, practice all available cards up to session cap
        queue = [...dueCardsList, ...cappedNew, ...otherCardsList].take(SrsConfig.defaultSessionCap).toList();
      } else {
        // Standard SRS queue: Due reviews first, followed by capped new cards
        queue = [...dueCardsList, ...cappedNew].take(SrsConfig.defaultSessionCap).toList();
      }

      sessionCards.value = queue;
      currentIndex.value = 0;
      undoStack.value = [];
      sessionStats.value = const SessionStats();
      _rewardClaimed = false;
      resetCardState();
      isLoading.value = false;
    } catch (e) {
      debugPrint('[StudySessionController] Failed to load deck: $e');
      isLoading.value = false;
    }
  }

  void startSession() {
    isSessionActive.value = true;
    resetCardState();
  }

  void exitToOverview() {
    isSessionActive.value = false;
    resetCardState();
  }

  void setMode(StudyMode mode) {
    if (currentMode.value != mode) {
      currentMode.value = mode;
      resetCardState();
    }
  }

  void toggleReveal() {
    isCardRevealed.value = !isCardRevealed.value;
  }

  void revealCard() {
    isCardRevealed.value = true;
  }

  void resetCardState() {
    isCardRevealed.value = false;
    selectedQuizOption.value = null;
    isQuizAnswered.value = false;
    _generateQuizOptions();
  }

  void selectQuizOption(int index) {
    if (isQuizAnswered.value) return;
    selectedQuizOption.value = index;
    isQuizAnswered.value = true;
    isCardRevealed.value = true;
  }

  void _generateQuizOptions() {
    final card = currentCard;
    if (card == null) {
      quizOptions.value = [];
      return;
    }

    final targetMeaning = card.meaning.trim();
    final candidates = <String>{};

    for (final other in allCards.value) {
      final m = other.meaning.trim();
      if (m.isNotEmpty && m != targetMeaning) {
        candidates.add(m);
      }
    }

    // Dynamic clean distractors if user has few cards
    if (candidates.length < 3) {
      final sampleDistractors = [
        'observe carefully and evaluate',
        'explain clearly with examples',
        'important appointment or promise',
        'calm, peaceful atmosphere',
        'prepare thoroughly in advance',
        'challenging endeavor requiring persistence',
      ];
      for (final d in sampleDistractors) {
        if (d != targetMeaning) candidates.add(d);
      }
    }

    final shuffledCandidates = candidates.toList()..shuffle();
    final options = <String>[targetMeaning, ...shuffledCandidates.take(3)]..shuffle();
    quizOptions.value = options;
  }

  Future<void> rateCurrentCard(SRSReviewRating rating) async {
    final card = currentCard;
    if (card == null) return;

    final result = SpacedRepetitionService.calculateNextReview(
      rating: rating,
      currentRepetitions: card.srsRepetition,
      currentInterval: card.srsInterval,
      currentEaseFactor: card.srsEaseFactor,
      currentLevel: card.level,
    );

    final updatedCard = card.copyWith(
      level: result.level,
      srsInterval: result.interval,
      srsRepetition: result.repetition,
      srsEaseFactor: result.easeFactor,
      srsNextReviewAt: result.nextReviewAt,
      srsLastReviewedAt: DateTime.now(),
      reviewCount: card.reviewCount + 1,
    );

    // Save previous state for instant Undo
    final event = ReviewEvent(
      previousCard: card,
      updatedCard: updatedCard,
      rating: rating,
      timestamp: DateTime.now(),
      previousQueueIndex: currentIndex.value,
      wasRelearning: rating == SRSReviewRating.again,
    );

    final newUndo = List<ReviewEvent>.from(undoStack.value)..add(event);
    undoStack.value = newUndo;

    final isLapse = (card.level == 'known' || card.level == 'mastered') &&
        (updatedCard.level == 'learning');
    sessionStats.value = sessionStats.value.copyWithReview(rating, isLapse);

    // Provide transient visual feedback pill
    _feedbackTimer?.cancel();
    lastRatingFeedback.value = (
      rating: rating,
      label: rating.name.toUpperCase(),
      newLevel: updatedCard.level.toUpperCase(),
      interval: SpacedRepetitionService.formatInterval(result.interval, isAgain: rating == SRSReviewRating.again),
    );
    _feedbackTimer = Timer(const Duration(milliseconds: 1400), () {
      lastRatingFeedback.value = null;
    });

    // Relearn queue: if Again, reinsert 3 positions ahead so learner practices it again
    final queue = List<Flashcard>.from(sessionCards.value);
    if (rating == SRSReviewRating.again) {
      final insertIndex = (currentIndex.value + SrsConfig.relearnStepGap + 1).clamp(0, queue.length);
      queue.insert(insertIndex, updatedCard);
      sessionCards.value = queue;
    }

    // Optimistic persistence to Supabase
    unawaited(AppState.instance.supabaseService.upsertVocabularyCard(updatedCard));

    // Advance queue
    currentIndex.value += 1;
    resetCardState();

    if (isFinished && !_rewardClaimed) {
      await claimSessionRewards();
    }
  }

  Future<void> markCurrentCardAsKnown() async {
    final card = currentCard;
    if (card == null) return;

    final seed = SpacedRepetitionService.seedSrsParamsForLevel('known');
    final updatedCard = card.copyWith(
      level: 'known',
      srsInterval: seed.interval,
      srsRepetition: seed.repetition,
      srsEaseFactor: seed.easeFactor,
      srsNextReviewAt: seed.nextReviewAt,
      srsLastReviewedAt: DateTime.now(),
      reviewCount: card.reviewCount + 1,
    );

    final event = ReviewEvent(
      previousCard: card,
      updatedCard: updatedCard,
      rating: SRSReviewRating.easy,
      timestamp: DateTime.now(),
      previousQueueIndex: currentIndex.value,
      wasRelearning: false,
    );

    undoStack.value = List<ReviewEvent>.from(undoStack.value)..add(event);
    sessionStats.value = sessionStats.value.copyWithReview(SRSReviewRating.easy, false);

    _feedbackTimer?.cancel();
    lastRatingFeedback.value = (
      rating: SRSReviewRating.easy,
      label: 'ĐÃ THUỘC',
      newLevel: 'KNOWN',
      interval: '${seed.interval}d',
    );
    _feedbackTimer = Timer(const Duration(milliseconds: 1400), () {
      lastRatingFeedback.value = null;
    });

    knownCount.value += 1;
    if (card.level == 'learning' && learningCount.value > 0) {
      learningCount.value -= 1;
    } else if (card.level == 'new' && newCount.value > 0) {
      newCount.value -= 1;
    }

    unawaited(AppState.instance.supabaseService.upsertVocabularyCard(updatedCard));

    currentIndex.value += 1;
    resetCardState();

    if (isFinished && !_rewardClaimed) {
      await claimSessionRewards();
    }
  }

  Future<void> undoLastRating() async {
    if (!canUndo) return;

    final events = List<ReviewEvent>.from(undoStack.value);
    final lastEvent = events.removeLast();
    undoStack.value = events;

    // Restore previous card
    final queue = List<Flashcard>.from(sessionCards.value);
    if (lastEvent.wasRelearning) {
      // Remove the reinserted card from later in the queue
      final reinsertedIndex = (lastEvent.previousQueueIndex + SrsConfig.relearnStepGap + 1).clamp(0, queue.length - 1);
      if (reinsertedIndex < queue.length && queue[reinsertedIndex].id == lastEvent.updatedCard.id) {
        queue.removeAt(reinsertedIndex);
      }
    }

    sessionCards.value = queue;
    currentIndex.value = lastEvent.previousQueueIndex;

    // Revert DB record
    unawaited(AppState.instance.supabaseService.upsertVocabularyCard(lastEvent.previousCard));

    resetCardState();
  }

  Future<void> claimSessionRewards() async {
    _rewardClaimed = true;
    try {
      final res = await AppState.instance.supabaseService.recordStreakActivity(DateTime.now());
      if (res != null && res['current_streak'] != null) {
        AppState.instance.currentStreak.value = (res['current_streak'] as num).toInt();
      }

      final currentDiamonds = AppState.instance.diamonds.value;
      final maxD = AppState.instance.maxDiamonds.value;
      if (currentDiamonds < maxD) {
        AppState.instance.diamonds.value = currentDiamonds + 1;
      }
    } catch (_) {}
  }

  void dispose() {
    _feedbackTimer?.cancel();
  }
}
