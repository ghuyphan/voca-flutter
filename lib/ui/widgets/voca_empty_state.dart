// lib/ui/widgets/voca_empty_state.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';

/// Semantic icon box variants matching lingua-tube's .empty-state__icon-box variants.
enum EmptyStateIconVariant {
  accent,
  neutral,
  error,
}

/// Reusable empty state view matching lingua-tube's Modern Luminous Voca Design System
/// (.empty-state, .empty-state--centered, .empty-state--compact).
class VocaEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Widget? actions;
  final EmptyStateIconVariant variant;
  final bool compact;
  final double? iconSize;
  final bool animate;

  const VocaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.actions,
    this.variant = EmptyStateIconVariant.accent,
    this.compact = false,
    this.iconSize,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final boxSize = compact ? 36.0 : 48.0;
    final effectiveIconSize = iconSize ?? (compact ? 16.0 : 28.0);

    // Compute icon box colors per semantic variant
    Color boxBg;
    Color boxBorder;
    Color iconColor;

    switch (variant) {
      case EmptyStateIconVariant.neutral:
        boxBg = colors.bgSurface;
        boxBorder = colors.borderColor;
        iconColor = colors.textMuted;
        break;
      case EmptyStateIconVariant.error:
        boxBg = colors.error.withOpacity(0.10);
        boxBorder = colors.error.withOpacity(0.25);
        iconColor = colors.error;
        break;
      case EmptyStateIconVariant.accent:
        boxBg = colors.accentPrimarySoft;
        boxBorder = colors.accentPrimary.withOpacity(0.25);
        iconColor = colors.accentPrimary;
        break;
    }

    final content = Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: compact ? 260.0 : 380.0),
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Icon Box (.empty-state__icon-box)
            Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                color: boxBg,
                shape: BoxShape.circle,
                border: Border.all(color: boxBorder, width: 1.0),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: effectiveIconSize,
                  color: iconColor,
                ),
              ),
            ),
            SizedBox(height: compact ? 8 : 12),

            // 2. Title (.empty-state__title)
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: compact ? 13.0 : 16.0,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                height: 1.35,
              ),
            ),

            // 3. Description / Hint (.empty-state__description)
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: compact ? 220.0 : 320.0),
                child: Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: compact ? colors.textMuted : colors.textSecondary,
                    fontSize: compact ? 12.0 : 13.0,
                    height: 1.45,
                  ),
                ),
              ),
            ],

            // 4. Action Buttons (.empty-state__actions)
            if (actions != null) ...[
              const SizedBox(height: 14),
              actions!,
            ] else if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (secondaryActionLabel != null && onSecondaryAction != null)
                    OutlinedButton(
                      onPressed: onSecondaryAction,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textSecondary,
                        side: BorderSide(color: colors.borderColor),
                        minimumSize: Size(0, compact ? 28 : 32),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        secondaryActionLabel!,
                        style: TextStyle(
                          fontSize: compact ? 12.0 : 13.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accentPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: Size(0, compact ? 28 : 32),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      actionLabel!,
                      style: TextStyle(
                        fontSize: compact ? 12.0 : 13.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    if (!animate) return content;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1.0 - value) * 6.0),
            child: child,
          ),
        );
      },
      child: content,
    );
  }
}
