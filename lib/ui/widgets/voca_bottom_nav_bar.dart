// lib/ui/widgets/voca_bottom_nav_bar.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import '../../state/player_coordinator.dart';

/// A native, polished, theme-aware 4-tab bottom navigation bar reimagined for mobile.
///
/// Designed to replace web-era navigation bar hacks with a first-class mobile experience:
/// - 4 primary tabs: Watch, Review, Vocab, More (No clunky center button)
/// - Frosted glass backdrop blur (iOS / Modern Android aesthetic)
/// - Adaptive Light and Dark mode styling via [VocaTheme] and [VocaColorPalette]
/// - Dynamic locale reactivity bound to [I18nService.currentLanguage]
/// - Silky-smooth micro-animations with ZERO rectangular ink flash/bleed
/// - Tactile haptic feedback on tab selection
/// - Live activity badge indicators (playing session, claimable rewards)
/// - Proper edge-to-edge safe area handling
class VocaBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback? onCreatePressed;
  final VoidCallback? onMorePressed;

  const VocaBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.onCreatePressed,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final isDark = context.isDarkMode;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Watch((context) {
      // Subscribe to language changes so labels update instantaneously
      final _ = I18nService.instance.currentLanguage.value;

      bool hasRewards = false;
      try {
        hasRewards = AppState.instance.gamificationService.hasClaimableRewards.value;
      } catch (_) {
        hasRewards = false;
      }

      bool hasActiveVideo = false;
      bool isPlaying = false;
      try {
        hasActiveVideo = PlayerCoordinator.instance.hasActiveVideo;
        isPlaying = PlayerCoordinator.instance.isPlaying.value;
      } catch (_) {
        hasActiveVideo = false;
        isPlaying = false;
      }

      final watchLabel = context.t('nav.watch', null, 'Watch');
      final reviewLabel = context.t('nav.review', null, 'Review');
      final vocabLabel = context.t('nav.vocab', null, 'Vocab');
      final moreLabel = context.t('nav.more', null, 'More');

      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? colors.bgSecondary.withOpacity(0.85)
                  : colors.bgCard.withOpacity(0.92),
              border: Border(
                top: BorderSide(
                  color: colors.borderColor.withOpacity(isDark ? 0.6 : 0.8),
                  width: 0.8,
                ),
              ),
            ),
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  // 1. Watch
                  _VocaNavItem(
                    icon: Icons.play_circle_outline_rounded,
                    activeIcon: Icons.play_circle_rounded,
                    label: watchLabel,
                    isSelected: currentIndex == 0,
                    onTap: () => onTabSelected(0),
                    colors: colors,
                    badge: hasActiveVideo
                        ? _PlayingIndicatorBadge(isPlaying: isPlaying, colors: colors)
                        : null,
                  ),

                  // 2. Review
                  _VocaNavItem(
                    icon: Icons.school_outlined,
                    activeIcon: Icons.school_rounded,
                    label: reviewLabel,
                    isSelected: currentIndex == 1,
                    onTap: () => onTabSelected(1),
                    colors: colors,
                  ),

                  // 3. Vocab
                  _VocaNavItem(
                    icon: Icons.menu_book_outlined,
                    activeIcon: Icons.menu_book_rounded,
                    label: vocabLabel,
                    isSelected: currentIndex == 2,
                    onTap: () => onTabSelected(2),
                    colors: colors,
                  ),

                  // 4. More (Personal Hub)
                  _VocaNavItem(
                    icon: Icons.grid_view_rounded,
                    activeIcon: Icons.grid_view_rounded,
                    label: moreLabel,
                    isSelected: currentIndex == 3,
                    onTap: () {
                      onTabSelected(3);
                      onMorePressed?.call();
                    },
                    colors: colors,
                    badge: hasRewards
                        ? _NotificationDotBadge(colors: colors)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _VocaNavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final VocaColorPalette colors;
  final Widget? badge;

  const _VocaNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    this.badge,
  });

  @override
  State<_VocaNavItem> createState() => _VocaNavItemState();
}

class _VocaNavItemState extends State<_VocaNavItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: widget.isSelected,
        label: widget.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated pill container with spring-scale on touch (zero rectangular ink flash)
              AnimatedScale(
                scale: _isPressed ? 0.92 : (widget.isSelected ? 1.05 : 1.0),
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? widget.colors.accentPrimarySoft
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        widget.isSelected ? widget.activeIcon : widget.icon,
                        size: 22,
                        color: widget.isSelected
                            ? widget.colors.accentPrimary
                            : widget.colors.textMuted,
                      ),
                      if (widget.badge != null)
                        Positioned(
                          top: -2,
                          right: -4,
                          child: widget.badge!,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isSelected
                      ? widget.colors.accentPrimary
                      : widget.colors.textMuted,
                  letterSpacing: widget.isSelected ? -0.1 : 0.0,
                ),
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationDotBadge extends StatelessWidget {
  final VocaColorPalette colors;

  const _NotificationDotBadge({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: colors.accentTertiary,
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.bgCard,
          width: 1.5,
        ),
      ),
    );
  }
}

class _PlayingIndicatorBadge extends StatelessWidget {
  final bool isPlaying;
  final VocaColorPalette colors;

  const _PlayingIndicatorBadge({
    required this.isPlaying,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: isPlaying ? colors.accentPrimary : colors.textMuted,
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.bgCard,
          width: 1.5,
        ),
      ),
    );
  }
}
