// lib/ui/gamification/widgets/streak_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../../../services/toast_service.dart';
import '../../../state/app_state.dart';
import '../../sheets/voca_bottom_sheet.dart';
import 'activity_heatmap_card.dart';
import 'next_streak_milestone_banner.dart';
import 'rpg_shield_crest.dart';

/// Modal bottom sheet presenting learning streaks, hearth progression, and freeze shields.
/// Features a centered heroic header banner matching the session recap style.
class StreakSheet extends StatelessWidget {
  const StreakSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showVocaBottomSheet(
      context: context,
      showCloseButton: true,
      maxHeightFactor: 0.90,
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      builder: (_) => const StreakSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final gamification = AppState.instance.gamificationService;

    return Watch((context) {
      final currentStreak = gamification.currentStreak.value;
      final longestStreak = gamification.longestStreak.value;
      final freezes = gamification.streakFreezes.value;
      final practicedToday = gamification.practicedToday;
      final totalXp = gamification.xp.value;

      final crestStyle = RpgCrestStyle.forStreak(currentStreak);

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 4),

            // 1. Hero Campfire Hearth RPG Crest (Clean shield, no background circle)
            _buildHeroHearthCrest(colors, crestStyle, freezes > 0),
            const SizedBox(height: 10),

            // 2. Stage Pill Tag (e.g. [ ★ Tàn Lửa ])
            _buildStagePill(context, colors, crestStyle),
            const SizedBox(height: 10),

            // 3. Centered Title
            Text(
              '$currentStreak ${context.t('streak.days', null, 'day streak!')}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),

            // 4. Centered Subtitle
            Text(
              context.t('streak.subtitle', null, 'Consistency is the secret to fluency'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12.5,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),

            // 5. Motivation Status Banner
            _buildMotivationBanner(context, colors, practicedToday),
            const SizedBox(height: 14),

            // 6. Stats Row: Best Streak & Freeze Shields
            Row(
              children: [
                // Best Record
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.isDark ? colors.bgSurface : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.borderColorLight),
                      boxShadow: [
                        if (!colors.isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colors.accentTertiary.withValues(alpha: colors.isDark ? 0.14 : 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.emoji_events_rounded, color: colors.accentTertiary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.t('streak.longestStreak', null, 'Longest Streak'),
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$longestStreak ${context.t('streak.daysShort', null, 'days')}',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Freeze Shields
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.isDark ? colors.bgSurface : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.borderColorLight),
                      boxShadow: [
                        if (!colors.isDark)
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: colors.colorDiamond.withValues(alpha: colors.isDark ? 0.14 : 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.shield_outlined, color: colors.colorDiamond, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.t('streak.freezesRemaining', null, 'Streak Freezes'),
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$freezes / 2',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Freeze Replenish Action (if < 2 freezes)
            if (freezes < 2) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: totalXp >= 150
                      ? () async {
                          HapticFeedback.lightImpact();
                          final success = await gamification.replenishFreeze();
                          if (context.mounted) {
                            if (success) {
                              ToastService.success(
                                context,
                                context.t('streak.freezeRestored', null, 'Frost Shield replenished! ❄️'),
                              );
                            } else {
                              ToastService.error(
                                context,
                                context.t('streak.insufficientXp', null, 'Need 150 XP to replenish shield'),
                              );
                            }
                          }
                        }
                      : null,
                  icon: Icon(Icons.ac_unit_rounded, size: 16, color: colors.colorDiamond),
                  label: Text(
                    totalXp >= 150
                        ? '${context.t('streak.infuseWard', null, 'Infuse Frost Shield')} (150 XP)'
                        : context.t('streak.notEnoughXp', null, 'Need 150 XP for Frost Shield'),
                    style: TextStyle(
                      color: totalXp >= 150 ? colors.colorDiamond : colors.textMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: totalXp >= 150 ? colors.colorDiamond.withValues(alpha: 0.4) : colors.borderColor,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const SizedBox(height: 4),
            ],

            // 7. Next Milestone Road Banner
            NextStreakMilestoneBanner(
              colors: colors,
              gamification: gamification,
            ),
            const SizedBox(height: 16),

            // 8. Heatmap Activity Matrix Card
            ActivityHeatmapCard(
              colors: colors,
              gamification: gamification,
              customTitle: '${context.t('common.activity', null, 'Activity')} (${context.t('study.last30Days', null, 'Last 30 Days')})',
              showOuterContainer: true,
            ),
            const SizedBox(height: 16),

            // 9. Campfire Wisdom Hint Footer
            _buildCampfireWisdom(context, colors, crestStyle),
            const SizedBox(height: 18),

            // 10. Close / Continue Action Button (M3 accessible dismiss)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  context.t('common.done', null, 'Got It'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    });
  }

  Widget _buildHeroHearthCrest(VocaColorPalette colors, RpgCrestStyle style, bool hasFrostWard) {
    IconData getStageIcon(RpgCrestStyle s) {
      return switch (s) {
        RpgCrestStyle.flameCold => Icons.mode_night_rounded,
        RpgCrestStyle.flameEmber => Icons.local_fire_department_rounded,
        RpgCrestStyle.flameBlaze => Icons.local_fire_department_rounded,
        RpgCrestStyle.flameBeacon => Icons.whatshot_rounded,
        _ => Icons.local_fire_department_rounded,
      };
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        RpgShieldCrest(
          width: 68,
          height: 76,
          style: style,
          icon: getStageIcon(style),
          iconSize: 34,
          innerInset: 2.5,
          showGlow: true,
        ),
        if (hasFrostWard)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: colors.colorDiamond,
                shape: BoxShape.circle,
                border: Border.all(color: colors.bgCard, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: colors.colorDiamond.withValues(alpha: 0.45),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.ac_unit_rounded, size: 13, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildStagePill(BuildContext context, VocaColorPalette colors, RpgCrestStyle style) {
    final localizedName = switch (style) {
      RpgCrestStyle.flameCold => context.t('streak.stageCold', null, 'Extinguished'),
      RpgCrestStyle.flameEmber => context.t('streak.stageEmber', null, 'Ember'),
      RpgCrestStyle.flameBlaze => context.t('streak.stageBlaze', null, 'Blaze'),
      RpgCrestStyle.flameBeacon => context.t('streak.stageBeacon', null, 'Beacon'),
      _ => style.displayName,
    };

    final stageColor = style.accentColor(colors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: stageColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: stageColor.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: stageColor),
          const SizedBox(width: 5),
          Text(
            localizedName,
            style: TextStyle(
              color: stageColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationBanner(BuildContext context, VocaColorPalette colors, bool practicedToday) {
    if (practicedToday) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.colorGrammar.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.colorGrammar.withValues(alpha: 0.30)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: colors.colorGrammar, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.t('streak.activeToday', null, 'Streak kept alive today! Great work!'),
                style: TextStyle(
                  color: colors.colorGrammar,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.colorFire.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.colorFire.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time_rounded, color: colors.colorFire, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.t('streak.riskToday', null, 'Practice today to keep your flame blazing!'),
              style: TextStyle(
                color: colors.colorFire,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampfireWisdom(BuildContext context, VocaColorPalette colors, RpgCrestStyle style) {
    final title = switch (style) {
      RpgCrestStyle.flameCold => context.t('streak.campfireColdTitle', null, 'The Hearth is Cold'),
      RpgCrestStyle.flameEmber => context.t('streak.campfireEmberTitle', null, "The Explorer's Ember"),
      RpgCrestStyle.flameBlaze => context.t('streak.campfireBlazeTitle', null, 'A Roaring Hearth'),
      RpgCrestStyle.flameBeacon => context.t('streak.campfireBeaconTitle', null, 'The Eternal Beacon'),
      _ => 'Campfire Lore',
    };

    final desc = switch (style) {
      RpgCrestStyle.flameCold => context.t('streak.campfireColdDesc', null, 'Night winds bite deep. Practice today to strike the flint and spark your ember.'),
      RpgCrestStyle.flameEmber => context.t('streak.campfireEmberDesc', null, 'A warm glow in the dark wilderness. Tend it daily to raise a roaring fire.'),
      RpgCrestStyle.flameBlaze => context.t('streak.campfireBlazeDesc', null, 'A fierce hearth dispelling the shadows of forgetting.'),
      RpgCrestStyle.flameBeacon => context.t('streak.campfireBeaconDesc', null, 'A sacred fire guiding your journey through fluency.'),
      _ => '',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_outlined, size: 16, color: colors.accentTertiary),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
