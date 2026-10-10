// lib/ui/widgets/voca_download_progress_indicator.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';

/// An animated download progress indicator featuring a persistent circular track ring,
/// spinning progress arc, and a centered downward arrow glyph.
///
/// Designed to clearly indicate an active downloading state and eliminate
/// M3 indeterminate CircularProgressIndicator collapse/flicker and alignment issues.
class VocaDownloadProgressIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? semanticsLabel;

  const VocaDownloadProgressIndicator({
    super.key,
    this.size = 28,
    this.strokeWidth = 2.5,
    this.color,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final primaryColor = color ?? colors.accentPrimary;

    final indicator = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Permanent background circular track so shape is always visible
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: 0.08),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.22),
                width: 1.5,
              ),
            ),
          ),
          // 2. Active rotating progress arc
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              color: primaryColor,
              strokeCap: StrokeCap.round,
            ),
          ),
          // 3. Centered download glyph for unmistakable download affordance
          Icon(
            Icons.arrow_downward_rounded,
            size: size * 0.48,
            color: primaryColor,
          ),
        ],
      ),
    );

    if (semanticsLabel != null) {
      return Semantics(
        liveRegion: true,
        label: semanticsLabel,
        child: indicator,
      );
    }

    return indicator;
  }
}
