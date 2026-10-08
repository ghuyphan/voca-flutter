// lib/ui/widgets/voca_option_picker.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../sheets/voca_bottom_sheet.dart';

class OptionItem {
  final String value;
  final String label;
  final String? example;
  final String? description;
  final String? icon; // Emoji or short text
  final IconData? iconData;
  final Widget? leading;
  final String? badge;
  final Color? badgeColor;

  const OptionItem({
    required this.value,
    required this.label,
    this.example,
    this.description,
    this.icon,
    this.iconData,
    this.leading,
    this.badge,
    this.badgeColor,
  });
}

/// Shows a native Option Picker bottom sheet matching lingua-tube's OptionPickerComponent.
Future<String?> showVocaOptionPicker({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<OptionItem> options,
  String? selectedValue,
  ValueChanged<String>? onSelect,
}) {
  return showVocaBottomSheet<String>(
    context: context,
    title: title,
    subtitle: subtitle,
    contentPadding: EdgeInsets.zero,
    builder: (ctx) {
      final colors = ctx.vocaColors;

      return ListView.separated(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: options.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: colors.borderColorLight),
        itemBuilder: (ctx, index) {
          final item = options[index];
          final isSelected = item.value == selectedValue;

          return Material(
            color: isSelected ? colors.accentPrimarySoft : Colors.transparent,
            child: InkWell(
              onTap: () async {
                if (onSelect != null) {
                  onSelect(item.value);
                  // Brief micro-pause for visual tactile ink feedback and live transform
                  await Future.delayed(const Duration(milliseconds: 120));
                }
                if (ctx.mounted) {
                  Navigator.of(ctx).pop(item.value);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    // Leading Icon, Emoji, or Custom Widget
                    if (item.leading != null) ...[
                      item.leading!,
                      const SizedBox(width: 14),
                    ] else if (item.icon != null) ...[
                      Text(item.icon!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 14),
                    ] else if (item.iconData != null) ...[
                      Icon(
                        item.iconData,
                        size: 20,
                        color: isSelected ? colors.accentPrimary : colors.textSecondary,
                      ),
                      const SizedBox(width: 14),
                    ],

                    // Label & Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.label,
                                style: TextStyle(
                                  color: isSelected ? colors.accentPrimary : colors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                              if (item.badge != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (item.badgeColor ?? colors.accentSecondary).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.badge!,
                                    style: TextStyle(
                                      color: item.badgeColor ?? colors.accentSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (item.example != null && item.example!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.example!,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          if (item.description != null && item.description!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.description!,
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Selected Checkmark
                    if (isSelected)
                      Icon(
                        Icons.check_rounded,
                        color: colors.accentPrimary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
