// lib/ui/study/study_deck_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/audio_service.dart';
import '../../services/srs_service.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';

enum StudyMode {
  flashcard('Flashcard', Icons.style_outlined, Icons.style),
  cloze('Cloze', Icons.text_snippet_outlined, Icons.text_snippet),
  quiz('Quiz', Icons.quiz_outlined, Icons.quiz);

  final String label;
  final IconData icon;
  final IconData activeIcon;
  const StudyMode(this.label, this.icon, this.activeIcon);
}

class StudyDeckScreen extends StatefulWidget {
  const StudyDeckScreen({super.key});

  @override
  State<StudyDeckScreen> createState() => _StudyDeckScreenState();
}

class _StudyDeckScreenState extends State<StudyDeckScreen>
    with SingleTickerProviderStateMixin {
  List<Flashcard> _dueCards = [];
  List<Flashcard> _allCards = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  StudyMode _currentMode = StudyMode.flashcard;

  // 3D Flip Animation
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isCardFlipped = false;

  // Cloze Mode state
  bool _isClozeRevealed = false;

  // Quiz Mode state
  List<String> _quizOptions = [];
  int? _selectedQuizOption;
  bool _isQuizAnswered = false;

  // Session Stats
  int _totalReviewed = 0;
  int _goodOrEasyCount = 0;
  int _againOrHardCount = 0;
  bool _rewardClaimed = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    )..addListener(() {
        final flipped = _flipController.value >= 0.5;
        if (flipped != _isCardFlipped) {
          setState(() => _isCardFlipped = flipped);
        }
      });

    _loadDueCards();
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _loadDueCards() async {
    setState(() => _isLoading = true);
    final supabase = AppState.instance.supabaseService;
    final lang = AppState.instance.activeLanguage.value;

    try {
      final allCards = await supabase.getVocabularyCards(language: lang);
      final now = DateTime.now();
      final due = allCards
          .where((c) =>
              c.srsNextReviewAt.isBefore(now) ||
              c.srsNextReviewAt.isAtSameMomentAs(now))
          .toList();

      if (mounted) {
        setState(() {
          _allCards = allCards;
          _dueCards = due.isNotEmpty ? due : allCards.take(10).toList();
          _isLoading = false;
          _currentIndex = 0;
          _totalReviewed = 0;
          _goodOrEasyCount = 0;
          _againOrHardCount = 0;
          _rewardClaimed = false;
          _resetCardState();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetCardState() {
    _flipController.reset();
    _isCardFlipped = false;
    _isClozeRevealed = false;
    _selectedQuizOption = null;
    _isQuizAnswered = false;
    _generateQuizOptions();
  }

  void _toggleFlip() {
    if (_flipController.isAnimating) return;
    if (_flipController.value < 0.5) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _generateQuizOptions() {
    if (_dueCards.isEmpty || _currentIndex >= _dueCards.length) {
      _quizOptions = [];
      return;
    }

    final current = _dueCards[_currentIndex];
    final correctMeaning = current.meaning;

    // Plausible distractors pool
    final candidatePool = <String>{};
    for (final card in _allCards) {
      if (card.meaning != correctMeaning && card.meaning.trim().isNotEmpty) {
        candidatePool.add(card.meaning);
      }
    }

    final fallbackDistractors = [
      'to look closely, observe carefully',
      'to explain clearly to someone',
      'an important occasion or promise',
      'deep emotion, happiness, joy',
      'to prepare in advance for tomorrow',
      'calm and quiet atmosphere',
      'a memorable journey or excursion',
      'a difficult challenge or hardship',
    ];

    for (final fb in fallbackDistractors) {
      if (fb != correctMeaning) candidatePool.add(fb);
    }

    final distractors = candidatePool.toList()..shuffle();
    final options = <String>[correctMeaning, ...distractors.take(3)];
    options.shuffle();

    _quizOptions = options;
  }

  Future<void> _rateCard(SRSReviewRating rating) async {
    if (_dueCards.isEmpty || _currentIndex >= _dueCards.length) return;

    final currentCard = _dueCards[_currentIndex];
    final result = SpacedRepetitionService.calculateNextReview(
      rating: rating,
      currentRepetitions: currentCard.srsRepetition,
      currentInterval: currentCard.srsInterval,
      currentEaseFactor: currentCard.srsEaseFactor,
    );

    final updatedCard = currentCard.copyWith(
      level: result.level,
      srsInterval: result.interval,
      srsRepetition: result.repetition,
      srsEaseFactor: result.easeFactor,
      srsNextReviewAt: result.nextReviewAt,
      srsLastReviewedAt: DateTime.now(),
    );

    // Save update to Supabase / local
    await AppState.instance.supabaseService.upsertVocabularyCard(updatedCard);

    _totalReviewed++;
    if (rating == SRSReviewRating.good || rating == SRSReviewRating.easy) {
      _goodOrEasyCount++;
    } else {
      _againOrHardCount++;
    }

    if (mounted) {
      setState(() {
        _currentIndex += 1;
        _resetCardState();
      });

      // If finished session, record streak & diamond rewards
      if (_currentIndex >= _dueCards.length && !_rewardClaimed) {
        _claimSessionRewards();
      }
    }
  }

  Future<void> _claimSessionRewards() async {
    _rewardClaimed = true;
    try {
      // 1. Record streak activity
      await AppState.instance.supabaseService.recordStreakActivity(DateTime.now());
      AppState.instance.currentStreak.value += 1;

      // 2. Add diamond credit
      final currentDiamonds = AppState.instance.diamonds.value;
      final maxD = AppState.instance.maxDiamonds.value;
      if (currentDiamonds < maxD) {
        AppState.instance.diamonds.value = currentDiamonds + 1;
      }
    } catch (_) {}
  }

  String _formatInterval(int days) {
    if (days == 0) return '<10m';
    if (days >= 30) return '${(days / 30).round()}mo';
    return '${days}d';
  }

  ({Color bg, Color text}) _getMasteryColors(String level) {
    final colors = context.vocaColors;
    switch (level.toLowerCase()) {
      case 'mastered':
        return (bg: colors.wordMasteredBg, text: colors.wordMasteredText);
      case 'known':
        return (bg: colors.wordKnownBg, text: colors.wordKnownText);
      case 'learning':
        return (bg: colors.wordLearningBg, text: colors.wordLearningText);
      case 'new':
      default:
        return (bg: colors.wordNewBg, text: colors.wordNewText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.bgPrimary,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isFinished = _dueCards.isEmpty || _currentIndex >= _dueCards.length;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.style, color: colors.accentPrimary, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                context.t('flashcards.studyDeck', null, 'SRS Study Deck'),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colors.textSecondary),
            tooltip: context.t('flashcards.reloadCards', null, 'Reload cards'),
            onPressed: _loadDueCards,
          ),
        ],
      ),
      body: SafeArea(
        child: isFinished ? _buildCelebrationScreen() : _buildActiveStudyScreen(),
      ),
    );
  }

  // -------------------------------------------------------------
  // ACTIVE STUDY SCREEN (RESPONSIVE TABLET & MOBILE)
  // -------------------------------------------------------------
  Widget _buildActiveStudyScreen() {
    final colors = context.vocaColors;
    final card = _dueCards[_currentIndex];
    final progress = (_currentIndex + 1) / _dueCards.length;
    final mastery = _getMasteryColors(card.level);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= VocaTokens.tabletBreakpoint;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
        child: Column(
          children: [
            // Mode Selector Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: StudyMode.values.map((mode) {
                  final isSelected = _currentMode == mode;
                  final modeText = context.t('flashcards.mode.${mode.name}', null, mode.label);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () {
                          if (_currentMode != mode) {
                            setState(() {
                              _currentMode = mode;
                              _resetCardState();
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? colors.accentPrimary : colors.bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? colors.accentPrimaryHover : colors.borderColor,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected ? mode.activeIcon : mode.icon,
                                size: 15,
                                color: isSelected ? Colors.white : colors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  modeText,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : colors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Progress bar & counter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${context.t('flashcards.card', null, 'Card')} ${_currentIndex + 1} ${context.t('flashcards.of', null, 'of')} ${_dueCards.length}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: mastery.bg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: mastery.text.withOpacity(0.35),
                          ),
                        ),
                        child: Text(
                          card.level.toUpperCase(),
                          style: TextStyle(
                            color: mastery.text,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: colors.bgSecondary,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.accentPrimary),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),

            // Active Study Mode Content (Flashcard, Cloze, Quiz)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildModeBody(card),
              ),
            ),

            // Bottom Rating Controls
            _buildBottomRatingBar(card),
          ],
        ),
      ),
    );
  }

  Widget _buildModeBody(Flashcard card) {
    switch (_currentMode) {
      case StudyMode.flashcard:
        return _build3DFlashcard(card);
      case StudyMode.cloze:
        return _buildClozeCard(card);
      case StudyMode.quiz:
        return _buildQuizCard(card);
    }
  }

  // -------------------------------------------------------------
  // 1. 3D FLASHCARD MODE (styled after study-mode.component.scss)
  // -------------------------------------------------------------
  Widget _build3DFlashcard(Flashcard card) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final angle = _flipAnimation.value * math.pi;
          final isBack = _flipAnimation.value >= 0.5;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isBack
                ? Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildCardBack(card),
                  )
                : _buildCardFront(card),
          );
        },
      ),
    );
  }

  Widget _buildCardFront(Flashcard card) {
    final colors = context.vocaColors;
    final reading = card.reading ?? card.pinyin ?? card.romanization;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderColor),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode ? Colors.black45 : Colors.black12,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Part of Speech tag
          if (card.partOfSpeech != null && card.partOfSpeech!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.borderColorLight),
              ),
              child: Text(
                card.partOfSpeech!.toUpperCase(),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),

          // Reading / Furigana
          if (reading != null && reading.isNotEmpty) ...[
            Text(
              reading,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Target Word
          Text(
            card.word,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),

          if (card.romanization != null && card.reading != null) ...[
            const SizedBox(height: 4),
            Text(
              card.romanization!,
              style: TextStyle(color: colors.textTertiary, fontSize: 13),
            ),
          ],

          const SizedBox(height: 18),

          // Audio Button with Radiant Coral speaker icon
          ValueListenableBuilder<String?>(
            valueListenable: AudioService.instance.currentPlaying,
            builder: (context, playing, _) {
              final isPlaying = playing == card.word;
              return ElevatedButton.icon(
                onPressed: () {
                  AudioService.instance.playWord(
                    card.word,
                    language: card.language,
                    fallbackAudioUrl: card.audio,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPlaying ? colors.accentPrimary : colors.bgSurface,
                  foregroundColor: isPlaying ? Colors.white : colors.accentPrimary,
                  side: BorderSide(color: colors.borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: Icon(
                  isPlaying ? Icons.volume_up : Icons.volume_up_outlined,
                  size: 18,
                  color: isPlaying ? Colors.white : colors.accentPrimary,
                ),
                label: Text(
                  isPlaying
                      ? context.t('audio.playing', null, 'Playing...')
                      : context.t('audio.pronounce', null, 'Pronounce'),
                  style: TextStyle(
                    color: isPlaying ? Colors.white : colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          // Hint to tap
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_outlined, size: 14, color: colors.textMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  context.t('flashcards.tapHint', null, 'Tap card to reveal meaning'),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(Flashcard card) {
    final colors = context.vocaColors;
    final reading = card.reading ?? card.pinyin ?? card.romanization;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.accentPrimary.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode ? Colors.black45 : Colors.black12,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Word header small
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    card.word,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (reading != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '($reading)',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.textSecondary, fontSize: 15),
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(Icons.volume_up, size: 20, color: colors.accentPrimary),
                  onPressed: () {
                    AudioService.instance.playWord(
                      card.word,
                      language: card.language,
                      fallbackAudioUrl: card.audio,
                    );
                  },
                ),
              ],
            ),

            Divider(color: colors.borderColorLight, height: 24),

            // Definition / Meaning
            Text(
              context.t('flashcards.meaning', null, 'MEANING'),
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              card.meaning,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),

            // Context Sentence if available
            if (card.contextSentence != null && card.contextSentence!.isNotEmpty) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.borderColorLight),
                ),
                child: Column(
                  children: [
                    Text(
                      card.contextSentence!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    if (card.contextTranslation != null &&
                        card.contextTranslation!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        card.contextTranslation!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Text(
              context.t('flashcards.tapBackHint', null, 'Tap card to flip back'),
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. CLOZE / CONTEXT SENTENCE MODE
  // -------------------------------------------------------------
  Widget _buildClozeCard(Flashcard card) {
    final colors = context.vocaColors;
    // Generate context sentence with masked target word
    final rawSentence = card.contextSentence ??
        '日常会話でよく使われる [ ___ ] という言葉です。';
    final hasContext = card.contextSentence != null && card.contextSentence!.isNotEmpty;

    final maskedSentence = rawSentence.replaceAll(card.word, '[ _____ ]');
    final reading = card.reading ?? card.pinyin ?? card.romanization;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderColor),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode ? Colors.black45 : Colors.black12,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Header info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accentPrimarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.t('practice.clozeTest', null, 'CLOZE TEST').toUpperCase(),
                  style: TextStyle(
                    color: colors.accentPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (card.partOfSpeech != null)
                Flexible(
                  child: Text(
                    card.partOfSpeech!.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Sentence Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.bgSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isClozeRevealed ? colors.colorGrammar.withOpacity(0.4) : colors.borderColor,
              ),
            ),
            child: Column(
              children: [
                if (!_isClozeRevealed)
                  Text(
                    maskedSentence,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else ...[
                  // Revealed authentic sentence with highlighted word
                  RichText(
                    textAlign: TextAlign.center,
                    text: _buildHighlightedSentence(rawSentence, card.word),
                  ),
                  if (card.contextTranslation != null && card.contextTranslation!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      card.contextTranslation!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Reading / Hint
          if (!_isClozeRevealed) ...[
            if (reading != null) ...[
              Text(
                'Reading Hint: $reading',
                style: TextStyle(color: colors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 14),
            ],

            ElevatedButton.icon(
              onPressed: () => setState(() => _isClozeRevealed = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.visibility, size: 18),
              label: Text(
                context.t('flashcards.revealContext', null, 'Reveal Word & Context'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ] else ...[
            // Meaning box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colors.wordMasteredBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.wordMasteredText.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    card.word,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.meaning,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Audio button with Coral accent
            IconButton.filled(
              onPressed: () {
                AudioService.instance.playWord(
                  hasContext ? card.contextSentence! : card.word,
                  language: card.language,
                );
              },
              style: IconButton.styleFrom(
                backgroundColor: colors.bgSurface,
                foregroundColor: colors.accentPrimary,
                side: BorderSide(color: colors.borderColor),
              ),
              icon: const Icon(Icons.volume_up, size: 20),
              tooltip: context.t('audio.listenContext', null, 'Listen to context'),
            ),
          ],
        ],
      ),
    );
  }

  TextSpan _buildHighlightedSentence(String sentence, String targetWord) {
    final colors = context.vocaColors;
    final parts = sentence.split(targetWord);
    final spans = <TextSpan>[];

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(
          text: parts[i],
          style: TextStyle(color: colors.textPrimary, fontSize: 17, height: 1.4),
        ));
      }
      if (i < parts.length - 1) {
        spans.add(TextSpan(
          text: targetWord,
          style: TextStyle(
            color: colors.accentPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            decoration: TextDecoration.underline,
          ),
        ));
      }
    }

    return TextSpan(children: spans);
  }

  // -------------------------------------------------------------
  // 3. MULTIPLE-CHOICE QUIZ MODE
  // -------------------------------------------------------------
  Widget _buildQuizCard(Flashcard card) {
    final colors = context.vocaColors;
    final reading = card.reading ?? card.pinyin ?? card.romanization;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderColor),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode ? Colors.black45 : Colors.black12,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Target Word & Audio
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Column(
                  children: [
                    if (reading != null && reading.isNotEmpty)
                      Text(
                        reading,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.textMuted, fontSize: 14),
                      ),
                    Text(
                      card.word,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.volume_up, color: colors.accentPrimary, size: 22),
                onPressed: () {
                  AudioService.instance.playWord(
                    card.word,
                    language: card.language,
                    fallbackAudioUrl: card.audio,
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 6),
          Text(
            context.t('flashcards.chooseDefinition', null, 'Choose the correct definition:'),
            style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          // 4 Quiz Options
          Expanded(
            child: ListView.separated(
              itemCount: _quizOptions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final option = _quizOptions[idx];
                final isSelected = _selectedQuizOption == idx;
                final isCorrect = option == card.meaning;

                Color optionBorder = colors.borderColor;
                Color optionBg = colors.bgSurface;
                Color textColor = colors.textSecondary;
                IconData? feedbackIcon;

                if (_isQuizAnswered) {
                  if (isCorrect) {
                    optionBorder = colors.colorGrammar;
                    optionBg = colors.colorGrammar.withOpacity(0.18);
                    textColor = colors.textPrimary;
                    feedbackIcon = Icons.check_circle;
                  } else if (isSelected) {
                    optionBorder = colors.error;
                    optionBg = colors.error.withOpacity(0.18);
                    textColor = colors.textPrimary;
                    feedbackIcon = Icons.cancel;
                  }
                }

                return InkWell(
                  onTap: _isQuizAnswered
                      ? null
                      : () {
                          setState(() {
                            _selectedQuizOption = idx;
                            _isQuizAnswered = true;
                          });
                        },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: optionBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: optionBorder, width: isSelected || isCorrect ? 1.5 : 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.bgHover,
                          ),
                          child: Text(
                            String.fromCharCode(65 + idx),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: isSelected || isCorrect ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (feedbackIcon != null)
                          Icon(
                            feedbackIcon,
                            size: 18,
                            color: isCorrect ? colors.colorGrammar : colors.error,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // BOTTOM SM-2 RATING BAR WITH INTERVAL PREVIEWS & VOCA ACCENTS
  // -------------------------------------------------------------
  Widget _buildBottomRatingBar(Flashcard card) {
    final colors = context.vocaColors;
    // Only show rating buttons when answer has been revealed
    final showRatings = (_currentMode == StudyMode.flashcard && _isCardFlipped) ||
        (_currentMode == StudyMode.cloze && _isClozeRevealed) ||
        (_currentMode == StudyMode.quiz && _isQuizAnswered);

    if (!showRatings) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              if (_currentMode == StudyMode.flashcard) {
                _toggleFlip();
              } else if (_currentMode == StudyMode.cloze) {
                setState(() => _isClozeRevealed = true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accentPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              _currentMode == StudyMode.quiz
                  ? context.t('flashcards.selectAnswerAbove', null, 'Select an answer above')
                  : context.t('flashcards.showAnswer', null, 'Show Answer'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    // Calculated intervals for each rating button
    final resHard = SpacedRepetitionService.calculateNextReview(
      rating: SRSReviewRating.hard,
      currentRepetitions: card.srsRepetition,
      currentInterval: card.srsInterval,
      currentEaseFactor: card.srsEaseFactor,
    );
    final resGood = SpacedRepetitionService.calculateNextReview(
      rating: SRSReviewRating.good,
      currentRepetitions: card.srsRepetition,
      currentInterval: card.srsInterval,
      currentEaseFactor: card.srsEaseFactor,
    );
    final resEasy = SpacedRepetitionService.calculateNextReview(
      rating: SRSReviewRating.easy,
      currentRepetitions: card.srsRepetition,
      currentInterval: card.srsInterval,
      currentEaseFactor: card.srsEaseFactor,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          _buildSM2Button(
            context.t('flashcards.again', null, 'Again'),
            '<10m',
            colors.error,
            SRSReviewRating.again,
          ),
          const SizedBox(width: 6),
          _buildSM2Button(
            context.t('flashcards.hard', null, 'Hard'),
            _formatInterval(resHard.interval),
            colors.warning,
            SRSReviewRating.hard,
          ),
          const SizedBox(width: 6),
          _buildSM2Button(
            context.t('flashcards.good', null, 'Good'),
            _formatInterval(resGood.interval),
            colors.colorGrammar,
            SRSReviewRating.good,
          ),
          const SizedBox(width: 6),
          _buildSM2Button(
            context.t('flashcards.easy', null, 'Easy'),
            _formatInterval(resEasy.interval),
            colors.accentPrimary,
            SRSReviewRating.easy,
          ),
        ],
      ),
    );
  }

  Widget _buildSM2Button(
    String label,
    String intervalBadge,
    Color color,
    SRSReviewRating rating,
  ) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => _rateCard(rating),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.12),
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.6), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          elevation: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                intervalBadge,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STUDY SESSION COMPLETION CELEBRATION (RESPONSIVE TABLET & MOBILE)
  // -------------------------------------------------------------
  Widget _buildCelebrationScreen() {
    final colors = context.vocaColors;
    final streak = AppState.instance.currentStreak.value;
    final accuracy = _totalReviewed > 0
        ? ((_goodOrEasyCount / _totalReviewed) * 100).round()
        : 100;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= VocaTokens.tabletBreakpoint;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Trophy Badge
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.colorGrammar.withOpacity(0.15),
                  border: Border.all(color: colors.colorGrammar, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: colors.colorGrammar.withOpacity(0.3),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.emoji_events,
                  size: 56,
                  color: colors.accentTertiary,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                context.t('flashcards.sessionComplete', null, 'Session Complete!'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.t('flashcards.sessionCompleteDesc', null, 'You finished all spaced repetition reviews for this deck.'),
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 14),
              ),

              const SizedBox(height: 24),

              // Streak & Diamond Rewards Row
              Row(
                children: [
                  // Streak Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.colorFire.withOpacity(0.4)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.local_fire_department, color: colors.colorFire, size: 30),
                          const SizedBox(height: 6),
                          Text(
                            '$streak ${context.t('gamification.dayStreak', null, 'Day Streak')}',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.t('flashcards.keepItUp', null, 'Keep it up!'),
                            style: TextStyle(color: colors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Diamond Reward Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.colorDiamond.withOpacity(0.4)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.diamond, color: colors.colorDiamond, size: 30),
                          const SizedBox(height: 6),
                          Text(
                            '+1 ${context.t('gamification.diamond', null, 'Diamond')}',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.t('flashcards.dailyBonus', null, 'Daily study bonus'),
                            style: TextStyle(color: colors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Session Recap Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('flashcards.sessionRecap', null, 'SESSION RECAP'),
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildRecapItem(context.t('flashcards.recapReviewed', null, 'Reviewed'), '$_totalReviewed', colors.wordKnownText, colors),
                        _buildRecapItem(context.t('flashcards.recapGoodEasy', null, 'Good / Easy'), '$_goodOrEasyCount', colors.colorGrammar, colors),
                        _buildRecapItem(context.t('flashcards.recapAgainHard', null, 'Again / Hard'), '$_againOrHardCount', colors.warning, colors),
                        _buildRecapItem(context.t('flashcards.recapAccuracy', null, 'Accuracy'), '$accuracy%', colors.accentSecondary, colors),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons: "Review More" or "Back to Home"
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          _loadDueCards();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textSecondary,
                        side: BorderSide(color: colors.borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        context.t('flashcards.backToHome', null, 'Back to Home'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loadDueCards,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      child: Text(
                        context.t('flashcards.reviewMore', null, 'Review More'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecapItem(String label, String value, Color color, VocaColorPalette colors) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
