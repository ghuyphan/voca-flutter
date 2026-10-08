// lib/ui/onboarding/widgets/onboarding_primitives.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../widgets/circle_flag.dart';
import 'staggered_entrance.dart';

/// Circular flag from `assets/flags/*.svg` rendered seamlessly without outer borders.
class RoundFlag extends StatelessWidget {
  final String asset;
  final double size;

  const RoundFlag({super.key, required this.asset, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return CircleFlag(
      code: asset,
      size: size,
      hasShadow: false,
    );
  }
}

/// Animated radio indicator (ring → filled check).
class RadioCheck extends StatelessWidget {
  final bool selected;
  final double size;

  const RadioCheck({super.key, required this.selected, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colors.accentPrimary : Colors.transparent,
        border: Border.all(
          color: selected ? colors.accentPrimary : colors.borderColorHover,
          width: selected ? 0 : 1.5,
        ),
      ),
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: const Cubic(0.34, 1.56, 0.64, 1.0),
        child: selected
            ? Icon(Icons.check_rounded, size: size * 0.64, color: Colors.white)
            : const SizedBox.shrink(),
      ),
    );
  }
}

/// iOS-style inset grouped container: rounded card with hairline dividers.
class GroupedCard extends StatelessWidget {
  final List<Widget> children;
  final double dividerIndent;

  const GroupedCard({super.key, required this.children, this.dividerIndent = 64});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(Padding(
          padding: EdgeInsets.only(left: dividerIndent),
          child: Container(height: 1, color: colors.borderColorLight),
        ));
      }
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(children: items),
    );
  }
}

/// Small rounded tag (exam badge, "Detected", etc.).
class TagChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final Color? border;
  final Widget? leading;

  const TagChip({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
    this.border,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border != null ? Border.all(color: border!) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 4)],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard step layout: large left-aligned title + subtitle, then content.
/// Scrolls only when the content doesn't fit (small phones / large text).
class OnboardingStepLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const OnboardingStepLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final content = <Widget>[
      Text(
        title,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 22,
          height: 1.25,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(
          subtitle!,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
      const SizedBox(height: 16),
      ...children,
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < content.length; i++)
            StaggeredEntrance(index: i, child: content[i]),
        ],
      ),
    );
  }
}

/// Uppercase section label used above grouped cards.
class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
