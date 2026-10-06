// lib/ui/study/widgets/anki_hud_header.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';

/// Top HUD header featuring iconic Anki tri-color counters (New, Learn, Due),
/// session progress bar, streak combo, and deck filter shortcut.
class AnkiHudHeader extends StatelessWidget {
  final String activeLanguage;
  final String subDeck;
  final int newCount;
  final int learningCount;
  final int dueCount;
  final int currentIndex;
  final int totalInSession;
  final int combo;
  final VoidCallback onOpenDeckSettings;
  final VoidCallback? onExit;

  const AnkiHudHeader({
    super.key,
    required this.activeLanguage,
    required this.subDeck,
    required this.newCount,
    required this.learningCount,
    required this.dueCount,
    required this.currentIndex,
    required this.totalInSession,
    this.combo = 0,
    required this.onOpenDeckSettings,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final progress = totalInSession > 0 ? (currentIndex + 1) / totalInSession : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Deck Pill, Anki Tri-Color Counters, Streak & Settings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Deck Filter Pill (e.g. "JA · ALL ▾")
              Flexible(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onOpenDeckSettings,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: VocaRadius.roundedPill,
                      border: Border.all(color: colors.borderColorLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            '${activeLanguage.toUpperCase()} · ${_formatSubDeck(subDeck)}',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: colors.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),

              // Center: Anki Iconic Tri-Color Counters [ 🔵 New | 🟠 Learn | 🟢 Due ]
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: VocaRadius.roundedPill,
                  border: Border.all(color: colors.borderColorLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Blue: New
                    _buildCountItem(
                      count: newCount,
                      color: const Color(0xFF3B82F6),
                      tooltip: 'New Cards',
                    ),
                    _buildDivider(colors),
                    // Orange: Learn
                    _buildCountItem(
                      count: learningCount,
                      color: const Color(0xFFF97316),
                      tooltip: 'Learning Cards',
                    ),
                    _buildDivider(colors),
                    // Green: Due
                    _buildCountItem(
                      count: dueCount,
                      color: const Color(0xFF10B981),
                      tooltip: 'Due for Review',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),

              // Right: Combo Streak & Settings Button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (combo >= 2) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.colorFire.withValues(alpha: 0.12),
                        borderRadius: VocaRadius.roundedPill,
                        border: Border.all(color: colors.colorFire.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_fire_department_rounded, size: 13, color: colors.colorFire),
                          const SizedBox(width: 2),
                          Text(
                            '$combo',
                            style: TextStyle(
                              color: colors.colorFire,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  IconButton(
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    color: colors.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: 'Deck Settings',
                    onPressed: onOpenDeckSettings,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Row 2: Sleek Progress Bar with capsule dots (or continuous bar if total > 15)
          Row(
            children: [
              Expanded(
                child: totalInSession <= 15
                    ? Row(
                        children: List.generate(totalInSession, (i) {
                          final isCurrent = i == currentIndex;
                          final isCompleted = i < currentIndex;
                          return Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              height: isCurrent ? 6 : 4,
                              margin: EdgeInsets.only(right: i < totalInSession - 1 ? 4 : 0),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? colors.accentPrimary
                                    : (isCompleted
                                        ? colors.accentPrimary.withValues(alpha: 0.55)
                                        : colors.bgSurface),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: isCurrent
                                      ? colors.accentPrimary
                                      : (isCompleted
                                          ? colors.accentPrimary.withValues(alpha: 0.55)
                                          : colors.borderColorLight),
                                  width: isCurrent ? 1.2 : 0.8,
                                ),
                              ),
                            ),
                          );
                        }),
                      )
                    : ClipRRect(
                        borderRadius: VocaRadius.roundedPill,
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: colors.bgSecondary,
                          valueColor: AlwaysStoppedAnimation<Color>(colors.accentPrimary),
                          minHeight: 4,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Text(
                '${currentIndex + 1}/$totalInSession',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountItem({
    required int count,
    required Color color,
    required String tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(VocaColorPalette colors) {
    return Container(
      width: 1,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: colors.borderColorLight,
    );
  }

  String _formatSubDeck(String deck) {
    return switch (deck) {
      'words' => 'WORDS',
      'grammar' => 'GRAMMAR',
      _ => 'ALL',
    };
  }
}
