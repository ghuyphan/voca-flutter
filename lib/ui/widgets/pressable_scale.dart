// lib/ui/widgets/pressable_scale.dart

import 'package:flutter/material.dart';
import '../../services/haptic_service.dart';

/// Native-feeling press feedback: scales down slightly while pressed, springs back,
/// and fires a selection haptic on tap.
///
/// Material 3 tactile enhancement for cards, primary tiles, and action surfaces.
/// Supports both standalone tap handling and passive wrapper mode around [InkWell].
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final bool haptic;
  final bool enabled;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.985,
    this.haptic = true,
    this.enabled = true,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool v) {
    if (!widget.enabled || _pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    if (!widget.enabled) {
      return widget.child;
    }

    final scaledChild = AnimatedScale(
      scale: _pressed && !reduceMotion ? widget.pressedScale : 1.0,
      duration: Duration(milliseconds: _pressed ? 90 : 220),
      curve: _pressed ? Curves.easeOut : const Cubic(0.34, 1.56, 0.64, 1.0),
      child: widget.child,
    );

    // If caller provided onTap, handle tap and haptics explicitly
    if (widget.onTap != null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: () {
          if (widget.haptic) HapticService.selection();
          widget.onTap!();
        },
        child: scaledChild,
      );
    }

    // Passive mode: wraps an existing InkWell or button without competing for gestures
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: scaledChild,
    );
  }
}
