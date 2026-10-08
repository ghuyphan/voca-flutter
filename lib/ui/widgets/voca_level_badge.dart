// lib/ui/widgets/voca_level_badge.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import 'voca_shimmer.dart';

enum LevelBadgeSize { small, medium, large }

/// Reusable level badge styled with Material 3 filled-pill guidelines.
/// Features clean tonal pill containers for UI surfaces and solid contrast fills for media overlays.
/// Supports clickable interactions and evaluating shimmer loading state.
class VocaLevelBadge extends StatelessWidget {
  final String? level;
  final LevelBadgeSize size;
  final bool showBorder;
  final bool isSolid;
  final bool isLoading;
  final VoidCallback? onTap;
  final String? customTitle;
  final double? borderRadius;

  const VocaLevelBadge({
    super.key,
    this.level,
    this.size = LevelBadgeSize.small,
    this.showBorder = false,
    this.isSolid = true,
    this.isLoading = false,
    this.onTap,
    this.customTitle,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final double radius = borderRadius ?? 100.0;

    if (isLoading) {
      double width;
      double height;
      switch (size) {
        case LevelBadgeSize.large:
          width = 64;
          height = 28;
          break;
        case LevelBadgeSize.medium:
          width = 54;
          height = 24;
          break;
        case LevelBadgeSize.small:
          width = 46;
          height = 20;
          break;
      }
      return Tooltip(
        message: customTitle ?? 'Evaluating level...',
        child: VocaShimmer.box(
          width: width,
          height: height,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    final isDark = context.isDarkMode;
    final effectiveLevel = (level != null && level!.isNotEmpty) ? level! : 'ALL';
    final info = LevelColorInfo.forLevel(effectiveLevel, isDark: isDark);
    final clean = LevelColorInfo.cleanLevel(effectiveLevel);

    double fontSize;
    EdgeInsets padding;

    switch (size) {
      case LevelBadgeSize.large:
        fontSize = 12.5;
        padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5);
        break;
      case LevelBadgeSize.medium:
        fontSize = 11.5;
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3.0);
        break;
      case LevelBadgeSize.small:
        fontSize = 10.5;
        padding = const EdgeInsets.symmetric(horizontal: 7, vertical: 2.0);
        break;
    }

    final bgColor = isSolid ? info.solidBg : info.bg;
    final textColor = isSolid ? info.solidText : info.text;

    Widget badge = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(radius),
        border: showBorder
            ? Border.all(color: info.border, width: 1)
            : (isSolid ? null : Border.all(color: info.border, width: 1)),
      ),
      child: Text(
        clean,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );

    if (onTap != null) {
      badge = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: badge,
      );
    }

    if (customTitle != null && customTitle!.isNotEmpty) {
      badge = Tooltip(
        message: customTitle!,
        child: badge,
      );
    }

    return badge;
  }
}
