// lib/ui/onboarding/widgets/onboarding_header.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';

/// Top header for the onboarding wizard featuring back button,
/// segmented linear progress bar, and skip action.
class OnboardingHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final bool showBack;
  final bool showSkip;

  const OnboardingHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    required this.onSkip,
    this.showBack = true,
    this.showSkip = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Back button (animates out on step 0)
          SizedBox(
            width: 40,
            height: 40,
            child: showBack && currentStep > 0
                ? IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary, size: 22),
                    tooltip: context.t('onboarding.back', null, 'Back'),
                    onPressed: onBack,
                    padding: EdgeInsets.zero,
                  )
                : const SizedBox.shrink(),
          ),

          // Center: Segmented Step Progress Bar
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: List.generate(totalSteps, (index) {
                  final isCompleted = currentStep > index;
                  final isActive = currentStep == index;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOutCubic,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: isCompleted || isActive
                              ? colors.accentPrimary
                              : (context.isDark ? colors.borderColor : colors.borderColorLight),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: colors.accentPrimary.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Right: Skip button
          SizedBox(
            width: 48,
            height: 40,
            child: showSkip && currentStep < totalSteps - 1
                ? TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: colors.textMuted,
                      textStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(context.t('onboarding.skip', null, 'Skip')),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
