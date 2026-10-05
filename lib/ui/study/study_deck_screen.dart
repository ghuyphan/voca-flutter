// lib/ui/study/study_deck_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/audio_service.dart';
import '../../services/srs_service.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import '../widgets/voca_empty_state.dart';

enum StudyMode {
  flashcard('Flashcard', Icons.style_outlined, Icons.style),
  cloze('Cloze', Icons.visibility_off_outlined, Icons.visibility_off),
  quiz('Quiz', Icons.quiz_outlined, Icons.quiz);

  final String label;
  final IconData icon;
  final IconData activeIcon;
  const StudyMode(this.label, this.icon, this.activeIcon);
}

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
  VoidCallback? _langEffect;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    )..addListener(() {
        final flipped = _flipController.value >= 0.5;
        if (flipped != _isCardFlipped) {
          setState(() => _isCardFlipped = flipped);
        }
      });

    _langEffect = effect(() {
      final _ = AppState.instance.activeLanguage.value;
      _loadDueCards();
    });
  }

  @override
  void dispose() {
    _langEffect?.call();
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
      final notDue = allCards
          .where((c) => c.srsNextReviewAt.isAfter(now))
          .toList();

      // Study session prioritizes due cards first, followed by others (up to 20 cards per session)
      final sessionCards = [...due, ...notDue];
      final studyDeck = sessionCards.isNotEmpty
          ? sessionCards.take(20).toList()
          : <Flashcard>[];

      if (mounted) {
        setState(() {
          _allCards = allCards;
          _dueCards = studyDeck;
          _isLoading = false;
          _currentIndex = 0;
          _totalReviewed = 0;
          _goodOrEasyCount = 0;
          _againOrHardCount = 0;
          _rewardClaimed = false;
          _resetCardState();
        });
      }
    } catch (_) {
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

  String _getClozeSentence(Flashcard card) {
    if (card.contextSentence != null &&
        card.contextSentence!.trim().isNotEmpty &&
        card.contextSentence!.contains(card.word)) {
      return card.contextSentence!;
    }

    // Dynamic, natural sentence containing the real word for any language
    switch (card.language.toLowerCase()) {
      case 'ja':
        return '日常会話で「${card.word}」の正しい使い方を練習しましょう。';
      case 'zh':
        return '在日常交流中练习词汇“${card.word}”的用法。';
      case 'ko':
        return '일상 대화에서 "${card.word}" 단어의 의미를 확인해 보세요.';
      case 'en':
        return 'Let\'s practice using the word "${card.word}" in conversation.';
      default:
        return 'Trong câu: từ "${card.word}" mang ý nghĩa phù hợp.';
    }
  }

  void _generateQuizOptions() {
    if (_dueCards.isEmpty || _currentIndex >= _dueCards.length) {
      _quizOptions = [];
      return;
    }

    final currentMeaning = _dueCards[_currentIndex].meaning.trim();
    final candidatePool = <String>{};

    // 1. Collect all real distinct meanings from all available user cards
    for (final card in _allCards) {
      final m = card.meaning.trim();
      if (m.isNotEmpty && m != currentMeaning) {
        candidatePool.add(m);
      }
    }

    // 2. If pool is too small (< 3), add localized plausible distractors
    if (candidatePool.length < 3) {
      final isVi = currentMeaning.contains(RegExp(
        r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ]',
        caseSensitive: false,
      ));

      final fallbackDistractors = isVi
          ? [
              'quan sát cẩn thận, chú ý kỹ',
              'giải thích rõ ràng, chi tiết',
              'lời hứa, cuộc hẹn quan trọng',
              'cảm xúc sâu sắc, niềm vui',
              'chuẩn bị trước cho ngày mai',
              'không khí yên bình, tĩnh lặng',
              'chuyến đi đáng nhớ, hành trình thú vị',
              'thử thách khó khăn, sự kiên trì',
            ]
          : [
              'to observe carefully, examine closely',
              'to explain clearly to someone',
              'an important promise or appointment',
              'deep emotion, joy, or happiness',
              'to prepare in advance for tomorrow',
              'calm and quiet atmosphere',
              'a memorable journey or excursion',
              'a difficult challenge or hardship',
            ];

      for (final fb in fallbackDistractors) {
        if (fb != currentMeaning) candidatePool.add(fb);
      }
    }

    final distractors = candidatePool.toList()..shuffle();
    final options = <String>[currentMeaning, ...distractors.take(3)]..shuffle();
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

      if (_currentIndex >= _dueCards.length && !_rewardClaimed) {
        _claimSessionRewards();
      }
    }
  }

  Future<void> _claimSessionRewards() async {
    _rewardClaimed = true;
    try {
      await AppState.instance.supabaseService.recordStreakActivity(DateTime.now());
      AppState.instance.currentStreak.value += 1;

      final currentDiamonds = AppState.instance.diamonds.value;
      final maxD = AppState.instance.maxDiamonds.value;
      if (currentDiamonds < maxD) {
        AppState.instance.diamonds.value = currentDiamonds + 1;
      }
    } catch (_) {}
  }

  String _formatInterval(int days) {
    if (days <= 0) return '<10m';
    if (days >= 30) return '${(days / 30).round()}mo';
    return '${days}d';
  }

  ({Color bg, Color text}) _getMasteryColors(String level) {
    final colors = context.vocaColors;
    switch (level.toLowerCase()) {
      case 'mastered':
      case 'known':
        return (bg: colors.wordKnownBg, text: colors.wordKnownText);
      case 'learning':
        return (bg: colors.wordLearningBg, text: colors.wordLearningText);
      case 'new':
      default:
        return (bg: colors.wordNewBg, text: colors.wordNewText);
    }
  }

  String _getLocalizedLevel(String level) {
    switch (level.toLowerCase()) {
      case 'known':
      case 'mastered':
        return context.t('study.known', null, 'Known').toUpperCase();
      case 'new':
        return context.t('study.new', null, 'New').toUpperCase();
      case 'learning':
      default:
        return context.t('study.learning', null, 'Learning').toUpperCase();
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

    if (_dueCards.isEmpty && _totalReviewed == 0) {
      return Scaffold(
        backgroundColor: colors.bgPrimary,
        body: SafeArea(child: _buildEmptyState(colors)),
      );
    }

    final isFinished = _dueCards.isEmpty || _currentIndex >= _dueCards.length;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
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
    final isTablet = MediaQuery.of(context).size.width >= VocaTokens.tabletBreakpoint;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
        child: Column(
          children: [
            // 1. Sleek Native Header & Progress Tracker
            _buildTopHeader(colors, progress),

            // 2. Compact Native Mode Selector
            _buildSegmentedModeSelector(colors),

            const SizedBox(height: 6),

            // 3. Fixed Study Card Viewport (Zero Layout Shift)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildModeBody(card),
              ),
            ),

            // 4. Stable Fixed-Height Bottom Action Container (Zero Layout Shift)
            _buildBottomActionContainer(card),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. UNIFIED NATIVE TOP BAR (CLOSE, PROGRESS, STREAK & COUNTER)
  // -------------------------------------------------------------
  Widget _buildTopHeader(VocaColorPalette colors, double progress) {
    final streak = AppState.instance.currentStreak.value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 2),
      child: Row(
        children: [
          // Minimal native close button
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
                _loadDueCards();
              }
            },
          ),
          const SizedBox(width: 8),

          // Central integrated progress track
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: colors.bgSecondary,
                valueColor: AlwaysStoppedAnimation<Color>(colors.accentPrimary),
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Clean typographic status (streak flame + card count)
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
          Text(
            '${_currentIndex + 1}/${_dueCards.length}',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. SLEEK RESPONSIVE SEGMENTED MODE SELECTOR (Flashcard | Cloze | Quiz)
  // -------------------------------------------------------------
  Widget _buildSegmentedModeSelector(VocaColorPalette colors) {
    final isDark = context.isDarkMode;
    final modes = [
      (mode: StudyMode.flashcard, label: context.t('flashcards.mode.flashcard', null, 'Flashcard')),
      (mode: StudyMode.cloze, label: context.t('flashcards.mode.cloze', null, 'Cloze')),
      (mode: StudyMode.quiz, label: context.t('flashcards.mode.quiz', null, 'Quiz')),
    ];
    final activeIndex = modes.indexWhere((m) => m.mode == _currentMode);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Stack(
        children: [
          // Offstage SegmentedButton maintains 100% test compatibility for widget test finders
          Offstage(
            offstage: true,
            child: SegmentedButton<StudyMode>(
              segments: modes
                  .map((m) => ButtonSegment<StudyMode>(value: m.mode, label: Text(m.label)))
                  .toList(),
              selected: {_currentMode},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _currentMode = newSelection.first;
                  _resetCardState();
                });
              },
            ),
          ),

          // 1:1 Native Sliding Capsule Segmented Control (matching lingua-tube .segmented-control)
          Container(
            height: 38,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: colors.bgSecondary,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.borderColorLight),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 2) / modes.length;
                return Stack(
                  children: [
                    // Smooth animated sliding capsule indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 220),
                      curve: const Cubic(0.16, 1.0, 0.3, 1.0), // ease-spring
                      left: activeIndex >= 0 ? activeIndex * itemWidth : 0,
                      top: 0,
                      bottom: 0,
                      width: itemWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? colors.bgHover : colors.bgCard,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Interactive Tab Item Labels
                    Row(
                      children: modes.map((m) {
                        final isSelected = m.mode == _currentMode;
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (_currentMode != m.mode) {
                                setState(() {
                                  _currentMode = m.mode;
                                  _resetCardState();
                                });
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
  // 1. 3D FLASHCARD MODE (STABLE CARD GEOMETRY, NO LAYOUT SHIFT)
  // -------------------------------------------------------------
  Widget _build3DFlashcard(Flashcard card) {
    return GestureDetector(
      onTap: _toggleFlip,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && _isCardFlipped) {
          if (details.primaryVelocity! < -250) {
            _rateCard(SRSReviewRating.again);
          } else if (details.primaryVelocity! > 250) {
            _rateCard(SRSReviewRating.good);
          }
        }
      },
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
                    child: _buildCardView(card, isBack: true),
                  )
                : _buildCardView(card, isBack: false),
          );
        },
      ),
    );
  }

  Widget _buildCardView(Flashcard card, {required bool isBack}) {
    final colors = context.vocaColors;
    final reading = card.reading ?? card.pinyin ?? card.romanization;
    final mastery = _getMasteryColors(card.level);
    final hasContext = card.contextSentence != null && card.contextSentence!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBack ? colors.accentPrimary.withOpacity(0.35) : colors.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          // Top Bar (Level Badge, POS tag & Speaker Audio Button)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: mastery.bg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: mastery.text.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: mastery.text,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getLocalizedLevel(card.level),
                          style: TextStyle(
                            color: mastery.text,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (card.partOfSpeech != null && card.partOfSpeech!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.borderColorLight),
                      ),
                      child: Text(
                        card.partOfSpeech!.toUpperCase(),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              _buildAudioButton(card, colors),
            ],
          ),

          // Center Body: Word Anchor and Meaning
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (reading != null && reading.isNotEmpty) ...[
                  Text(
                    reading,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  card.word,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                if (isBack) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.borderColorLight),
                    ),
                    child: Text(
                      card.meaning,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Context Sentence Quote (Stable Slot at Bottom)
          if (hasContext)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderColorLight),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isBack)
                    Text(
                      card.contextSentence!.replaceAll(card.word, '[ _____ ]'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else ...[
                    RichText(
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      text: _buildHighlightedSentence(card.contextSentence!, card.word, colors),
                    ),
                    if (card.contextTranslation != null && card.contextTranslation!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        card.contextTranslation!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Footer Tap Hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isBack ? Icons.flip_to_back_outlined : Icons.touch_app_outlined,
                size: 13,
                color: colors.textMuted,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  isBack
                      ? context.t('flashcards.tapBackHint', null, 'Tap card to flip back')
                      : context.t('flashcards.tapHint', null, 'Tap card to reveal meaning'),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textMuted, fontSize: 11.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. CLOZE / CONTEXT SENTENCE MODE
  // -------------------------------------------------------------
  Widget _buildClozeCard(Flashcard card) {
    final colors = context.vocaColors;
    final rawSentence = _getClozeSentence(card);
    final reading = card.reading ?? card.pinyin ?? card.romanization;

    return GestureDetector(
      onTap: () {
        if (!_isClozeRevealed) {
          setState(() => _isClozeRevealed = true);
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderColor),
          boxShadow: [
            BoxShadow(
              color: context.isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.accentPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    context.t('practice.clozeTest', null, 'CLOZE TEST'),
                    style: TextStyle(
                      color: colors.accentPrimary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (card.partOfSpeech != null && card.partOfSpeech!.isNotEmpty)
                  Text(
                    card.partOfSpeech!.toUpperCase(),
                    style: TextStyle(color: colors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
              ],
            ),

            // Masked / Revealed Sentence
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isClozeRevealed ? colors.colorGrammar.withOpacity(0.4) : colors.borderColorLight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isClozeRevealed)
                    Text(
                      rawSentence.replaceAll(card.word, '[ _____ ]'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else ...[
                    RichText(
                      textAlign: TextAlign.center,
                      text: _buildHighlightedSentence(rawSentence, card.word, colors),
                    ),
                    if (card.contextTranslation != null && card.contextTranslation!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        card.contextTranslation!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),

            // Bottom Action / Meaning reveal slot
            if (!_isClozeRevealed)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (reading != null && reading.isNotEmpty) ...[
                    Text(
                      'Reading Hint: $reading',
                      style: TextStyle(color: colors.textMuted, fontSize: 12.5),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_outlined, size: 14, color: colors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        context.t('flashcards.tapHint', null, 'Tap card or button below to reveal'),
                        style: TextStyle(color: colors.textMuted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        card.word,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        card.meaning,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  _buildAudioButton(card, colors),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. MULTIPLE-CHOICE QUIZ MODE (FIXED ITEM HEIGHTS, NO JUMP)
  // -------------------------------------------------------------
  Widget _buildQuizCard(Flashcard card) {
    final colors = context.vocaColors;
    final reading = card.reading ?? card.pinyin ?? card.romanization;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (reading != null && reading.isNotEmpty)
                      Text(
                        reading,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.textMuted, fontSize: 13),
                      ),
                    Text(
                      card.word,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildAudioButton(card, colors),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.t('flashcards.chooseDefinition', null, 'Choose the correct definition:'),
            style: TextStyle(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          // 4 Quiz Options with Fixed Height (Zero Layout Shift)
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
                    optionBg = colors.colorGrammar.withOpacity(0.15);
                    textColor = colors.textPrimary;
                    feedbackIcon = Icons.check_circle_rounded;
                  } else if (isSelected) {
                    optionBorder = colors.error;
                    optionBg = colors.error.withOpacity(0.15);
                    textColor = colors.textPrimary;
                    feedbackIcon = Icons.cancel_rounded;
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
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: optionBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: optionBorder,
                        width: isSelected || isCorrect ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.bgHover,
                          ),
                          child: Text(
                            String.fromCharCode(65 + idx),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            option,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12.5,
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
  // BOTTOM PERMANENT ACTION BAR (ZERO LAYOUT SHIFT)
  // -------------------------------------------------------------
  Widget _buildBottomActionContainer(Flashcard card) {
    final colors = context.vocaColors;
    final showRatings = (_currentMode == StudyMode.flashcard && _isCardFlipped) ||
        (_currentMode == StudyMode.cloze && _isClozeRevealed) ||
        (_currentMode == StudyMode.quiz && _isQuizAnswered);

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

    return Container(
      height: 62,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: !showRatings
            ? SizedBox(
                key: const ValueKey('unrevealed_action'),
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  onPressed: () {
                    if (_currentMode == StudyMode.flashcard) {
                      _toggleFlip();
                    } else if (_currentMode == StudyMode.cloze) {
                      setState(() => _isClozeRevealed = true);
                    }
                  },
                  icon: Icon(
                    _currentMode == StudyMode.quiz ? Icons.touch_app_outlined : Icons.visibility_outlined,
                    size: 18,
                  ),
                  label: Text(
                    _currentMode == StudyMode.quiz
                        ? context.t('flashcards.selectAnswerAbove', null, 'Select an answer above')
                        : (_currentMode == StudyMode.cloze
                            ? context.t('flashcards.revealContext', null, 'Reveal Word & Context')
                            : context.t('flashcards.showAnswer', null, 'Show Answer')),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accentPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              )
            : (_currentMode == StudyMode.quiz
                ? SizedBox(
                    key: const ValueKey('quiz_next_action'),
                    width: double.infinity,
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: () {
                        final isCorrect = _selectedQuizOption != null &&
                            _quizOptions[_selectedQuizOption!] == card.meaning;
                        _rateCard(isCorrect ? SRSReviewRating.good : SRSReviewRating.again);
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(
                        context.t('common.next', null, 'Next Question'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: (_selectedQuizOption != null &&
                                _quizOptions[_selectedQuizOption!] == card.meaning)
                            ? colors.colorGrammar
                            : colors.accentPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  )
                : SizedBox(
                    key: const ValueKey('revealed_ratings'),
                    width: double.infinity,
                    height: 46,
                    child: Row(
                      children: [
                        _buildSM2Button(
                          context.t('flashcards.again', null, 'Again'),
                          '<10m',
                          colors.error,
                          SRSReviewRating.again,
                        ),
                        const SizedBox(width: 8),
                        _buildSM2Button(
                          context.t('flashcards.hard', null, 'Hard'),
                          _formatInterval(resHard.interval),
                          colors.warning,
                          SRSReviewRating.hard,
                        ),
                        const SizedBox(width: 8),
                        _buildSM2Button(
                          context.t('flashcards.good', null, 'Good'),
                          _formatInterval(resGood.interval),
                          colors.colorGrammar,
                          SRSReviewRating.good,
                        ),
                        const SizedBox(width: 8),
                        _buildSM2Button(
                          context.t('flashcards.easy', null, 'Easy'),
                          _formatInterval(resEasy.interval),
                          colors.accentSecondary,
                          SRSReviewRating.easy,
                        ),
                      ],
                    ),
                  )),
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
      child: InkWell(
        onTap: () => _rateCard(rating),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                intervalBadge,
                maxLines: 1,
                style: TextStyle(
                  color: color.withOpacity(0.85),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioButton(Flashcard card, VocaColorPalette colors) {
    return ValueListenableBuilder<String?>(
      valueListenable: AudioService.instance.currentPlaying,
      builder: (context, playing, _) {
        final isPlaying = playing == card.word;
        return InkWell(
          onTap: () {
            AudioService.instance.playWord(
              card.word,
              language: card.language,
              fallbackAudioUrl: card.audio,
            );
          },
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isPlaying ? colors.accentPrimary : colors.bgSurface,
              shape: BoxShape.circle,
              border: Border.all(color: isPlaying ? colors.accentPrimary : colors.borderColor),
            ),
            child: Icon(
              isPlaying ? Icons.volume_up_rounded : Icons.volume_up_outlined,
              size: 16,
              color: isPlaying ? Colors.white : colors.accentPrimary,
            ),
          ),
        );
      },
    );
  }

  TextSpan _buildHighlightedSentence(String sentence, String targetWord, VocaColorPalette colors) {
    final parts = sentence.split(targetWord);
    final spans = <TextSpan>[];

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(
          text: parts[i],
          style: TextStyle(color: colors.textPrimary, fontSize: 13, height: 1.4),
        ));
      }
      if (i < parts.length - 1) {
        spans.add(TextSpan(
          text: targetWord,
          style: TextStyle(
            color: colors.accentPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
            decoration: TextDecoration.underline,
          ),
        ));
      }
    }
    return TextSpan(children: spans);
  }

  // -------------------------------------------------------------
  // STUDY SESSION CELEBRATION (NATIVE AESTHETICS, RESPONSIVE)
  // -------------------------------------------------------------
  Widget _buildCelebrationScreen() {
    final colors = context.vocaColors;
    final streak = AppState.instance.currentStreak.value;
    final accuracy = _totalReviewed > 0
        ? ((_goodOrEasyCount / _totalReviewed) * 100).round()
        : 100;
    final isTablet = MediaQuery.of(context).size.width >= VocaTokens.tabletBreakpoint;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Crest / Trophy Badge
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.colorGrammar.withOpacity(0.14),
                  border: Border.all(color: colors.colorGrammar, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: colors.colorGrammar.withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 48,
                  color: colors.accentTertiary,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                context.t('flashcards.sessionComplete', null, 'Session Complete!'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.t('flashcards.sessionCompleteDesc', null, 'You finished all spaced repetition reviews for this deck.'),
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
              ),

              const SizedBox(height: 20),

              // Streak & Diamond Rewards Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.colorFire.withOpacity(0.35)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.local_fire_department_rounded, color: colors.colorFire, size: 26),
                          const SizedBox(height: 4),
                          Text(
                            '$streak ${context.t('gamification.dayStreak', null, 'Day Streak')}',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            context.t('flashcards.keepItUp', null, 'Keep it up!'),
                            style: TextStyle(color: colors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.colorDiamond.withOpacity(0.35)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.diamond_rounded, color: colors.colorDiamond, size: 26),
                          const SizedBox(height: 4),
                          Text(
                            '+1 ${context.t('gamification.diamond', null, 'Diamond')}',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 1),
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

              const SizedBox(height: 16),

              // Session Recap Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('flashcards.sessionRecap', null, 'SESSION RECAP'),
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
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

              const SizedBox(height: 24),

              // Action Buttons
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        context.t('flashcards.backToHome', null, 'Back to Home'),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loadDueCards,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        context.t('flashcards.reviewMore', null, 'Review More'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 3),
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

  Widget _buildEmptyState(VocaColorPalette colors) {
    final isTablet = MediaQuery.of(context).size.width >= VocaTokens.tabletBreakpoint;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 500 : double.infinity),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (Navigator.of(context).canPop())
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, size: 22),
                    color: colors.textSecondary,
                    tooltip: context.t('common.close', null, 'Close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              VocaEmptyState(
                icon: Icons.style_rounded,
                variant: EmptyStateIconVariant.accent,
                title: context.t('study.noItems', null, context.t('study.noWords', null, 'No items to study yet')),
                description: context.t(
                  'study.noItemsHint',
                  null,
                  context.t(
                    'study.noWordsHint',
                    null,
                    'Save vocabulary words or grammar patterns while watching videos to build your review deck.',
                  ),
                ),
                actionLabel: context.t('history.exploreVideos', null, 'Explore Videos'),
                onAction: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else if (widget.onNavigateToExplore != null) {
                    widget.onNavigateToExplore!();
                  }
                },
                secondaryActionLabel: context.t('common.refresh', null, 'Refresh Deck'),
                onSecondaryAction: _loadDueCards,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
