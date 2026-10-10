// lib/ui/widgets/voca_sliding_segmented_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/voca_theme.dart';

/// Canonical Material 3 segmented control wrapping Flutter's SegmentedButton<String>.
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
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    final activeValue = values.contains(selectedValue) ? selectedValue : values.first;

    return SegmentedButton<String>(
      segments: [
        for (int i = 0; i < values.length; i++)
          ButtonSegment<String>(
            value: values[i],
            label: Text(
              labels.length > i ? labels[i] : values[i],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      selected: {activeValue},
      showSelectedIcon: false,
      onSelectionChanged: (Set<String> newSelection) {
        if (newSelection.isNotEmpty) {
          HapticFeedback.selectionClick();
          onSelected(newSelection.first);
        }
      },
      style: SegmentedButton.styleFrom(
        minimumSize: Size(0, height),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}
