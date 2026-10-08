// lib/ui/explore/widgets/explore_chips_bar.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../models/explore_category.dart';

enum ExploreTab { videos, playlists }

/// Unified topic & level filter bar using official Flutter Material 3 chips with consistent geometry.
class ExploreChipsBar extends StatelessWidget {
  final ExploreCategory selectedCategory;
  final String selectedLevel;
  final ExploreTab currentTab;
  final VoidCallback onLevelFilterPressed;
  final VoidCallback onAllPressed;
  final VoidCallback onPlaylistsPressed;
  final ValueChanged<ExploreCategory> onCategorySelected;

  const ExploreChipsBar({
    super.key,
    required this.selectedCategory,
    required this.selectedLevel,
    required this.currentTab,
    required this.onLevelFilterPressed,
    required this.onAllPressed,
    required this.onPlaylistsPressed,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final hasActiveLevel = selectedLevel != 'All';
    final levelInfo = LevelColorInfo.forLevel(selectedLevel, isDark: colors.isDark);

    final isAllSelected = currentTab == ExploreTab.videos && selectedCategory == ExploreCategory.all;
    final isPlaylistsSelected = currentTab == ExploreTab.playlists;

    const topicCategories = [
      ExploreCategory.trending,
      ExploreCategory.animeDrama,
      ExploreCategory.music,
      ExploreCategory.news,
      ExploreCategory.vlog,
      ExploreCategory.conversation,
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // 1. Level Refinement Chip (Official M3 ActionChip)
          ActionChip(
            onPressed: onLevelFilterPressed,
            avatar: hasActiveLevel
                ? Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: levelInfo.text,
                      shape: BoxShape.circle,
                    ),
                  )
                : Icon(
                    Icons.filter_alt_rounded,
                    size: 14,
                    color: colors.textSecondary,
                  ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasActiveLevel ? selectedLevel : context.t('explore.filter', null, 'Filters'),
                  style: TextStyle(
                    color: hasActiveLevel ? levelInfo.text : colors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: hasActiveLevel ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: hasActiveLevel ? levelInfo.text : colors.textSecondary,
                ),
              ],
            ),
            color: WidgetStateProperty.resolveWith((states) {
              if (hasActiveLevel) return levelInfo.bg;
              return colors.bgCard;
            }),
            surfaceTintColor: Colors.transparent,
            side: WidgetStateBorderSide.resolveWith((states) {
              if (hasActiveLevel) {
                return BorderSide(color: levelInfo.border, width: 1.5);
              }
              return BorderSide(color: colors.borderColor, width: 1.0);
            }),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            visualDensity: VisualDensity.compact,
          ),

          const SizedBox(width: 8),

          // 2. "All" Feed Chip (Official M3 FilterChip)
          _buildFilterChip(
            isSelected: isAllSelected,
            onSelected: onAllPressed,
            icon: Icons.play_arrow_rounded,
            label: context.t('common.all', null, 'All'),
            colors: colors,
          ),

          const SizedBox(width: 8),

          // 3. "Playlists" Chip (Official M3 FilterChip)
          _buildFilterChip(
            isSelected: isPlaylistsSelected,
            onSelected: onPlaylistsPressed,
            icon: Icons.format_list_bulleted_rounded,
            label: context.t('explore.playlists', null, 'Playlists'),
            colors: colors,
          ),

          const SizedBox(width: 8),

          // 4. Topic Category Chips (Official M3 FilterChips)
          ...topicCategories.map((cat) {
            final isCatSelected = currentTab == ExploreTab.videos && selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                isSelected: isCatSelected,
                onSelected: () => onCategorySelected(cat),
                icon: cat.icon,
                label: cat.getLabel(context),
                colors: colors,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required bool isSelected,
    required VoidCallback onSelected,
    required IconData icon,
    required String label,
    required VocaColorPalette colors,
  }) {
    return FilterChip(
      selected: isSelected,
      onSelected: (_) => onSelected(),
      avatar: Icon(
        icon,
        size: 14,
        color: isSelected ? colors.accentPrimary : colors.textSecondary,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? colors.accentPrimary : colors.textSecondary,
          fontSize: 12.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      showCheckmark: false,
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colors.accentPrimarySoft;
        }
        return colors.bgCard;
      }),
      surfaceTintColor: Colors.transparent,
      side: WidgetStateBorderSide.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return BorderSide(color: colors.accentPrimary, width: 1.5);
        }
        return BorderSide(color: colors.borderColor, width: 1.0);
      }),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      visualDensity: VisualDensity.compact,
    );
  }
}
