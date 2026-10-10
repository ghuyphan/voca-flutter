// lib/services/haptic_service.dart

import 'package:flutter/services.dart';
import '../state/app_state.dart';

/// Unified tactile haptic feedback service for Voca Mobile.
///
/// Centralizes all platform [HapticFeedback] invocations and respects the
/// user's `hapticFeedbackEnabled` preference in [AppState.instance.userSettings].
class HapticService {
  HapticService._();

  /// Returns true if haptic feedback is enabled in user settings.
  static bool get isEnabled =>
      AppState.instance.userSettings.value.hapticFeedbackEnabled;

  /// Subtle click for selection changes, tab switches, chips, and segmented controls.
  static Future<void> selection() async {
    if (!isEnabled) return;
    await HapticFeedback.selectionClick();
  }

  /// Light tactile impact for standard button taps, toggles, and minor confirmations.
  static Future<void> light() async {
    if (!isEnabled) return;
    await HapticFeedback.lightImpact();
  }

  /// Medium tactile impact for primary CTAs, card swipes, warnings, and reward claims.
  static Future<void> medium() async {
    if (!isEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  /// Heavy tactile impact for major milestones (e.g., daily chest) or errors.
  static Future<void> heavy() async {
    if (!isEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  /// Standard device vibration fallback.
  static Future<void> vibrate() async {
    if (!isEnabled) return;
    await HapticFeedback.vibrate();
  }
}
