// lib/ui/study/widgets/deck_overview.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../study_session_controller.dart';

class DeckOverview extends StatelessWidget {
  final int dueCount;
  final int newCount;
  final int learningCount;
  final int knownCount;
  final int totalCount;
  final StudyMode selectedMode;
  final ValueChanged<StudyMode> onSelectMode;
  final VoidCallback onStartSession;
  final VoidCallback onPracticeAnyway;
  final VoidCallback? onExploreVideos;

  const DeckOverview({
    super.key,
    required this.dueCount,
    required this.newCount,
    required this.learningCount,
    required this.knownCount,
    required this.totalCount,
    required this.selectedMode,
    required this.onSelectMode,
    required this.onStartSession,
    required this.onPracticeAnyway,
    this.onExploreVideos,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final isTablet = MediaQuery.of(context).size.width >= VocaTokens.tabletBreakpoint;
    final hasDueCards = dueCount > 0 || newCount > 0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                context.t('study.title', null, 'Study & Review'),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.t('study.subtitle', null, 'Review your vocabulary with spaced repetition flashcards'),
                style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
              ),

              const SizedBox(height: 20),

              // 4 Metrics Grid
              Row(
                children: [
                  _buildMetricCard(
                    title: context.t('study.due', null, 'Due Now'),
                    count: dueCount,
                    color: dueCount > 0 ? colors.accentPrimary : colors.textMuted,
                    icon: Icons.timer_outlined,
                    colors: colors,
                  ),
                  const SizedBox(width: 10),
                  _buildMetricCard(
                    title: context.t('study.new', null, 'New'),
                    count: newCount,
                    color: colors.colorGrammar,
                    icon: Icons.eco_outlined,
                    colors: colors,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildMetricCard(
                    title: context.t('study.learning', null, 'Learning'),
                    count: learningCount,
                    color: colors.warning,
                    icon: Icons.school_outlined,
                    colors: colors,
                  ),
                  const SizedBox(width: 10),
                  _buildMetricCard(
                    title: context.t('study.known', null, 'Known'),
                    count: knownCount,
                    color: colors.wordKnownText,
                    icon: Icons.check_circle_outline_rounded,
                    colors: colors,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Study Mode Pill Selector
              Text(
                context.t('study.selectMode', null, 'Choose Study Mode'),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                height: 44,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: colors.bgSecondary,
                  borderRadius: VocaRadius.roundedPill,
                  border: Border.all(color: colors.borderColorLight),
                ),
                child: Row(
                  children: [
                    _buildModeTab(StudyMode.flashcard, context.t('flashcards.mode.flashcard', null, 'Flashcard'), Icons.style_outlined, colors),
                    _buildModeTab(StudyMode.cloze, context.t('flashcards.mode.cloze', null, 'Cloze'), Icons.visibility_off_outlined, colors),
                    _buildModeTab(StudyMode.quiz, context.t('flashcards.mode.quiz', null, 'Quiz'), Icons.quiz_outlined, colors),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Primary Action Buttons
              if (hasDueCards) ...[
                SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: onStartSession,
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: Text(
                      '${context.t('study.start', null, 'Start Review')} (${dueCount + newCount})',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accentPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: VocaRadius.roundedMd),
                    ),
                  ),
                ),
              ] else ...[
                // All caught up state
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colors.bgCard,
                    borderRadius: VocaRadius.roundedLg,
                    border: Border.all(color: colors.borderColorLight),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.done_all_rounded, size: 40, color: colors.colorGrammar),
                      const SizedBox(height: 8),
                      Text(
                        context.t('study.allCaughtUp', null, 'All Caught Up!'),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.t('study.allCaughtUpDesc', null, 'No cards are currently due for review right now.'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: OutlinedButton.icon(
                          onPressed: onPracticeAnyway,
                          icon: const Icon(Icons.fitness_center_rounded, size: 18),
                          label: Text(context.t('study.practiceAnyway', null, 'Practice Anyway (Early Review)')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.accentPrimary,
                            side: BorderSide(color: colors.accentPrimary),
                            shape: RoundedRectangleBorder(borderRadius: VocaRadius.roundedMd),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required VocaColorPalette colors,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: VocaRadius.roundedLg,
          border: Border.all(color: colors.borderColorLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(icon, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(
    StudyMode mode,
    String label,
    IconData icon,
    VocaColorPalette colors,
  ) {
    final isSelected = selectedMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => onSelectMode(mode),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: VocaMotion.fast,
          decoration: BoxDecoration(
            color: isSelected ? colors.bgCard : Colors.transparent,
            borderRadius: VocaRadius.roundedPill,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color: isSelected ? colors.accentPrimary : colors.textMuted,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected ? colors.textPrimary : colors.textMuted,
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
