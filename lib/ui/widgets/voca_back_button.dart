// lib/ui/widgets/voca_back_button.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../onboarding/widgets/pressable_scale.dart';

/// Unified signature Voca Back Button.
/// Matches the 1:1 circular framed button in Voca design tokens:
/// - 40x40 circle container (with >= 44x44 thumb accessibility target)
/// - colors.bgSurface background
/// - 1.0px colors.borderColor outline
/// - colors.textPrimary icon with soft press feedback & haptic
class VocaBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;
  final double iconSize;
  final String? tooltip;
  final IconData icon;

  const VocaBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.size = 40,
    this.iconSize = 20,
    this.tooltip,
    this.icon = Icons.arrow_back_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final resolvedTooltip = tooltip ?? context.t('common.back', null, 'Back');
    final effectiveOnPressed = onPressed ?? () => Navigator.of(context).maybePop();

    return Semantics(
      button: true,
      label: resolvedTooltip,
      child: Tooltip(
        message: resolvedTooltip,
        child: SizedBox(
          width: size < 48 ? 48 : size,
          height: size < 48 ? 48 : size,
          child: Center(
            child: PressableScale(
              onTap: effectiveOnPressed,
              pressedScale: 0.92,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: backgroundColor ?? colors.bgSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor ?? colors.borderColor,
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: color ?? colors.textPrimary,
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
