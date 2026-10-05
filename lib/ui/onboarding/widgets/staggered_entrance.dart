import 'dart:async';
import 'package:flutter/material.dart';

/// Fades + slides its child up once, after `index * stepDelay`.
/// Respects reduced-motion settings.
class StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration stepDelay;
  final Duration baseDelay;
  final double offsetY;

  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.stepDelay = const Duration(milliseconds: 45),
    this.baseDelay = const Duration(milliseconds: 60),
    this.offsetY = 14,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _curve =
      CurvedAnimation(parent: _c, curve: const Cubic(0.16, 1.0, 0.3, 1.0));
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations) {
      _c.value = 1.0;
      return;
    }
    final delay = widget.baseDelay + widget.stepDelay * widget.index;
    _timer = Timer(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _timer?.cancel();
      _c.value = 1.0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _curve.value) * widget.offsetY),
          child: child,
        ),
      ),
    );
  }
}
