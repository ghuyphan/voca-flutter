// lib/ui/study/widgets/deck_overview.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../config/voca_theme.dart';
import '../../../models/voca_models.dart';
import '../../../services/gamification_service.dart';
import '../../../services/i18n_service.dart';
import '../../../services/toast_service.dart';
import '../../../state/app_state.dart';
import '../../gamification/streak_screen.dart';
import '../../onboarding/models/onboarding_models.dart';
import '../study_session_controller.dart';
import 'deck_cloze_quiz_sheet.dart';

/// Clean, high-craft Deck Overview Dashboard.
/// Features a native sliding capsule segmented bar, balanced hero card with radial goal indicator,
/// non-truncating stage pills, compact session controls, and full-width launch CTA.
class DeckOverview extends StatelessWidget {
  final StudySessionController controller;
  final VoidCallback onStartSession;
  final VoidCallback onStartDueOnlySession;
  final VoidCallback? onExploreVideos;

  const DeckOverview({
    super.key,
    required this.controller,
    required this.onStartSession,
    required this.onStartDueOnlySession,
    this.onExploreVideos,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final isTablet = MediaQuery.of(context).size.width >= VocaTokens.tabletBreakpoint;
    final gamification = AppState.instance.gamificationService;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 560 : double.infinity),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Native Sliding Segmented Bar (Words | Grammar | All) + Streak Flame Button
              _buildTopBar(context, colors),

              const SizedBox(height: 18),

              // 2. Focused Hero Due Card with Radial Progress Ring & Context
              _buildHeroDueCard(context, colors),

              const SizedBox(height: 18),

              // 3. Stage Filter Pills Row (● New, ● Learning, ● Known)
              _buildStagePillsRow(context, colors),

              const SizedBox(height: 22),

              // 4. Session Controls Row (Batch Size Selector + Due Only Toggle)
              _buildSessionControlsRow(context, colors),

              const SizedBox(height: 24),

              // 5. Full-Width Launch Action Button (with smooth explore secondary action)
              _buildLaunchButton(context, colors),

              const SizedBox(height: 20),

              // 6. Memory Map (Visual 4-Column Bar Chart)
              _buildMemoryMapSection(context, colors),

              const SizedBox(height: 18),

              // 7. Last 30 Days Activity Heatmap Grid
              _buildHeatmapSection(context, colors, gamification),

              const SizedBox(height: 18),

              // 8. More Practice Section (Cloze Sentence Quiz)
              _buildMorePracticeSection(context, colors),

              const SizedBox(height: 18),

              // 9. Daily Quests Section (Missions with 1-tap rewards & Companion Crest)
              _buildDailyQuestsSection(context, colors, gamification),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Top Bar: Native Sliding Segmented Control + Circular Flame Button
  Widget _buildTopBar(BuildContext context, VocaColorPalette colors) {
    final subDeckKeys = ['words', 'grammar', 'all'];
    final subDeckLabels = [
      context.t('study.deckWords', null, 'Words'),
      context.t('study.deckGrammar', null, 'Grammar'),
      context.t('study.deckAll', null, 'All'),
    ];

    return Row(
      children: [
        // Native sliding capsule segmented control
        Expanded(
          child: Watch((_) {
            final selectedSubDeck = controller.subDeck.value;
            return VocaSlidingSegmentedBar(
              values: subDeckKeys,
              labels: subDeckLabels,
              selectedValue: selectedSubDeck,
              onSelected: (val) => controller.setSubDeck(val),
              colors: colors,
              height: 38,
            );
          }),
        ),

        const SizedBox(width: 10),

        // Circular 38px Streak Flame Action Button
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colors.bgSurface,
            shape: BoxShape.circle,
            border: Border.all(color: colors.borderColor),
          ),
          child: IconButton(
            icon: Icon(Icons.local_fire_department_rounded, size: 19, color: colors.colorFire),
            padding: EdgeInsets.zero,
            tooltip: context.t('streak.title', null, 'Streak'),
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StreakScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 2. Hero Due Card with Radial Progress Ring & Context (layout-shift free)
  Widget _buildHeroDueCard(BuildContext context, VocaColorPalette colors) {
    final gamification = AppState.instance.gamificationService;

    return Watch((_) {
      final dueCount = controller.dueCount.value;
      final estMinutes = controller.estimatedMinutes;
      final isEmptyDeck = controller.allCards.value.isEmpty;

      final srsMission = gamification.dailyMissions.value.missions
          .where((m) => m.type == MissionType.srsReview)
          .firstOrNull;
      final dailyTarget = srsMission?.target ?? 10;
      final dailyProgress = srsMission?.progress ?? controller.sessionStats.value.totalReviewed;
      final goalFraction = dailyTarget > 0 ? (dailyProgress / dailyTarget).clamp(0.0, 1.0) : 0.0;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            if (dueCount > 0) {
              onStartDueOnlySession();
            } else if (!isEmptyDeck) {
              ToastService.info(context, context.t('study.allDone', null, 'All cards cleared for today! 🎉'));
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(colors.isDark ? 0.35 : 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              children: [
                // Top row: Section tag + Estimated study time badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 15, color: colors.accentPrimary),
                        const SizedBox(width: 6),
                        Text(
                          context.t('study.dueToday', null, 'Due Today'),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (dueCount > 0) ...[
                          const SizedBox(width: 5),
                          Icon(Icons.arrow_forward_ios_rounded, size: 11, color: colors.accentPrimary),
                        ],
                      ],
                    ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.borderColorLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 12, color: colors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        context.t('study.estimatedMinutes', {'minutes': estMinutes}, '~$estMinutes min'),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Center Readout: Radial Progress Ring + Large Numeral
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Circular Daily Goal Ring (56x56)
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: goalFraction,
                        strokeWidth: 5,
                        backgroundColor: colors.bgSurface,
                        valueColor: AlwaysStoppedAnimation(
                          goalFraction >= 1.0 ? colors.success : colors.accentPrimary,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                      Icon(
                        goalFraction >= 1.0
                            ? Icons.check_circle_rounded
                            : Icons.local_fire_department_rounded,
                        size: 24,
                        color: goalFraction >= 1.0 ? colors.success : colors.colorFire,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 18),

                // Big Count & Contextual Subtitle (fixed height to prevent layout shift)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$dueCount',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 34,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            isEmptyDeck
                                ? context.t('study.noWordsHint', null, 'Save words while watching videos to build your review deck.')
                                : dueCount > 0
                                    ? context.t('study.cardsReadyHint', null, 'Cards waiting for spaced review')
                                    : context.t('study.allDone', null, 'All cards cleared for today! 🎉'),
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Bottom Daily Goal Track
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 4,
                color: colors.bgSurface,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: goalFraction,
                  child: Container(color: colors.textPrimary),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Goal Row (Daily Goal · Progress / Target)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.t('study.dailyGoal', null, 'Daily Goal'),
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$dailyProgress / $dailyTarget',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
});
}

  /// 3. Stage Filter Pills Row (● New, ● Learning, ● Known)
  Widget _buildStagePillsRow(BuildContext context, VocaColorPalette colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Watch((_) {
        final fresh = controller.newCount.value;
        final learning = controller.learningCount.value;
        final known = controller.knownCount.value;
        final incNew = controller.includeNew.value;
        final incLearning = controller.includeLearning.value;
        final incKnown = controller.includeKnown.value;

        return Row(
          children: [
            _buildStagePill(
              label: context.t('study.new', null, 'New'),
              count: fresh,
              dotColor: const Color(0xFF60A5FA),
              isActive: incNew,
              onTap: () => controller.toggleDeckInclusion('new'),
              colors: colors,
            ),
            const SizedBox(width: 8),
            _buildStagePill(
              label: context.t('study.learning', null, 'Learning'),
              count: learning,
              dotColor: const Color(0xFFFBBF24),
              isActive: incLearning,
              onTap: () => controller.toggleDeckInclusion('learning'),
              colors: colors,
            ),
            const SizedBox(width: 8),
            _buildStagePill(
              label: context.t('study.known', null, 'Known'),
              count: known,
              dotColor: const Color(0xFF34D399),
              isActive: incKnown,
              onTap: () => controller.toggleDeckInclusion('known'),
              colors: colors,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStagePill({
    required String label,
    required int count,
    required Color dotColor,
    required bool isActive,
    required VoidCallback onTap,
    required VocaColorPalette colors,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? colors.borderColorHover : colors.borderColorLight,
          ),
        ),
        child: Opacity(
          opacity: isActive ? 1.0 : 0.45,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 4. Session Controls Row (Batch Size Selector + Due Only Toggle)
  Widget _buildSessionControlsRow(BuildContext context, VocaColorPalette colors) {
    final sizeKeys = ['5', '10', '20', 'all'];
    final sizeLabels = ['5', '10', '20', context.t('study.allCards', null, 'All')];

    return Watch((_) {
      final currentSize = controller.sessionSize.value;
      final dueOnly = controller.dueOnly.value;
      final currentKey = currentSize == null ? 'all' : '$currentSize';

      return Row(
        children: [
          // Sliding batch size selector
          Expanded(
            child: VocaSlidingSegmentedBar(
              values: sizeKeys,
              labels: sizeLabels,
              selectedValue: currentKey,
              onSelected: (key) {
                final size = key == 'all' ? null : int.tryParse(key);
                controller.setSessionSize(size);
              },
              colors: colors,
              height: 38,
            ),
          ),

          const SizedBox(width: 10),

          // Due Only Toggle Pill
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              controller.toggleDueOnly();
            },
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dueOnly ? colors.accentPrimary.withValues(alpha: 0.15) : colors.bgSurface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: dueOnly ? colors.accentPrimary : colors.borderColor,
                  width: dueOnly ? 1.2 : 1.0,
                ),
              ),
              child: Text(
                context.t('study.dueOnly', null, 'Due Only'),
                style: TextStyle(
                  color: dueOnly ? colors.accentPrimary : colors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: dueOnly ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  /// 5. Full-Width Launch Action Button (with smooth animated secondary explore action)
  Widget _buildLaunchButton(BuildContext context, VocaColorPalette colors) {
    return Watch((_) {
      final isEmptyDeck = controller.allCards.value.isEmpty;
      final sessionCount = controller.sessionCardsCount;
      final hasCandidates = sessionCount > 0;
      final showExploreSecondary = !isEmptyDeck && sessionCount == 0 && onExploreVideos != null;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                if (isEmptyDeck) {
                  onExploreVideos?.call();
                } else if (!hasCandidates) {
                  controller.startSession(practiceAnyway: true);
                } else {
                  onStartSession();
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEmptyDeck ? Icons.movie_filter_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEmptyDeck
                        ? context.t('study.exploreVideos', null, 'Explore Videos')
                        : hasCandidates
                            ? '${context.t('study.startReview', null, 'Start Review')} ($sessionCount)'
                            : context.t('study.practiceAnyway', null, 'Practice Anyway'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: showExploreSecondary
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildExploreVideosButton(context, colors),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );
    });
  }

  /// Secondary explore action when user is caught up
  Widget _buildExploreVideosButton(BuildContext context, VocaColorPalette colors) {
    return Center(
      child: TextButton.icon(
        onPressed: () {
          HapticFeedback.selectionClick();
          onExploreVideos?.call();
        },
        icon: Icon(Icons.movie_filter_outlined, size: 16, color: colors.textSecondary),
        label: Text(
          context.t('study.exploreVideos', null, 'Explore videos for new words'),
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 6. Memory Map Section (Visual 4-Column Bar Chart matching M3 preview)
  Widget _buildMemoryMapSection(BuildContext context, VocaColorPalette colors) {
    return Watch((_) {
      final cards = controller.allCards.value;
      final activeDeck = controller.subDeck.value;
      final deckCards = cards.where((c) {
        final isG = controller.isGrammarCard(c);
        if (activeDeck == 'words') return !isG;
        if (activeDeck == 'grammar') return isG;
        return true;
      }).toList();

      final totalCount = deckCards.length;
      final now = DateTime.now();

      final newCount = controller.newCount.value;
      final learningCount = controller.learningCount.value;
      final knownCount = controller.knownCount.value;
      final masteredCount = deckCards.where((c) => c.level == 'known' && c.srsInterval >= 21).length;

      // Calculate actual due count for each stage to render solid fill
      final learningDue = deckCards.where((c) {
        final norm = WordLevels.normalize(c.level);
        return norm == WordLevels.learning && (c.srsNextReviewAt.isBefore(now) || c.srsNextReviewAt.isAtSameMomentAs(now));
      }).length;

      final knownDue = deckCards.where((c) {
        final norm = WordLevels.normalize(c.level);
        return norm == WordLevels.known && c.srsInterval < 21 && (c.srsNextReviewAt.isBefore(now) || c.srsNextReviewAt.isAtSameMomentAs(now));
      }).length;

      final masteredDue = deckCards.where((c) {
        return c.level == 'known' && c.srsInterval >= 21 && (c.srsNextReviewAt.isBefore(now) || c.srsNextReviewAt.isAtSameMomentAs(now));
      }).length;

      final maxCount = math.max(1, math.max(math.max(newCount, learningCount), math.max(knownCount, masteredCount)));
      final deckNoun = activeDeck == 'grammar'
          ? context.t('study.deckGrammar', null, 'grammar').toLowerCase()
          : (activeDeck == 'words'
              ? context.t('study.deckWords', null, 'words').toLowerCase()
              : context.t('study.items', null, 'items').toLowerCase());

      return Container(
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderColor),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_graph_rounded, size: 16, color: colors.colorGrammar),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${context.t('study.memoryMap', null, 'Memory map')} · $totalCount $deckNoun',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildMemoryMapColumn(
                  context,
                  colors,
                  label: context.t('vocab.new', null, 'New'),
                  count: newCount,
                  maxCount: maxCount,
                  color: const Color(0xFF38BDF8),
                  dueCount: 0,
                ),
                const SizedBox(width: 8),
                _buildMemoryMapColumn(
                  context,
                  colors,
                  label: context.t('vocab.learning', null, 'Learning'),
                  count: learningCount,
                  maxCount: maxCount,
                  color: colors.colorGrammar,
                  dueCount: learningDue,
                ),
                const SizedBox(width: 8),
                _buildMemoryMapColumn(
                  context,
                  colors,
                  label: context.t('vocab.known', null, 'Known'),
                  count: knownCount,
                  maxCount: maxCount,
                  color: const Color(0xFF58AFFF),
                  dueCount: knownDue,
                ),
                const SizedBox(width: 8),
                _buildMemoryMapColumn(
                  context,
                  colors,
                  label: context.t('study.stageMastered', null, 'Mastered'),
                  count: masteredCount,
                  maxCount: maxCount,
                  color: colors.accentSecondary,
                  dueCount: masteredDue,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              context.t('study.solidPartDueToday', null, 'Solid part: due today'),
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMemoryMapColumn(
    BuildContext context,
    VocaColorPalette colors, {
    required String label,
    required int count,
    required int maxCount,
    required Color color,
    int dueCount = 0,
  }) {
    final double normalizedFraction = count > 0 ? (count / maxCount).clamp(0.08, 1.0) : 0.0;
    final double barHeight = count > 0 ? (normalizedFraction * 48.0) : 4.0;
    final bool hasItems = count > 0;
    final double dueFraction = (count > 0 && dueCount > 0) ? (dueCount / count).clamp(0.0, 1.0) : 0.0;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: hasItems ? color : colors.textMuted,
              fontSize: 13,
              fontWeight: hasItems ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: barHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: hasItems ? color.withOpacity(0.18) : colors.bgSurface,
              borderRadius: BorderRadius.circular(hasItems ? 8 : 999),
              border: Border.all(
                color: hasItems ? color.withOpacity(0.4) : colors.borderColorLight,
                width: hasItems ? 1.5 : 1.0,
              ),
            ),
            child: hasItems && dueFraction > 0
                ? Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: (barHeight * dueFraction).clamp(3.0, barHeight),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.vertical(
                          bottom: const Radius.circular(6.5),
                          top: dueFraction >= 0.95 ? const Radius.circular(6.5) : Radius.zero,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: hasItems ? color : colors.textMuted,
              fontSize: 11,
              fontWeight: hasItems ? FontWeight.w700 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 7. Last 30 Days Activity Heatmap Section (0-shift, high-performance static row matrix)
  Widget _buildHeatmapSection(
    BuildContext context,
    VocaColorPalette colors,
    GamificationService gamification,
  ) {
    return Watch((_) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final activeDates = gamification.activeDates;
      final df = DateFormat('yyyy-MM-dd');
      final streak = gamification.currentStreak.value;

      final days = List.generate(30, (i) {
        final d = today.subtract(Duration(days: 29 - i));
        final dStr = df.format(d);
        final isActive = activeDates.contains(dStr);
        final isToday = (i == 29);
        return (date: d, isActive: isActive, isToday: isToday);
      });

      return Container(
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderColor),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 16, color: colors.colorFire),
                    const SizedBox(width: 8),
                    Text(
                      context.t('study.last30Days', null, 'Last 30 days'),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      context.t('study.less', null, 'Less'),
                      style: TextStyle(color: colors.textMuted, fontSize: 11),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.colorGrammar.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.colorGrammar,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      context.t('study.more', null, 'More'),
                      style: TextStyle(color: colors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2 Rows of 15 tiles (0-layout shift, 0 dual-pass measurement overhead)
            Column(
              children: [
                Row(
                  children: List.generate(15, (col) {
                    final dayInfo = days[col];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: Tooltip(
                            triggerMode: TooltipTriggerMode.tap,
                            preferBelow: false,
                            message: '${DateFormat('MMM d').format(dayInfo.date)}: ${dayInfo.isActive ? context.t('study.heatmapReviewed', null, 'Reviewed') : context.t('study.heatmapRestDay', null, 'Rest day')}',
                            child: Container(
                              decoration: BoxDecoration(
                                color: dayInfo.isActive ? colors.colorGrammar : colors.bgSurface,
                                borderRadius: BorderRadius.circular(3.5),
                                border: dayInfo.isToday
                                    ? Border.all(color: colors.accentPrimary, width: 1.5)
                                    : Border.all(color: colors.borderColorLight, width: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(15, (col) {
                    final dayInfo = days[col + 15];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: Tooltip(
                            triggerMode: TooltipTriggerMode.tap,
                            preferBelow: false,
                            message: '${DateFormat('MMM d').format(dayInfo.date)}: ${dayInfo.isActive ? context.t('study.heatmapReviewed', null, 'Reviewed') : context.t('study.heatmapRestDay', null, 'Rest day')}',
                            child: Container(
                              decoration: BoxDecoration(
                                color: dayInfo.isActive ? colors.colorGrammar : colors.bgSurface,
                                borderRadius: BorderRadius.circular(3.5),
                                border: dayInfo.isToday
                                    ? Border.all(color: colors.accentPrimary, width: 1.5)
                                    : Border.all(color: colors.borderColorLight, width: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🔥 $streak ${context.t('streak.dayStreak', null, 'days streak')}',
                  style: TextStyle(
                    color: colors.colorFire,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.t('study.tapDayToView', null, 'Tap a day to view'),
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  /// 8. More Practice Section: Cloze Sentence Quiz
  Widget _buildMorePracticeSection(BuildContext context, VocaColorPalette colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_esports_rounded, size: 16, color: colors.accentPrimary),
              const SizedBox(width: 8),
              Text(
                context.t('study.morePractice', null, 'More Practice'),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              final candidateCards = controller.allCards.value
                  .where((c) =>
                      c.contextSentence != null &&
                      c.contextSentence!.trim().isNotEmpty &&
                      c.contextSentence!.contains(c.word))
                  .toList();
              if (candidateCards.isEmpty) {
                ToastService.show(
                  context,
                  context.t('study.noContextSentencesHint', null, 'Save words from videos to practice with authentic sentence context!'),
                  type: ToastType.info,
                );
              } else {
                DeckClozeQuizSheet.show(context, controller.allCards.value);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderColorLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.accentPrimarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.psychology_rounded, size: 22, color: colors.accentPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                context.t('study.clozeQuizTitle', null, 'Cloze Sentence Quiz'),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.accentPrimarySoft,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '+15 XP',
                                style: TextStyle(
                                  color: colors.accentPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.t('study.clozeQuizDesc', null, 'Practice missing words from authentic video sentences'),
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.textMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 9. Daily Quests Section (Missions with 1-tap rewards & Companion Crest)
  Widget _buildDailyQuestsSection(
    BuildContext context,
    VocaColorPalette colors,
    GamificationService gamification,
  ) {
    return Watch((_) {
      final missions = gamification.dailyMissions.value.missions;
      final canClaimBonus = gamification.canClaimDailyBonus.value;
      final userSettings = AppState.instance.userSettings.value;
      final companionId = userSettings.companionClass.toLowerCase();
      final compOpt = CompanionOption.all.firstWhere(
        (c) => c.id == companionId,
        orElse: () => CompanionOption.all.first,
      );

      return Container(
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderColor),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.local_fire_department_rounded, size: 18, color: colors.colorFire),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          context.t('study.dailyQuests', null, 'Daily Quests'),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Companion guide badge: subtle, refined neutral tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.borderColorLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(compOpt.icon, size: 13, color: colors.textSecondary),
                      const SizedBox(width: 4.5),
                      Text(
                        context.t(compOpt.nameKey, null, compOpt.id[0].toUpperCase() + compOpt.id.substring(1)),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (canClaimBonus) ...[
              const SizedBox(height: 10),
              _buildDailyChestBonusCard(context, colors, gamification),
            ],
            const SizedBox(height: 12),
            ...missions.map((m) {
              final isCompleted = m.isCompleted;
              final isClaimed = m.isClaimed;
              final fraction = m.progressRatio;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCompleted && !isClaimed
                          ? colors.accentPrimary.withValues(alpha: 0.35)
                          : colors.borderColorLight,
                    ),
                  ),
                  child: Opacity(
                    opacity: isClaimed ? 0.6 : 1.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Clean, quiet neutral icon container (38x38)
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: colors.bgCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: colors.borderColorLight),
                          ),
                          child: Icon(
                            isCompleted ? Icons.check_circle_rounded : m.icon,
                            size: 19,
                            color: isCompleted ? colors.accentPrimary : colors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Mission Body
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header: Title + subtle XP tag
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      m.localizedTitle(context),
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colors.bgCard,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(color: colors.borderColorLight),
                                    ),
                                    child: Text(
                                      '+${m.xpReward} XP',
                                      style: TextStyle(
                                        color: colors.textSecondary,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),

                              // Description
                              Text(
                                m.localizedDescription(context),
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),

                              // Footer: Sleek progress bar + count + claim action
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: Container(
                                        height: 4,
                                        color: colors.bgCard,
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: fraction,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: colors.accentPrimary,
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${m.progress}/${m.target}',
                                    style: TextStyle(
                                      color: colors.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  if (isClaimed || isCompleted) ...[
                                    const SizedBox(width: 8),
                                    if (isClaimed)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_rounded, size: 12, color: colors.textMuted),
                                          const SizedBox(width: 3),
                                          Text(
                                            context.t('missions.claimed', null, 'Claimed'),
                                            style: TextStyle(
                                              color: colors.textMuted,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      FilledButton(
                                        onPressed: () {
                                          HapticFeedback.mediumImpact();
                                          gamification.claimMission(m.id);
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor: colors.accentPrimary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                          minimumSize: const Size(56, 24),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                        ),
                                        child: Text(
                                          context.t('missions.claim', null, 'Claim'),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  /// Daily Completion Chest Card matching lingua-tube design when all daily quests are finished
  Widget _buildDailyChestBonusCard(
    BuildContext context,
    VocaColorPalette colors,
    GamificationService gamification,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderColorLight),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.borderColorLight),
            ),
            child: Icon(Icons.card_giftcard_rounded, color: colors.accentPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        context.t('missions.dailyChest', null, 'Daily Bonus'),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+50 XP',
                      style: TextStyle(
                        color: colors.accentPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  context.t('missions.dailyChestDesc', null, 'All daily quests finished! Open the chest.'),
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              gamification.claimDailyBonus();
            },
            style: FilledButton.styleFrom(
              backgroundColor: colors.accentPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(60, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: Text(
              context.t('missions.claim', null, 'Claim'),
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// Native-feeling sliding segmented control with gliding thumb animation.
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
    final selectedIndex = values.indexOf(selectedValue).clamp(0, values.length - 1);

    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / values.length;

          return Stack(
            children: [
              // Gliding thumb indicator
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(colors.isDark ? 0.35 : 0.08),
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
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelected(values[i]);
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 160),
                          style: TextStyle(
                            color: isSelected ? colors.textPrimary : colors.textMuted,
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
