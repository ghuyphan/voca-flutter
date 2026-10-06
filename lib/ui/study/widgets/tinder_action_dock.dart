// lib/ui/study/widgets/tinder_action_dock.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/voca_theme.dart';

/// Refined circular action dock combining Tinder gesture ergonomics
/// with SuperMemo-2 / Anki spaced repetition intervals.
/// Uses Voca's obsidian dark theme with crisp 1.5px semantic borders,
/// spring press micro-interactions, and visual focus states.
class TinderActionDock extends StatelessWidget {
  final bool canUndo;
  final bool isRevealed;
  final String againInterval;
  final String hardInterval;
  final String goodInterval;
  final String easyInterval;
  final VoidCallback onUndo;
  final VoidCallback onAgain;
  final VoidCallback onHard;
  final VoidCallback onFlip;
  final VoidCallback onGood;
  final VoidCallback onEasy;

  const TinderActionDock({
    super.key,
    required this.canUndo,
    required this.isRevealed,
    this.againInterval = '<10m',
    this.hardInterval = '1d',
    this.goodInterval = '3d',
    this.easyInterval = '7d',
    required this.onUndo,
    required this.onAgain,
    required this.onHard,
    required this.onFlip,
    required this.onGood,
    required this.onEasy,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Undo / Rewind Button (38px, subtle neutral)
          _DockButton(
            size: 38,
            icon: Icons.replay_rounded,
            iconSize: 18,
            color: colors.textSecondary,
            label: 'Undo',
            isEnabled: canUndo,
            onTap: onUndo,
            colors: colors,
          ),

          // 2. Again Button (50px, Coral / Red)
          _DockButton(
            size: 50,
            icon: Icons.close_rounded,
            iconSize: 26,
            color: colors.error,
            label: againInterval,
            onTap: onAgain,
            colors: colors,
            isPrimary: true,
            isHighlighted: isRevealed,
          ),

          // 3. Hard Button (44px, Amber)
          _DockButton(
            size: 44,
            icon: Icons.hourglass_bottom_rounded,
            iconSize: 20,
            color: colors.warning,
            label: hardInterval,
            onTap: onHard,
            colors: colors,
            isHighlighted: isRevealed,
          ),

          // 4. Flip / Reveal Center Button (44px, Surface Neutral)
          _DockButton(
            size: 44,
            icon: isRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            iconSize: 20,
            color: colors.textPrimary,
            label: 'Flip',
            onTap: onFlip,
            colors: colors,
            isNeutral: true,
          ),

          // 5. Good Button (50px, Mint / Emerald)
          _DockButton(
            size: 50,
            icon: Icons.check_rounded,
            iconSize: 28,
            color: colors.colorGrammar,
            label: goodInterval,
            onTap: onGood,
            colors: colors,
            isPrimary: true,
            isHighlighted: isRevealed,
          ),

          // 6. Easy Button (44px, Electric Purple)
          _DockButton(
            size: 44,
            icon: Icons.star_rounded,
            iconSize: 22,
            color: colors.accentSecondary,
            label: easyInterval,
            onTap: onEasy,
            colors: colors,
            isHighlighted: isRevealed,
          ),
        ],
      ),
    );
  }
}

class _DockButton extends StatefulWidget {
  final double size;
  final IconData icon;
  final double iconSize;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final VocaColorPalette colors;
  final bool isEnabled;
  final bool isPrimary;
  final bool isNeutral;
  final bool isHighlighted;

  const _DockButton({
    required this.size,
    required this.icon,
    required this.iconSize,
    required this.color,
    required this.label,
    required this.onTap,
    required this.colors,
    this.isEnabled = true,
    this.isPrimary = false,
    this.isNeutral = false,
    this.isHighlighted = false,
  });

  @override
  State<_DockButton> createState() => _DockButtonState();
}

class _DockButtonState extends State<_DockButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.isNeutral
        ? widget.colors.borderColor
        : widget.color.withValues(
            alpha: widget.isPrimary
                ? (widget.isHighlighted ? 0.90 : 0.70)
                : (widget.isHighlighted ? 0.70 : 0.45),
          );

    return Opacity(
      opacity: widget.isEnabled ? 1.0 : 0.35,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.isEnabled
            ? (_) {
                setState(() => _isPressed = false);
                HapticFeedback.lightImpact();
                widget.onTap();
              }
            : null,
        onTapCancel: widget.isEnabled ? () => setState(() => _isPressed = false) : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isNeutral ? widget.colors.bgSurface : widget.colors.bgCard,
                  border: Border.all(
                    color: borderColor,
                    width: widget.isPrimary ? 2.0 : 1.4,
                  ),
                  boxShadow: [
                    if (widget.isEnabled)
                      BoxShadow(
                        color: (widget.isHighlighted && !widget.isNeutral
                                ? widget.color
                                : Colors.black)
                            .withValues(alpha: widget.isHighlighted ? 0.25 : 0.3),
                        blurRadius: widget.isHighlighted ? 10 : 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    widget.icon,
                    size: widget.iconSize,
                    color: widget.isNeutral ? widget.colors.textPrimary : widget.color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Interval Label
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isEnabled
                      ? (widget.isNeutral ? widget.colors.textSecondary : widget.color)
                      : widget.colors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
