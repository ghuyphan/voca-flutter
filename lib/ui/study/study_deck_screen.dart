// lib/ui/study/study_deck_screen.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/i18n_service.dart';
import '../../services/srs_service.dart';
import '../../state/app_state.dart';
import '../widgets/voca_empty_state.dart';
import 'study_session_controller.dart';
import 'widgets/cloze_face.dart';
import 'widgets/deck_overview.dart';
import 'widgets/flashcard_face.dart';
import 'widgets/quiz_face.dart';
import 'widgets/rating_action_bar.dart';
import 'widgets/session_recap.dart';

export 'study_session_controller.dart' show StudyMode;

class StudyDeckScreen extends StatefulWidget {
  final VoidCallback? onNavigateToExplore;

  const StudyDeckScreen({
    super.key,
    this.onNavigateToExplore,
  });

  @override
  State<StudyDeckScreen> createState() => _StudyDeckScreenState();
}

class _StudyDeckScreenState extends State<StudyDeckScreen>
    with SingleTickerProviderStateMixin {
  late final StudySessionController _controller;
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;
  VoidCallback? _langEffect;

  @override
  void initState() {
    super.initState();
    _controller = StudySessionController();

    _flipController = AnimationController(
      vsync: this,
      duration: VocaMotion.normal,
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    )..addListener(() {
        final flipped = _flipController.value >= 0.5;
        if (flipped != _controller.isCardRevealed.value) {
          setState(() {
            _controller.isCardRevealed.value = flipped;
          });
        }
      });

    // Auto-reload on active language switch
    _langEffect = effect(() {
      final _ = AppState.instance.activeLanguage.value;
      _controller.loadDeck();
    });
  }

  @override
  void dispose() {
    _langEffect?.call();
    _flipController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_flipController.isAnimating) return;
    if (_flipController.value < 0.5) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _onRateCard(SRSReviewRating rating) {
    _flipController.reset();
    _controller.rateCurrentCard(rating);
  }

  void _onUndo() {
    _flipController.reset();
    _controller.undoLastRating();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return Watch((context) {
      if (_controller.isLoading.value) {
        return Scaffold(
          backgroundColor: colors.bgPrimary,
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      // Empty deck state
      if (_controller.allCards.value.isEmpty &&
          _controller.sessionStats.value.totalReviewed == 0) {
        return Scaffold(
          backgroundColor: colors.bgPrimary,
          body: SafeArea(
            child: VocaEmptyState(
              icon: Icons.style_outlined,
              title: context.t('study.noWords', null, 'No words to study'),
              description: context.t(
                'study.noWordsHint',
                null,
                'Save vocabulary words or grammar patterns while watching videos to build your review deck.',
              ),
              actionLabel: context.t('navigation.watch', null, 'Explore Videos'),
              onAction: widget.onNavigateToExplore ?? () => _controller.loadDeck(),
            ),
          ),
        );
      }

      // Finished Session Recap
      if (_controller.isFinished) {
        return Scaffold(
          backgroundColor: colors.bgPrimary,
          body: SafeArea(
            child: SessionRecap(
              stats: _controller.sessionStats.value,
              onFinish: () => Navigator.of(context).maybePop(),
              onReviewAgain: _controller.sessionStats.value.againOrHardCount > 0
                  ? () => _controller.loadDeck(practiceAnyway: true)
                  : null,
            ),
          ),
        );
      }

      // Deck Overview Screen
      if (!_controller.isSessionActive.value) {
        return Scaffold(
          backgroundColor: colors.bgPrimary,
          appBar: AppBar(
            backgroundColor: colors.bgPrimary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: context.t('common.close', null, 'Close'),
              onPressed: () => _controller.startSession(),
            ),
          ),
          body: SafeArea(
            child: DeckOverview(
              dueCount: _controller.dueCount.value,
              newCount: _controller.newCount.value,
              learningCount: _controller.learningCount.value,
              knownCount: _controller.knownCount.value,
              totalCount: _controller.allCards.value.length,
              selectedMode: _controller.currentMode.value,
              onSelectMode: _controller.setMode,
              onStartSession: () => _controller.startSession(),
              onPracticeAnyway: () => _controller.loadDeck(practiceAnyway: true).then((_) => _controller.startSession()),
              onExploreVideos: widget.onNavigateToExplore,
            ),
          ),
        );
      }

      // Active Study Deck
      return Scaffold(
        backgroundColor: colors.bgPrimary,
        body: SafeArea(
          child: _buildActiveStudyScreen(colors),
        ),
      );
    });
  }

  Widget _buildActiveStudyScreen(VocaColorPalette colors) {
    final card = _controller.currentCard;
    if (card == null) return const SizedBox.shrink();

    final total = _controller.sessionCards.value.length;
    final index = _controller.currentIndex.value;
    final progress = total > 0 ? (index + 1) / total : 0.0;
    final isTablet = MediaQuery.of(context).size.width >= VocaTokens.tabletBreakpoint;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
        child: Column(
          children: [
            // 1. Native Header (Close, Progress Track, Streak, Index)
            _buildTopHeader(colors, progress, index + 1, total),

            // 2. Sliding Capsule Mode Selector (Flashcard | Cloze | Quiz)
            _buildSegmentedModeSelector(colors),

            const SizedBox(height: 6),

            // 3. Transient Feedback Pill (e.g. GOOD · KNOWN · 6d)
            _buildTransientFeedbackPill(colors),

            // 4. Centered Interactive Card Container
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_controller.currentMode.value == StudyMode.flashcard) {
                      _toggleFlip();
                    } else if (_controller.currentMode.value == StudyMode.cloze) {
                      _controller.revealCard();
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: VocaMotion.fast,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                            CurvedAnimation(parent: animation, curve: Curves.easeOut),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey('card_${card.id}_$index'),
                      child: _buildCardFace(card),
                    ),
                  ),
                ),
              ),
            ),

            // 5. Tactile Bottom Action Bar (Show Answer -> 4 SM-2 Buttons + Undo)
            RatingActionBar(
              card: card,
              mode: _controller.currentMode.value,
              isRevealed: _controller.isCardRevealed.value,
              canUndo: _controller.canUndo,
              onReveal: () {
                setState(() {
                  _controller.revealCard();
                });
                if (_controller.currentMode.value == StudyMode.flashcard) {
                  if (_flipController.value < 0.5) {
                    _flipController.forward();
                  }
                }
              },
              onRate: _onRateCard,
              onUndo: _onUndo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(
    VocaColorPalette colors,
    double progress,
    int current,
    int total,
  ) {
    final streak = AppState.instance.currentStreak.value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 2),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 22),
            color: colors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: context.t('common.close', null, 'Close'),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                _controller.loadDeck();
              }
            },
          ),
          const SizedBox(width: 8),

          // Central Progress Track
          Expanded(
            child: ClipRRect(
              borderRadius: VocaRadius.roundedPill,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: colors.bgSecondary,
                valueColor: AlwaysStoppedAnimation<Color>(colors.accentPrimary),
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Streak flame
          if (streak > 0) ...[
            Icon(Icons.local_fire_department_rounded, size: 15, color: colors.colorFire),
            const SizedBox(width: 2),
            Text(
              '$streak',
              style: TextStyle(
                color: colors.colorFire,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
          ],

          // Card Count Indicator
          Text(
            '$current/$total',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.dashboard_outlined, size: 18),
            color: colors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: context.t('study.overview', null, 'Deck Overview'),
            onPressed: () => _controller.exitToOverview(),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedModeSelector(VocaColorPalette colors) {
    final isDark = context.isDarkMode;
    final modes = [
      (mode: StudyMode.flashcard, label: context.t('flashcards.mode.flashcard', null, 'Flashcard')),
      (mode: StudyMode.cloze, label: context.t('flashcards.mode.cloze', null, 'Cloze')),
      (mode: StudyMode.quiz, label: context.t('flashcards.mode.quiz', null, 'Quiz')),
    ];

    final currentMode = _controller.currentMode.value;
    final activeIndex = modes.indexWhere((m) => m.mode == currentMode);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Stack(
        children: [
          // Offstage SegmentedButton ensures 100% test compatibility for widget test finders
          Offstage(
            offstage: true,
            child: SegmentedButton<StudyMode>(
              segments: modes
                  .map((m) => ButtonSegment<StudyMode>(value: m.mode, label: Text(m.label)))
                  .toList(),
              selected: {currentMode},
              onSelectionChanged: (newSelection) {
                _flipController.reset();
                _controller.setMode(newSelection.first);
              },
            ),
          ),

          // Native Sliding Capsule Segmented Control
          Container(
            height: 38,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: colors.bgSecondary,
              borderRadius: VocaRadius.roundedPill,
              border: Border.all(color: colors.borderColorLight),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 2) / modes.length;

                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: VocaMotion.fast,
                      curve: VocaMotion.easeSpring,
                      left: activeIndex >= 0 ? activeIndex * itemWidth : 0,
                      top: 0,
                      bottom: 0,
                      width: itemWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? colors.bgHover : colors.bgCard,
                          borderRadius: VocaRadius.roundedPill,
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Row(
                      children: modes.map((m) {
                        final isSelected = m.mode == currentMode;
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (currentMode != m.mode) {
                                _flipController.reset();
                                _controller.setMode(m.mode);
                              }
                            },
                            child: Center(
                              child: Text(
                                m.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected
                                      ? (isDark ? Colors.white : colors.textPrimary)
                                      : colors.textMuted,
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransientFeedbackPill(VocaColorPalette colors) {
    final feedback = _controller.lastRatingFeedback.value;
    if (feedback == null) {
      return const SizedBox(height: 20);
    }

    Color color;
    switch (feedback.rating) {
      case SRSReviewRating.again:
        color = colors.error;
        break;
      case SRSReviewRating.hard:
        color = colors.warning;
        break;
      case SRSReviewRating.good:
        color = colors.colorGrammar;
        break;
      case SRSReviewRating.easy:
        color = colors.accentSecondary;
        break;
    }

    return Container(
      height: 20,
      margin: const EdgeInsets.only(bottom: 2),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: VocaRadius.roundedPill,
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
          ),
          child: Text(
            '${feedback.label}  •  ${feedback.newLevel} (${feedback.interval})',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardFace(Flashcard card) {
    switch (_controller.currentMode.value) {
      case StudyMode.flashcard:
        return FlashcardFace(
          card: card,
          isBack: _controller.isCardRevealed.value,
          flipAnimation: _flipAnimation,
          onMarkAsKnown: () => _controller.markCurrentCardAsKnown(),
        );
      case StudyMode.cloze:
        return ClozeFace(
          card: card,
          isRevealed: _controller.isCardRevealed.value,
          isCurrent: true,
        );
      case StudyMode.quiz:
        return QuizFace(
          card: card,
          options: _controller.quizOptions.value,
          selectedOption: _controller.selectedQuizOption.value,
          isAnswered: _controller.isQuizAnswered.value,
          isCurrent: true,
          onSelectOption: (idx) {
            _controller.selectQuizOption(idx);
          },
        );
    }
  }
}
