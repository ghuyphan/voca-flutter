// lib/ui/sheets/voca_bottom_sheet.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';

/// Shows a native Flutter modal bottom sheet styled according to the VOCA design system.
/// Matches the behavior of lingua-tube's BottomSheetComponent while leveraging
/// Flutter's native gesture physics, draggable sheet physics, and edge-to-edge support.
Future<T?> showVocaBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,
  String? title,
  String? subtitle,
  Widget? trailingAction,
  bool showDragHandle = true,
  bool showCloseButton = true,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
  double maxHeightFactor = 0.88,
  EdgeInsetsGeometry? contentPadding,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final colors = ctx.vocaColors;
      final viewInsets = MediaQuery.of(ctx).viewInsets;

      return AnimatedPadding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * maxHeightFactor,
          ),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: colors.borderColor, width: 1),
              left: BorderSide(color: colors.borderColor, width: 1),
              right: BorderSide(color: colors.borderColor, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(colors.isDark ? 0.45 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Native Drag Handle Pill
              if (showDragHandle)
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    decoration: BoxDecoration(
                      color: colors.borderColorHover,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

              // Sheet Header
              if (title != null || trailingAction != null || showCloseButton)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (title != null)
                              Text(
                                title,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (trailingAction != null) ...[
                        trailingAction,
                        const SizedBox(width: 4),
                      ],
                      if (showCloseButton)
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: colors.textMuted, size: 20),
                          splashRadius: 20,
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.of(ctx).pop(),
                          tooltip: ctx.t('common.close', null, 'Close'),
                        ),
                    ],
                  ),
                ),

              if (title != null)
                Divider(height: 1, color: colors.borderColorLight),

              // Content Area
              Flexible(
                child: Padding(
                  padding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: builder(ctx),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
