// lib/ui/study/widgets/deck_cloze_quiz_sheet.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../models/voca_models.dart';
import '../../../services/haptic_service.dart';
import '../../../services/i18n_service.dart';
import '../../../state/app_state.dart';
import '../../sheets/voca_bottom_sheet.dart';

/// Clean Material 3 Cloze (Fill-in-the-blank) Sentence Quiz for saved vocabulary.
/// Allows learners to test active recall using authentic YouTube context sentences.
class DeckClozeQuizSheet extends StatefulWidget {
  final List<Flashcard> cards;

  const DeckClozeQuizSheet({
    super.key,
    required this.cards,
  });

  static Future<void> show(BuildContext context, List<Flashcard> cards) {
    return showVocaBottomSheet(
      context: context,
      title: context.t('study.clozeQuizTitle', null, 'Cloze Sentence Quiz'),
      subtitle: context.t('study.clozeQuizDesc', null, 'Practice missing words from authentic video sentences'),
      showCloseButton: true,
      maxHeightFactor: 0.90,
      contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      builder: (_) => DeckClozeQuizSheet(cards: cards),
    );
  }

  @override
  State<DeckClozeQuizSheet> createState() => _DeckClozeQuizSheetState();
}

class _DeckClozeQuizSheetState extends State<DeckClozeQuizSheet> {
  late final List<Flashcard> _quizCards;
  int _currentIndex = 0;
  int _score = 0;
  int _earnedXpTotal = 0;
  bool _isFinished = false;

  // Current question state
  int? _selectedOptionIndex;
  bool? _lastAwarded;
  List<String> _currentOptions = [];

  @override
  void initState() {
    super.initState();
    // Filter cards with sentence context containing the word
    final candidates = widget.cards
        .where((c) =>
            c.contextSentence != null &&
            c.contextSentence!.trim().isNotEmpty &&
            c.contextSentence!.contains(c.word))
        .toList();

    candidates.shuffle(math.Random());
    _quizCards = candidates.take(5).toList();

    if (_quizCards.isNotEmpty) {
      _prepareQuestion(_quizCards[0]);
    } else {
      _isFinished = true;
    }
  }

  void _prepareQuestion(Flashcard card) {
    _selectedOptionIndex = null;
    _lastAwarded = null;

    final correctWord = card.word;
    final otherWords = widget.cards
        .where((c) => c.word != correctWord && c.word.trim().isNotEmpty)
        .map((c) => c.word)
        .toSet()
        .toList();

    otherWords.shuffle(math.Random());
    final distractors = otherWords.take(3).toList();

    // Language-aware fallback distractors if total user cards are very few (< 4)
    final lang = AppState.instance.activeLanguage.value.toLowerCase();
    final List<String> fallbacks = switch (lang) {
      'en' || 'english' => ['word', 'time', 'point', 'thing', 'way', 'place'],
      'zh' || 'chinese' => ['这个', '可以', '没有', '因为', '所以', '但是'],
      'ko' || 'korean' => ['그것', '하다', '있다', '에서', '때문', '좋다'],
      _ => ['こと', 'する', 'から', 'ため', 'ある', 'いい'],
    };
    for (final f in fallbacks) {
      if (distractors.length >= 3) break;
      if (f != correctWord && !distractors.contains(f)) {
        distractors.add(f);
      }
    }

    final allOpts = [correctWord, ...distractors];
    allOpts.shuffle(math.Random());
    _currentOptions = allOpts;
  }

  Future<void> _handleOptionSelect(int index, String option) async {
    if (_selectedOptionIndex != null || _quizCards.isEmpty) return;

    final currentCard = _quizCards[_currentIndex];
    final isCorrect = option == currentCard.word;

    setState(() {
      _selectedOptionIndex = index;
      if (isCorrect) {
        _score++;
      }
    });

    if (isCorrect) {
      HapticService.light();
      final awarded = await AppState.instance.gamificationService.onQuizCompleted(
        quizKey: 'card_${currentCard.id}',
      );
      if (mounted) {
        setState(() {
          _lastAwarded = awarded;
          if (awarded) {
            _earnedXpTotal += 20;
          }
        });
      }
    } else {
      HapticService.medium();
    }
  }

  void _goToNext() {
    if (_currentIndex + 1 < _quizCards.length) {
      setState(() {
        _currentIndex++;
        _prepareQuestion(_quizCards[_currentIndex]);
      });
    } else {
      setState(() {
        _isFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    if (_quizCards.isEmpty || _isFinished) {
      return _buildFinishedView(context, colors);
    }

    final currentCard = _quizCards[_currentIndex];
    final sentence = currentCard.contextSentence ?? '';
    final translation = currentCard.contextTranslation;
    final maskedSentence = sentence.replaceFirst(currentCard.word, '[ _____ ]');
    final canEarnXp = AppState.instance.gamificationService.canEarnQuizXp('card_${currentCard.id}');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress Row: Question # & XP indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_currentIndex + 1} / ${_quizCards.length}',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: canEarnXp ? colors.accentPrimarySoft : colors.bgSecondary,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: canEarnXp
                      ? colors.accentPrimary.withValues(alpha: 0.3)
                      : colors.borderColorLight,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    canEarnXp ? Icons.bolt_rounded : Icons.refresh_rounded,
                    size: 13,
                    color: canEarnXp ? colors.accentPrimary : colors.textSecondary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    canEarnXp ? '+20 XP' : context.t('study.practiceMode', null, 'Practice'),
                    style: TextStyle(
                      color: canEarnXp ? colors.accentPrimary : colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Context Sentence Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                maskedSentence,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              if (translation != null && translation.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  translation,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 4 Multiple Choice Options (2x2 Grid)
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 52,
          children: List.generate(_currentOptions.length, (idx) {
            final opt = _currentOptions[idx];
            final isSelected = _selectedOptionIndex == idx;
            final isCorrectAnswer = opt == currentCard.word;

            Color bg = colors.bgSurface;
            Color border = colors.borderColor;
            Color textCol = colors.textPrimary;

            if (_selectedOptionIndex != null) {
              if (isCorrectAnswer) {
                bg = colors.success.withValues(alpha: 0.18);
                border = colors.success;
                textCol = colors.success;
              } else if (isSelected) {
                bg = colors.error.withValues(alpha: 0.18);
                border = colors.error;
                textCol = colors.error;
              }
            }

            return Semantics(
              button: true,
              enabled: _selectedOptionIndex == null,
              selected: isSelected,
              label: opt,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _selectedOptionIndex != null ? null : () => _handleOptionSelect(idx, opt),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: border,
                        width: isSelected || (_selectedOptionIndex != null && isCorrectAnswer) ? 1.5 : 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      opt,
                      style: TextStyle(
                        color: textCol,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 18),

        // Answer Feedback Indicator (shows instantly when an option is selected)
        if (_selectedOptionIndex != null) ...[
          Builder(
            builder: (_) {
              final isCorrect = _currentOptions[_selectedOptionIndex!] == currentCard.word;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: isCorrect ? colors.success : colors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCorrect
                          ? (_lastAwarded == true
                              ? context.t('study.correctBonus', null, 'Correct! +20 XP')
                              : context.t('study.correctPracticed', null, 'Correct! Practiced (+0 XP)'))
                          : '${context.t('study.correctAnswer', null, 'Correct answer:')} ${currentCard.word}',
                      style: TextStyle(
                        color: isCorrect ? colors.success : colors.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ] else
          const SizedBox(height: 6),

        // Permanent Bottom Action Button (always visible, disabled before choosing, active once chosen)
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _selectedOptionIndex != null ? _goToNext : null,
            style: FilledButton.styleFrom(
              backgroundColor: colors.accentPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: colors.bgSurface,
              disabledForegroundColor: colors.textMuted,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: _selectedOptionIndex == null
                    ? BorderSide(color: colors.borderColor, width: 1.2)
                    : BorderSide.none,
              ),
            ),
            child: Text(
              _currentIndex + 1 < _quizCards.length
                  ? context.t('common.next', null, 'Next Question')
                  : context.t('study.done', null, 'Done'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _selectedOptionIndex != null ? Colors.white : colors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinishedView(BuildContext context, VocaColorPalette colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.success.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: colors.success.withValues(alpha: 0.3)),
          ),
          child: Icon(Icons.check_circle_rounded, size: 30, color: colors.success),
        ),
        const SizedBox(height: 14),
        Text(
          context.t('study.sessionComplete', null, 'Quiz Complete!'),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$_score / ${_quizCards.length} ${context.t('study.correct', null, 'Correct')}',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _earnedXpTotal > 0 ? colors.accentPrimarySoft : colors.bgSecondary,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _earnedXpTotal > 0
                  ? colors.accentPrimary.withValues(alpha: 0.3)
                  : colors.borderColorLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_earnedXpTotal > 0)
                Icon(Icons.bolt_rounded, size: 15, color: colors.accentPrimary)
              else
                Icon(Icons.refresh_rounded, size: 15, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(
                _earnedXpTotal > 0
                    ? '+$_earnedXpTotal XP'
                    : context.t('study.reviewCompleted', null, 'Review Complete (+0 XP)'),
                style: TextStyle(
                  color: _earnedXpTotal > 0 ? colors.accentPrimary : colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            context.t(
              'study.unlimitedPracticeNotice',
              null,
              'You can practice unlimited times for memory retention! XP rewards reset tomorrow.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: colors.accentPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              context.t('study.done', null, 'Done'),
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
