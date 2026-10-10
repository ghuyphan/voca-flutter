// lib/ui/sheets/level_filter_sheet.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import 'voca_bottom_sheet.dart';

/// Clean, focused proficiency level filter sheet matching lingua-tube & AGENTS.md.
class LevelFilterSheet extends StatefulWidget {
  final String selectedLevel;
  final List<String> availableLevels;
  final ValueChanged<String> onApply;

  const LevelFilterSheet({
    super.key,
    required this.selectedLevel,
    required this.availableLevels,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required String selectedLevel,
    required List<String> availableLevels,
    required ValueChanged<String> onApply,
  }) {
    return showVocaBottomSheet(
      context: context,
      title: context.t('level.dialogTitle', null, 'Proficiency Level'),
      subtitle: context.t('level.filterByLevel', null, 'Filter by difficulty level'),
      showCloseButton: true,
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      builder: (_) => LevelFilterSheet(
        selectedLevel: selectedLevel,
        availableLevels: availableLevels,
        onApply: onApply,
      ),
    );
  }

  @override
  State<LevelFilterSheet> createState() => _LevelFilterSheetState();
}

class _LevelFilterSheetState extends State<LevelFilterSheet> {
  late String _level;

  @override
  void initState() {
    super.initState();
    _level = widget.selectedLevel;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              // 'All Levels' Chip
              FilterChip(
                selected: _level == 'All',
                showCheckmark: false,
                avatar: Icon(
                  Icons.all_inclusive_rounded,
                  size: 15,
                  color: _level == 'All' ? colors.accentPrimary : colors.textSecondary,
                ),
                label: Text(
                  context.t('level.allLevels', null, 'Tất cả cấp độ'),
                  style: TextStyle(
                    color: _level == 'All' ? colors.accentPrimary : colors.textSecondary,
                    fontSize: 13,
                    fontWeight: _level == 'All' ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onSelected: (_) {
                  setState(() => _level = 'All');
                },
              ),

              // Individual Level FilterChips (N5, N4, N3, etc.)
              ...widget.availableLevels.where((l) => l != 'All').map((lvl) {
                final isSelected = _level == lvl;
                final info = LevelColorInfo.forLevel(lvl, isDark: colors.isDark);
                return FilterChip(
                  selected: isSelected,
                  showCheckmark: false,
                  avatar: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isSelected ? info.text : info.text.withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                    ),
                  ),
                  label: Text(
                    lvl,
                    style: TextStyle(
                      color: isSelected ? info.text : colors.textPrimary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  color: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return info.bg;
                    }
                    return colors.bgCard;
                  }),
                  surfaceTintColor: Colors.transparent,
                  side: WidgetStateBorderSide.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return BorderSide(color: info.border, width: 1.5);
                    }
                    return BorderSide(color: colors.borderColor, width: 1.0);
                  }),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  onSelected: (_) {
                    setState(() => _level = lvl);
                  },
                );
              }),
            ],
          ),

          const SizedBox(height: 24),

          // Action Footer: Reset & Apply Filters (M3 Buttons)
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _level = 'All');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    side: BorderSide(color: colors.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    context.t('common.reset', null, 'Reset'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onApply(_level);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    context.t('explore.applyFilters', null, 'Apply Filters'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
