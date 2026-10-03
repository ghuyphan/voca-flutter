// lib/ui/video/double_tap_seek_ripple.dart

import 'package:flutter/material.dart';

/// YouTube Mobile-style Double-Tap Seek Ripple Overlay
///
/// Renders an authentic curved semi-circular ripple arc covering the tapped half of the
/// video player with:
/// - A smooth inward-curving translucent arc (`Colors.white.withOpacity(0.18)`).
/// - 3 animated flashing chevron arrows (<<< for rewind, >>> for forward).
/// - Accumulator count label ("10s", "20s", "30s" etc.).
/// - Spring pop scale animation on every tap and smooth fade out.
class DoubleTapSeekRipple extends StatefulWidget {
  final bool isLeft;
  final int seconds;

  const DoubleTapSeekRipple({
    super.key,
    required this.isLeft,
    required this.seconds,
  });

  @override
  State<DoubleTapSeekRipple> createState() => _DoubleTapSeekRippleState();
}

class _DoubleTapSeekRippleState extends State<DoubleTapSeekRipple>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  late final AnimationController _arrowsController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
    _scaleController.forward();

    _arrowsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant DoubleTapSeekRipple oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seconds != widget.seconds) {
      _scaleController.forward(from: 0.8);
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _arrowsController.dispose();
    super.dispose();
  }

  Widget _buildChevron(int index) {
    return AnimatedBuilder(
      animation: _arrowsController,
      builder: (context, child) {
        // Staggered light sequence across the 3 chevrons (0, 1, 2)
        final progress = _arrowsController.value;
        // Direction: if left (rewind), animation flows right-to-left; if right, left-to-right
        final activeIndex = widget.isLeft ? (2 - index) : index;
        final phase = (progress * 3.0) - activeIndex;
        final opacity = (phase >= 0.0 && phase <= 1.2) ? 1.0 : 0.35;

        return Icon(
          widget.isLeft ? Icons.play_arrow_rounded : Icons.play_arrow_rounded,
          color: Colors.white.withOpacity(opacity),
          size: 20,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final borderRadius = widget.isLeft
            ? BorderRadius.horizontal(right: Radius.elliptical(height * 0.45, height))
            : BorderRadius.horizontal(left: Radius.elliptical(height * 0.45, height));

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: borderRadius,
          ),
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated 3-Chevron Arrow Group
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(widget.isLeft ? -1.0 : 1.0, 1.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildChevron(0),
                        _buildChevron(1),
                        _buildChevron(2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Accumulator text ("10s", "20s", etc.)
                  Text(
                    '${widget.seconds}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
