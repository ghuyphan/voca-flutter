// lib/ui/study/widgets/rating_action_bar.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../models/study_session_models.dart';
import '../../../models/voca_models.dart';
import '../../../services/i18n_service.dart';
import '../../../services/srs_service.dart';
import '../study_session_controller.dart';

class RatingActionBar extends StatelessWidget {
  final Flashcard card;
  final StudyMode mode;
  final bool isRevealed;
  final bool canUndo;
  final VoidCallback onReveal;
  final ValueChanged<SRSReviewRating> onRate;
  final VoidCallback onUndo;

  const RatingActionBar({
    super.key,
    required this.card,
    required this.mode,
    required this.isRevealed,
    required this.canUndo,
    required this.onReveal,
    required this.onRate,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

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

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: AnimatedSwitcher(
        duration: VocaMotion.fast,
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: !isRevealed
            ? _buildRevealButton(context, colors)
            : _buildRatingButtons(
                context,
                colors,
                resHard: resHard,
                resGood: resGood,
                resEasy: resEasy,
              ),
      ),
    );
  }

  Widget _buildRevealButton(BuildContext context, VocaColorPalette colors) {
    final isQuiz = mode == StudyMode.quiz;
    final isCloze = mode == StudyMode.cloze;

    return SizedBox(
      key: const ValueKey('unrevealed_action'),
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: onReveal,
        icon: Icon(
          isQuiz ? Icons.touch_app_outlined : Icons.visibility_outlined,
          size: 19,
        ),
        label: Text(
          isQuiz
              ? context.t('flashcards.selectAnswerAbove', null, 'Select an answer above')
              : (isCloze
                  ? context.t('flashcards.revealContext', null, 'Reveal Word & Context')
                  : context.t('flashcards.showAnswer', null, 'Show Answer')),
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: colors.accentPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: VocaRadius.roundedMd),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildRatingButtons(
    BuildContext context,
    VocaColorPalette colors, {
    required SRSCalculationResult resHard,
    required SRSCalculationResult resGood,
    required SRSCalculationResult resEasy,
  }) {
    final buttons = [
      RatingDisplayData(
        rating: SRSReviewRating.again,
        label: context.t('flashcards.again', null, 'Again'),
        interval: '<10m',
        color: colors.error,
        icon: Icons.close_rounded,
      ),
      RatingDisplayData(
        rating: SRSReviewRating.hard,
        label: context.t('flashcards.hard', null, 'Hard'),
        interval: SpacedRepetitionService.formatInterval(resHard.interval),
        color: colors.warning,
        icon: Icons.timelapse_rounded,
      ),
      RatingDisplayData(
        rating: SRSReviewRating.good,
        label: context.t('flashcards.good', null, 'Good'),
        interval: SpacedRepetitionService.formatInterval(resGood.interval),
        color: colors.colorGrammar,
        icon: Icons.check_rounded,
      ),
      RatingDisplayData(
        rating: SRSReviewRating.easy,
        label: context.t('flashcards.easy', null, 'Easy'),
        interval: SpacedRepetitionService.formatInterval(resEasy.interval),
        color: colors.accentSecondary,
        icon: Icons.star_rounded,
      ),
    ];

    return SizedBox(
      key: const ValueKey('revealed_ratings'),
      width: double.infinity,
      height: 54,
      child: Row(
        children: [
          // Undo Button
          if (canUndo) ...[
            IconButton(
              tooltip: context.t('study.undo', null, 'Undo last card'),
              icon: const Icon(Icons.undo_rounded, size: 20),
              color: colors.textSecondary,
              style: IconButton.styleFrom(
                backgroundColor: colors.bgSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: VocaRadius.roundedMd,
                  side: BorderSide(color: colors.borderColorLight),
                ),
                minimumSize: const Size(42, 52),
              ),
              onPressed: onUndo,
            ),
            const SizedBox(width: 6),
          ],

          // SM-2 Rating Buttons Row
          Expanded(
            child: Row(
              children: buttons.map((b) {
                final isGood = b.rating == SRSReviewRating.good;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onRate(b.rating),
                        borderRadius: VocaRadius.roundedMd,
                        child: AnimatedContainer(
                          duration: VocaMotion.fast,
                          height: 52,
                          decoration: BoxDecoration(
                            color: isGood
                                ? b.color.withValues(alpha: 0.12)
                                : colors.bgSurface,
                            borderRadius: VocaRadius.roundedMd,
                            border: Border.all(
                              color: isGood
                                  ? b.color.withValues(alpha: 0.45)
                                  : colors.borderColorLight,
                              width: isGood ? 1.5 : 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Interval badge above
                              Text(
                                b.interval,
                                maxLines: 1,
                                style: TextStyle(
                                  color: isGood ? b.color : colors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 1),
                              // Action Label
                              Text(
                                b.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isGood ? b.color : colors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Micro indicator bar
                              Container(
                                width: 14,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: b.color.withValues(alpha: isGood ? 0.9 : 0.4),
                                  borderRadius: VocaRadius.roundedPill,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
