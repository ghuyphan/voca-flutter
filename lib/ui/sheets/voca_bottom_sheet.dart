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
    showDragHandle: false,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final colors = ctx.vocaColors;
      final viewInsets = MediaQuery.of(ctx).viewInsets;
      final bottomInset = MediaQuery.paddingOf(ctx).bottom;
      final screenHeight = MediaQuery.sizeOf(ctx).height;
      final availableHeight = (screenHeight - viewInsets.bottom).clamp(100.0, screenHeight);

      return AnimatedPadding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: availableHeight * maxHeightFactor,
          ),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: colors.borderColor, width: 1),
              left: BorderSide(color: colors.borderColor, width: 1),
              right: BorderSide(color: colors.borderColor, width: 1),
            ),
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag Handle Pill (Inside container, centered at top)
                    if (showDragHandle)
                      Center(
                        child: Semantics(
                          label: ctx.t('common.dragHandle', null, 'Drag handle'),
                          child: Container(
                            width: 36,
                            height: 4,
                            margin: EdgeInsets.only(
                              top: 12,
                              bottom: title != null ? 4 : 12,
                            ),
                            decoration: BoxDecoration(
                              color: colors.borderColorHover,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),

                    // Title Header (if title specified) with integrated close button
                    if (title != null) ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          showDragHandle ? 10 : 16,
                          showCloseButton ? 8 : 20,
                          12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
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
                            if (trailingAction != null) trailingAction,
                            if (showCloseButton)
                              IconButton(
                                icon: Icon(Icons.close_rounded, color: colors.textMuted, size: 20),
                                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                padding: const EdgeInsets.all(10),
                                onPressed: () => Navigator.of(ctx).pop(),
                                tooltip: ctx.t('common.close', null, 'Close'),
                              ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: colors.borderColorLight),
                    ],

                    // Content Area with loose flex fit to dynamically wrap content
                    Flexible(
                      fit: FlexFit.loose,
                      child: Padding(
                        padding: (contentPadding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 16))
                            .add(EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 0)),
                        child: builder(ctx),
                      ),
                    ),
                  ],
                ),

                // Floating close button for sheets without a title header
                if (title == null && showCloseButton)
                  Positioned(
                    top: showDragHandle ? 8 : 4,
                    right: 8,
                    child: IconButton(
                      icon: Icon(Icons.close_rounded, color: colors.textMuted, size: 20),
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      padding: const EdgeInsets.all(12),
                      onPressed: () => Navigator.of(ctx).pop(),
                      tooltip: ctx.t('common.close', null, 'Close'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
