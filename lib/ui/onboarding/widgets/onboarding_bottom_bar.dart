// lib/ui/onboarding/widgets/onboarding_bottom_bar.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/haptic_service.dart';
import '../../../services/i18n_service.dart';

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
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottomInset > 0 ? bottomInset : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Optional Legal Consent Line
          if (showConsent) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text.rich(
                TextSpan(
                  text: context.t(
                    'auth.landingPolicyConsentPrefix',
                    null,
                    'By continuing, you agree to our ',
                  ),
                  style: TextStyle(
                    color: colors.textSecondary.withValues(alpha: 0.85),
                    fontSize: 12,
                    height: 1.35,
                  ),
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: GestureDetector(
                        onTap: onTermsTap,
                        child: Text(
                          context.t('settings.terms', null, 'Terms of Service'),
                          style: TextStyle(
                            color: colors.accentPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    TextSpan(
                      text: context.t('auth.landingPolicyConsentJoiner', null, ' and '),
                      style: TextStyle(
                        color: colors.textSecondary.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: GestureDetector(
                        onTap: onPrivacyTap,
                        child: Text(
                          context.t('settings.privacyPolicy', null, 'Privacy Policy'),
                          style: TextStyle(
                            color: colors.accentPrimary,
                            fontSize: 12,
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

          // Primary Full-Width CTA Button (M3 FilledButton with 16dp rounded shape)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: isLoading
                  ? null
                  : () {
                      HapticService.light();
                      onPressed();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: colors.accentPrimary.withValues(alpha: 0.55),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
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
                            Icon(
                              icon,
                              size: 20,
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),

          // Optional Secondary Action Link Below (M3 min 48dp touch target)
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: secondaryLabel == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: onSecondary,
                        style: TextButton.styleFrom(
                          foregroundColor: colors.textSecondary,
                          textStyle: const TextStyle(
                            fontSize: 14,
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
