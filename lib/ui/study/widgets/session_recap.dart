// lib/ui/study/widgets/session_recap.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../models/study_session_models.dart';
import '../../../services/audio_service.dart';
import '../../../services/haptic_service.dart';
import '../../../services/i18n_service.dart';
import '../../../state/app_state.dart';
import '../../gamification/widgets/animated_fire_icon.dart';
import '../../gamification/widgets/celebration_confetti.dart';
import '../../gamification/widgets/rpg_shield_crest.dart';

/// Highly-polished, consistent Session Recap Screen.
/// Uses authentic RPG shield crests with spring pop entrance,
/// balanced 2x2 performance metrics grid, and rewarding XP/streak summaries.
class SessionRecap extends StatefulWidget {
  final SessionStats stats;
  final VoidCallback onDone;
  final VoidCallback? onKeepGoing;
  final VoidCallback? onReviewAgain;
  final VoidCallback? onClose;

  const SessionRecap({
    super.key,
    required this.stats,
    required this.onDone,
    this.onKeepGoing,
    this.onReviewAgain,
    this.onClose,
  });

  @override
  State<SessionRecap> createState() => _SessionRecapState();
}

class _SessionRecapState extends State<SessionRecap>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _crestScaleAnimation;
  late final Animation<double> _crestFadeAnimation;

  late final AnimationController _crestBreathingController;
  late final AnimationController _countersController;
  late final Animation<double> _countersAnimation;

  @override
  void initState() {
    super.initState();

    // 1:1 with web's crestPop: 500ms cubic-bezier(0.34, 1.56, 0.64, 1)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _crestScaleAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Cubic(0.34, 1.56, 0.64, 1.0),
      ),
    );

    _crestFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
      ),
    );

    // Continuous ambient breathing glow on the crest
    _crestBreathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // Smooth counting up animation for metrics, XP, and streak
    _countersController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _countersAnimation = CurvedAnimation(
      parent: _countersController,
      curve: Curves.easeOutCubic,
    );

    _entranceController.forward();
    _countersController.forward();

    // Play celebratory victory fanfare sound effect on session finish
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AudioService.instance.playVictoryChime();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _crestBreathingController.dispose();
    _countersController.dispose();
    super.dispose();
  }

  void _handleDone() {
    HapticService.medium();
    widget.onDone();
  }

  void _handleClose() {
    HapticService.light();
    (widget.onClose ?? widget.onDone)();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final streak = AppState.instance.currentStreak.value;
    final accuracy = widget.stats.totalReviewed > 0
        ? widget.stats.accuracyRate.round()
        : 100;
    final isTablet = MediaQuery.sizeOf(context).width >= 600.0;
    final displayCardsCount = widget.stats.uniqueCardsCount > 0
        ? widget.stats.uniqueCardsCount
        : widget.stats.totalReviewed;
    final xpGained = displayCardsCount * 10;

    // Rank tier based on accuracy
    final isGold = accuracy >= 90;
    final isSilver = accuracy >= 75 && accuracy < 90;
    final crestStyle = isGold
        ? RpgCrestStyle.gold
        : (isSilver ? RpgCrestStyle.silver : RpgCrestStyle.bronze);

    final rankTitle = isGold
        ? context.t('gamification.gold', null, 'Gold Champion')
        : (isSilver
            ? context.t('gamification.silver', null, 'Silver Knight')
            : context.t('gamification.bronze', null, 'Bronze Warrior'));

    final rankColor = isGold
        ? colors.accentTertiary
        : (isSilver ? const Color(0xFFCBD5E1) : const Color(0xFFF59E0B));

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 560 : double.infinity),
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // 1. RPG Shield Crest with Spring Pop & Living Ambient Breathing Glow
                  RepaintBoundary(
                    child: ScaleTransition(
                      scale: _crestScaleAnimation,
                      child: FadeTransition(
                        opacity: _crestFadeAnimation,
                        child: SizedBox(
                          width: 110,
                          height: 110,
                          child: AnimatedBuilder(
                            animation: _crestBreathingController,
                            child: RpgShieldCrest(
                              width: 86,
                              height: 98,
                              style: crestStyle,
                              icon: isGold ? Icons.emoji_events_rounded : Icons.shield_rounded,
                              iconSize: 42,
                              showGlow: false,
                            ),
                            builder: (context, crestChild) {
                              final glowPulse = 0.20 + (0.16 * _crestBreathingController.value);
                              final glowSpread = 2.0 + (3.0 * _crestBreathingController.value);
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 86,
                                    height: 86,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: crestStyle.glowColor.withValues(alpha: glowPulse),
                                          blurRadius: 26,
                                          spreadRadius: glowSpread,
                                        ),
                                      ],
                                    ),
                                  ),
                                  crestChild!,
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Rank Title Badge & Session Complete Copy (Statically anchored)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: rankColor.withValues(alpha: 0.12),
                          borderRadius: VocaRadius.roundedPill,
                          border: Border.all(color: rankColor.withValues(alpha: 0.35), width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isGold ? Icons.star_rounded : Icons.military_tech_rounded,
                              size: 14,
                              color: rankColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              rankTitle,
                              style: TextStyle(
                                color: rankColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.t('flashcards.sessionComplete', null, 'Session Complete!'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.t('flashcards.sessionCompleteDesc', null, 'All scheduled reviews for this queue are finished.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // 3. Streak & Rewards Row with Animated Fire Icon & Rolling Numbers
                  AnimatedBuilder(
                    animation: _countersAnimation,
                    builder: (context, _) {
                      final animatedStreak = (streak * _countersAnimation.value).round();
                      final animatedXp = (xpGained * _countersAnimation.value).round();

                      return Row(
                        children: [
                          // Streak Card with living animated fire icon
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: colors.bgCard,
                                borderRadius: VocaRadius.roundedLg,
                                border: Border.all(color: colors.colorFire.withValues(alpha: 0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.colorFire.withValues(alpha: 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: colors.colorFire.withValues(alpha: 0.14),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: AnimatedFireIcon(size: 20),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '$animatedStreak ${context.t('gamification.dayStreak', null, 'Days')}',
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    context.t('flashcards.keepItUp', null, 'Streak active! 🔥'),
                                    style: TextStyle(color: colors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // XP Gained Card with rolling XP number
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: colors.bgCard,
                                borderRadius: VocaRadius.roundedLg,
                                border: Border.all(color: colors.accentTertiary.withValues(alpha: 0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.accentTertiary.withValues(alpha: 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: colors.accentTertiary.withValues(alpha: 0.14),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.bolt_rounded, color: colors.accentTertiary, size: 18),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '+$animatedXp XP',
                                          style: TextStyle(
                                            color: colors.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    context.t('gamification.earnedXp', null, 'Study bonus earned'),
                                    style: TextStyle(color: colors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  // 4. Balanced 2x2 Performance Metrics Grid
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.bgCard,
                      borderRadius: VocaRadius.roundedXl,
                      border: Border.all(color: colors.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: colors.isDark ? 0.3 : 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.insights_rounded, size: 16, color: colors.accentPrimary),
                            const SizedBox(width: 8),
                            Text(
                              context.t('flashcards.sessionRecap', null, 'PERFORMANCE BREAKDOWN'),
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Row 1: Cards Reviewed & Accuracy %
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                icon: Icons.style_rounded,
                                iconColor: colors.accentPrimary,
                                label: context.t('flashcards.recapReviewed', null, 'Cards Reviewed'),
                                targetValue: displayCardsCount.toDouble(),
                                suffix: '',
                                colors: colors,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricTile(
                                icon: Icons.pie_chart_rounded,
                                iconColor: accuracy >= 80 ? colors.colorGrammar : colors.warning,
                                label: context.t('flashcards.recapAccuracy', null, 'Accuracy Rate'),
                                targetValue: accuracy.toDouble(),
                                suffix: '%',
                                colors: colors,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Row 2: Good/Easy Count & Missed Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                icon: Icons.check_circle_rounded,
                                iconColor: colors.colorGrammar,
                                label: context.t('flashcards.recapGoodEasy', null, 'Good / Easy'),
                                targetValue: widget.stats.goodOrEasyCount.toDouble(),
                                suffix: '',
                                colors: colors,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricTile(
                                icon: Icons.replay_rounded,
                                iconColor: widget.stats.againOrHardCount > 0 ? colors.error : colors.textMuted,
                                label: context.t('flashcards.recapAgainHard', null, 'Missed / Retry'),
                                targetValue: widget.stats.againOrHardCount.toDouble(),
                                suffix: '',
                                colors: colors,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 5. Action Buttons Row/Column
                  Column(
                    children: [
                      // Review Missed Cards Button (M3 FilledButton.tonal secondary recovery CTA)
                      if (widget.onReviewAgain != null && widget.stats.againOrHardCount > 0) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.tonalIcon(
                            onPressed: () {
                              HapticService.medium();
                              widget.onReviewAgain?.call();
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 19),
                            label: Text(
                              context.t(
                                'study.reviewMissedCards',
                                {'count': widget.stats.againOrHardCount.toString()},
                                'Review Missed Cards (${widget.stats.againOrHardCount})',
                              ),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.accentPrimary.withValues(alpha: 0.12),
                              foregroundColor: colors.accentPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Keep Going / Study Next Batch Button (Matching Explore Videos tonal button from Overview)
                      if (widget.onKeepGoing != null) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: FilledButton.tonalIcon(
                            onPressed: () {
                              HapticService.selection();
                              widget.onKeepGoing?.call();
                            },
                            icon: const Icon(Icons.play_arrow_rounded, size: 20),
                            label: Text(
                              context.t('study.continueNextBatch', null, 'Continue (Next Batch)'),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.accentPrimary.withValues(alpha: 0.12),
                              foregroundColor: colors.accentPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Primary Done / Back to Deck Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _handleDone,
                          icon: const Icon(Icons.check_rounded, size: 20),
                          label: Text(
                            context.t('study.done', null, 'Done'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.accentPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Confetti Particle Shower Celebration Overlay (GPU-isolated RepaintBoundary, ignores touches)
            const Positioned.fill(
              child: RepaintBoundary(
                child: CelebrationConfetti(),
              ),
            ),

            // Top-right close button (min 48x48 hit target)
            Positioned(
              top: 4,
              right: 4,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close_rounded, size: 18, color: colors.textMuted),
                      padding: EdgeInsets.zero,
                      tooltip: context.t('common.close', null, 'Close'),
                      onPressed: _handleClose,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Individual 2x2 Metric Cell with animated counter
  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required double targetValue,
    required String suffix,
    required VocaColorPalette colors,
  }) {
    return AnimatedBuilder(
      animation: _countersAnimation,
      builder: (context, _) {
        final animatedVal = (targetValue * _countersAnimation.value).round();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.borderColorLight),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$animatedVal$suffix',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
