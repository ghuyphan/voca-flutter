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
              if (_controller.isSessionActive.value && _controller.isFinished) {
                return SessionRecap(
                  stats: _controller.sessionStats.value,
                  onDone: () => _controller.exitToOverview(),
                  onFinish: () => _controller.exitToOverview(),
                  onClose: () => _controller.exitToOverview(),
                  onKeepGoing: () => _controller.startNextBatch(),
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
                  onStartSession: () => _controller.startSession(
                    practiceAnyway: _controller.sessionCardsCount == 0,
                  ),
                  onStartDueOnlySession: () => _controller.startSession(dueOnlyMode: true),
                  onExploreVideos: widget.onNavigateToExplore,
                );
              }

              final intervals = _calculateIntervals(currentCard);

              return Column(
                children: [
                  // Top Anki HUD with integrated Exit and Undo Buttons
                  AnkiHudHeader(
                    activeLanguage: activeLang,
                    subDeck: _controller.subDeck.value,
                    newCount: _controller.newCount.value,
                    learningCount: _controller.learningCount.value,
                    dueCount: _controller.dueCount.value,
                    currentIndex: _controller.currentIndex.value,
                    totalInSession: _controller.initialQueueSize.value > 0
                        ? _controller.initialQueueSize.value
                        : _controller.sessionCards.value.length,
                    combo: _controller.currentCombo.value,
                    onOpenDeckSettings: _openDeckSettings,
                    onExit: () => _controller.exitToOverview(),
                    onUndo: _controller.canUndo ? () => _controller.undoLastRating() : null,
                  ),

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
                        againInterval: '<1 min',
                        hardInterval: intervals.hard,
                        goodInterval: intervals.good,
                        easyInterval: intervals.easy,
                        onSwipe: (rating) => _controller.rateCurrentCard(rating),
                        onToggleFlip: () => _controller.toggleReveal(),
                        onTogglePeekReading: () => _controller.toggleReadingPeek(),
                      ),
                    ),
                  ),

                  // Bottom 4-Button SRS Action Dock matching screenshot
                  TinderActionDock(
                    againInterval: '<1 min',
                    hardInterval: intervals.hard,
                    goodInterval: intervals.good,
                    easyInterval: intervals.easy,
                    onAgain: () => _stackController.swipeLeft(),
                    onHard: () => _stackController.swipeDown(),
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
}
