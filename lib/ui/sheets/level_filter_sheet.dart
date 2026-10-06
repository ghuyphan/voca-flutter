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
                  color: _level == 'All' ? colors.textInverse : colors.textSecondary,
                ),
                label: Text(
                  context.t('level.allLevels', null, 'All Levels'),
                  style: TextStyle(
                    color: _level == 'All' ? colors.textInverse : colors.textSecondary,
                    fontSize: 13,
                    fontWeight: _level == 'All' ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                backgroundColor: colors.bgCard,
                selectedColor: colors.textPrimary,
                side: BorderSide(
                  color: _level == 'All' ? colors.textPrimary : colors.borderColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
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
                  avatar: isSelected
                      ? Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: info.text,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  label: Text(
                    lvl,
                    style: TextStyle(
                      color: isSelected ? info.text : colors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  backgroundColor: colors.bgCard,
                  selectedColor: info.bg,
                  side: BorderSide(
                    color: isSelected ? info.border : colors.borderColor,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) {
                    setState(() => _level = lvl);
                  },
                );
              }),
            ],
          ),

          const SizedBox(height: 24),

          // Action Footer: Reset & Apply Filters
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onApply(_level);
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
