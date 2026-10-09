// lib/ui/gamification/streak_screen.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../services/gamification_service.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../study/study_deck_screen.dart';
import '../widgets/voca_back_button.dart';
import 'widgets/activity_heatmap_card.dart';
import 'widgets/next_streak_milestone_banner.dart';
import 'widgets/rpg_shield_crest.dart';

/// Dedicated Full-Screen Experience for Learning Streaks & Hearth Progression.
class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final gamification = AppState.instance.gamificationService;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary,
        elevation: 0,
        leadingWidth: 68,
        leading: const Padding(
          padding: EdgeInsets.only(left: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: VocaBackButton(),
          ),
        ),
        centerTitle: true,
        title: Text(
          context.t('streak.title', null, 'Daily Streak'),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: colors.textMuted, size: 22),
            onPressed: () => _showStreakInfoDialog(context, colors),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Watch((context) {
          final currentStreak = gamification.currentStreak.value;
          final longestStreak = gamification.longestStreak.value;
          final freezes = gamification.streakFreezes.value;
          final practicedToday = gamification.practicedToday;
          final totalXp = gamification.xp.value;

          // Determine hearth stage
          final crestStyle = RpgCrestStyle.forStreak(currentStreak);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),

                // 1. Hero Campfire Hearth RPG Crest
                _buildHeroHearthCrest(colors, crestStyle, freezes > 0),
                const SizedBox(height: 20),

                // 2. Streak Number & Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$currentStreak',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.t('streak.days', null, 'Days'),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 3. Stage Pill Tag
                _buildStagePill(colors, crestStyle),
                const SizedBox(height: 16),

                // 4. Motivation Status Banner
                _buildMotivationBanner(context, colors, practicedToday),
                const SizedBox(height: 20),

                // 5. 30-Day Activity Heatmap Grid
                ActivityHeatmapCard(
                  colors: colors,
                  gamification: gamification,
                ),
                const SizedBox(height: 14),

                // 6. Next Streak Milestone Banner (linking streak to achievements roadmap)
                NextStreakMilestoneBanner(
                  colors: colors,
                  gamification: gamification,
                ),
                const SizedBox(height: 20),

                // 7. Stats Grid: Best Streak & Freeze Shields
                _buildStatsGrid(context, colors, longestStreak, freezes, totalXp, gamification),
                const SizedBox(height: 28),

                // 7. Freeze Shield Inventory Card
                _buildFreezeInventoryCard(context, colors, freezes, totalXp, gamification),
                const SizedBox(height: 32),

                // 8. Primary CTA Button: Practice Today's Words
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StudyDeckScreen()),
                      );
                    },
                    icon: const Icon(Icons.local_fire_department_rounded, size: 20),
                    label: Text(
                      context.t('streak.practiceToday', null, "Practice Today's Words"),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accentPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Hero Campfire Hearth RPG Crest Widget
  Widget _buildHeroHearthCrest(VocaColorPalette colors, RpgCrestStyle style, bool hasFrostWard) {
    IconData getStageIcon(RpgCrestStyle s) {
      switch (s) {
        case RpgCrestStyle.flameCold:
          return Icons.fireplace_outlined;
        case RpgCrestStyle.flameEmber:
          return Icons.local_fire_department_outlined;
        case RpgCrestStyle.flameBlaze:
          return Icons.local_fire_department_rounded;
        case RpgCrestStyle.flameBeacon:
          return Icons.whatshot_rounded;
        default:
          return Icons.local_fire_department_rounded;
      }
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Pulsing background glow
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: style.glowColor.withValues(alpha: 0.35),
            ),
          ),
        ),

        // RPG Shield Crest (Hero Size 80x92)
        RpgShieldCrest(
          width: 80,
          height: 92,
          style: style,
          icon: getStageIcon(style),
          iconSize: 42,
          innerInset: 3.0,
        ),

        // Floating Frost Ward shield badge if freeze is active
        if (hasFrostWard)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colors.bgCard,
                shape: BoxShape.circle,
                border: Border.all(color: colors.colorDiamond, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: colors.colorDiamond.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.shield_rounded,
                  size: 15,
                  color: colors.colorDiamond,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Campfire Stage Pill Tag
  Widget _buildStagePill(VocaColorPalette colors, RpgCrestStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fireplace_rounded, size: 14, color: style.glowColor),
          const SizedBox(width: 6),
          Text(
            style.displayName,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Motivation Status Banner
  Widget _buildMotivationBanner(BuildContext context, VocaColorPalette colors, bool practicedToday) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: practicedToday
            ? colors.success.withValues(alpha: 0.10)
            : colors.colorFire.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: practicedToday
              ? colors.success.withValues(alpha: 0.25)
              : colors.colorFire.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            practicedToday ? Icons.check_circle_rounded : Icons.bolt_rounded,
            color: practicedToday ? colors.success : colors.colorFire,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              practicedToday
                  ? context.t('streak.practicedToday', null, 'Embers burning brightly! Daily goal accomplished.')
                  : context.t('streak.keepStreak', null, 'Study today to keep your campfire blazing and protect your streak!'),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Stats Grid
  Widget _buildStatsGrid(
    BuildContext context,
    VocaColorPalette colors,
    int longestStreak,
    int freezes,
    int totalXp,
    GamificationService gamification,
  ) {
    return Row(
      children: [
        // Longest Streak
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.bgSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.accentTertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.accentTertiary.withValues(alpha: 0.25)),
                  ),
                  child: Icon(Icons.emoji_events_rounded, color: colors.accentTertiary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('streak.longestStreak', null, 'BEST RECORD'),
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$longestStreak days',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
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
        const SizedBox(width: 12),

        // Freezes Left
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.bgSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.colorDiamond.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.colorDiamond.withValues(alpha: 0.25)),
                  ),
                  child: Icon(Icons.shield_outlined, color: colors.colorDiamond, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('streak.freezesRemaining', null, 'FROST SHIELD'),
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$freezes / 2',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
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
    );
  }

  /// Freeze Shield Inventory & Replenish Card
  Widget _buildFreezeInventoryCard(
    BuildContext context,
    VocaColorPalette colors,
    int freezes,
    int totalXp,
    GamificationService gamification,
  ) {
    final canReplenish = freezes < 2 && totalXp >= 150;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.ac_unit_rounded, size: 18, color: colors.colorDiamond),
                  const SizedBox(width: 8),
                  Text(
                    context.t('streak.frostWardTitle', null, 'Frost Ward Protection'),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Replenish Button
              if (freezes < 2)
                ElevatedButton.icon(
                  onPressed: () async {
                    if (totalXp < 150) {
                      ToastService.info(
                        context,
                        'Need 150 XP to replenish a Frost Ward shield (You have $totalXp XP).',
                      );
                      return;
                    }

                    final success = await gamification.replenishFreeze();
                    if (context.mounted && success) {
                      ToastService.success(
                        context,
                        'Frost Ward replenished! +1 Shield active (-150 XP).',
                      );
                    }
                  },
                  icon: const Icon(Icons.add_rounded, size: 14),
                  label: const Text('+1 (150 XP)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canReplenish ? colors.colorDiamond : colors.bgHover,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.t(
              'streak.frostWardDesc',
              null,
              'Frost Ward shields preserve your streak if you miss an immersion day. Freezes automatically trigger when needed.',
            ),
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

  void _showStreakInfoDialog(BuildContext context, VocaColorPalette colors) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.borderColor),
        ),
        title: Text(
          ctx.t('streak.infoTitle', null, 'How Streaks Work'),
          style: TextStyle(color: colors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: Text(
          ctx.t(
            'streak.infoContent',
            null,
            '• Watch any video lesson or review flashcards once per calendar day to keep your streak.\n\n'
            '• 1-6 Days: Kindle Ember\n'
            '• 7-29 Days: Blazing Hearth\n'
            '• 30+ Days: Eternal Beacon\n\n'
            '• Frost Ward shields automatically protect your habit when life gets busy!',
          ),
          style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.t('common.gotIt', null, 'Got it'), style: TextStyle(color: colors.accentPrimary)),
          ),
        ],
      ),
    );
  }
}
