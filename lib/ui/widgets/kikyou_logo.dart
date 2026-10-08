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
        painter: _KikyouPainter(color ?? context.vocaColors.accentPrimary),
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
    final radius = math.min(size.width, size.height) / 2;

    final petalPaint = Paint()
      ..color = petalColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.save();
    canvas.translate(center.dx, center.dy);

    final flowerPath = Path();
    final singlePetal = _createPetalPath(radius / 300.0);

    // 5 authentic Kikyou Japanese bellflower petals rotated radially
    for (int i = 0; i < 5; i++) {
      final matrix = Matrix4.rotationZ(i * 2 * math.pi / 5);
      flowerPath.addPath(singlePetal.transform(matrix.storage), Offset.zero);
    }

    // Single clean circular negative-space pistil cutout (even-odd fill rule)
    final pistilRadius = radius * (38.0 / 300.0);
    flowerPath.addOval(Rect.fromCircle(center: Offset.zero, radius: pistilRadius));
    flowerPath.fillType = PathFillType.evenOdd;

    canvas.drawPath(flowerPath, petalPaint);
    canvas.restore();
  }

  Path _createPetalPath(double scale) {
    final path = Path();
    path.moveTo(0, -300 * scale);
    path.cubicTo(
      5.0 * scale,
      -295.1 * scale,
      18.55 * scale,
      -287.5 * scale,
      34.34 * scale,
      -280.8 * scale,
    );
    path.cubicTo(
      69.0 * scale,
      -266.3 * scale,
      117.0 * scale,
      -227.9 * scale,
      108.65 * scale,
      -173.7 * scale,
    );
    path.cubicTo(
      106.5 * scale,
      -166.2 * scale,
      105.2 * scale,
      -161.9 * scale,
      101.75 * scale,
      -155.7 * scale,
    );
    path.lineTo(0, 0);
    path.lineTo(-101.75 * scale, -155.7 * scale);
    path.cubicTo(
      -105.2 * scale,
      -161.9 * scale,
      -106.5 * scale,
      -166.2 * scale,
      -108.65 * scale,
      -173.7 * scale,
    );
    path.cubicTo(
      -117.0 * scale,
      -227.9 * scale,
      -69.0 * scale,
      -266.3 * scale,
      -34.34 * scale,
      -280.8 * scale,
    );
    path.cubicTo(
      -18.55 * scale,
      -287.5 * scale,
      -5.0 * scale,
      -295.1 * scale,
      0,
      -300 * scale,
    );
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _KikyouPainter oldDelegate) =>
      oldDelegate.petalColor != petalColor;
}
