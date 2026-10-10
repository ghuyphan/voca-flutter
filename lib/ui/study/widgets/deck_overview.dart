// lib/ui/study/widgets/deck_overview.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../config/voca_theme.dart';
import '../../../models/voca_models.dart';
import '../../../services/gamification_service.dart';
import '../../../services/haptic_service.dart';
import '../../../services/i18n_service.dart';
import '../../../services/toast_service.dart';
import '../../../state/app_state.dart';
import '../../gamification/widgets/activity_heatmap_card.dart';
import '../../gamification/widgets/achievements_sheet.dart';
import '../../gamification/widgets/streak_sheet.dart';
import '../../widgets/voca_sliding_segmented_bar.dart';
import '../study_session_controller.dart';
import 'deck_cloze_quiz_sheet.dart';

/// Clean, high-craft Deck Overview Dashboard.
/// Features native sliding segmented controls, interactive tooltips,
/// and simplified StreakSheet modal.
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
    final isTablet = MediaQuery.sizeOf(context).width >= 600.0;
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
              // 1. Top Header (Title + Streak Badge) + Material 3 Secondary TabBar
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

  /// 1. Top Bar: Native Sliding Segmented Bar + Streak Flame Pill Badge (38dp height)
  Widget _buildTopBar(BuildContext context, VocaColorPalette colors) {
    final gamification = AppState.instance.gamificationService;
    final subDeckKeys = ['words', 'grammar', 'all'];
    final subDeckLabels = [
      context.t('study.deckWords', null, 'Words'),
      context.t('study.deckGrammar', null, 'Grammar'),
      context.t('study.deckAll', null, 'All'),
    ];

    return Watch((_) {
      final currentSubDeck = controller.subDeck.value;
      final streak = gamification.currentStreak.value;

      return Row(
        children: [
          // Sub-deck switcher (Words | Grammar | All)
          Expanded(
            child: VocaSlidingSegmentedBar(
              values: subDeckKeys,
              labels: subDeckLabels,
              selectedValue: currentSubDeck,
              colors: colors,
              height: 38,
              onSelected: (val) {
                if (controller.subDeck.value != val) {
                  controller.setSubDeck(val);
                  final cards = controller.allCards.value;
                  if (cards.isNotEmpty) {
                    final inDeck = cards.where((c) {
                      final isG = controller.isGrammarCard(c);
                      if (val == 'words') return !isG;
                      if (val == 'grammar') return isG;
                      return true;
                    }).length;
                    if (inDeck == 0) {
                      ToastService.info(
                        context,
                        val == 'grammar'
                            ? context.t('study.noGrammarHint', null, 'No grammar patterns saved in this deck yet!')
                            : context.t('study.noWordsHint', null, 'No vocabulary words saved in this deck yet!'),
                      );
                    }
                  }
                }
              },
            ),
          ),

          const SizedBox(width: 10),

          // Tappable Streak Flame Pill with Tooltip -> Opens StreakSheet (48x48dp minimum target)
          Tooltip(
            message: context.t('streak.viewStreakDetails', null, 'View streak calendar & shields'),
            child: Semantics(
              button: true,
              label: context.t('streak.viewStreakDetails', null, 'Streak: $streak days. View streak calendar and shields'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticService.selection();
                        StreakSheet.show(context);
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: colors.colorFire.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: colors.colorFire.withValues(alpha: 0.32),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_fire_department_rounded, size: 20, color: colors.colorFire),
                            const SizedBox(width: 6),
                            Text(
                              '$streak',
                              style: TextStyle(
                                color: colors.colorFire,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });
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
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticService.medium();
            if (dueCount > 0) {
              onStartDueOnlySession();
            } else if (!isEmptyDeck) {
              ToastService.info(
                context,
                context.t('study.allDone', null, 'All cards cleared for today! 🎉'),
              );
            } else {
              ToastService.info(
                context,
                context.t('study.noWordsHint', null, 'Save words while watching videos to build your review deck.'),
                actionLabel: onExploreVideos != null ? context.t('study.exploreVideos', null, 'Explore') : null,
                onAction: onExploreVideos,
              );
              onExploreVideos?.call();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.borderColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              children: [
                // Top row: Section tag + Estimated study time badge
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 15, color: colors.accentPrimary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              context.t('study.dueToday', null, 'Due Today'),
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (dueCount > 0) ...[
                            const SizedBox(width: 5),
                            Icon(Icons.arrow_forward_ios_rounded, size: 11, color: colors.accentPrimary),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
                  child: Container(
                    color: goalFraction >= 1.0 ? colors.success : colors.accentPrimary,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Goal Row (Daily Goal · Progress / Target)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    context.t('study.dailyGoal', null, 'Daily Goal'),
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
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
              dotColor: colors.wordNewText,
              isActive: incNew,
              onTap: () => controller.toggleDeckInclusion('new'),
              colors: colors,
            ),
            const SizedBox(width: 8),
            _buildStagePill(
              label: context.t('study.learning', null, 'Learning'),
              count: learning,
              dotColor: colors.wordLearningText,
              isActive: incLearning,
              onTap: () => controller.toggleDeckInclusion('learning'),
              colors: colors,
            ),
            const SizedBox(width: 8),
            _buildStagePill(
              label: context.t('study.known', null, 'Known'),
              count: known,
              dotColor: colors.wordKnownText,
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
    return Tooltip(
      message: '$label: $count (${isActive ? "Active" : "Filtered out"})',
      child: Semantics(
        button: true,
        selected: isActive,
        label: '$label: $count',
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticService.selection();
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
                      width: isActive ? 1.2 : 1.0,
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 4. Session Controls Row (Batch Size Selector + Due Only Toggle)
  Widget _buildSessionControlsRow(BuildContext context, VocaColorPalette colors) {
    return Watch((_) {
      final currentSize = controller.sessionSize.value;
      final dueOnly = controller.dueOnly.value;
      final currentKey = currentSize == null ? 'all' : '$currentSize';

      return Row(
        children: [
          // Batch size selector using VocaSlidingSegmentedBar
          Expanded(
            child: VocaSlidingSegmentedBar(
              values: const ['5', '10', '20', 'all'],
              labels: [
                '5',
                '10',
                '20',
                context.t('study.deckAll', null, 'All'),
              ],
              selectedValue: currentKey,
              colors: colors,
              height: 38,
              onSelected: (key) {
                final size = key == 'all' ? null : int.tryParse(key);
                controller.setSessionSize(size);
              },
            ),
          ),

          const SizedBox(width: 10),

          // Due Only Filter / Toggle Pill (48x48dp minimum hit target with crisp styling)
          Tooltip(
            message: dueOnly
                ? context.t('study.dueOnlyActiveHint', null, 'Only showing cards due for review')
                : context.t('study.dueOnlyInactiveHint', null, 'Reviewing cards ahead of schedule'),
            child: Semantics(
              button: true,
              selected: dueOnly,
              label: context.t('study.dueOnly', null, 'Due Only'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticService.selection();
                        controller.toggleDueOnly();
                        if (controller.dueOnly.value && controller.dueCount.value == 0) {
                          ToastService.info(
                            context,
                            context.t('study.allDone', null, 'All cards cleared for today! 🎉 Turn off "Due Only" to practice ahead.'),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: dueOnly
                              ? colors.accentPrimary.withValues(alpha: 0.14)
                              : colors.bgSurface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: dueOnly ? colors.accentPrimary : colors.borderColor,
                            width: dueOnly ? 1.2 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              dueOnly ? Icons.alarm_on_rounded : Icons.alarm_rounded,
                              size: 16,
                              color: dueOnly ? colors.accentPrimary : colors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.t('study.dueOnly', null, 'Due Only'),
                              style: TextStyle(
                                color: dueOnly ? colors.accentPrimary : colors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: dueOnly ? FontWeight.w700 : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                HapticService.medium();
                if (isEmptyDeck) {
                  ToastService.info(
                    context,
                    context.t('study.noWordsHint', null, 'Save words while watching videos to build your review deck.'),
                    actionLabel: onExploreVideos != null ? context.t('study.exploreVideos', null, 'Explore') : null,
                    onAction: onExploreVideos,
                  );
                  onExploreVideos?.call();
                } else if (!hasCandidates) {
                  final currentSubDeck = controller.subDeck.value;
                  final availableInDeck = controller.allCards.value.where((card) {
                    final isG = controller.isGrammarCard(card);
                    if (currentSubDeck == 'words' && isG) return false;
                    if (currentSubDeck == 'grammar' && !isG) return false;
                    return true;
                  }).length;

                  if (availableInDeck == 0) {
                    ToastService.info(
                      context,
                      currentSubDeck == 'grammar'
                          ? context.t('study.noGrammarHint', null, 'No grammar patterns saved in this deck yet!')
                          : context.t('study.noWordsHint', null, 'Save words while watching videos to build your review deck.'),
                    );
                  } else {
                    controller.startSession(practiceAnyway: true);
                    if (controller.sessionCards.value.isEmpty) {
                      ToastService.info(
                        context,
                        context.t('study.allDone', null, 'All cards cleared for today! 🎉'),
                      );
                    }
                  }
                } else {
                  onStartSession();
                  if (controller.sessionCards.value.isEmpty) {
                    ToastService.info(
                      context,
                      context.t('study.allDone', null, 'All cards cleared for today! 🎉'),
                    );
                  }
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isEmptyDeck ? Icons.movie_filter_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
    return SizedBox(
      height: 44,
      child: FilledButton.tonalIcon(
        onPressed: () {
          HapticService.selection();
          onExploreVideos?.call();
        },
        style: FilledButton.styleFrom(
          backgroundColor: colors.accentPrimary.withValues(alpha: 0.12),
          foregroundColor: colors.accentPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        icon: const Icon(Icons.movie_filter_rounded, size: 18),
        label: Text(
          context.t('study.exploreVideosAction', null, 'Explore videos to add words'),
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
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

      final newCount = deckCards.where((c) => WordLevels.normalize(c.level) == WordLevels.isNew).length;
      final learningCount = deckCards.where((c) => WordLevels.normalize(c.level) == WordLevels.learning).length;
      final knownCount = deckCards.where((c) {
        final norm = WordLevels.normalize(c.level);
        return norm == WordLevels.known && c.srsInterval < 21;
      }).length;
      final masteredCount = deckCards.where((c) {
        final norm = WordLevels.normalize(c.level);
        return (norm == WordLevels.known || norm == 'mastered') && c.srsInterval >= 21;
      }).length;

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
        final norm = WordLevels.normalize(c.level);
        return (norm == WordLevels.known || norm == 'mastered') && c.srsInterval >= 21 && (c.srsNextReviewAt.isBefore(now) || c.srsNextReviewAt.isAtSameMomentAs(now));
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
                  color: colors.wordNewText,
                  dueCount: 0,
                ),
                const SizedBox(width: 8),
                _buildMemoryMapColumn(
                  context,
                  colors,
                  label: context.t('vocab.learning', null, 'Learning'),
                  count: learningCount,
                  maxCount: maxCount,
                  color: colors.wordLearningText,
                  dueCount: learningDue,
                ),
                const SizedBox(width: 8),
                _buildMemoryMapColumn(
                  context,
                  colors,
                  label: context.t('vocab.known', null, 'Known'),
                  count: knownCount,
                  maxCount: maxCount,
                  color: colors.wordKnownText,
                  dueCount: knownDue,
                ),
                const SizedBox(width: 8),
                _buildMemoryMapColumn(
                  context,
                  colors,
                  label: context.t('study.stageMastered', null, 'Mastered'),
                  count: masteredCount,
                  maxCount: maxCount,
                  color: colors.wordMasteredText,
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
    final double targetHeight = count > 0 ? (normalizedFraction * 50.0).clamp(6.0, 50.0) : 4.0;
    final bool hasItems = count > 0;
    final double dueFraction = (count > 0 && dueCount > 0) ? (dueCount / count).clamp(0.0, 1.0) : 0.0;

    return Expanded(
      child: Tooltip(
        message: '$label: $count (${dueCount > 0 ? "$dueCount due today" : "Not due"})',
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
            SizedBox(
              height: 52,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('memory_col_${label}_$targetHeight'),
                  tween: Tween<double>(begin: 0.0, end: targetHeight),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedBarHeight, _) {
                    return Container(
                      height: animatedBarHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: hasItems ? color.withValues(alpha: 0.18) : colors.bgSurface,
                        borderRadius: BorderRadius.circular(hasItems ? 8 : 999),
                        border: Border.all(
                          color: hasItems ? color.withValues(alpha: 0.4) : colors.borderColorLight,
                          width: hasItems ? 1.5 : 1.0,
                        ),
                      ),
                      child: hasItems && dueFraction > 0 && animatedBarHeight > 0
                          ? Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: (animatedBarHeight * dueFraction).clamp(
                                  math.min(3.0, animatedBarHeight),
                                  animatedBarHeight,
                                ),
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
                    );
                  },
                ),
              ),
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
      ),
    );
  }
  /// 7. Last 30 Days Activity Heatmap Section (with fluid in-place day inspector)
  Widget _buildHeatmapSection(
    BuildContext context,
    VocaColorPalette colors,
    GamificationService gamification,
  ) {
    return ActivityHeatmapCard(colors: colors, gamification: gamification);
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
              HapticService.selection();
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
                            Builder(
                              builder: (_) {
                                final isCapReached = AppState.instance.gamificationService.isQuizCapReachedToday;
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isCapReached ? colors.bgSecondary : colors.accentPrimarySoft,
                                    borderRadius: BorderRadius.circular(4),
                                    border: isCapReached ? Border.all(color: colors.borderColorLight) : null,
                                  ),
                                  child: Text(
                                    isCapReached
                                        ? context.t('study.practiceMode', null, 'Practice')
                                        : '+20 XP',
                                    style: TextStyle(
                                      color: isCapReached ? colors.textSecondary : colors.accentPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                );
                              },
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

  /// 9. Daily Quests Section (Missions with 1-tap rewards & zero layout-shift architecture)
  Widget _buildDailyQuestsSection(
    BuildContext context,
    VocaColorPalette colors,
    GamificationService gamification,
  ) {
    return Watch((_) {
      final missionsState = gamification.dailyMissions.value;
      final missions = missionsState.missions;
      final completedCount = missions.where((m) => m.isCompleted).length;
      final totalMissions = missions.length;
      final canClaimBonus = gamification.canClaimDailyBonus.value;
      final isBonusClaimed = missionsState.allCompletedBonusClaimed;
      final bonusXp = missionsState.bonusXp;

      final isAllCompleted = totalMissions > 0 && completedCount >= totalMissions;

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
            // Header Row: Icon + Title + Progress Badge + Companion Tag
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isAllCompleted
                                ? colors.colorGrammar.withValues(alpha: 0.5)
                                : colors.borderColorLight,
                          ),
                        ),
                        child: Text(
                          '$completedCount/$totalMissions',
                          style: TextStyle(
                            color: isAllCompleted ? colors.colorGrammar : colors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Interactive Achievements badge button opening AchievementsSheet (min 48x48 hit target)
                Semantics(
                  button: true,
                  label: context.t('achievements.title', null, 'Achievements'),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    child: Center(
                      child: InkWell(
                        onTap: () => AchievementsSheet.show(context),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: colors.bgSurface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: colors.borderColorLight),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.emoji_events_rounded,
                                size: 14,
                                color: colors.colorFire,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${gamification.achievements.value.where((a) => a.isUnlocked).length}/${gamification.achievements.value.length}',
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Missions List (Permanent height & zero layout shift)
            ...missions.map((m) => _buildMissionCard(context, colors, gamification, m)),

            const SizedBox(height: 4),

            // Permanent Daily Completion Chest Goalpost (Always docked at bottom - 0 layout shift)
            _buildDailyChestGoalpost(
              context: context,
              colors: colors,
              gamification: gamification,
              completedCount: completedCount,
              totalMissions: totalMissions,
              canClaimBonus: canClaimBonus,
              isBonusClaimed: isBonusClaimed,
              bonusXp: bonusXp,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMissionCard(
    BuildContext context,
    VocaColorPalette colors,
    GamificationService gamification,
    DailyMission m,
  ) {
    final isCompleted = m.isCompleted;
    final isClaimed = m.isClaimed;
    final fraction = m.progressRatio;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCompleted && !isClaimed
                ? colors.accentPrimary.withValues(alpha: 0.45)
                : colors.borderColorLight,
            width: isCompleted && !isClaimed ? 1.5 : 1.0,
          ),
          boxShadow: isCompleted && !isClaimed
              ? [
                  BoxShadow(
                    color: colors.accentPrimary.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Opacity(
          opacity: isClaimed ? 0.65 : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Icon + Title & Description + Action / Reward Slot
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon container with responsive state color
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? (isClaimed
                              ? colors.colorGrammar.withValues(alpha: 0.12)
                              : colors.accentPrimary.withValues(alpha: 0.12))
                          : colors.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCompleted
                            ? (isClaimed
                                ? colors.colorGrammar.withValues(alpha: 0.3)
                                : colors.accentPrimary.withValues(alpha: 0.3))
                            : colors.borderColorLight,
                      ),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check_circle_rounded : m.icon,
                      size: 18,
                      color: isCompleted
                          ? (isClaimed ? colors.colorGrammar : colors.accentPrimary)
                          : colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Center content: Title & Description (Full width without squeezing)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          m.localizedTitle(context),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Action Slot: XP Badge / Claim Button / Claimed Badge
                  _buildMissionActionSlot(
                    context: context,
                    colors: colors,
                    gamification: gamification,
                    mission: m,
                    isCompleted: isCompleted,
                    isClaimed: isClaimed,
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Bottom Row: Linear Progress Bar + Numeric Count
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 5,
                        color: colors.bgCard,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: fraction),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          builder: (context, animatedValue, _) {
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: animatedValue,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isCompleted ? colors.colorGrammar : colors.accentPrimary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${m.progress}/${m.target}',
                    style: TextStyle(
                      color: isCompleted ? colors.colorGrammar : colors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissionActionSlot({
    required BuildContext context,
    required VocaColorPalette colors,
    required GamificationService gamification,
    required DailyMission mission,
    required bool isCompleted,
    required bool isClaimed,
  }) {
    if (isClaimed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.borderColorLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 12, color: colors.colorGrammar),
            const SizedBox(width: 3),
            Text(
              context.t('missions.claimed', null, 'Claimed'),
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (isCompleted) {
      return FilledButton(
        onPressed: () {
          HapticService.medium();
          final ok = gamification.claimMission(mission.id);
          if (ok) {
            ToastService.success(
              context,
              context.t('missions.claimedReward', {'xp': mission.xpReward}, '+${mission.xpReward} XP earned! 🎉'),
            );
          }
        },
        style: FilledButton.styleFrom(
          backgroundColor: colors.accentPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.padded,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        child: Text(
          '${context.t('missions.claim', null, 'Claim')} +${mission.xpReward} XP',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      );
    }

    // In Progress State: Clean reward badge (+XX XP)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.borderColorLight),
      ),
      child: Text(
        '+${mission.xpReward} XP',
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Permanent Daily Completion Chest Goalpost (Docked at bottom of Daily Quests, 0-shift)
  Widget _buildDailyChestGoalpost({
    required BuildContext context,
    required VocaColorPalette colors,
    required GamificationService gamification,
    required int completedCount,
    required int totalMissions,
    required bool canClaimBonus,
    required bool isBonusClaimed,
    required int bonusXp,
  }) {
    final isReadyToOpen = canClaimBonus && !isBonusClaimed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isReadyToOpen
            ? colors.accentPrimary.withValues(alpha: 0.08)
            : colors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isReadyToOpen
              ? colors.accentPrimary.withValues(alpha: 0.5)
              : (isBonusClaimed
                  ? colors.colorGrammar.withValues(alpha: 0.3)
                  : colors.borderColorLight),
          width: isReadyToOpen ? 1.5 : 1.0,
        ),
        boxShadow: isReadyToOpen
            ? [
                BoxShadow(
                  color: colors.accentPrimary.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Chest Icon Badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isReadyToOpen
                  ? colors.accentPrimary.withValues(alpha: 0.18)
                  : (isBonusClaimed
                      ? colors.colorGrammar.withValues(alpha: 0.14)
                      : colors.bgCard),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isReadyToOpen
                    ? colors.accentPrimary.withValues(alpha: 0.4)
                    : (isBonusClaimed
                        ? colors.colorGrammar.withValues(alpha: 0.35)
                        : colors.borderColorLight),
              ),
            ),
            child: Icon(
              isBonusClaimed
                  ? Icons.check_circle_rounded
                  : (isReadyToOpen ? Icons.card_giftcard_rounded : Icons.inventory_2_outlined),
              color: isReadyToOpen
                  ? colors.accentPrimary
                  : (isBonusClaimed ? colors.colorGrammar : colors.textSecondary),
              size: 19,
            ),
          ),
          const SizedBox(width: 10),

          // Chest description & progress info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        context.t('missions.dailyChest', null, 'Daily Completion Chest'),
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
                      '+$bonusXp XP',
                      style: TextStyle(
                        color: isBonusClaimed ? colors.colorGrammar : colors.accentPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isBonusClaimed
                      ? context.t('missions.allDoneForToday', null, 'All daily quests finished! See you tomorrow. 🎉')
                      : (isReadyToOpen
                          ? context.t('missions.dailyChestReady', null, 'All 3 quests done! Tap to open your chest.')
                          : context.t('missions.dailyChestDesc', null, 'Complete all $totalMissions missions to unlock')),
                  style: TextStyle(
                    color: isReadyToOpen ? colors.accentPrimary : colors.textMuted,
                    fontSize: 11.5,
                    fontWeight: isReadyToOpen ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Action: Open Button, Claimed Badge, or 3-step Progress Dashes
          if (isReadyToOpen)
            FilledButton(
              onPressed: () {
                HapticService.heavy();
                final ok = gamification.claimDailyBonus();
                if (ok) {
                  HapticService.light();
                  ToastService.success(
                    context,
                    context.t('missions.dailyChestClaimed', null, 'Claimed +$bonusXp XP Daily Completion Chest! 🏆'),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.padded,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              child: Text(
                context.t('missions.claim', null, 'Open'),
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
              ),
            )
          else if (isBonusClaimed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: colors.colorGrammar.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 12, color: colors.colorGrammar),
                  const SizedBox(width: 3),
                  Text(
                    context.t('missions.claimed', null, 'Claimed'),
                    style: TextStyle(
                      color: colors.colorGrammar,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            // In Progress: Clear lock progress badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: colors.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 12, color: colors.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    '$completedCount/$totalMissions',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

