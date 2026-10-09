// lib/services/srs_service.dart

import 'dart:math';
import '../config/voca_tokens.dart';

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
  /// Deterministic SuperMemo-2 (SM-2) scheduling calculation with accurate mastery progression
  static SRSCalculationResult calculateNextReview({
    required SRSReviewRating rating,
    required int currentRepetitions,
    required int currentInterval,
    required double currentEaseFactor,
    String currentLevel = 'learning',
    DateTime? fromDate,
  }) {
    final now = fromDate ?? DateTime.now();
    int repetition = currentRepetitions;
    int interval = currentInterval;
    double ease = currentEaseFactor;
    String normalizedLevel = currentLevel.toLowerCase().trim();
    if (normalizedLevel == 'mastered') normalizedLevel = 'known';

    switch (rating) {
      case SRSReviewRating.again:
        repetition = 0;
        interval = 0;
        ease = max(SrsConfig.minEaseFactor, ease - 0.20);
        // Lapse: whether new, learning, or known, Again sets card to learning
        normalizedLevel = 'learning';
        break;

      case SRSReviewRating.hard:
        repetition += 1;
        interval = repetition <= 1 ? 1 : max(1, (interval * 1.2).round());
        ease = max(SrsConfig.minEaseFactor, ease - 0.15);
        if (normalizedLevel == 'new') {
          normalizedLevel = 'learning';
        }
        // If it was already known, keep it known unless failed
        break;

      case SRSReviewRating.good:
        repetition += 1;
        if (repetition == 1) {
          interval = 1;
        } else if (repetition == 2) {
          interval = 6;
        } else {
          interval = max(1, (interval * ease).round());
        }

        // Progression check
        if (interval >= SrsConfig.matureIntervalDays || repetition >= 3) {
          normalizedLevel = 'known';
        } else {
          normalizedLevel = 'learning';
        }
        break;

      case SRSReviewRating.easy:
        repetition += 1;
        if (repetition == 1) {
          interval = 2;
        } else if (repetition == 2) {
          interval = 8;
        } else {
          interval = max(2, (interval * ease * 1.3).round());
        }
        ease += 0.15;

        // Easy graduation: if learner easily knew it from the start or rep >= 2
        if (repetition >= 2 || interval >= 7 || normalizedLevel == 'new') {
          normalizedLevel = 'known';
        } else {
          normalizedLevel = 'learning';
        }
        break;
    }

    interval = min(SrsConfig.maxIntervalDays, interval);

    final nextReviewAt = interval <= 0
        ? now // Due immediately for same-session relearning
        : now.add(Duration(days: interval));

    return SRSCalculationResult(
      repetition: repetition,
      interval: interval,
      easeFactor: ease,
      level: normalizedLevel,
      nextReviewAt: nextReviewAt,
    );
  }

  /// Format an interval in days into a clean, human-readable compact badge matching lingua-tube (e.g. "<10m", "1d", "3d", "2w", "1mo", "1.2y")
  static String formatInterval(int days, {bool isAgain = false}) {
    if (isAgain || days <= 0) return '<10m';
    if (days == 1) return '1d';
    if (days < 7) return '${days}d';
    if (days < 30) {
      final weeks = (days / 7).round();
      return '${weeks}w';
    }
    if (days < 365) {
      final months = (days / 30).round();
      if (months >= 12) return '1y';
      return '${months}mo';
    }
    final years = (days / 365).toStringAsFixed(1).replaceAll('.0', '');
    return '${years}y';
  }

  /// Seeds appropriate SRS scheduling parameters when a card level is manually altered in the UI
  static ({int repetition, int interval, double easeFactor, DateTime nextReviewAt}) seedSrsParamsForLevel(
    String level, {
    DateTime? fromDate,
  }) {
    final now = fromDate ?? DateTime.now();
    switch (level.toLowerCase().trim()) {
      case 'known':
      case 'mastered':
        return (
          repetition: 3,
          interval: SrsConfig.matureIntervalDays,
          easeFactor: SrsConfig.defaultEaseFactor,
          nextReviewAt: now.add(const Duration(days: SrsConfig.matureIntervalDays)),
        );
      case 'learning':
        return (
          repetition: 1,
          interval: 1,
          easeFactor: SrsConfig.defaultEaseFactor,
          nextReviewAt: now.add(const Duration(days: 1)),
        );
      case 'new':
      default:
        return (
          repetition: 0,
          interval: 0,
          easeFactor: SrsConfig.defaultEaseFactor,
          nextReviewAt: now,
        );
    }
  }
}
