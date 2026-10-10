// lib/ui/gamification/widgets/animated_fire_icon.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';

/// A self-contained, smooth vector animated flame icon that dances and flickers
/// within its own icon bounds without cluttering surrounding UI.
class AnimatedFireIcon extends StatefulWidget {
  final double size;
  final Color? color;
  final Color? innerColor;

  const AnimatedFireIcon({
    super.key,
    this.size = 20.0,
    this.color,
    this.innerColor,
  });

  @override
  State<AnimatedFireIcon> createState() => _AnimatedFireIconState();
}

class _AnimatedFireIconState extends State<AnimatedFireIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final baseColor = widget.color ?? colors.colorFire;
    final coreColor = widget.innerColor ?? const Color(0xFFFBBF24);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _FireIconPainter(
              progress: _controller.value,
              outerColor: baseColor,
              innerColor: coreColor,
            ),
          );
        },
      ),
    );
  }
}

class _FireIconPainter extends CustomPainter {
  final double progress;
  final Color outerColor;
  final Color innerColor;

  _FireIconPainter({
    required this.progress,
    required this.outerColor,
    required this.innerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Phase angles for organic non-linear flame oscillation
    final phase1 = progress * 2 * math.pi;
    final phase2 = (progress * 2 * math.pi) + (math.pi / 3);

    // Tip sway & stretch harmonics
    final tipSway = math.sin(phase1) * (w * 0.07);
    final tipStretch = math.cos(phase2) * (h * 0.05);

    final leftLickSway = math.sin(phase2 + 1.0) * (w * 0.05);
    final rightLickSway = math.cos(phase1 + 0.5) * (w * 0.04);

    // 1. Outer Flame Body
    final outerPath = Path();
    final centerX = w * 0.5;
    final bottomY = h * 0.94;

    // Main flame tip
    final tipX = centerX + tipSway;
    final tipY = h * 0.06 + tipStretch;

    outerPath.moveTo(tipX, tipY);

    // Right curve down with secondary lick
    outerPath.cubicTo(
      w * 0.78 + rightLickSway, h * 0.28,
      w * 0.92, h * 0.52,
      w * 0.82, h * 0.74,
    );
    outerPath.cubicTo(
      w * 0.74, h * 0.90,
      centerX + (w * 0.28), bottomY,
      centerX, bottomY,
    );

    // Left curve up with secondary lick
    outerPath.cubicTo(
      centerX - (w * 0.28), bottomY,
      w * 0.26, h * 0.90,
      w * 0.18, h * 0.74,
    );
    outerPath.cubicTo(
      w * 0.08, h * 0.52,
      w * 0.22 + leftLickSway, h * 0.28,
      tipX, tipY,
    );
    outerPath.close();

    final outerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          outerColor,
          Color.lerp(outerColor, const Color(0xFFF97316), 0.6) ?? outerColor,
          const Color(0xFFFBBF24),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(outerPath, outerPaint);

    // 2. Inner Flame Core (dances out of phase)
    final innerProgress = (progress + 0.25) % 1.0;
    final innerPhase = innerProgress * 2 * math.pi;
    final innerTipSway = math.sin(innerPhase) * (w * 0.05);
    final innerStretch = math.cos(innerPhase + 0.8) * (h * 0.04);

    final innerTipX = centerX + innerTipSway;
    final innerTipY = h * 0.40 + innerStretch;

    final innerPath = Path();
    innerPath.moveTo(innerTipX, innerTipY);

    innerPath.cubicTo(
      centerX + (w * 0.22), h * 0.54,
      centerX + (w * 0.26), h * 0.78,
      centerX, bottomY * 0.96,
    );
    innerPath.cubicTo(
      centerX - (w * 0.26), h * 0.78,
      centerX - (w * 0.22), h * 0.54,
      innerTipX, innerTipY,
    );
    innerPath.close();

    final innerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          innerColor,
          const Color(0xFFFEF08A),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(innerPath, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _FireIconPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.outerColor != outerColor ||
        oldDelegate.innerColor != innerColor;
  }
}
