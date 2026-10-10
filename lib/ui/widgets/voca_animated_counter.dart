import 'package:flutter/material.dart';

/// Material 3 Expressive Rolling Metric Counter
///
/// Rolls up smoothly from 0 (or previous value) to the target [value]
/// using [Curves.easeOutCubic].
///
/// Features:
/// - Smooth numeric interpolation with easing.
/// - Automatically injects [FontFeature.tabularFigures] to eliminate character jitter.
/// - Customizable duration, curve, prefix, suffix, and formatter.
/// - Automatically displays target number instantly when [MediaQuery.maybeDisableAnimationsOf] is true.
class VocaAnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final String? prefix;
  final String? suffix;
  final String Function(int)? formatter;
  final TextAlign? textAlign;

  const VocaAnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
    this.prefix,
    this.suffix,
    this.formatter,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final effectiveDuration = reduceMotion ? Duration.zero : duration;

    // Ensure tabular figures are active so number cycling does not cause horizontal jitter
    final effectiveStyle = (style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: [
        ...?style?.fontFeatures,
        const FontFeature.tabularFigures(),
      ],
    );

    return TweenAnimationBuilder<double>(
      key: ValueKey('animated_counter_${value}_$reduceMotion'),
      tween: Tween<double>(begin: reduceMotion ? value.toDouble() : 0.0, end: value.toDouble()),
      duration: effectiveDuration,
      curve: curve,
      builder: (context, currentVal, _) {
        final currentInt = currentVal.round();
        final formattedNumber = formatter != null
            ? formatter!(currentInt)
            : currentInt.toString();

        final displayText = '${prefix ?? ''}$formattedNumber${suffix ?? ''}';

        return Text(
          displayText,
          style: effectiveStyle,
          textAlign: textAlign,
        );
      },
    );
  }
}
