// lib/ui/widgets/voca_shimmer.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';

/// Unified Skeleton Loading Wave Shimmer
///
/// Ported from lingua-tube/src/styles/_skeletons.scss:
/// - 1.6s ease-in-out infinite wave animation loop
/// - 90deg gradient: bgSecondary (0%) -> bgHover (50%) -> bgSecondary (100%)
/// - Accessibility & reduced-motion support (pauses shimmer when reduced motion is preferred)
class VocaShimmer extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;
  final bool enabled;

  const VocaShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1600),
    this.enabled = true,
  });

  /// Shimmering box / rectangle with customizable width, height, and border radius
  factory VocaShimmer.box({
    Key? key,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    Color? baseColor,
    Color? highlightColor,
    bool enabled = true,
  }) {
    return VocaShimmer(
      key: key,
      baseColor: baseColor,
      highlightColor: highlightColor,
      enabled: enabled,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// Shimmering text placeholder line (defaults to height: 12)
  factory VocaShimmer.line({
    Key? key,
    double? width,
    double height = 12.0,
    BorderRadius? borderRadius,
    Color? baseColor,
    Color? highlightColor,
    bool enabled = true,
  }) {
    return VocaShimmer.box(
      key: key,
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(4),
      baseColor: baseColor,
      highlightColor: highlightColor,
      enabled: enabled,
    );
  }

  /// Shimmering circle placeholder (for avatars, badges, circular buttons)
  factory VocaShimmer.circle({
    Key? key,
    required double size,
    Color? baseColor,
    Color? highlightColor,
    bool enabled = true,
  }) {
    return VocaShimmer(
      key: key,
      baseColor: baseColor,
      highlightColor: highlightColor,
      enabled: enabled,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  State<VocaShimmer> createState() => _VocaShimmerState();
}

class _VocaShimmerState extends State<VocaShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(VocaShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final base = widget.baseColor ?? colors.bgSecondary;
    final highlight = widget.highlightColor ?? colors.bgHover;

    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (!widget.enabled || disableAnimations) {
      return ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: [base, base],
        ).createShader(bounds),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _animation.value;
            final dx = -2.0 + 4.0 * t;
            return LinearGradient(
              begin: Alignment(dx - 1.0, 0.0),
              end: Alignment(dx + 1.0, 0.0),
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
