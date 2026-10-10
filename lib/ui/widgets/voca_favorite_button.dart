// lib/ui/widgets/voca_favorite_button.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../services/haptic_service.dart';

/// Accessible, Material 3 Favorite Heart Button with spring bounce micro-interaction.
///
/// Features:
/// - Enforces standard 48x48dp M3 touch target (`kMinInteractiveDimension`).
/// - Spring scale bounce animation on favorite activation (1.0 -> 0.78 -> 1.28 -> 1.0).
/// - Tactile haptic feedback pairing ([HapticService.light]).
/// - M3 state layer with circular ink ripple.
/// - Full accessibility semantics for screen readers.
/// - Automatically disables spring bounce when [MediaQuery.maybeDisableAnimationsOf] is true.
class VocaFavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onToggle;
  final double iconSize;
  final Color? activeColor;
  final Color? inactiveColor;
  final String? tooltip;

  const VocaFavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onToggle,
    this.iconSize = 20.0,
    this.activeColor,
    this.inactiveColor,
    this.tooltip,
  });

  @override
  State<VocaFavoriteButton> createState() => _VocaFavoriteButtonState();
}

class _VocaFavoriteButtonState extends State<VocaFavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _scaleAnimation = TweenSequence<double>([
      // 1. Initial compression on touch
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.78).chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
      // 2. Spring pop overshoot
      TweenSequenceItem(
        tween: Tween(begin: 0.78, end: 1.28).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      // 3. Settle back to resting scale
      TweenSequenceItem(
        tween: Tween(begin: 1.28, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant VocaFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isFavorite && widget.isFavorite) {
      final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (!reduceMotion) {
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    final nextState = !widget.isFavorite;
    if (nextState) {
      HapticService.light();
      final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (!reduceMotion) {
        _controller.forward(from: 0.0);
      }
    } else {
      HapticService.selection();
    }
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final active = widget.activeColor ?? colors.accentPrimary;
    final inactive = widget.inactiveColor ?? colors.textMuted;
    final semanticLabel = widget.isFavorite ? 'Remove from favorites' : 'Add to favorites';

    return Semantics(
      button: true,
      label: semanticLabel,
      value: widget.isFavorite ? 'Favorited' : 'Not favorited',
      child: Tooltip(
        message: widget.tooltip ?? semanticLabel,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Material(
            color: Colors.transparent,
            child: InkResponse(
              onTap: _handleTap,
              containedInkWell: true,
              highlightShape: BoxShape.circle,
              radius: 22,
              child: Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Icon(
                    widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: widget.iconSize,
                    color: widget.isFavorite ? active : inactive,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
