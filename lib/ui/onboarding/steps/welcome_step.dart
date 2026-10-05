// lib/ui/onboarding/steps/welcome_step.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../widgets/staggered_entrance.dart';

/// Step 0: Welcome hero with a live dual-subtitle demo and 3 value bullets.
class WelcomeStep extends StatelessWidget {
  final String demoLanguage;

  const WelcomeStep({super.key, required this.demoLanguage});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = MediaQuery.sizeOf(context);
    final heroHeight = (size.height * 0.26).clamp(150.0, 240.0);

    final features = <(IconData, Color, String)>[
      (
        Icons.subtitles_rounded,
        colors.accentPrimary,
        context.t('onboarding.features.subtitles', null, 'Bilingual subtitles with audio sync'),
      ),
      (
        Icons.touch_app_rounded,
        colors.colorDiamond,
        context.t('onboarding.features.dict', null, 'Tap any word to translate instantly'),
      ),
      (
        Icons.style_rounded,
        colors.accentSecondary,
        context.t('onboarding.features.srs', null, 'Spaced repetition flashcards'),
      ),
    ];

    final children = <Widget>[
      // Hero illustration with soft accent glow
      SizedBox(
        height: heroHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: heroHeight * 1.1,
              height: heroHeight * 1.1,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.accentPrimary.withValues(alpha: context.isDark ? 0.22 : 0.14),
                    colors.accentPrimary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            Image.asset(
              'assets/illustrations/onboarding-hero-trio-trans.webp',
              height: heroHeight,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Image.asset('assets/images/app_logo.png', width: 96, height: 96),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Text(
        context.t('onboarding.welcomeTitle', null, 'Welcome to Voca'),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 30,
          height: 1.15,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        context.t(
          'onboarding.welcomeSubtitle',
          null,
          'Learn languages naturally through YouTube videos',
        ),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 24),
      _DemoSubtitleCard(language: demoLanguage),
      const SizedBox(height: 20),
      for (final f in features)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: f.$2.withValues(alpha: context.isDark ? 0.16 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(f.$1, size: 19, color: f.$2),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  f.$3,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++)
            StaggeredEntrance(index: i, child: children[i]),
        ],
      ),
    );
  }
}

/// Mimics an in-player subtitle: target line on top, translation below.
class _DemoSubtitleCard extends StatelessWidget {
  final String language;
  const _DemoSubtitleCard({required this.language});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        children: [
          Text(
            context.t('onboarding.demo.$language.text', null, '日本語を勉強しましょう'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 19,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.t('onboarding.demo.$language.translation', null, "Let's study Japanese together!"),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13.5,
              height: 1.35,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
