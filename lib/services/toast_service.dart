// lib/services/toast_service.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/voca_theme.dart';

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
    // 1. Native Platform Haptic Feedback
    switch (type) {
      case ToastType.success:
        HapticFeedback.lightImpact();
        break;
      case ToastType.warning:
        HapticFeedback.mediumImpact();
        break;
      case ToastType.error:
        HapticFeedback.heavyImpact();
        break;
      case ToastType.info:
        HapticFeedback.selectionClick();
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

    Color iconColor;
    IconData iconData;
    Color borderColor;

    switch (type) {
      case ToastType.success:
        iconColor = palette.success;
        iconData = Icons.check_circle_rounded;
        borderColor = palette.success.withOpacity(0.35);
        break;
      case ToastType.error:
        iconColor = palette.error;
        iconData = Icons.error_rounded;
        borderColor = palette.error.withOpacity(0.35);
        break;
      case ToastType.warning:
        iconColor = palette.warning;
        iconData = Icons.warning_rounded;
        borderColor = palette.warning.withOpacity(0.35);
        break;
      case ToastType.info:
        iconColor = palette.accentPrimary;
        iconData = Icons.info_outline_rounded;
        borderColor = palette.borderColor;
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        elevation: 4,
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.bgCard,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor, width: 1.2),
        ),
        content: Row(
          children: [
            Icon(iconData, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  messenger?.hideCurrentSnackBar();
                  onAction();
                },
                style: TextButton.styleFrom(
                  foregroundColor: palette.accentPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
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
