// lib/ui/library/widgets/library_top_bar.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';

/// Top bar with 38px segmented control (Watch History | Playlists) and Settings action button.
class LibraryTopBar extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onSettingsPressed;

  const LibraryTopBar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          // Sleek 38px Segmented Control (Watch History | Playlists)
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: colors.borderColor),
              ),
              child: Row(
                children: [
                  _buildSegmentItem(
                    index: 0,
                    icon: Icons.history_rounded,
                    label: context.t('history.title', null, 'Watch History'),
                    colors: colors,
                  ),
                  _buildSegmentItem(
                    index: 1,
                    icon: Icons.playlist_play_rounded,
                    label: context.t('nav.playlists', null, 'Playlists'),
                    colors: colors,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 38px Settings Gear Action Button
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.bgSurface,
              shape: BoxShape.circle,
              border: Border.all(color: colors.borderColor),
            ),
            child: IconButton(
              icon: Icon(Icons.settings_outlined, color: colors.textSecondary, size: 19),
              padding: EdgeInsets.zero,
              tooltip: context.t('nav.settings', null, 'Settings'),
              onPressed: onSettingsPressed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem({
    required int index,
    required IconData icon,
    required String label,
    required VocaColorPalette colors,
  }) {
    final isSelected = currentTab == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTabChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected ? (colors.isDark ? colors.bgHover : colors.bgCard) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: colors.isDark ? 0.4 : 0.06),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? colors.accentPrimary : colors.textMuted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? colors.textPrimary : colors.textMuted,
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
