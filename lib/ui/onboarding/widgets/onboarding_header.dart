// lib/ui/onboarding/widgets/onboarding_header.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import 'pressable_scale.dart';

/// Top bar: back button · segmented progress · skip.
/// [progress] is 1-based; pass 0 to hide the progress bar (Welcome step).
class OnboardingHeader extends StatelessWidget {
  final int progress;
  final int totalSegments;
  final bool showBack;
  final bool showSkip;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  const OnboardingHeader({
    super.key,
    required this.progress,
    required this.totalSegments,
    required this.showBack,
    required this.showSkip,
    required this.onBack,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Back
            SizedBox(
              width: 48,
              height: 48,
              child: AnimatedOpacity(
                opacity: showBack ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: !showBack,
                  child: Semantics(
                    button: true,
                    label: context.t('onboarding.back', null, 'Back'),
                    child: PressableScale(
                      onTap: onBack,
                      pressedScale: 0.9,
                      child: Center(
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: colors.bgSurface,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.borderColor),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Progress
            Expanded(
              child: AnimatedOpacity(
                opacity: progress > 0 ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Semantics(
                  label: context.t(
                    'onboarding.stepProgress',
                    {'current': progress, 'total': totalSegments},
                    'Step $progress of $totalSegments',
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: List.generate(totalSegments, (i) {
                        final filled = i < progress;
                        return Expanded(
                          child: Container(
                            height: 5,
                            margin: EdgeInsets.only(
                              right: i == totalSegments - 1 ? 0 : 5,
                            ),
                            decoration: BoxDecoration(
                              color: colors.bgTertiary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            alignment: Alignment.centerLeft,
                            child: AnimatedFractionallySizedBox(
                              duration: const Duration(milliseconds: 420),
                              curve: const Cubic(0.16, 1.0, 0.3, 1.0),
                              widthFactor: filled ? 1 : 0,
                              heightFactor: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colors.accentPrimary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),

            // Skip
            SizedBox(
              width: 64,
              height: 48,
              child: AnimatedOpacity(
                opacity: showSkip ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: IgnorePointer(
                  ignoring: !showSkip,
                  child: TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: colors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(context.t('onboarding.skip', null, 'Skip')),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
