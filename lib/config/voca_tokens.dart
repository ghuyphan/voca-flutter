// lib/config/voca_tokens.dart

import 'package:flutter/material.dart';

/// Spacing scale directly matching VOCA design system CSS variables
class VocaSpace {
  static const double space2xs = 4.0;
  static const double spaceXs = 8.0;
  static const double spaceSm = 12.0;
  static const double spaceBase = 16.0;
  static const double spaceMd = 20.0;
  static const double spaceLgSm = 24.0;
  static const double spaceLg = 32.0;
  static const double spaceXl = 48.0;
}

/// Border radius scale matching --border-radius-* in AGENTS.md
class VocaRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double base = 10.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double pill = 999.0;

  static final BorderRadius roundedXs = BorderRadius.circular(xs);
  static final BorderRadius roundedSm = BorderRadius.circular(sm);
  static final BorderRadius roundedBase = BorderRadius.circular(base);
  static final BorderRadius roundedMd = BorderRadius.circular(md);
  static final BorderRadius roundedLg = BorderRadius.circular(lg);
  static final BorderRadius roundedXl = BorderRadius.circular(xl);
  static final BorderRadius roundedXxl = BorderRadius.circular(xxl);
  static final BorderRadius roundedPill = BorderRadius.circular(pill);
}

/// Animation timing & curves matching --ease-spring and motion specs
class VocaMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration spring = Duration(milliseconds: 500);

  static const Curve easeFast = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Curve easeSpring = Cubic(0.16, 1.0, 0.3, 1.0);
  static const Curve bounce = Cubic(0.34, 1.56, 0.64, 1.0);
}

/// Element sizing standards matching AGENTS.md
class VocaSize {
  static const double btnHeightXs = 28.0;
  static const double btnHeightSm = 32.0;
  static const double btnHeightMd = 38.0;
  static const double btnHeightLg = 44.0;
  static const double btnHeightXl = 52.0;
  static const double touchTargetMin = 48.0;
}

/// Swipe deck gesture thresholds and physics constants
class SwipeConfig {
  /// Drag distance ratio relative to screen width before swipe is committed
  static const double horizontalCommitThresholdRatio = 0.35;

  /// Drag distance ratio relative to screen height for vertical swipes
  static const double verticalCommitThresholdRatio = 0.25;

  /// Fling velocity threshold (in logical pixels per second) to commit swipe
  static const double flingCommitVelocity = 800.0;

  /// Maximum rotation angle (radians) during horizontal drag (approx 12 degrees)
  static const double maxRotationAngle = 0.21;

  /// Next card scale in background stack
  static const double backgroundCardScale = 0.95;

  /// Next card Y offset in background stack
  static const double backgroundCardYOffset = 12.0;
}

/// SRS SuperMemo-2 Spaced Repetition parameters and progression thresholds
class SrsConfig {
  /// Days interval threshold where a card is officially recognized as mature / known
  static const int matureIntervalDays = 21;

  /// Default starting ease factor
  static const double defaultEaseFactor = 2.5;

  /// Minimum ease factor floor
  static const double minEaseFactor = 1.3;

  /// Maximum new cards introduced per day by default
  static const int defaultDailyNewLimit = 10;

  /// Maximum cards scheduled per active study session
  static const int defaultSessionCap = 20;

  /// Maximum scheduled interval cap (100 years matching Anki/lingua-tube)
  static const int maxIntervalDays = 36500;

  /// Position offset in the queue to reinsert cards rated Again for relearning
  static const int relearnStepGap = 3;
}
