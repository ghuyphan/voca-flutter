// lib/ui/onboarding/widgets/onboarding_selection_tile.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/voca_theme.dart';

/// Universal, highly reusable selection tile for onboarding options.
/// Features tactile spring scale press feedback, haptics, leading badges,
/// title chips, subtitles, and radio checkmark rings.
class OnboardingSelectionTile extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? tagChip;
  final Widget? leading;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? accentColor;
  final EdgeInsetsGeometry padding;
  final Widget? trailing;

  const OnboardingSelectionTile({
    super.key,
    required this.title,
    this.subtitle,
    this.tagChip,
    this.leading,
    required this.isSelected,
    required this.onTap,
    this.accentColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.trailing,
  });

  @override
  State<OnboardingSelectionTile> createState() => _OnboardingSelectionTileState();
}

class _OnboardingSelectionTileState extends State<OnboardingSelectionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    _pressController.reverse();
  }

  void _handleTapCancel() {
    _pressController.reverse();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activeColor = widget.accentColor ?? colors.accentPrimary;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 10),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? activeColor.withOpacity(context.isDark ? 0.12 : 0.08)
                : colors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? activeColor
                  : (context.isDark ? colors.borderColor : colors.borderColorLight),
              width: widget.isSelected ? 1.5 : 1.0,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(context.isDark ? 0.15 : 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 14),
              ],

              // Center text column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.tagChip != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.bgSurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: colors.borderColorLight,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                widget.tagChip!,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Trailing selection indicator (or custom trailing widget)
              if (widget.trailing != null)
                widget.trailing!
              else
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isSelected ? activeColor : Colors.transparent,
                    border: Border.all(
                      color: widget.isSelected
                          ? activeColor
                          : (context.isDark ? colors.borderColorHover : colors.textMuted),
                      width: widget.isSelected ? 0 : 1.5,
                    ),
                  ),
                  child: widget.isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
