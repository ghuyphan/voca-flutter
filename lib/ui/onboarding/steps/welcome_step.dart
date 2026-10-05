// lib/ui/onboarding/steps/welcome_step.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';

/// Step 0: Welcome Hero & Core Value Propositions
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Authentic Adventure Hero Trio Illustration
          Container(
            height: 140,
            alignment: Alignment.center,
            child: Image.asset(
              'assets/illustrations/onboarding-hero-trio.webp',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/app_logo.png',
                width: 88,
                height: 88,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            context.t('onboarding.welcomeTitle', null, 'Welcome to Voca'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 8),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.t(
                'onboarding.welcomeSubtitle',
                null,
                'Learn languages naturally through authentic YouTube immersion',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: colors.textMuted,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // 3 Core Value Prop Feature Cards
          _buildFeatureCard(
            context: context,
            icon: Icons.ondemand_video_rounded,
            iconColor: const Color(0xFFFF6B82),
            title: context.t('onboarding.featureVideos', null, 'Authentic YouTube Videos'),
            description: context.t(
              'onboarding.featureVideosDesc',
              null,
              'Study with anime, music, podcasts, and native vlogs you actually love.',
            ),
          ),

          _buildFeatureCard(
            context: context,
            icon: Icons.subtitles_rounded,
            iconColor: const Color(0xFF38BDF8),
            title: context.t('onboarding.featureSubtitles', null, 'Interactive Subtitles & Furigana'),
            description: context.t(
              'onboarding.featureSubtitlesDesc',
              null,
              'Tap any word for instant readings, pinyin, bilingual definitions, and grammar.',
            ),
          ),

          _buildFeatureCard(
            context: context,
            icon: Icons.psychology_rounded,
            iconColor: const Color(0xFFA78BFA),
            title: context.t('onboarding.featureSrs', null, 'Spaced Repetition Deck'),
            description: context.t(
              'onboarding.featureSrsDesc',
              null,
              'One-tap sentence mining with SM-2 algorithm for long-term memory retention.',
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDark ? colors.borderColor : colors.borderColorLight,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(context.isDark ? 0.14 : 0.09),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withOpacity(0.24)),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
