// lib/ui/gamification/widgets/celebration_confetti.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// High-performance, GPU-friendly confetti burst widget for celebration moments.
/// Drives CustomPainter directly via `repaint: _controller` with zero widget rebuilds,
/// zero offscreen `Opacity` saveLayer allocations, and realistic 3D paper flutter physics.
class CelebrationConfetti extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onFinished;

  const CelebrationConfetti({
    super.key,
    this.duration = const Duration(milliseconds: 2400),
    this.onFinished,
  });

  @override
  State<CelebrationConfetti> createState() => _CelebrationConfettiState();
}

class _CelebrationConfettiState extends State<CelebrationConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiParticle> _particles;
  bool _isDone = false;

  static const List<Color> _palette = [
    Color(0xFFFF6B82), // Radiant Coral
    Color(0xFF10B981), // Mint
    Color(0xFF38BDF8), // Sky Blue
    Color(0xFFF59E0B), // Warm Gold
    Color(0xFFEA580C), // Flame
    Color(0xFFA855F7), // Iris / Purple
  ];

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _particles = List.generate(42, (i) {
      // Fountain burst upward in a fan cone (-145 deg to -35 deg)
      final spreadAngle = -math.pi * 0.5 + (random.nextDouble() - 0.5) * math.pi * 0.72;
      final speed = 260.0 + random.nextDouble() * 340.0;
      return _ConfettiParticle(
        color: _palette[i % _palette.length],
        startX: 0.5 + (random.nextDouble() - 0.5) * 0.24,
        startY: 0.18 + (random.nextDouble() - 0.5) * 0.06,
        vx: math.cos(spreadAngle) * speed,
        vy: math.sin(spreadAngle) * speed,
        rotation: random.nextDouble() * math.pi * 2,
        rotationSpeed: (random.nextDouble() - 0.5) * 9.0,
        tumbleSpeed: 4.0 + random.nextDouble() * 6.0,
        tumblePhase: random.nextDouble() * math.pi * 2,
        swayAmp: 10.0 + random.nextDouble() * 18.0,
        swayFreq: 2.5 + random.nextDouble() * 3.0,
        width: 7.0 + random.nextDouble() * 4.5,
        height: 4.5 + random.nextDouble() * 3.5,
        isCircle: i % 4 == 0,
      );
    });

    _controller.forward().then((_) {
      if (!mounted) return;
      setState(() => _isDone = true);
      widget.onFinished?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDone) return const SizedBox.shrink();

    return IgnorePointer(
      ignoring: true,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(
            particles: _particles,
            animation: _controller,
          ),
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  final Color color;
  final double startX;
  final double startY;
  final double vx;
  final double vy;
  final double rotation;
  final double rotationSpeed;
  final double tumbleSpeed;
  final double tumblePhase;
  final double swayAmp;
  final double swayFreq;
  final double width;
  final double height;
  final bool isCircle;

  const _ConfettiParticle({
    required this.color,
    required this.startX,
    required this.startY,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.tumbleSpeed,
    required this.tumblePhase,
    required this.swayAmp,
    required this.swayFreq,
    required this.width,
    required this.height,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final Animation<double> animation;
  final Paint _paint = Paint()..style = PaintingStyle.fill;

  _ConfettiPainter({
    required this.particles,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t <= 0.0 || t >= 1.0) return;

    final fade = (1.0 - (t - 0.62) / 0.38).clamp(0.0, 1.0);
    if (fade <= 0.01) return;

    final timeSec = t * 2.4;
    // Air-drag damped displacement integral: (1 - e^(-k*t)) / k
    const drag = 2.2;
    final dragFactor = (1.0 - math.exp(-drag * timeSec)) / drag;
    const terminalGravity = 195.0;

    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];
      final sway = math.sin(timeSec * p.swayFreq + p.tumblePhase) * p.swayAmp * (timeSec * 0.6).clamp(0.0, 1.0);
      final x = (p.startX * size.width) + (p.vx * dragFactor) + sway;
      final y = (p.startY * size.height) + (p.vy * dragFactor) + (terminalGravity * timeSec * timeSec * 0.65);

      if (y > size.height + 16 || y < -40 || x < -16 || x > size.width + 16) {
        continue;
      }

      _paint.color = p.color.withValues(alpha: fade);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotation + (p.rotationSpeed * timeSec));

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.width * 0.42, _paint);
      } else {
        // 3D paper tumble illusion via horizontal cosine foreshortening
        final tumbleScaleY = math.cos(timeSec * p.tumbleSpeed + p.tumblePhase).abs().clamp(0.22, 1.0);
        final h = p.height * tumbleScaleY;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.width, height: h),
            const Radius.circular(2.0),
          ),
          _paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => false;
}

