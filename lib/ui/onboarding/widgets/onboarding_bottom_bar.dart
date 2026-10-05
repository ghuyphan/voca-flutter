// lib/ui/onboarding/widgets/onboarding_bottom_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/voca_theme.dart';
import 'pressable_scale.dart';

/// Thumb-zone primary CTA with optional secondary text link below.
/// Content above fades into the bar instead of a hard divider.
class OnboardingBottomBar extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isLoading;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const OnboardingBottomBar({
    super.key,
    required this.label,
    this.icon = Icons.arrow_forward_rounded,
    required this.onPressed,
    this.isLoading = false,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, 0.22],
          colors: [colors.bgPrimary.withValues(alpha: 0), colors.bgPrimary],
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset > 0 ? bottomInset : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: label,
            child: PressableScale(
              haptic: false,
              onTap: isLoading
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      onPressed();
                    },
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: colors.accentPrimary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colors.accentPrimary
                          .withValues(alpha: context.isDark ? 0.28 : 0.24),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: isLoading
                      ? const SizedBox(
                          key: ValueKey('loading'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          key: ValueKey(label),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                            if (icon != null) ...[
                              const SizedBox(width: 8),
                              Icon(icon, size: 20, color: Colors.white),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: secondaryLabel == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: TextButton(
                        onPressed: onSecondary,
                        style: TextButton.styleFrom(
                          foregroundColor: colors.textSecondary,
                          textStyle: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(secondaryLabel!),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
