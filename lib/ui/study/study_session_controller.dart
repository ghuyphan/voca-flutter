// lib/ui/study/study_session_controller.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_tokens.dart';
import '../../models/study_session_models.dart';
import '../../models/voca_models.dart';
import '../../services/audio_service.dart';
import '../../services/srs_service.dart';
import '../../services/supabase_service.dart';
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

  // Stats & History
  final sessionStats = signal<SessionStats>(const SessionStats());
  final undoStack = signal<List<ReviewEvent>>([]);

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

  Flashcard? get cardAfterNext {
    final list = sessionCards.value;
    final idx = currentIndex.value + 2;
    if (idx < list.length) {
      return list[idx];
    }
    return null;
  }

  final initialQueueSize = signal<int>(0);
  final Set<String> _reviewedCardIds = {};

  bool get isFinished =>
      isSessionActive.value &&
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
    final activeLang = AppState.instance.activeLanguage.value.trim().toLowerCase();
    final cards = allCards.value;

    return cards.where((card) {
      final cl = card.language.trim().toLowerCase();
      if (cl != activeLang && !cl.startsWith('$activeLang-') && !activeLang.startsWith('$cl-')) {
        return false;
      }
      final isGrammar = isGrammarCard(card);
      if (deck == 'words' && isGrammar) return false;
      if (deck == 'grammar' && !isGrammar) return false;

      final norm = WordLevels.normalize(card.level);
      final isDue = (card.srsNextReviewAt.isBefore(now) || card.srsNextReviewAt.isAtSameMomentAs(now)) && norm != WordLevels.isNew;

      if (onlyDue) {
        if (norm == WordLevels.isNew) return false;
        if (!isDue) return false;
        return true;
      }

      if (norm == WordLevels.isNew && !incNew) return false;
      if (norm == WordLevels.learning && !incLearning) return false;
      // Due mature cards should never be hidden from review queue just because includeKnown is disabled
      if ((norm == WordLevels.known || norm == 'mastered') && !incKnown && !isDue) return false;

      return true;
    }).toList();
  });

  List<Flashcard> get filteredCandidates => _computedFilteredCandidates.value;

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
    final activeLang = AppState.instance.activeLanguage.value.trim().toLowerCase();

    int due = 0;
    int fresh = 0;
    int learning = 0;
    int known = 0;

    for (final card in allCards.value) {
      final cl = card.language.trim().toLowerCase();
      if (cl != activeLang && !cl.startsWith('$activeLang-') && !activeLang.startsWith('$cl-')) {
        continue;
      }

      final isGrammar = isGrammarCard(card);
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
  }

  Future<void> loadDeck({bool autoStart = true, bool practiceAnyway = false}) async {
    isLoading.value = true;
    final supabase = AppState.instance.supabaseService;
    final lang = AppState.instance.activeLanguage.value.trim().toLowerCase();

    try {
      final cards = await supabase.getVocabularyCards(language: lang);
      _grammarCache.clear();

      final filtered = cards.where((c) {
        final cl = c.language.trim().toLowerCase();
        return cl == lang || cl.startsWith('$lang-') || lang.startsWith('$cl-');
      }).toList();

      allCards.value = SupabaseService.deduplicateCards(filtered);
      _recalculateMetrics();

      currentIndex.value = 0;
      undoStack.value = [];
      sessionStats.value = const SessionStats();
      currentCombo.value = 0;
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
    unawaited(AudioService.instance.stop());
    if (dueOnlyMode) {
      dueOnly.value = true;
    }

    final candidates = filteredCandidates;
    List<Flashcard> queue;

    if (practiceAnyway || candidates.isNotEmpty) {
      // Prioritize Due/Learning cards first, then New cards
      final now = DateTime.now();
      final dueCards = <Flashcard>[];
      final newCards = <Flashcard>[];
      final otherCards = <Flashcard>[];

      final currentSubDeck = subDeck.value;
      final pool = candidates.isNotEmpty
          ? candidates
          : allCards.value.where((card) {
              final isGrammar = isGrammarCard(card);
              if (currentSubDeck == 'words' && isGrammar) return false;
              if (currentSubDeck == 'grammar' && !isGrammar) return false;
              return true;
            }).toList();

      // Deduplicate cards by ID
      final seenIds = <String>{};
      final uniquePool = <Flashcard>[];
      for (final card in pool) {
        if (seenIds.add(card.id)) {
          uniquePool.add(card);
        }
      }

      for (final card in uniquePool) {
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
    initialQueueSize.value = queue.length;
    currentIndex.value = 0;
    _reviewedCardIds.clear();
    undoStack.value = [];
    sessionStats.value = const SessionStats();
    currentCombo.value = 0;
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
      initialQueueSize.value = missed.length;
      currentIndex.value = 0;
      _reviewedCardIds.clear();
      undoStack.value = [];
      sessionStats.value = const SessionStats();
      currentCombo.value = 0;
      _rewardClaimed = false;
      isSessionActive.value = true;
      resetCardState();
    }
  }

  void exitToOverview() {
    unawaited(AudioService.instance.stop());
    isSessionActive.value = false;
    sessionCards.value = [];
    initialQueueSize.value = 0;
    currentIndex.value = 0;
    _reviewedCardIds.clear();
    resetCardState();
    _recalculateMetrics();
  }

  void toggleReveal() {
    isCardRevealed.value = !isCardRevealed.value;
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
    unawaited(AudioService.instance.stop());

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

    final isLapse = (card.level == 'known' || card.level == 'mastered') &&
        (updatedCard.level == 'learning');
    final isNewUnique = _reviewedCardIds.add(card.id);

    // Save previous state for instant Undo
    final event = ReviewEvent(
      previousCard: card,
      updatedCard: updatedCard,
      rating: rating,
      timestamp: DateTime.now(),
      previousQueueIndex: currentIndex.value,
      wasRelearning: rating == SRSReviewRating.again,
      previousStats: sessionStats.value,
      previousCombo: currentCombo.value,
      isNewUniqueCard: isNewUnique,
    );

    final newUndo = List<ReviewEvent>.from(undoStack.value)..add(event);
    undoStack.value = newUndo;

    sessionStats.value = sessionStats.value.copyWithReview(
      rating,
      isLapse,
      isNewUniqueCard: isNewUnique,
    );

    // Update combo streak
    if (rating == SRSReviewRating.again) {
      currentCombo.value = 0;
    } else {
      currentCombo.value += 1;
    }

    // Relearn queue: if Again, reinsert 3 positions ahead
    final queue = List<Flashcard>.from(sessionCards.value);
    if (rating == SRSReviewRating.again) {
      final insertIndex = (currentIndex.value + SrsConfig.relearnStepGap + 1).clamp(0, queue.length);
      queue.insert(insertIndex, updatedCard);
      sessionCards.value = queue;
    }

    // Optimistic persistence to Supabase and in-place allCards sync
    final allList = List<Flashcard>.from(allCards.value);
    final allIdx = allList.indexWhere((c) =>
        c.id == updatedCard.id ||
        (c.word.trim().toLowerCase() == updatedCard.word.trim().toLowerCase() &&
            c.language.toLowerCase() == updatedCard.language.toLowerCase()));
    if (allIdx >= 0) {
      allList[allIdx] = updatedCard;
      allCards.value = allList;
      _recalculateMetrics();
    }

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
    unawaited(AudioService.instance.stop());

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

    final isNewUnique = _reviewedCardIds.add(card.id);

    final event = ReviewEvent(
      previousCard: card,
      updatedCard: updatedCard,
      rating: SRSReviewRating.easy,
      timestamp: DateTime.now(),
      previousQueueIndex: currentIndex.value,
      wasRelearning: false,
      previousStats: sessionStats.value,
      previousCombo: currentCombo.value,
      isNewUniqueCard: isNewUnique,
    );

    final newUndo = List<ReviewEvent>.from(undoStack.value)..add(event);
    undoStack.value = newUndo;

    sessionStats.value = sessionStats.value.copyWithReview(
      SRSReviewRating.easy,
      false,
      isNewUniqueCard: isNewUnique,
    );

    currentCombo.value += 1;

    // Optimistic persistence to Supabase and in-place allCards sync
    final allList = List<Flashcard>.from(allCards.value);
    final allIdx = allList.indexWhere((c) =>
        c.id == updatedCard.id ||
        (c.word.trim().toLowerCase() == updatedCard.word.trim().toLowerCase() &&
            c.language.toLowerCase() == updatedCard.language.toLowerCase()));
    if (allIdx >= 0) {
      allList[allIdx] = updatedCard;
      allCards.value = allList;
      _recalculateMetrics();
    }

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

  Future<void> undoLastRating() async {
    if (!canUndo) return;
    unawaited(AudioService.instance.stop());

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

    if (lastEvent.isNewUniqueCard) {
      _reviewedCardIds.remove(lastEvent.previousCard.id);
    }

    sessionCards.value = queue;
    currentIndex.value = lastEvent.previousQueueIndex;

    // Restore stats and streak combo
    sessionStats.value = lastEvent.previousStats;
    currentCombo.value = lastEvent.previousCombo;

    // Revert DB record and in-place allCards sync
    final allList = List<Flashcard>.from(allCards.value);
    final allIdx = allList.indexWhere((c) =>
        c.id == lastEvent.previousCard.id ||
        (c.word.trim().toLowerCase() == lastEvent.previousCard.word.trim().toLowerCase() &&
            c.language.toLowerCase() == lastEvent.previousCard.language.toLowerCase()));
    if (allIdx >= 0) {
      allList[allIdx] = lastEvent.previousCard;
      allCards.value = allList;
      _recalculateMetrics();
    }

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

  void dispose() {}
}
