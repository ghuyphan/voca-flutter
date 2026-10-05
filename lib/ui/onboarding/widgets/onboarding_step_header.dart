// lib/ui/onboarding/widgets/onboarding_step_header.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';

/// Standard step title & subtitle header with optional prologue pill badge.
class OnboardingStepHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badgeText;
  final IconData? badgeIcon;
  final TextAlign textAlign;

  const OnboardingStepHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.badgeIcon,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCenter = textAlign == TextAlign.center;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment:
            isCenter ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          if (badgeText != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.accentPrimary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: colors.accentPrimary.withOpacity(0.24),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (badgeIcon != null) ...[
                    Icon(badgeIcon, size: 12, color: colors.accentPrimary),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    badgeText!.toUpperCase(),
                    style: TextStyle(
                      color: colors.accentPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          Text(
            title,
            textAlign: textAlign,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            subtitle,
            textAlign: textAlign,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
