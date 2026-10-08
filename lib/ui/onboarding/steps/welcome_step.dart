// lib/ui/onboarding/steps/welcome_step.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../../widgets/kikyou_logo.dart';
import '../widgets/staggered_entrance.dart';

/// Step 0: Welcome hero and core value propositions.
/// Styled 1:1 with VOCA's AuthScreen landing visual language:
/// - Exact 104x104 squircle app icon badge with ambient coral radial halo
/// - Authoritative bold 'VOCA' brand title + localized 'Welcome to Voca' banner
/// - Clean, localized subtitle
/// - 3 native feature cards showcasing authentic video immersion,
///   interactive subtitles, and SRS memory flashcards.
class WelcomeStep extends StatelessWidget {
  final String demoLanguage;

  const WelcomeStep({super.key, required this.demoLanguage});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.isDark;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Master 104x104 App Icon Badge with Ambient Coral Glow (1:1 with AuthScreen)
            StaggeredEntrance(
              index: 0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Soft radial background halo
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          colors.accentPrimary
                              .withValues(alpha: isDark ? 0.22 : 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  // 104x104 App Icon Squircle Container
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: colors.borderColor, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: colors.accentPrimary
                              .withValues(alpha: isDark ? 0.25 : 0.14),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.35 : 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 104,
                        height: 104,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: KikyouLogo(
                              size: 56,
                              color: colors.accentPrimary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Authoritative VOCA Brand Title & Localized Welcome Banner (1:1 with AuthScreen)
            StaggeredEntrance(
              index: 1,
              child: Semantics(
                header: true,
                child: Column(
                  children: [
                    Text(
                      'VOCA',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.t(
                        'onboarding.welcomeTitle',
                        null,
                        'Welcome to Voca',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.accentPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 3. Localized Subtitle
            StaggeredEntrance(
              index: 2,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  context.t(
                    'onboarding.welcomeSubtitle',
                    null,
                    'Learn languages naturally through YouTube videos',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 4. Native Feature Highlights
            StaggeredEntrance(
              index: 3,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  children: [
                    _FeatureTile(
                      icon: Icons.play_circle_fill_rounded,
                      iconColor: colors.accentPrimary,
                      text: context.t(
                        'onboarding.features.subtitles',
                        null,
                        'Bilingual subtitles with audio sync',
                      ),
                      colors: colors,
                    ),
                    const SizedBox(height: 10),
                    _FeatureTile(
                      icon: Icons.translate_rounded,
                      iconColor: colors.colorGrammar,
                      text: context.t(
                        'onboarding.features.dict',
                        null,
                        'Tap any word to translate instantly',
                      ),
                      colors: colors,
                    ),
                    const SizedBox(height: 10),
                    _FeatureTile(
                      icon: Icons.style_rounded,
                      iconColor: colors.accentSecondary,
                      text: context.t(
                        'onboarding.features.srs',
                        null,
                        'Spaced repetition flashcards',
                      ),
                      colors: colors,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final VocaColorPalette colors;

  const _FeatureTile({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: colors.isDark ? 0.20 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: colors.isDark ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
