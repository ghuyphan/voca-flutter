// lib/ui/widgets/voca_empty_state.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';

/// Reusable empty state view matching lingua-tube's EmptyStateComponent.
class VocaEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  const VocaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final padding = compact ? const EdgeInsets.all(16) : const EdgeInsets.all(32);
    final iconContainerSize = compact ? 52.0 : 72.0;
    final iconSize = compact ? 26.0 : 36.0;

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Soft glowing icon container
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: colors.accentPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.accentPrimary.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: colors.accentPrimary,
              ),
            ),
            SizedBox(height: compact ? 12 : 20),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: compact ? 15 : 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),

            // Description
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: compact ? 12.5 : 14,
                    height: 1.4,
                  ),
                ),
              ),
            ],

            // Action button
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? 14 : 22),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 16 : 24,
                    vertical: compact ? 10 : 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
