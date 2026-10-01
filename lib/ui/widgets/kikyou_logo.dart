// lib/ui/widgets/kikyou_logo.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';

/// Kikyou (Japanese bellflower) emblem widget representing VOCA.
class KikyouLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const KikyouLogo({
    super.key,
    this.size = 28,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _KikyouPainter(color ?? VocaTokens.accentPrimary),
      ),
    );
  }
}

class _KikyouPainter extends CustomPainter {
  final Color petalColor;

  _KikyouPainter(this.petalColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final petalPaint = Paint()
      ..color = petalColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Authentic Kikyou Japanese flower: 5 pointed petals
    const petals = 5;
    final path = Path();
    for (int i = 0; i < petals * 2; i++) {
      final angle = (i * math.pi / petals) - (math.pi / 2);
      final r = (i % 2 == 0) ? radius : radius * 0.42;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, petalPaint);

    // Center circle core
    final corePaint = Paint()
      ..color = const Color(0xFFFFFDFB)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius * 0.28, corePaint);

    final innerDot = Paint()
      ..color = petalColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius * 0.14, innerDot);
  }

  @override
  bool shouldRepaint(covariant _KikyouPainter oldDelegate) =>
      oldDelegate.petalColor != petalColor;
}
