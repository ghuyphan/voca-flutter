// lib/ui/onboarding/widgets/onboarding_bottom_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import 'pressable_scale.dart';

/// Thumb-zone primary CTA pill button with optional legal consent above
/// and optional secondary text link below.
class OnboardingBottomBar extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isLoading;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool showConsent;
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyTap;

  const OnboardingBottomBar({
    super.key,
    required this.label,
    this.icon = Icons.arrow_forward_rounded,
    required this.onPressed,
    this.isLoading = false,
    this.secondaryLabel,
    this.onSecondary,
    this.showConsent = false,
    this.onTermsTap,
    this.onPrivacyTap,
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
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset > 0 ? bottomInset : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Optional Legal Consent Line (Above button, matching reference screenshot)
          if (showConsent) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text.rich(
                TextSpan(
                  text: context.t('auth.landingPolicyConsentPrefix', null, 'By continuing you agree to our\n'),
                  style: TextStyle(
                    color: colors.textSecondary.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: GestureDetector(
                        onTap: onTermsTap,
                        child: Text(
                          context.t('settings.terms', null, 'terms of service'),
                          style: TextStyle(
                            color: colors.accentPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    TextSpan(
                      text: context.t('auth.landingPolicyConsentJoiner', null, ' and '),
                      style: TextStyle(
                        color: colors.textSecondary.withValues(alpha: 0.85),
                        fontSize: 12.5,
                      ),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: GestureDetector(
                        onTap: onPrivacyTap,
                        child: Text(
                          context.t('settings.privacy', null, 'privacy policy'),
                          style: TextStyle(
                            color: colors.accentPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          // Primary Full-Width Pill CTA Button
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
                height: 52,
                decoration: BoxDecoration(
                  color: colors.accentPrimary,
                  borderRadius: BorderRadius.circular(999),
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
                          mainAxisAlignment: MainAxisAlignment.center,
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

          // Optional Secondary Action Link Below
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
