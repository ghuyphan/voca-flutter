// lib/services/srs_service.dart

import 'dart:math';

enum SRSReviewRating {
  again(1),
  hard(3),
  good(4),
  easy(5);

  final int score;
  const SRSReviewRating(this.score);
}

class SRSCalculationResult {
  final int repetition;
  final int interval;
  final double easeFactor;
  final String level;
  final DateTime nextReviewAt;

  SRSCalculationResult({
    required this.repetition,
    required this.interval,
    required this.easeFactor,
    required this.level,
    required this.nextReviewAt,
  });
}

class SpacedRepetitionService {
  /// SuperMemo-2 (SM-2) scheduling calculation
  static SRSCalculationResult calculateNextReview({
    required SRSReviewRating rating,
    required int currentRepetitions,
    required int currentInterval,
    required double currentEaseFactor,
    DateTime? fromDate,
  }) {
    final now = fromDate ?? DateTime.now();
    int repetition = currentRepetitions;
    int interval = currentInterval;
    double ease = currentEaseFactor;
    String level = 'learning';

    switch (rating) {
      case SRSReviewRating.again:
        repetition = 0;
        interval = 0;
        ease = max(1.3, ease - 0.20);
        level = 'learning';
        break;

      case SRSReviewRating.hard:
        repetition += 1;
        interval = repetition <= 1 ? 1 : (interval * 1.2).round();
        ease = max(1.3, ease - 0.15);
        level = 'learning';
        break;

      case SRSReviewRating.good:
        repetition += 1;
        if (repetition == 1) {
          interval = 1;
        } else if (repetition == 2) {
          interval = 6;
        } else {
          interval = (interval * ease).round();
        }
        level = repetition >= 3 ? 'known' : 'learning';
        break;

      case SRSReviewRating.easy:
        repetition += 1;
        if (repetition == 1) {
          interval = 2;
        } else if (repetition == 2) {
          interval = 8;
        } else {
          interval = (interval * ease * 1.3).round();
        }
        ease += 0.15;
        level = repetition >= 2 ? 'known' : 'learning';
        break;
    }

    final nextReviewAt = now.add(Duration(days: interval));

    return SRSCalculationResult(
      repetition: repetition,
      interval: interval,
      easeFactor: ease,
      level: level,
      nextReviewAt: nextReviewAt,
    );
  }
}
