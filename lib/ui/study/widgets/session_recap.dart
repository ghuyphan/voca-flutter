// lib/ui/study/widgets/session_recap.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/voca_theme.dart';
import '../../../models/study_session_models.dart';
import '../../../services/i18n_service.dart';
import '../../../state/app_state.dart';
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _crestScaleAnimation;
  late final Animation<double> _crestFadeAnimation;

  @override
  void initState() {
    super.initState();

    // 1:1 with web's crestPop: 500ms cubic-bezier(0.34, 1.56, 0.64, 1)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _handleDone() {
    HapticFeedback.mediumImpact();
    widget.onDone();
  }

  void _handleClose() {
    HapticFeedback.lightImpact();
    (widget.onClose ?? widget.onDone)();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final streak = AppState.instance.currentStreak.value;
    final accuracy = widget.stats.totalReviewed > 0
        ? widget.stats.accuracyRate.round()
        : 100;
    final isTablet = MediaQuery.of(context).size.width >= VocaTokens.tabletBreakpoint;
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

                  // 1. RPG Shield Crest with Spring Pop & Subtle Ambient Glow
                  ScaleTransition(
                    scale: _crestScaleAnimation,
                    child: FadeTransition(
                      opacity: _crestFadeAnimation,
                      child: SizedBox(
                        width: 110,
                        height: 110,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: crestStyle.glowColor.withValues(alpha: 0.24),
                                    blurRadius: 24,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            RpgShieldCrest(
                              width: 86,
                              height: 98,
                              style: crestStyle,
                              icon: isGold ? Icons.emoji_events_rounded : Icons.shield_rounded,
                              iconSize: 42,
                              showGlow: false,
                            ),
                          ],
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

                  // 3. Streak & Rewards Row
                  Row(
                    children: [
                      // Streak Card
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
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: colors.colorFire.withValues(alpha: 0.14),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.local_fire_department_rounded, color: colors.colorFire, size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '$streak ${context.t('gamification.dayStreak', null, 'Days')}',
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

                      // XP Gained Card
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
                                      '+$xpGained XP',
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
                      // Review Missed Cards Button (if any)
                      if (widget.onReviewAgain != null && widget.stats.againOrHardCount > 0) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              widget.onReviewAgain?.call();
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 19),
                            label: Text(
                              context.t(
                                'study.reviewMissedCards',
                                {'count': widget.stats.againOrHardCount.toString()},
                                'Review Missed Cards (${widget.stats.againOrHardCount})',
                              ),
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.accentPrimary,
                              side: BorderSide(color: colors.accentPrimary, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: VocaRadius.roundedPill),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Keep Going / Study Next Batch Button
                      if (widget.onKeepGoing != null) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              widget.onKeepGoing?.call();
                            },
                            icon: const Icon(Icons.play_arrow_rounded, size: 20),
                            label: Text(
                              context.t('study.continueNextBatch', null, 'Continue (Next Batch)'),
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.textPrimary,
                              side: BorderSide(color: colors.borderColor),
                              shape: RoundedRectangleBorder(borderRadius: VocaRadius.roundedPill),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Primary Done / Back to Deck Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _handleDone,
                          icon: const Icon(Icons.check_rounded, size: 20),
                          label: Text(
                            context.t('study.done', null, 'Done'),
                            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.accentPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: VocaRadius.roundedPill),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
                  '${targetValue.round()}$suffix',
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
  }
}
