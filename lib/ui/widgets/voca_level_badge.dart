// lib/ui/widgets/voca_level_badge.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import 'voca_shimmer.dart';

enum LevelBadgeSize { small, medium, large }

/// Reusable level badge matching lingua-tube's LevelBadgeComponent.
/// Automatically adapts to current theme (Dark / Light) with high-contrast pastel styling.
/// Supports clickable interactions and evaluating shimmer loading state.
class VocaLevelBadge extends StatelessWidget {
  final String? level;
  final LevelBadgeSize size;
  final bool showBorder;
  final bool isLoading;
  final VoidCallback? onTap;
  final String? customTitle;

  const VocaLevelBadge({
    super.key,
    this.level,
    this.size = LevelBadgeSize.small,
    this.showBorder = true,
    this.isLoading = false,
    this.onTap,
    this.customTitle,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      double width;
      double height;
      switch (size) {
        case LevelBadgeSize.large:
          width = 64;
          height = 30;
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
          borderRadius: BorderRadius.circular(999),
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
        fontSize = 13.0;
        padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
        break;
      case LevelBadgeSize.medium:
        fontSize = 11.5;
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5);
        break;
      case LevelBadgeSize.small:
        fontSize = 10.5;
        padding = const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5);
        break;
    }

    Widget badge = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: info.bg,
        borderRadius: BorderRadius.circular(999),
        border: showBorder ? Border.all(color: info.border, width: 1) : null,
      ),
      child: Text(
        clean,
        style: TextStyle(
          color: info.text,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );

    if (onTap != null) {
      badge = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
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
