// lib/ui/study/study_deck_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
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

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'mastered':
        return const Color(0xFF10B981);
      case 'known':
        return const Color(0xFF38BDF8);
      case 'learning':
        return const Color(0xFFF59E0B);
      case 'new':
      default:
        return const Color(0xFF818CF8);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isFinished = _dueCards.isEmpty || _currentIndex >= _dueCards.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.style, color: Color(0xFF6366F1), size: 22),
            SizedBox(width: 8),
            Text(
              'SRS Study Deck',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
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
  // ACTIVE STUDY SCREEN
  // -------------------------------------------------------------
  Widget _buildActiveStudyScreen() {
    final card = _dueCards[_currentIndex];
    final progress = (_currentIndex + 1) / _dueCards.length;

    return Column(
      children: [
        // Mode Selector Pills
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: StudyMode.values.map((mode) {
              final isSelected = _currentMode == mode;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF818CF8) : Colors.white10,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected ? mode.activeIcon : mode.icon,
                            size: 16,
                            color: isSelected ? Colors.white : Colors.white60,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            mode.label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Card ${_currentIndex + 1} of ${_dueCards.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getLevelColor(card.level).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _getLevelColor(card.level).withOpacity(0.35),
                      ),
                    ),
                    child: Text(
                      card.level.toUpperCase(),
                      style: TextStyle(
                        color: _getLevelColor(card.level),
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
                  backgroundColor: const Color(0xFF1E293B),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
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
  // 1. 3D FLASHCARD MODE
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
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Part of Speech tag
          if (card.partOfSpeech != null && card.partOfSpeech!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                card.partOfSpeech!.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
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
                color: Color(0xFF94A3B8),
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
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),

          if (card.romanization != null && card.reading != null) ...[
            const SizedBox(height: 6),
            Text(
              card.romanization!,
              style: const TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],

          const SizedBox(height: 20),

          // Audio Button
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
                  backgroundColor: isPlaying ? const Color(0xFF6366F1) : const Color(0xFF334155),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: Icon(isPlaying ? Icons.volume_up : Icons.volume_up_outlined, size: 18),
                label: Text(isPlaying ? 'Playing...' : 'Pronounce'),
              );
            },
          ),

          const SizedBox(height: 36),

          // Hint to tap
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_outlined, size: 16, color: Color(0xFF64748B)),
              SizedBox(width: 6),
              Text(
                'Tap card to reveal meaning',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontStyle: FontStyle.italic),
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
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.5)),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Word header small
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  card.word,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (reading != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '($reading)',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                  ),
                ],
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.volume_up, size: 20, color: Color(0xFF6366F1)),
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

            const Divider(color: Colors.white12, height: 28),

            // Definition / Meaning
            const Text(
              'MEANING',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              card.meaning,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),

            // Context Sentence if available
            if (card.contextSentence != null && card.contextSentence!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Text(
                      card.contextSentence!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    if (card.contextTranslation != null &&
                        card.contextTranslation!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        card.contextTranslation!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Text(
              'Tap card to flip back',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
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
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(24),
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
                  color: const Color(0xFF6366F1).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'CLOZE TEST',
                  style: TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (card.partOfSpeech != null)
                Text(
                  card.partOfSpeech!.toUpperCase(),
                  style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Sentence Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isClozeRevealed ? const Color(0xFF10B981).withOpacity(0.4) : Colors.white10,
              ),
            ),
            child: Column(
              children: [
                if (!_isClozeRevealed)
                  Text(
                    maskedSentence,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
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
                    const SizedBox(height: 10),
                    Text(
                      card.contextTranslation!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Reading / Hint
          if (!_isClozeRevealed) ...[
            if (reading != null) ...[
              Text(
                'Reading Hint: $reading',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton.icon(
              onPressed: () => setState(() => _isClozeRevealed = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('Reveal Word & Context', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ] else ...[
            // Meaning box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    card.word,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.meaning,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Audio button
            IconButton.filled(
              onPressed: () {
                AudioService.instance.playWord(
                  hasContext ? card.contextSentence! : card.word,
                  language: card.language,
                );
              },
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF334155),
                foregroundColor: Colors.white,
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
          style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.4),
        ));
      }
      if (i < parts.length - 1) {
        spans.add(TextSpan(
          text: targetWord,
          style: const TextStyle(
            color: Color(0xFF34D399),
            fontWeight: FontWeight.bold,
            fontSize: 20,
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
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Target Word & Audio
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  if (reading != null && reading.isNotEmpty)
                    Text(
                      reading,
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                    ),
                  Text(
                    card.word,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.volume_up, color: Color(0xFF6366F1), size: 24),
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

          const SizedBox(height: 8),
          const Text(
            'Choose the correct definition:',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // 4 Quiz Options
          Expanded(
            child: ListView.separated(
              itemCount: _quizOptions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final option = _quizOptions[idx];
                final isSelected = _selectedQuizOption == idx;
                final isCorrect = option == card.meaning;

                Color optionBorder = Colors.white12;
                Color optionBg = Colors.white.withOpacity(0.04);
                Color textColor = Colors.white70;
                IconData? feedbackIcon;

                if (_isQuizAnswered) {
                  if (isCorrect) {
                    optionBorder = const Color(0xFF10B981);
                    optionBg = const Color(0xFF10B981).withOpacity(0.2);
                    textColor = Colors.white;
                    feedbackIcon = Icons.check_circle;
                  } else if (isSelected) {
                    optionBorder = const Color(0xFFEF4444);
                    optionBg = const Color(0xFFEF4444).withOpacity(0.2);
                    textColor = Colors.white;
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: optionBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: optionBorder, width: isSelected || isCorrect ? 1.5 : 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                          child: Text(
                            String.fromCharCode(65 + idx),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: isSelected || isCorrect ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (feedbackIcon != null)
                          Icon(
                            feedbackIcon,
                            size: 20,
                            color: isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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
  // BOTTOM SM-2 RATING BAR WITH INTERVAL PREVIEWS
  // -------------------------------------------------------------
  Widget _buildBottomRatingBar(Flashcard card) {
    // Only show rating buttons when answer has been revealed
    final showRatings = (_currentMode == StudyMode.flashcard && _isCardFlipped) ||
        (_currentMode == StudyMode.cloze && _isClozeRevealed) ||
        (_currentMode == StudyMode.quiz && _isQuizAnswered);

    if (!showRatings) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              backgroundColor: const Color(0xFF6366F1),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          _buildSM2Button('Again', '<10m', const Color(0xFFEF4444), SRSReviewRating.again),
          const SizedBox(width: 8),
          _buildSM2Button('Hard', _formatInterval(resHard.interval), const Color(0xFFF59E0B), SRSReviewRating.hard),
          const SizedBox(width: 8),
          _buildSM2Button('Good', _formatInterval(resGood.interval), const Color(0xFF3B82F6), SRSReviewRating.good),
          const SizedBox(width: 8),
          _buildSM2Button('Easy', _formatInterval(resEasy.interval), const Color(0xFF10B981), SRSReviewRating.easy),
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
          side: BorderSide(color: color.withOpacity(0.6), width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 8),
          elevation: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                intervalBadge,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
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
  // STUDY SESSION COMPLETION CELEBRATION
  // -------------------------------------------------------------
  Widget _buildCelebrationScreen() {
    final streak = AppState.instance.currentStreak.value;
    final accuracy = _totalReviewed > 0
        ? ((_goodOrEasyCount / _totalReviewed) * 100).round()
        : 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 10),

          // Trophy Animated Badge
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981).withOpacity(0.15),
              border: Border.all(color: const Color(0xFF10B981), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events,
              size: 56,
              color: Color(0xFFFBBF24),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Session Complete!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You finished all spaced repetition reviews for this deck.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 14),
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
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF97316).withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.local_fire_department, color: Color(0xFFF97316), size: 30),
                      const SizedBox(height: 6),
                      Text(
                        '$streak Day Streak',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Keep it up!',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
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
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.diamond, color: Color(0xFF38BDF8), size: 30),
                      SizedBox(height: 6),
                      Text(
                        '+1 Diamond',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Daily study bonus',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
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
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SESSION RECAP',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildRecapItem('Reviewed', '$_totalReviewed', const Color(0xFF38BDF8)),
                    _buildRecapItem('Good / Easy', '$_goodOrEasyCount', const Color(0xFF10B981)),
                    _buildRecapItem('Again / Hard', '$_againOrHardCount', const Color(0xFFF59E0B)),
                    _buildRecapItem('Accuracy', '$accuracy%', const Color(0xFF818CF8)),
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
                      // Switch to explore or reload
                      _loadDueCards();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
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
                    backgroundColor: const Color(0xFF6366F1),
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
    );
  }

  Widget _buildRecapItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}
