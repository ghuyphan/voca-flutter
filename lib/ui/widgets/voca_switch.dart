// lib/ui/widgets/voca_switch.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../services/haptic_service.dart';

/// Reusable theme-aware toggle switch matching lingua-tube's SwitchComponent.
class VocaSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? label;
  final String? subtitle;
  final Widget? leading;

  const VocaSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.subtitle,
    this.leading,
  });

  void _handleToggle(bool nextValue) {
    onChanged(nextValue);
    HapticService.selection();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    final switchWidget = Switch(
      value: value,
      onChanged: _handleToggle,
    );

    if (label == null) {
      return switchWidget;
    }

    return InkWell(
      onTap: () => _handleToggle(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label!,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            switchWidget,
          ],
        ),
      ),
    );
  }
}
