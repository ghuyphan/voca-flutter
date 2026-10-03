// lib/ui/sheets/category_filter_sheet.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../explore/models/explore_category.dart';
import 'voca_bottom_sheet.dart';

class CategoryFilterSheet extends StatefulWidget {
  final String selectedCategory;
  final String selectedLevel;
  final List<String> availableLevels;
  final List<String>? categories;
  final void Function(String category, String level) onApply;

  const CategoryFilterSheet({
    super.key,
    required this.selectedCategory,
    required this.selectedLevel,
    required this.availableLevels,
    this.categories,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required String selectedCategory,
    required String selectedLevel,
    required List<String> availableLevels,
    List<String>? categories,
    required void Function(String category, String level) onApply,
  }) {
    return showVocaBottomSheet(
      context: context,
      title: context.t('explore.filterVideos', null, 'Filter Videos'),
      subtitle: context.t('explore.filterSubtitle', null, 'Refine by topic and difficulty level'),
      showCloseButton: true,
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      builder: (_) => CategoryFilterSheet(
        selectedCategory: selectedCategory,
        selectedLevel: selectedLevel,
        availableLevels: availableLevels,
        categories: categories,
        onApply: onApply,
      ),
    );
  }

  @override
  State<CategoryFilterSheet> createState() => _CategoryFilterSheetState();
}

class _CategoryFilterSheetState extends State<CategoryFilterSheet> {
  late String _category;
  late String _level;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _level = widget.selectedLevel;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    const categoryList = ExploreCategory.values;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section 1: Categories / Topics
          Text(
            context.t('explore.topics', null, 'TOPICS & CATEGORIES').toUpperCase(),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoryList.map((cat) {
              final isSelected = _category == cat.id;
              return ChoiceChip(
                selected: isSelected,
                avatar: Icon(
                  cat.icon,
                  size: 16,
                  color: isSelected ? Colors.white : colors.textMuted,
                ),
                label: Text(cat.getLabel(context)),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _category = cat.id;
                    });
                  }
                },
                backgroundColor: colors.bgSurface,
                selectedColor: colors.accentPrimary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : colors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? colors.accentPrimary : colors.borderColor,
                  ),
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Section 2: Difficulty Levels
          Text(
            context.t('explore.levelFilter', null, 'DIFFICULTY LEVEL').toUpperCase(),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // All levels option
              ChoiceChip(
                selected: _level == 'All',
                label: Text(context.t('common.all', null, 'All Levels')),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _level = 'All';
                    });
                  }
                },
                backgroundColor: colors.bgSurface,
                selectedColor: colors.accentPrimary,
                labelStyle: TextStyle(
                  color: _level == 'All' ? Colors.white : colors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: _level == 'All' ? FontWeight.w700 : FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: _level == 'All' ? colors.accentPrimary : colors.borderColor,
                  ),
                ),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              ),

              // Language-specific levels (e.g. N5, N4, N3, etc.)
              ...widget.availableLevels.where((l) => l != 'All').map((lvl) {
                final isSelected = _level == lvl;
                final info = LevelColorInfo.forLevel(lvl, isDark: colors.isDark);
                return ChoiceChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: info.text,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(lvl),
                    ],
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _level = selected ? lvl : 'All';
                    });
                  },
                  backgroundColor: colors.bgSurface,
                  selectedColor: isSelected ? info.bg : colors.bgSurface,
                  labelStyle: TextStyle(
                    color: isSelected ? info.text : colors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? info.border : colors.borderColor,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                );
              }),
            ],
          ),

          const SizedBox(height: 24),

          // Section 3: Action Buttons (Reset All & Apply)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _category = 'All';
                      _level = 'All';
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    side: BorderSide(color: colors.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.t('common.reset', null, 'Reset All'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onApply(_category, _level);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.t('common.apply', null, 'Apply Filters'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
