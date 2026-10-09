// lib/ui/widgets/voca_confirm_dialog.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../sheets/voca_bottom_sheet.dart';

enum ConfirmDialogVariant { primary, danger }

/// Shows a native confirmation bottom sheet matching lingua-tube's ConfirmDialogComponent.
Future<bool> showVocaConfirmDialog({
  required BuildContext context,
  required String title,
  String? message,
  String? confirmText,
  String? confirmLabel,
  String? cancelText,
  ConfirmDialogVariant variant = ConfirmDialogVariant.primary,
  bool? isDestructive,
  IconData? icon,
}) async {
  final resolvedCancel = cancelText ?? context.t('common.cancel', null, 'Cancel');
  final resolvedConfirm = confirmLabel ?? confirmText ?? context.t('common.confirm', null, 'Confirm');
  final effectiveDanger = isDestructive == true || variant == ConfirmDialogVariant.danger;

  final result = await showVocaBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    showCloseButton: false,
    contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
    builder: (ctx) {
      final colors = ctx.vocaColors;
      final isDanger = effectiveDanger;
      final displayIcon = icon ?? (isDanger ? Icons.warning_amber_rounded : Icons.info_outline_rounded);
      final iconColor = isDanger ? colors.error : colors.accentPrimary;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(displayIcon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    resolvedCancel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: isDanger ? colors.error : colors.accentPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    resolvedConfirm,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  return result ?? false;
}
