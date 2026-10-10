// lib/ui/widgets/voca_sliding_segmented_bar.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../services/haptic_service.dart';

/// Reusable native sliding capsule segmented bar matching Voca's Material 3 aesthetics.
class VocaSlidingSegmentedBar extends StatelessWidget {
  final List<String> values;
  final List<String> labels;
  final String selectedValue;
  final ValueChanged<String> onSelected;
  final VocaColorPalette colors;
  final double height;

  const VocaSlidingSegmentedBar({
    super.key,
    required this.values,
    required this.labels,
    required this.selectedValue,
    required this.onSelected,
    required this.colors,
    this.height = 38,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    final rawIndex = values.indexOf(selectedValue);
    final selectedIndex = (rawIndex >= 0 ? rawIndex : 0).clamp(0, values.length - 1);

    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.isDark ? colors.bgSurface : colors.bgSecondary,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / values.length;

          return Stack(
            children: [
              // Gliding thumb indicator (white pill in light mode, elevated card in dark mode)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                left: selectedIndex * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.isDark ? colors.bgHover : colors.bgCard,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: colors.isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                ),
              ),

              // Segment Labels & Gestures
              Row(
                children: List.generate(values.length, (i) {
                  final isSelected = i == selectedIndex;
                  return Expanded(
                    child: Semantics(
                      selected: isSelected,
                      button: true,
                      label: labels.length > i ? labels[i] : values[i],
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticService.selection();
                          onSelected(values[i]);
                        },
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 160),
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: isSelected ? colors.textPrimary : colors.textMuted,
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            ),
                            child: Text(
                              labels.length > i ? labels[i] : values[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

