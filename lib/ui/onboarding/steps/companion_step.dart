// lib/ui/onboarding/steps/companion_step.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../models/onboarding_models.dart';
import '../widgets/companion_speech_bubble.dart';
import '../widgets/onboarding_selection_tile.dart';
import '../widgets/onboarding_step_header.dart';

/// Step 3: Choose Companion Spirit Guide Archetype
class CompanionStep extends StatelessWidget {
  final String selectedCompanion;
  final ValueChanged<String> onCompanionChanged;

  const CompanionStep({
    super.key,
    required this.selectedCompanion,
    required this.onCompanionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final activeCompanion = CompanionSpiritOption.all.firstWhere(
      (c) => c.id == selectedCompanion,
      orElse: () => CompanionSpiritOption.all.first,
    );

    final activeQuote = context.t(
      activeCompanion.quoteKey,
      null,
      "I'll guide your journey through authentic speech!",
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingStepHeader(
            badgeText: context.t('onboarding.stageRecruit', null, 'Recruit Companion'),
            badgeIcon: Icons.auto_awesome_rounded,
            title: context.t('onboarding.companionTitle', null, 'Choose Your Companion Spirit'),
            subtitle: context.t(
              'onboarding.companionSubtitle',
              null,
              'Your companion brings unique passive guidance to your journey',
            ),
          ),

          // Live Companion Speech Bubble (updates dynamically on selection)
          CompanionSpeechBubble(
            quote: activeQuote,
            accentColor: activeCompanion.color,
          ),

          const SizedBox(height: 8),

          // 8 Companion Guides (DRY using OnboardingSelectionTile)
          ...CompanionSpiritOption.all.map((comp) {
            final isSelected = selectedCompanion == comp.id;
            final name = context.t(comp.nameKey, null, comp.id);
            final trait = context.t(comp.traitKey, null, 'Specialty');

            return OnboardingSelectionTile(
              title: name,
              tagChip: 'Lv.1',
              subtitle: trait,
              isSelected: isSelected,
              accentColor: comp.color,
              onTap: () => onCompanionChanged(comp.id),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: comp.color.withOpacity(context.isDark ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? comp.color : colors.borderColorLight,
                    width: isSelected ? 1.4 : 1.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    comp.avatarAsset,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      comp.icon,
                      color: comp.color,
                      size: 22,
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
