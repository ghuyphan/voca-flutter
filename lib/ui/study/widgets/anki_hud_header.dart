// lib/ui/study/widgets/anki_hud_header.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/haptic_service.dart';
import '../../../services/i18n_service.dart';

/// Top HUD header featuring minimal dash capsule progress, session counter, and undo action.
class AnkiHudHeader extends StatelessWidget {
  final int currentIndex;
  final int totalInSession;
  final VoidCallback onOpenDeckSettings;
  final VoidCallback? onExit;
  final VoidCallback? onUndo;

  const AnkiHudHeader({
    super.key,
    required this.currentIndex,
    required this.totalInSession,
    required this.onOpenDeckSettings,
    this.onExit,
    this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final total = totalInSession > 0 ? totalInSession : 1;
    final displayIndex = currentIndex.clamp(0, total);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Left: Exit '✕' Button
          if (onExit != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 22),
              color: colors.textSecondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              tooltip: context.t('study.exitToOverview', null, 'Exit to Overview'),
              onPressed: () {
                HapticService.selection();
                onExit?.call();
              },
            )
          else
            const SizedBox(width: 48),

          const SizedBox(width: 8),

          // 2. Center: Segmented Dash / Capsule Progress Track + Count (0/10)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: _buildDashProgress(context, colors, displayIndex, total),
                ),
                const SizedBox(width: 10),
                Text(
                  '$displayIndex/$total',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 3. Right: Replay/Undo & Deck Settings Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onUndo != null) ...[
                IconButton(
                  icon: const Icon(Icons.replay_rounded, size: 21),
                  color: colors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  tooltip: context.t('study.undo', null, 'Undo'),
                  onPressed: () {
                    HapticService.selection();
                    onUndo?.call();
                  },
                ),
                const SizedBox(width: 2),
              ],
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 20),
                color: colors.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                tooltip: context.t('study.deckSettings', null, 'Deck Settings'),
                onPressed: () {
                  HapticService.selection();
                  onOpenDeckSettings();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashProgress(
    BuildContext context,
    VocaColorPalette colors,
    int current,
    int total,
  ) {
    // If total cards <= 14, render individual capsule dashes like the screenshot
    if (total <= 14) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(total, (i) {
          final isCompleted = i < current;
          final isCurrent = i == current;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: total > 10 ? 12 : 16,
            height: 7,
            decoration: BoxDecoration(
              color: isCompleted
                  ? colors.accentPrimary
                  : (isCurrent
                      ? colors.accentPrimary.withValues(alpha: 0.18)
                      : colors.bgSurface),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isCurrent
                    ? colors.accentPrimary
                    : (isCompleted
                        ? colors.accentPrimary
                        : colors.borderColorLight),
                width: isCurrent ? 1.5 : 1.0,
              ),
            ),
          );
        }),
      );
    }

    // Otherwise, render a continuous smooth capsule track
    final frac = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 6,
        color: colors.bgSurface,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: frac,
          child: Container(
            decoration: BoxDecoration(
              color: colors.accentPrimary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}
