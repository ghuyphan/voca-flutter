// lib/ui/onboarding/steps/license_step.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../models/onboarding_models.dart';
import '../widgets/onboarding_step_header.dart';

/// Step 4: Adventurer License Pass & Starter Loot Cache
class LicenseStep extends StatelessWidget {
  final String learningLanguage;
  final String rankId;
  final String companionId;
  final int dailyGoalMinutes;

  const LicenseStep({
    super.key,
    required this.learningLanguage,
    required this.rankId,
    required this.companionId,
    required this.dailyGoalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final realm = LearningRealmOption.all.firstWhere(
      (r) => r.code == learningLanguage,
      orElse: () => LearningRealmOption.all.first,
    );

    final rank = RankLevelOption.all.firstWhere(
      (r) => r.id == rankId,
      orElse: () => RankLevelOption.all.first,
    );

    final companion = CompanionSpiritOption.all.firstWhere(
      (c) => c.id == companionId,
      orElse: () => CompanionSpiritOption.all.first,
    );

    final rankName = context.t('onboarding.ranks.${rank.rankKey}', null, rank.rankKey);
    final companionName = context.t(companion.nameKey, null, companion.id);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingStepHeader(
            badgeText: context.t('onboarding.prologueBadge', null, 'The Awakening'),
            badgeIcon: Icons.workspace_premium_rounded,
            title: context.t('onboarding.starterTitle', null, 'Adventurer License Activated!'),
            subtitle: context.t(
              'onboarding.starterSubtitle',
              null,
              'The Guild welcomes you with your initial supply cache',
            ),
          ),

          // Holographic Guild Adventurer Pass Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: context.isDark
                    ? [
                        const Color(0xFF1F2432),
                        const Color(0xFF161922),
                      ]
                    : [
                        const Color(0xFFFFFFFF),
                        const Color(0xFFF6F8FA),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.accentPrimary.withOpacity(0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.accentPrimary.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Header Tag
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: colors.accentPrimary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.t('onboarding.guildCharter', null, 'Voca Guild Charter').toUpperCase(),
                        style: TextStyle(
                          color: colors.accentPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.accentPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'OFFICIAL PASS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFF6B82),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Center Avatar & Hunter Identity
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: companion.color.withOpacity(0.18),
                            shape: BoxShape.circle,
                            border: Border.all(color: companion.color, width: 2),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              companion.avatarAsset,
                              width: 58,
                              height: 58,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                companion.icon,
                                color: companion.color,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.bgCard,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: companion.color, width: 1),
                            ),
                            child: const Text(
                              'Lv.1',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$rankName • $companionName',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${context.t(companion.traitKey, null, '')} guide',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                Divider(
                  height: 1,
                  color: context.isDark ? colors.borderColorLight : colors.borderColor,
                ),
                const SizedBox(height: 14),

                // Badges row (Realm, Exam, Pace)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPassBadge(
                      label: '${realm.flagEmoji} ${realm.name}',
                      bgColor: realm.accentColor.withOpacity(0.12),
                      textColor: realm.accentColor,
                    ),
                    _buildPassBadge(
                      label: rank.examBadge,
                      bgColor: rank.badgeBg,
                      textColor: rank.badgeText,
                    ),
                    _buildPassBadge(
                      label: '🔥 $dailyGoalMinutes min/day',
                      bgColor: VocaTokens.colorFire.withOpacity(0.12),
                      textColor: VocaTokens.colorFire,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Starter Supply Cache Section
          Text(
            context.t('onboarding.starterSubtitle', null, 'Initial Supply Cache'),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 12),

          // 2x2 Loot Grid (DRY using StarterLootItem.all)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
            ),
            itemCount: StarterLootItem.all.length,
            itemBuilder: (context, index) {
              final loot = StarterLootItem.all[index];
              final title = context.t(loot.titleKey, null, '');
              final desc = context.t(loot.descKey, null, '');

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: context.isDark ? colors.borderColor : colors.borderColorLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: loot.bgTint,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(loot.icon, color: loot.iconColor, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPassBadge({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
