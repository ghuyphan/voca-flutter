// lib/ui/study/widgets/tinder_action_dock.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/haptic_service.dart';
import '../../../services/i18n_service.dart';

/// Material 3 Expressive Connected Button Group for SRS grading (Again, Hard, Good, Easy).
/// Uses calm surface container hierarchy (`bgCard`), restrained semantic accents,
/// directional swipe icons, and M3 corner radius morphing on press.
class TinderActionDock extends StatelessWidget {
  final String againInterval;
  final String hardInterval;
  final String goodInterval;
  final String easyInterval;
  final bool isRevealed;
  final VoidCallback onAgain;
  final VoidCallback onHard;
  final VoidCallback onGood;
  final VoidCallback onEasy;
  final VoidCallback? onShowAnswer;

  const TinderActionDock({
    super.key,
    this.againInterval = '<1 min',
    this.hardInterval = '1 d',
    this.goodInterval = '1 d',
    this.easyInterval = '2 d',
    this.isRevealed = true,
    required this.onAgain,
    required this.onHard,
    required this.onGood,
    required this.onEasy,
    this.onShowAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: !isRevealed
            ? KeyedSubtree(
                key: const ValueKey('front_dock'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.t('study.tapToRevealHint', null, 'Tap card or button below to reveal answer'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: onShowAnswer,
                        icon: const Icon(Icons.visibility_rounded, size: 20),
                        label: Text(
                          context.t('study.showAnswer', null, 'Show Answer'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.accentPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: VocaRadius.roundedPill,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : KeyedSubtree(
                key: const ValueKey('back_dock'),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colors.bgSecondary.withValues(alpha: 0.85)
                        : colors.bgSecondary,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colors.borderColorLight,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // 1. Again (Swipe Left - Coral)
                      Expanded(
                        child: _SrsSegmentButton(
                          title: context.t('study.again', null, 'Again'),
                          interval: againInterval,
                          directionIcon: Icons.west_rounded,
                          semanticColor: colors.accentPrimary,
                           restingBorderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(20),
                            right: Radius.circular(6),
                          ),
                          onTap: onAgain,
                        ),
                      ),
                      const SizedBox(width: 3),

                      // 2. Hard (Swipe Down - Amber/Flame)
                      Expanded(
                        child: _SrsSegmentButton(
                          title: context.t('study.hard', null, 'Hard'),
                          interval: hardInterval,
                          directionIcon: Icons.south_rounded,
                          semanticColor: colors.colorFire,
                          restingBorderRadius: BorderRadius.circular(6),
                          onTap: onHard,
                        ),
                      ),
                      const SizedBox(width: 3),

                      // 3. Good (Swipe Right - Mint Green)
                      Expanded(
                        child: _SrsSegmentButton(
                          title: context.t('study.good', null, 'Good'),
                          interval: goodInterval,
                          directionIcon: Icons.east_rounded,
                          semanticColor: colors.success,
                          restingBorderRadius: BorderRadius.circular(6),
                          onTap: onGood,
                        ),
                      ),
                      const SizedBox(width: 3),

                      // 4. Easy (Swipe Up - Sky/Iris)
                      Expanded(
                        child: _SrsSegmentButton(
                          title: context.t('study.easy', null, 'Easy'),
                          interval: easyInterval,
                          directionIcon: Icons.north_rounded,
                          semanticColor: colors.accentSecondary,
                          restingBorderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(6),
                            right: Radius.circular(20),
                          ),
                          onTap: onEasy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Individual segment in the M3 Connected Button Group with shape morphing on press.
class _SrsSegmentButton extends StatefulWidget {
  final String title;
  final String interval;
  final IconData directionIcon;
  final Color semanticColor;
  final BorderRadius restingBorderRadius;
  final VoidCallback onTap;

  const _SrsSegmentButton({
    required this.title,
    required this.interval,
    required this.directionIcon,
    required this.semanticColor,
    required this.restingBorderRadius,
    required this.onTap,
  });

  @override
  State<_SrsSegmentButton> createState() => _SrsSegmentButtonState();
}

class _SrsSegmentButtonState extends State<_SrsSegmentButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final isDark = context.isDarkMode;

    // M3 Expressive shape morph: connected inner corners (6dp) morph to 16dp when pressed
    final effectiveRadius = _isPressed
        ? BorderRadius.circular(16)
        : widget.restingBorderRadius;

    final surfaceColor = _isPressed
        ? widget.semanticColor.withValues(alpha: isDark ? 0.22 : 0.14)
        : colors.bgCard;

    final borderColor = _isPressed
        ? widget.semanticColor.withValues(alpha: 0.55)
        : colors.borderColor.withValues(alpha: isDark ? 0.7 : 0.5);

    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: Semantics(
        button: true,
        label: '${widget.title}, interval ${widget.interval}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: effectiveRadius,
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: effectiveRadius,
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: () {
                HapticService.light();
                widget.onTap();
              },
              splashColor: widget.semanticColor.withValues(alpha: 0.18),
              highlightColor: widget.semanticColor.withValues(alpha: 0.08),
              child: Container(
                height: 60,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.directionIcon,
                          size: 13,
                          color: widget.semanticColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.interval,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.semanticColor.withValues(alpha: isDark ? 0.9 : 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

