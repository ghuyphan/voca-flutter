// lib/ui/explore/widgets/explore_chips_bar.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../models/explore_category.dart';

enum ExploreTab { videos, playlists }

/// Horizontal chips bar matching lingua-tube's chips carousel & AGENTS.md.
class ExploreChipsBar extends StatelessWidget {
  final ExploreCategory selectedCategory;
  final String selectedLevel;
  final ExploreTab currentTab;
  final List<String> levels;
  final VoidCallback onFilterPressed;
  final VoidCallback onAllPressed;
  final VoidCallback onPlaylistsPressed;
  final ValueChanged<String> onLevelSelected;

  const ExploreChipsBar({
    super.key,
    required this.selectedCategory,
    required this.selectedLevel,
    required this.currentTab,
    required this.levels,
    required this.onFilterPressed,
    required this.onAllPressed,
    required this.onPlaylistsPressed,
    required this.onLevelSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final hasActiveCategory = selectedCategory != ExploreCategory.all;
    final hasActiveFilter = hasActiveCategory || (selectedLevel != 'All' && currentTab == ExploreTab.videos);
    final isAllSelected = currentTab == ExploreTab.videos && selectedLevel == 'All' && !hasActiveCategory;
    final isPlaylistsSelected = currentTab == ExploreTab.playlists;

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // 1. (☷ Filter ⌄) Pill Chip
          InkWell(
            onTap: onFilterPressed,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: hasActiveFilter ? colors.accentPrimarySoft : colors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasActiveFilter ? colors.accentPrimary : colors.borderColor,
                  width: hasActiveFilter ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasActiveCategory ? selectedCategory.icon : Icons.filter_alt_rounded,
                    size: 14,
                    color: hasActiveFilter ? colors.accentPrimary : colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasActiveCategory
                        ? selectedCategory.getLabel(context)
                        : context.t('explore.filter', null, 'Filters'),
                    style: TextStyle(
                      color: hasActiveFilter ? colors.accentPrimary : colors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: hasActiveFilter ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: hasActiveFilter ? colors.accentPrimary : colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 2. (▶ All) Pill Chip
          InkWell(
            onTap: onAllPressed,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isAllSelected ? colors.textPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isAllSelected ? colors.textPrimary : colors.borderColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    size: 16,
                    color: isAllSelected ? colors.textInverse : colors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    context.t('common.all', null, 'All'),
                    style: TextStyle(
                      color: isAllSelected ? colors.textInverse : colors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: isAllSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 3. (≡ Playlists) Pill Chip
          InkWell(
            onTap: onPlaylistsPressed,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: isPlaylistsSelected ? colors.textPrimary : colors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPlaylistsSelected ? colors.textPrimary : colors.borderColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.format_list_bulleted_rounded,
                    size: 15,
                    color: isPlaylistsSelected ? colors.textInverse : colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.t('playlist.title', null, 'Playlists'),
                    style: TextStyle(
                      color: isPlaylistsSelected ? colors.textInverse : colors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: isPlaylistsSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Proficiency Level Chips (e.g. N5, N4, N3, etc.)
          ...levels.where((l) => l != 'All').map((lvl) {
            final isSelected = selectedLevel == lvl && currentTab == ExploreTab.videos;
            final info = LevelColorInfo.forLevel(lvl, isDark: colors.isDark);
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(lvl),
                onSelected: (_) => onLevelSelected(lvl),
                backgroundColor: colors.bgCard,
                selectedColor: info.bg,
                labelStyle: TextStyle(
                  color: isSelected ? info.text : colors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected ? info.border : colors.borderColor,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
