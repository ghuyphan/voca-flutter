// lib/models/study_session_models.dart

import '../services/srs_service.dart';
import 'voca_models.dart';

/// Immutable record of a card review event supporting optimistic updates and instant undo
class ReviewEvent {
  final Flashcard previousCard;
  final Flashcard updatedCard;
  final SRSReviewRating rating;
  final DateTime timestamp;
  final int previousQueueIndex;
  final bool wasRelearning;
  final SessionStats previousStats;
  final int previousCombo;
  final bool isNewUniqueCard;

  const ReviewEvent({
    required this.previousCard,
    required this.updatedCard,
    required this.rating,
    required this.timestamp,
    required this.previousQueueIndex,
    this.wasRelearning = false,
    this.previousStats = const SessionStats(),
    this.previousCombo = 0,
    this.isNewUniqueCard = false,
  });
}

/// Aggregated metrics for the active study session
class SessionStats {
  final int totalReviewed;
  final int uniqueCardsCount;
  final int goodOrEasyCount;
  final int againOrHardCount;
  final int lapses;

  const SessionStats({
    this.totalReviewed = 0,
    this.uniqueCardsCount = 0,
    this.goodOrEasyCount = 0,
    this.againOrHardCount = 0,
    this.lapses = 0,
  });

  double get accuracyRate =>
      totalReviewed > 0 ? (goodOrEasyCount / totalReviewed) * 100 : 0.0;

  SessionStats copyWithReview(
    SRSReviewRating rating,
    bool isLapse, {
    bool isNewUniqueCard = false,
  }) {
    final isPositive =
        rating == SRSReviewRating.good || rating == SRSReviewRating.easy;
    return SessionStats(
      totalReviewed: totalReviewed + 1,
      uniqueCardsCount: uniqueCardsCount + (isNewUniqueCard ? 1 : 0),
      goodOrEasyCount: goodOrEasyCount + (isPositive ? 1 : 0),
      againOrHardCount: againOrHardCount + (isPositive ? 0 : 1),
      lapses: lapses + (isLapse ? 1 : 0),
    );
  }
}
