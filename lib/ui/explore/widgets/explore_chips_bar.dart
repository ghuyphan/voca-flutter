// lib/ui/explore/widgets/explore_chips_bar.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../models/explore_category.dart';

enum ExploreTab { videos, playlists }

/// Clean, topic-first horizontal chips bar with smooth animated transitions.
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
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // 1. Level Refinement Chip (e.g. "Filters ⌄" or "🟢 N4 ⌄")
          InkWell(
            onTap: onLevelFilterPressed,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: hasActiveLevel ? levelInfo.bg : colors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasActiveLevel ? levelInfo.border : colors.borderColor,
                  width: hasActiveLevel ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasActiveLevel)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: levelInfo.text,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    Icon(
                      Icons.filter_alt_rounded,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    hasActiveLevel ? selectedLevel : context.t('explore.filter', null, 'Filters'),
                    style: TextStyle(
                      color: hasActiveLevel ? levelInfo.text : colors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: hasActiveLevel ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: hasActiveLevel ? levelInfo.text : colors.textSecondary,
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
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

          // 4. Topic Category Chips (Trending, Anime, Music, News, Vlog, Conversation)
          ...topicCategories.map((cat) {
            final isCatSelected = currentTab == ExploreTab.videos && selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: InkWell(
                onTap: () => onCategorySelected(cat),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                  decoration: BoxDecoration(
                    color: isCatSelected ? colors.accentPrimarySoft : colors.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCatSelected ? colors.accentPrimary : colors.borderColor,
                      width: isCatSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat.icon,
                        size: 14,
                        color: isCatSelected ? colors.accentPrimary : colors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cat.getLabel(context),
                        style: TextStyle(
                          color: isCatSelected ? colors.accentPrimary : colors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: isCatSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
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
