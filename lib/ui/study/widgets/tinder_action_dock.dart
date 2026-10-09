// lib/ui/study/widgets/tinder_action_dock.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';

/// Clean, tactile 4-button SRS Action Dock matching the canonical review UI.
/// Features centered swipe hint and 4 large rounded buttons (Again, Hard, Good, Easy)
/// with colored borders, intervals, and subtle spring press micro-interactions.
class TinderActionDock extends StatelessWidget {
  final String againInterval;
  final String hardInterval;
  final String goodInterval;
  final String easyInterval;
  final VoidCallback onAgain;
  final VoidCallback onHard;
  final VoidCallback onGood;
  final VoidCallback onEasy;

  const TinderActionDock({
    super.key,
    this.againInterval = '<1 min',
    this.hardInterval = '1 d',
    this.goodInterval = '1 d',
    this.easyInterval = '2 d',
    required this.onAgain,
    required this.onHard,
    required this.onGood,
    required this.onEasy,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Centered 4-way Gesture Hint
          Text(
            context.t('study.swipeHint4Way', null, 'Swipe ← Again · → Good · ↓ Hard · ↑ Easy'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          // Row of 4 Material 3 Action Buttons [ Again | Hard | Good | Easy ]
          Row(
            children: [
              // 1. Again (Coral)
              Expanded(
                child: _SrsActionButton(
                  title: context.t('study.again', null, 'Again'),
                  interval: againInterval,
                  semanticColor: colors.accentPrimary,
                  borderColor: colors.accentPrimary.withValues(alpha: isDark ? 0.35 : 0.28),
                  bgColor: colors.accentPrimary.withValues(alpha: isDark ? 0.12 : 0.08),
                  onTap: onAgain,
                ),
              ),
              const SizedBox(width: 8),

              // 2. Hard (Orange Flame)
              Expanded(
                child: _SrsActionButton(
                  title: context.t('study.hard', null, 'Hard'),
                  interval: hardInterval,
                  semanticColor: colors.colorFire,
                  borderColor: colors.colorFire.withValues(alpha: isDark ? 0.35 : 0.28),
                  bgColor: colors.colorFire.withValues(alpha: isDark ? 0.12 : 0.08),
                  onTap: onHard,
                ),
              ),
              const SizedBox(width: 8),

              // 3. Good (Mint Green)
              Expanded(
                child: _SrsActionButton(
                  title: context.t('study.good', null, 'Good'),
                  interval: goodInterval,
                  semanticColor: colors.success,
                  borderColor: colors.success.withValues(alpha: isDark ? 0.35 : 0.28),
                  bgColor: colors.success.withValues(alpha: isDark ? 0.12 : 0.08),
                  onTap: onGood,
                ),
              ),
              const SizedBox(width: 8),

              // 4. Easy (Iris / Violet)
              Expanded(
                child: _SrsActionButton(
                  title: context.t('study.easy', null, 'Easy'),
                  interval: easyInterval,
                  semanticColor: colors.accentSecondary,
                  borderColor: colors.accentSecondary.withValues(alpha: isDark ? 0.35 : 0.28),
                  bgColor: colors.accentSecondary.withValues(alpha: isDark ? 0.12 : 0.08),
                  onTap: onEasy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Material 3 Tonal Card Action Button with native ink splash ripples
class _SrsActionButton extends StatefulWidget {
  final String title;
  final String interval;
  final Color semanticColor;
  final Color borderColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _SrsActionButton({
    required this.title,
    required this.interval,
    required this.semanticColor,
    required this.borderColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  State<_SrsActionButton> createState() => _SrsActionButtonState();
}

class _SrsActionButtonState extends State<_SrsActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return AnimatedScale(
      scale: _isPressed ? 0.94 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: Semantics(
        button: true,
        label: '${widget.title}, interval ${widget.interval}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.semanticColor.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: widget.bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: widget.borderColor, width: 1.2),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onTap();
              },
              splashColor: widget.semanticColor.withValues(alpha: 0.16),
              highlightColor: widget.semanticColor.withValues(alpha: 0.08),
              child: Container(
                height: 60,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.semanticColor,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.interval,
                    textAlign: TextAlign.center,
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
          ),
        ),
      ),
    ),
  );
  }
}
