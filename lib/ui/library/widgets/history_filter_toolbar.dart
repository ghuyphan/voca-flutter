// lib/ui/library/widgets/history_filter_toolbar.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../../sheets/voca_bottom_sheet.dart';
import '../../widgets/circle_flag.dart';

/// Clean, solid 2-row toolbar matching lingua-tube's .panel-toolbar:
/// Row 1: 38px Pill Search input + Clear History button
/// Row 2: Filter scroll strip (All / Favorites, Language picker chip, Level chips)
class HistoryFilterToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final String selectedLang;
  final String selectedLevel;
  final bool showOnlyFavorites;
  final bool hasHistoryItems;
  final VoidCallback onClearHistory;
  final ValueChanged<String> onLangChanged;
  final ValueChanged<String> onLevelChanged;
  final ValueChanged<bool> onFavoritesChanged;

  const HistoryFilterToolbar({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.selectedLang,
    required this.selectedLevel,
    required this.showOnlyFavorites,
    required this.hasHistoryItems,
    required this.onClearHistory,
    required this.onLangChanged,
    required this.onLevelChanged,
    required this.onFavoritesChanged,
  });

  static Widget buildCircleFlag(String langCode, {double size = 16}) {
    return CircleFlag(code: langCode, size: size);
  }

  static String getLanguageLabel(String lang) {
    switch (lang) {
      case 'ja': return 'Japanese';
      case 'zh': return 'Chinese';
      case 'ko': return 'Korean';
      case 'en': return 'English';
      default: return 'Language';
    }
  }

  List<String> _getLevelsForLanguage(String lang) {
    switch (lang) {
      case 'ja':
        return const ['N5', 'N4', 'N3', 'N2', 'N1'];
      case 'zh':
        return const ['HSK 1', 'HSK 2', 'HSK 3', 'HSK 4', 'HSK 5', 'HSK 6'];
      case 'ko':
        return const ['TOPIK 1', 'TOPIK 2', 'TOPIK 3', 'TOPIK 4', 'TOPIK 5', 'TOPIK 6'];
      case 'en':
        return const ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
      default:
        return const ['N5', 'N4', 'N3', 'N2', 'N1'];
    }
  }

  void _openLanguagePicker(BuildContext context, VocaColorPalette colors) {
    showVocaBottomSheet(
      context: context,
      title: context.t('playlist.browseByLanguage', null, 'Filter by Language'),
      builder: (ctx) {
        final options = [
          {'code': 'all', 'label': context.t('playlist.allLanguages', null, 'All Languages')},
          {'code': 'ja', 'label': 'Japanese (日本語)'},
          {'code': 'zh', 'label': 'Chinese (中文)'},
          {'code': 'ko', 'label': 'Korean (한국어)'},
          {'code': 'en', 'label': 'English'},
        ];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final code = opt['code']!;
            final label = opt['label']!;
            final isSelected = selectedLang == code;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              leading: code == 'all'
                  ? Icon(Icons.public_rounded, size: 20, color: colors.textSecondary)
                  : buildCircleFlag(code, size: 20),
              title: Text(
                label,
                style: TextStyle(
                  color: isSelected ? colors.accentPrimary : colors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_rounded, color: colors.accentPrimary, size: 20)
                  : null,
              onTap: () {
                Navigator.of(ctx).pop();
                onLangChanged(code);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VocaColorPalette colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.bgCard : colors.bgSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? colors.accentPrimary : colors.borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.accentPrimary.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? colors.accentPrimary : colors.textMuted,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? colors.accentPrimary : colors.textSecondary,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final levels = _getLevelsForLanguage(selectedLang);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Search Bar & Clear Button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, size: 18, color: colors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          style: TextStyle(color: colors.textPrimary, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: context.t('history.searchHistory', null, 'Search watch history...'),
                            hintStyle: TextStyle(color: colors.textMuted, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () => searchController.clear(),
                          child: Icon(Icons.close_rounded, size: 16, color: colors.textMuted),
                        ),
                    ],
                  ),
                ),
              ),
              if (hasHistoryItems) ...[
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: colors.error, size: 19),
                    padding: EdgeInsets.zero,
                    tooltip: context.t('history.clearAll', null, 'Clear History'),
                    onPressed: onClearHistory,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: Filter Scroll Strip (All, Favorites, Language picker chip, Levels)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // "All" chip
                _buildFilterChip(
                  label: context.t('history.all', null, 'All'),
                  icon: Icons.list_rounded,
                  isSelected: !showOnlyFavorites && selectedLevel == 'all',
                  colors: colors,
                  onTap: () {
                    onFavoritesChanged(false);
                    onLevelChanged('all');
                  },
                ),
                const SizedBox(width: 6),

                // "Favorites" chip
                _buildFilterChip(
                  label: context.t('history.favorites', null, 'Favorites'),
                  icon: showOnlyFavorites ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  isSelected: showOnlyFavorites,
                  colors: colors,
                  onTap: () => onFavoritesChanged(!showOnlyFavorites),
                ),
                const SizedBox(width: 6),

                // Language Picker Chip
                GestureDetector(
                  onTap: () => _openLanguagePicker(context, colors),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: selectedLang != 'all' ? colors.bgCard : colors.bgSurface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selectedLang != 'all' ? colors.accentPrimary : colors.borderColor,
                        width: selectedLang != 'all' ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selectedLang != 'all')
                          buildCircleFlag(selectedLang, size: 14)
                        else
                          Icon(Icons.translate_rounded, size: 14, color: colors.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          selectedLang != 'all'
                              ? getLanguageLabel(selectedLang)
                              : context.t('playlist.allLanguages', null, 'Language'),
                          style: TextStyle(
                            color: selectedLang != 'all' ? colors.accentPrimary : colors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: colors.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Dynamic Level Chips
                ...levels.map((lvl) {
                  final isSelected = selectedLevel == lvl;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildFilterChip(
                      label: lvl,
                      isSelected: isSelected,
                      colors: colors,
                      onTap: () => onLevelChanged(isSelected ? 'all' : lvl),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
