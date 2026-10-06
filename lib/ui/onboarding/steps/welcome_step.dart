// lib/ui/onboarding/steps/welcome_step.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../widgets/staggered_entrance.dart';

/// Step 0: Welcome hero modeled 1:1 on the ACTE React Native onboarding:
/// - Atmospheric gradient canvas with spacious, centered layout
/// - Centered hero illustration (260-280px) with ambient radial back-glow
/// - Impactful screen title ("Welcome to Voca") & refined subtitle
/// - Breathable, clutter-free immersion without cards or visual noise
class WelcomeStep extends StatelessWidget {
  final String demoLanguage;

  const WelcomeStep({super.key, required this.demoLanguage});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = MediaQuery.sizeOf(context);
    final isDark = colors.isDark;
    final heroHeight = (size.height * 0.32).clamp(220.0, 300.0);

    final illustrationAsset = isDark
        ? 'assets/illustrations/onboarding-bilingual-dark.webp'
        : 'assets/illustrations/onboarding-bilingual-light.webp';

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. ACTE-style Art Frame with soft radial ambient back-glow
            StaggeredEntrance(
              index: 0,
              child: SizedBox(
                width: heroHeight,
                height: heroHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ambient radial glow behind artwork
                    Container(
                      width: heroHeight * 1.05,
                      height: heroHeight * 1.05,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            colors.accentPrimary.withValues(alpha: isDark ? 0.20 : 0.10),
                            colors.accentPrimary.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                    Image.asset(
                      illustrationAsset,
                      width: heroHeight * 0.95,
                      height: heroHeight * 0.95,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/illustrations/onboarding-bilingual.webp',
                        height: heroHeight * 0.95,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            Image.asset('assets/images/app_logo.png', width: 96, height: 96),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2. ACTE-style Bold Screen Title
            StaggeredEntrance(
              index: 1,
              child: Semantics(
                header: true,
                child: Column(
                  children: [
                    Text(
                      context.t('onboarding.welcomePrefix', null, 'Welcome to'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Voca',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.accentPrimary,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 3. ACTE-style Refined Subtitle
            StaggeredEntrance(
              index: 2,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  context.t(
                    'onboarding.welcomeSubtitle',
                    null,
                    'Master languages naturally through authentic YouTube media',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 15.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
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
