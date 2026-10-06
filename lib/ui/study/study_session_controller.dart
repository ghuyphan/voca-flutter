// lib/ui/study/study_session_controller.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_tokens.dart';
import '../../models/study_session_models.dart';
import '../../models/voca_models.dart';
import '../../services/srs_service.dart';
import '../../state/app_state.dart';

class StudySessionController {
  final isLoading = signal<bool>(true);
  final isSessionActive = signal<bool>(false); // Lands on Deck Hub by default

  // Deck filters & configurations
  final subDeck = signal<String>('all'); // 'all' | 'words' | 'grammar'
  final sessionSize = signal<int?>(10); // 5, 10, 20, or null (all)
  final dueOnly = signal<bool>(false);
  final includeNew = signal<bool>(true);
  final includeLearning = signal<bool>(true);
  final includeKnown = signal<bool>(false);

  // Cards & Queues
  final allCards = signal<List<Flashcard>>([]);
  final sessionCards = signal<List<Flashcard>>([]);
  final currentIndex = signal<int>(0);

  // Card interaction state
  final isCardRevealed = signal<bool>(false);
  final isReadingPeeked = signal<bool>(false);

  // Gamification & Combos
  final currentCombo = signal<int>(0);
  final maxCombo = signal<int>(0);

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
  final wordsCount = signal<int>(0);
  final grammarCount = signal<int>(0);

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

  Flashcard? get cardAfterNext {
    final list = sessionCards.value;
    final idx = currentIndex.value + 2;
    if (idx < list.length) {
      return list[idx];
    }
    return null;
  }

  int get remainingInSession =>
      (sessionCards.value.length - currentIndex.value).clamp(0, sessionCards.value.length);

  bool get isFinished =>
      !isLoading.value &&
      sessionCards.value.isNotEmpty &&
      currentIndex.value >= sessionCards.value.length;

  bool get canUndo => undoStack.value.isNotEmpty;

  final Map<String, bool> _grammarCache = {};

  bool isGrammarCard(Flashcard card) {
    if (card.partOfSpeech != null && card.partOfSpeech!.toLowerCase().contains('grammar')) {
      return true;
    }
    final key = '${card.language}:${card.word}';
    return _grammarCache.putIfAbsent(key, () {
      try {
        return AppState.instance.grammarEngine.isGrammar(card.word, card.language);
      } catch (_) {
        return false;
      }
    });
  }

  // Memoized candidate list according to current subDeck, dueOnly, and status toggles
  late final Computed<List<Flashcard>> _computedFilteredCandidates = computed(() {
    final now = DateTime.now();
    final deck = subDeck.value;
    final onlyDue = dueOnly.value;
    final incNew = includeNew.value;
    final incLearning = includeLearning.value;
    final incKnown = includeKnown.value;
    final cards = allCards.value;

    return cards.where((card) {
      final isGrammar = isGrammarCard(card);
      if (deck == 'words' && isGrammar) return false;
      if (deck == 'grammar' && !isGrammar) return false;

      final norm = WordLevels.normalize(card.level);
      if (norm == WordLevels.isNew && !incNew) return false;
      if (norm == WordLevels.learning && !incLearning) return false;
      if ((norm == WordLevels.known || norm == 'mastered') && !incKnown) return false;

      if (onlyDue) {
        if (norm == WordLevels.isNew) return false;
        if (card.srsNextReviewAt.isAfter(now)) return false;
      }
      return true;
    }).toList();
  });

  List<Flashcard> get filteredCandidates => _computedFilteredCandidates.value;

  int get availableCandidateCount => _computedFilteredCandidates.value.length;

  late final Computed<int> _computedSessionCardsCount = computed(() {
    final candidates = _computedFilteredCandidates.value;
    final size = sessionSize.value;
    if (size == null) return candidates.length;
    return candidates.length.clamp(0, size);
  });

  int get sessionCardsCount => _computedSessionCardsCount.value;

  late final Computed<int> _computedEstimatedMinutes = computed(() {
    final count = _computedSessionCardsCount.value;
    return (count * 0.35).ceil().clamp(1, 60);
  });

  int get estimatedMinutes => _computedEstimatedMinutes.value;

  void setSubDeck(String deck) {
    subDeck.value = deck;
    _recalculateMetrics();
  }

  void setSessionSize(int? size) {
    sessionSize.value = size;
  }

  void toggleDueOnly() {
    dueOnly.value = !dueOnly.value;
  }

  void toggleDeckInclusion(String stage) {
    if (stage == 'new') {
      includeNew.value = !includeNew.value;
    } else if (stage == 'learning') {
      includeLearning.value = !includeLearning.value;
    } else if (stage == 'known') {
      includeKnown.value = !includeKnown.value;
    }
    // Prevent deselecting all three
    if (!includeNew.value && !includeLearning.value && !includeKnown.value) {
      if (stage == 'new') includeNew.value = true;
      if (stage == 'learning') includeLearning.value = true;
      if (stage == 'known') includeKnown.value = true;
    }
  }

  void _recalculateMetrics() {
    final now = DateTime.now();
    final deck = subDeck.value;

    int due = 0;
    int fresh = 0;
    int learning = 0;
    int known = 0;
    int words = 0;
    int grammar = 0;

    for (final card in allCards.value) {
      final isGrammar = isGrammarCard(card);
      if (isGrammar) {
        grammar++;
      } else {
        words++;
      }

      if (deck == 'words' && isGrammar) continue;
      if (deck == 'grammar' && !isGrammar) continue;

      final norm = WordLevels.normalize(card.level);
      if (norm == WordLevels.isNew) {
        fresh++;
      } else if (norm == WordLevels.learning) {
        learning++;
        if (card.srsNextReviewAt.isBefore(now) || card.srsNextReviewAt.isAtSameMomentAs(now)) {
          due++;
        }
      } else if (norm == WordLevels.known || norm == 'mastered') {
        known++;
        if (card.srsNextReviewAt.isBefore(now) || card.srsNextReviewAt.isAtSameMomentAs(now)) {
          due++;
        }
      }
    }

    dueCount.value = due;
    newCount.value = fresh;
    learningCount.value = learning;
    knownCount.value = known;
    wordsCount.value = words;
    grammarCount.value = grammar;
  }

  Future<void> loadDeck({bool autoStart = true, bool practiceAnyway = false}) async {
    isLoading.value = true;
    final supabase = AppState.instance.supabaseService;
    final lang = AppState.instance.activeLanguage.value;

    try {
      final cards = await supabase.getVocabularyCards(language: lang);
      _grammarCache.clear();
      allCards.value = cards;
      _recalculateMetrics();

      currentIndex.value = 0;
      undoStack.value = [];
      sessionStats.value = const SessionStats();
      currentCombo.value = 0;
      maxCombo.value = 0;
      _rewardClaimed = false;
      resetCardState();

      if (autoStart && cards.isNotEmpty) {
        startSession(practiceAnyway: practiceAnyway);
      } else {
        isSessionActive.value = false;
      }
      isLoading.value = false;
    } catch (e) {
      debugPrint('[StudySessionController] Failed to load deck: $e');
      isLoading.value = false;
    }
  }

  void startNextBatch() {
    startSession(practiceAnyway: true);
  }

  void startSession({bool dueOnlyMode = false, bool practiceAnyway = false}) {
    if (dueOnlyMode) {
      dueOnly.value = true;
      includeKnown.value = true;
      includeLearning.value = true;
      includeNew.value = false;
    }

    final candidates = filteredCandidates;
    List<Flashcard> queue;

    if (practiceAnyway || candidates.isNotEmpty) {
      // Prioritize Due/Learning cards first, then New cards
      final now = DateTime.now();
      final dueCards = <Flashcard>[];
      final newCards = <Flashcard>[];
      final otherCards = <Flashcard>[];

      for (final card in (candidates.isNotEmpty ? candidates : allCards.value)) {
        final norm = WordLevels.normalize(card.level);
        if (norm == WordLevels.isNew) {
          newCards.add(card);
        } else if (card.srsNextReviewAt.isBefore(now) || card.srsNextReviewAt.isAtSameMomentAs(now)) {
          dueCards.add(card);
        } else {
          otherCards.add(card);
        }
      }

      final combined = [...dueCards, ...newCards, ...otherCards];
      final size = sessionSize.value;
      queue = size != null ? combined.take(size).toList() : combined;
    } else {
      queue = [];
    }

    sessionCards.value = queue;
    currentIndex.value = 0;
    undoStack.value = [];
    sessionStats.value = const SessionStats();
    currentCombo.value = 0;
    maxCombo.value = 0;
    _rewardClaimed = false;
    isSessionActive.value = true;
    resetCardState();
  }

  void restartFailedCards() {
    final missed = undoStack.value
        .where((e) => e.rating == SRSReviewRating.again || e.rating == SRSReviewRating.hard)
        .map((e) => e.previousCard)
        .toSet()
        .toList();

    if (missed.isNotEmpty) {
      sessionCards.value = missed;
      currentIndex.value = 0;
      undoStack.value = [];
      sessionStats.value = const SessionStats();
      currentCombo.value = 0;
      maxCombo.value = 0;
      _rewardClaimed = false;
      isSessionActive.value = true;
      resetCardState();
    }
  }

  void exitToOverview() {
    isSessionActive.value = false;
    resetCardState();
    _recalculateMetrics();
  }

  void toggleReveal() {
    isCardRevealed.value = !isCardRevealed.value;
  }

  void revealCard() {
    isCardRevealed.value = true;
  }

  void toggleReadingPeek() {
    isReadingPeeked.value = !isReadingPeeked.value;
  }

  void resetCardState() {
    isCardRevealed.value = false;
    isReadingPeeked.value = false;
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

    // Update combo streak
    if (rating == SRSReviewRating.again) {
      currentCombo.value = 0;
    } else {
      currentCombo.value += 1;
      if (currentCombo.value > maxCombo.value) {
        maxCombo.value = currentCombo.value;
      }
    }

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

    // Relearn queue: if Again, reinsert 3 positions ahead
    final queue = List<Flashcard>.from(sessionCards.value);
    if (rating == SRSReviewRating.again) {
      final insertIndex = (currentIndex.value + SrsConfig.relearnStepGap + 1).clamp(0, queue.length);
      queue.insert(insertIndex, updatedCard);
      sessionCards.value = queue;
    }

    // Optimistic persistence to Supabase
    unawaited(AppState.instance.supabaseService.upsertVocabularyCard(updatedCard));
    try {
      unawaited(AppState.instance.gamificationService.onCardReviewed(allCards.value.length));
    } catch (_) {}

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
      label: 'KNOWN',
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

    currentCombo.value += 1;
    if (currentCombo.value > maxCombo.value) {
      maxCombo.value = currentCombo.value;
    }

    unawaited(AppState.instance.supabaseService.upsertVocabularyCard(updatedCard));
    try {
      unawaited(AppState.instance.gamificationService.onCardReviewed(allCards.value.length));
    } catch (_) {}

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

      // Record daily practice activity in local GamificationService
      await AppState.instance.gamificationService.recordActivity();
    } catch (_) {}
  }

  void dispose() {
    _feedbackTimer?.cancel();
  }
}
