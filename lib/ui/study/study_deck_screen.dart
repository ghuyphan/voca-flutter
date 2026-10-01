// lib/ui/study/study_deck_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/audio_service.dart';
import '../../services/srs_service.dart';
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
    switch (level.toLowerCase()) {
      case 'mastered':
        return (bg: VocaTokens.wordMasteredBg, text: VocaTokens.wordMasteredText);
      case 'known':
        return (bg: VocaTokens.wordKnownBg, text: VocaTokens.wordKnownText);
      case 'learning':
        return (bg: VocaTokens.wordLearningBg, text: VocaTokens.wordLearningText);
      case 'new':
      default:
        return (bg: VocaTokens.wordNewBg, text: VocaTokens.wordNewText);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: VocaTokens.bgPrimary,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isFinished = _dueCards.isEmpty || _currentIndex >= _dueCards.length;

    return Scaffold(
      backgroundColor: VocaTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: VocaTokens.bgPrimary,
        elevation: 0,
        titleSpacing: 16,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.style, color: VocaTokens.accentPrimary, size: 20),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'SRS Study Deck',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: VocaTokens.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: VocaTokens.textSecondary),
            tooltip: 'Reload cards',
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
                            color: isSelected ? VocaTokens.accentPrimary : VocaTokens.bgCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? VocaTokens.accentPrimaryHover : VocaTokens.borderColor,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected ? mode.activeIcon : mode.icon,
                                size: 15,
                                color: isSelected ? Colors.white : VocaTokens.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  mode.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : VocaTokens.textSecondary,
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
                          'Card ${_currentIndex + 1} of ${_dueCards.length}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: VocaTokens.textSecondary,
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
                      backgroundColor: VocaTokens.bgSecondary,
                      valueColor: const AlwaysStoppedAnimation<Color>(VocaTokens.accentPrimary),
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
    final reading = card.reading ?? card.pinyin ?? card.romanization;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: VocaTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VocaTokens.borderColor),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 8)),
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
                color: VocaTokens.bgSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: VocaTokens.borderColorLight),
              ),
              child: Text(
                card.partOfSpeech!.toUpperCase(),
                style: const TextStyle(
                  color: VocaTokens.textSecondary,
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
              style: const TextStyle(
                color: VocaTokens.textMuted,
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
            style: const TextStyle(
              color: VocaTokens.textPrimary,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),

          if (card.romanization != null && card.reading != null) ...[
            const SizedBox(height: 4),
            Text(
              card.romanization!,
              style: const TextStyle(color: VocaTokens.textTertiary, fontSize: 13),
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
                  backgroundColor: isPlaying ? VocaTokens.accentPrimary : VocaTokens.bgSurface,
                  foregroundColor: isPlaying ? Colors.white : VocaTokens.accentPrimary,
                  side: const BorderSide(color: VocaTokens.borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: Icon(
                  isPlaying ? Icons.volume_up : Icons.volume_up_outlined,
                  size: 18,
                  color: isPlaying ? Colors.white : VocaTokens.accentPrimary,
                ),
                label: Text(
                  isPlaying ? 'Playing...' : 'Pronounce',
                  style: TextStyle(
                    color: isPlaying ? Colors.white : VocaTokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          // Hint to tap
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.touch_app_outlined, size: 14, color: VocaTokens.textMuted),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Tap card to reveal meaning',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: VocaTokens.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(Flashcard card) {
    final reading = card.reading ?? card.pinyin ?? card.romanization;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: VocaTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VocaTokens.accentPrimary.withOpacity(0.4)),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 8)),
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
                    style: const TextStyle(
                      color: VocaTokens.textPrimary,
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
                      style: const TextStyle(color: VocaTokens.textSecondary, fontSize: 15),
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.volume_up, size: 20, color: VocaTokens.accentPrimary),
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

            const Divider(color: VocaTokens.borderColorLight, height: 24),

            // Definition / Meaning
            const Text(
              'MEANING',
              style: TextStyle(
                color: VocaTokens.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              card.meaning,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: VocaTokens.textPrimary,
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
                  color: VocaTokens.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: VocaTokens.borderColorLight),
                ),
                child: Column(
                  children: [
                    Text(
                      card.contextSentence!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: VocaTokens.textPrimary,
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
                        style: const TextStyle(
                          color: VocaTokens.textSecondary,
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
            const Text(
              'Tap card to flip back',
              style: TextStyle(color: VocaTokens.textMuted, fontSize: 11),
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
    // Generate context sentence with masked target word
    final rawSentence = card.contextSentence ??
        '日常会話でよく使われる [ ___ ] という言葉です。';
    final hasContext = card.contextSentence != null && card.contextSentence!.isNotEmpty;

    final maskedSentence = rawSentence.replaceAll(card.word, '[ _____ ]');
    final reading = card.reading ?? card.pinyin ?? card.romanization;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: VocaTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VocaTokens.borderColor),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 8)),
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
                  color: VocaTokens.accentPrimarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'CLOZE TEST',
                  style: TextStyle(
                    color: VocaTokens.accentPrimary,
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
                    style: const TextStyle(color: VocaTokens.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
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
              color: VocaTokens.bgSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isClozeRevealed ? VocaTokens.colorGrammar.withOpacity(0.4) : VocaTokens.borderColor,
              ),
            ),
            child: Column(
              children: [
                if (!_isClozeRevealed)
                  Text(
                    maskedSentence,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: VocaTokens.textPrimary,
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
                      style: const TextStyle(
                        color: VocaTokens.textSecondary,
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
                style: const TextStyle(color: VocaTokens.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 14),
            ],

            ElevatedButton.icon(
              onPressed: () => setState(() => _isClozeRevealed = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: VocaTokens.accentPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('Reveal Word & Context', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ] else ...[
            // Meaning box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: VocaTokens.wordMasteredBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VocaTokens.wordMasteredText.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    card.word,
                    style: const TextStyle(
                      color: VocaTokens.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.meaning,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: VocaTokens.textSecondary,
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
                backgroundColor: VocaTokens.bgSurface,
                foregroundColor: VocaTokens.accentPrimary,
                side: const BorderSide(color: VocaTokens.borderColor),
              ),
              icon: const Icon(Icons.volume_up, size: 20),
              tooltip: 'Listen to context',
            ),
          ],
        ],
      ),
    );
  }

  TextSpan _buildHighlightedSentence(String sentence, String targetWord) {
    final parts = sentence.split(targetWord);
    final spans = <TextSpan>[];

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(
          text: parts[i],
          style: const TextStyle(color: VocaTokens.textPrimary, fontSize: 17, height: 1.4),
        ));
      }
      if (i < parts.length - 1) {
        spans.add(TextSpan(
          text: targetWord,
          style: const TextStyle(
            color: VocaTokens.accentPrimary,
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
    final reading = card.reading ?? card.pinyin ?? card.romanization;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: VocaTokens.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VocaTokens.borderColor),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 8)),
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
                        style: const TextStyle(color: VocaTokens.textMuted, fontSize: 14),
                      ),
                    Text(
                      card.word,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: VocaTokens.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.volume_up, color: VocaTokens.accentPrimary, size: 22),
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
          const Text(
            'Choose the correct definition:',
            style: TextStyle(color: VocaTokens.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
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

                Color optionBorder = VocaTokens.borderColor;
                Color optionBg = VocaTokens.bgSurface;
                Color textColor = VocaTokens.textSecondary;
                IconData? feedbackIcon;

                if (_isQuizAnswered) {
                  if (isCorrect) {
                    optionBorder = VocaTokens.colorGrammar;
                    optionBg = VocaTokens.colorGrammar.withOpacity(0.18);
                    textColor = VocaTokens.textPrimary;
                    feedbackIcon = Icons.check_circle;
                  } else if (isSelected) {
                    optionBorder = VocaTokens.error;
                    optionBg = VocaTokens.error.withOpacity(0.18);
                    textColor = VocaTokens.textPrimary;
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
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: VocaTokens.bgHover,
                          ),
                          child: Text(
                            String.fromCharCode(65 + idx),
                            style: const TextStyle(
                              color: VocaTokens.textPrimary,
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
                            color: isCorrect ? VocaTokens.colorGrammar : VocaTokens.error,
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
              backgroundColor: VocaTokens.accentPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              _currentMode == StudyMode.quiz ? 'Select an answer above' : 'Show Answer',
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
          _buildSM2Button('Again', '<10m', VocaTokens.error, SRSReviewRating.again),
          const SizedBox(width: 6),
          _buildSM2Button('Hard', _formatInterval(resHard.interval), VocaTokens.warning, SRSReviewRating.hard),
          const SizedBox(width: 6),
          _buildSM2Button('Good', _formatInterval(resGood.interval), VocaTokens.colorGrammar, SRSReviewRating.good),
          const SizedBox(width: 6),
          _buildSM2Button('Easy', _formatInterval(resEasy.interval), VocaTokens.accentPrimary, SRSReviewRating.easy),
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
                  color: VocaTokens.colorGrammar.withOpacity(0.15),
                  border: Border.all(color: VocaTokens.colorGrammar, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: VocaTokens.colorGrammar.withOpacity(0.3),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 56,
                  color: VocaTokens.accentTertiary,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Session Complete!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: VocaTokens.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'You finished all spaced repetition reviews for this deck.',
                textAlign: TextAlign.center,
                style: TextStyle(color: VocaTokens.textSecondary, fontSize: 14),
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
                        color: VocaTokens.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: VocaTokens.colorFire.withOpacity(0.4)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.local_fire_department, color: VocaTokens.colorFire, size: 30),
                          const SizedBox(height: 6),
                          Text(
                            '$streak Day Streak',
                            style: const TextStyle(
                              color: VocaTokens.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Keep it up!',
                            style: TextStyle(color: VocaTokens.textMuted, fontSize: 11),
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
                        color: VocaTokens.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: VocaTokens.colorDiamond.withOpacity(0.4)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.diamond, color: VocaTokens.colorDiamond, size: 30),
                          SizedBox(height: 6),
                          Text(
                            '+1 Diamond',
                            style: TextStyle(
                              color: VocaTokens.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Daily study bonus',
                            style: TextStyle(color: VocaTokens.textMuted, fontSize: 11),
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
                  color: VocaTokens.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: VocaTokens.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SESSION RECAP',
                      style: TextStyle(
                        color: VocaTokens.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildRecapItem('Reviewed', '$_totalReviewed', VocaTokens.wordKnownText),
                        _buildRecapItem('Good / Easy', '$_goodOrEasyCount', VocaTokens.colorGrammar),
                        _buildRecapItem('Again / Hard', '$_againOrHardCount', VocaTokens.warning),
                        _buildRecapItem('Accuracy', '$accuracy%', VocaTokens.accentSecondary),
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
                        foregroundColor: VocaTokens.textSecondary,
                        side: const BorderSide(color: VocaTokens.borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loadDueCards,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VocaTokens.accentPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      child: const Text('Review More', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildRecapItem(String label, String value, Color color) {
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
              style: const TextStyle(color: VocaTokens.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
