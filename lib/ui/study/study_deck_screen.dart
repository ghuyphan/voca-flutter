// lib/ui/study/study_deck_screen.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/srs_service.dart';
import '../../state/app_state.dart';
import 'study_session_controller.dart';
import 'widgets/anki_hud_header.dart';
import 'widgets/deck_overview.dart';
import 'widgets/deck_settings_sheet.dart';
import 'widgets/session_recap.dart';
import 'widgets/tinder_action_dock.dart';
import 'widgets/tinder_card_stack.dart';

/// Unified Study Screen featuring:
/// 1. Anki-inspired Deck Overview dashboard with tri-color stats & session controls.
/// 2. Active Tinder multi-card swiping session with fluid thumb pivot physics & floating circular action dock.
class StudyDeckScreen extends StatefulWidget {
  final VoidCallback? onNavigateToExplore;

  const StudyDeckScreen({
    super.key,
    this.onNavigateToExplore,
  });

  @override
  State<StudyDeckScreen> createState() => _StudyDeckScreenState();
}

class _StudyDeckScreenState extends State<StudyDeckScreen> {
  late final StudySessionController _controller;
  final TinderStackController _stackController = TinderStackController();
  VoidCallback? _langEffect;

  @override
  void initState() {
    super.initState();
    _controller = StudySessionController();

    // Auto-reload on active language switch
    _langEffect = effect(() {
      final _ = AppState.instance.activeLanguage.value;
      _controller.loadDeck(autoStart: false);
    });
  }

  @override
  void dispose() {
    _langEffect?.call();
    _controller.dispose();
    super.dispose();
  }

  void _openDeckSettings() {
    DeckSettingsSheet.show(context, _controller, () {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final isTablet = MediaQuery.of(context).size.width >= VocaTokens.tabletBreakpoint;
    final activeLang = AppState.instance.activeLanguage.value;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 560 : double.infinity),
            child: Watch((context) {
              // 1. Loading State
              if (_controller.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(color: colors.accentPrimary),
                );
              }

              // 2. Session Complete State (Celebration & Recap)
              if (_controller.isFinished) {
                return SessionRecap(
                  stats: _controller.sessionStats.value,
                  onFinish: () {
                    _controller.exitToOverview();
                  },
                  onReviewAgain: _controller.sessionStats.value.againOrHardCount > 0
                      ? () => _controller.restartFailedCards()
                      : null,
                );
              }

              // 3. Default View: Deck Overview Dashboard or Inactive/Empty Session
              final currentCard = _controller.currentCard;
              if (!_controller.isSessionActive.value || currentCard == null || _controller.sessionCards.value.isEmpty) {
                return DeckOverview(
                  controller: _controller,
                  onStartSession: () => _controller.startSession(),
                  onStartDueOnlySession: () => _controller.startSession(dueOnlyMode: true),
                  onExploreVideos: widget.onNavigateToExplore,
                );
              }

              final intervals = _calculateIntervals(currentCard);

              return Column(
                children: [
                  // Top Anki HUD Row with Exit to Overview Button
                  Padding(
                    padding: const EdgeInsets.only(left: 4, right: 8, top: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22),
                          color: colors.textSecondary,
                          tooltip: 'Exit to Overview',
                          onPressed: () => _controller.exitToOverview(),
                        ),
                        Expanded(
                          child: AnkiHudHeader(
                            activeLanguage: activeLang,
                            subDeck: _controller.subDeck.value,
                            newCount: _controller.newCount.value,
                            learningCount: _controller.learningCount.value,
                            dueCount: _controller.dueCount.value,
                            currentIndex: _controller.currentIndex.value,
                            totalInSession: _controller.sessionCards.value.length,
                            combo: _controller.currentCombo.value,
                            onOpenDeckSettings: _openDeckSettings,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Transient Feedback Pill (e.g. GOOD · KNOWN · 3d)
                  _buildTransientFeedbackPill(colors),

                  // Center Tinder Multi-Card Stack
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TinderCardStack(
                        controller: _stackController,
                        currentCard: currentCard,
                        nextCard: _controller.nextCard,
                        cardAfterNext: _controller.cardAfterNext,
                        isRevealed: _controller.isCardRevealed.value,
                        isReadingPeeked: _controller.isReadingPeeked.value,
                        againInterval: '<10m',
                        hardInterval: intervals.hard,
                        goodInterval: intervals.good,
                        easyInterval: intervals.easy,
                        onSwipe: (rating) => _controller.rateCurrentCard(rating),
                        onToggleFlip: () => _controller.toggleReveal(),
                        onTogglePeekReading: () => _controller.toggleReadingPeek(),
                        onMarkAsKnown: () => _controller.markCurrentCardAsKnown(),
                      ),
                    ),
                  ),

                  // Bottom Tinder Action Dock
                  TinderActionDock(
                    canUndo: _controller.canUndo,
                    isRevealed: _controller.isCardRevealed.value,
                    againInterval: '<10m',
                    hardInterval: intervals.hard,
                    goodInterval: intervals.good,
                    easyInterval: intervals.easy,
                    onUndo: () => _controller.undoLastRating(),
                    onAgain: () => _stackController.swipeLeft(),
                    onHard: () => _stackController.swipeDown(),
                    onFlip: () => _stackController.flipCard(),
                    onGood: () => _stackController.swipeRight(),
                    onEasy: () => _stackController.swipeUp(),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  ({String hard, String good, String easy}) _calculateIntervals(Flashcard card) {
    final resHard = SpacedRepetitionService.calculateNextReview(
      rating: SRSReviewRating.hard,
      currentRepetitions: card.srsRepetition,
      currentInterval: card.srsInterval,
      currentEaseFactor: card.srsEaseFactor,
      currentLevel: card.level,
    );
    final resGood = SpacedRepetitionService.calculateNextReview(
      rating: SRSReviewRating.good,
      currentRepetitions: card.srsRepetition,
      currentInterval: card.srsInterval,
      currentEaseFactor: card.srsEaseFactor,
      currentLevel: card.level,
    );
    final resEasy = SpacedRepetitionService.calculateNextReview(
      rating: SRSReviewRating.easy,
      currentRepetitions: card.srsRepetition,
      currentInterval: card.srsInterval,
      currentEaseFactor: card.srsEaseFactor,
      currentLevel: card.level,
    );

    return (
      hard: SpacedRepetitionService.formatInterval(resHard.interval),
      good: SpacedRepetitionService.formatInterval(resGood.interval),
      easy: SpacedRepetitionService.formatInterval(resEasy.interval),
    );
  }

  Widget _buildTransientFeedbackPill(VocaColorPalette colors) {
    final feedback = _controller.lastRatingFeedback.value;
    final color = feedback != null
        ? switch (feedback.rating) {
            SRSReviewRating.again => colors.error,
            SRSReviewRating.hard => colors.warning,
            SRSReviewRating.good => colors.colorGrammar,
            SRSReviewRating.easy => colors.accentSecondary,
          }
        : null;

    return SizedBox(
      height: 22,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: feedback != null && color != null
              ? Container(
                  key: ValueKey('${feedback.rating.name}_${feedback.interval}'),
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
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
