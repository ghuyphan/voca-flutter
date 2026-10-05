// lib/ui/onboarding/widgets/companion_speech_bubble.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';

/// Animated speech bubble displaying the companion spirit's signature voice line.
class CompanionSpeechBubble extends StatelessWidget {
  final String quote;
  final Color accentColor;

  const CompanionSpeechBubble({
    super.key,
    required this.quote,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(quote),
        margin: const EdgeInsets.only(top: 8, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(context.isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withOpacity(0.28),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '“$quote”',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13.5,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
