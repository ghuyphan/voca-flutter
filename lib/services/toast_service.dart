import 'package:flutter/material.dart';
import '../config/voca_theme.dart';
import 'haptic_service.dart';

enum ToastType { success, error, info, warning }

/// Production Material 3 Toast & Notification Service.
///
/// Features:
/// - Attached globally via [messengerKey] to [MaterialApp.scaffoldMessengerKey].
/// - Context-free safe: can be called anywhere (after Navigator.pop, in background callbacks).
/// - Native tactile haptic feedback on every notification event.
/// - Prevents queue backlog by clearing previous snackbars before presenting new ones.
/// - Material 3 floating elevation, themed borders, status icons, and interactive action buttons.
class ToastService {
  /// Global ScaffoldMessenger key registered at MaterialApp root
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Shows a floating Material 3 transient notification.
  /// [context] is optional; if omitted or unmounted, falls back to [messengerKey].
  static void show(
    BuildContext? context,
    String message, {
    ToastType type = ToastType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    // 1. Native Platform Haptic Feedback (unified via HapticService)
    switch (type) {
      case ToastType.success:
        HapticService.light();
        break;
      case ToastType.warning:
        HapticService.medium();
        break;
      case ToastType.error:
        HapticService.heavy();
        break;
      case ToastType.info:
        HapticService.selection();
        break;
    }

    // 2. Resolve active ScaffoldMessengerState
    ScaffoldMessengerState? messenger;
    if (context != null && context.mounted) {
      messenger = ScaffoldMessenger.maybeOf(context);
    }
    messenger ??= messengerKey.currentState;
    if (messenger == null) return;

    // 3. Clear existing active snackbars to prevent sluggish FIFO queuing
    messenger.clearSnackBars();

    // 4. Resolve theme palette
    VocaColorPalette palette = VocaColorPalette.dark;
    if (context != null && context.mounted) {
      try {
        palette = context.vocaColors;
      } catch (_) {
        palette = VocaColorPalette.dark;
      }
    } else {
      try {
        palette = VocaTheme.colors(messenger.context);
      } catch (_) {
        palette = VocaColorPalette.dark;
      }
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.bgCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: palette.borderColor, width: 0.8),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: palette.accentPrimary,
                onPressed: onAction,
              )
            : null,
        duration: duration,
      ),
    );
  }

  static void success(
    BuildContext? context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    show(
      context,
      message,
      type: ToastType.success,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void error(
    BuildContext? context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 4000),
  }) {
    show(
      context,
      message,
      type: ToastType.error,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void warning(
    BuildContext? context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    show(
      context,
      message,
      type: ToastType.warning,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void info(
    BuildContext? context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    show(
      context,
      message,
      type: ToastType.info,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  // Context-free convenience helpers
  static void showMsg(
    String message, {
    ToastType type = ToastType.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(milliseconds: 3000),
  }) {
    show(
      null,
      message,
      type: type,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void successRaw(String message, {String? actionLabel, VoidCallback? onAction}) =>
      show(null, message, type: ToastType.success, actionLabel: actionLabel, onAction: onAction);

  static void errorRaw(String message, {String? actionLabel, VoidCallback? onAction}) =>
      show(null, message, type: ToastType.error, actionLabel: actionLabel, onAction: onAction);

  static void warningRaw(String message, {String? actionLabel, VoidCallback? onAction}) =>
      show(null, message, type: ToastType.warning, actionLabel: actionLabel, onAction: onAction);

  static void infoRaw(String message, {String? actionLabel, VoidCallback? onAction}) =>
      show(null, message, type: ToastType.info, actionLabel: actionLabel, onAction: onAction);
}
