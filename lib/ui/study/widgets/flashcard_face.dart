// lib/ui/study/widgets/flashcard_face.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../models/voca_models.dart';
import '../../../services/audio_service.dart';
import '../../../services/i18n_service.dart';

class FlashcardFace extends StatelessWidget {
  final Flashcard card;
  final bool isBack;
  final Animation<double> flipAnimation;
  final VoidCallback? onMarkAsKnown;

  const FlashcardFace({
    super.key,
    required this.card,
    required this.isBack,
    required this.flipAnimation,
    this.onMarkAsKnown,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: flipAnimation,
      builder: (context, child) {
        final angle = flipAnimation.value * math.pi;
        final showingBack = flipAnimation.value >= 0.5;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: showingBack
              ? Transform(
                  transform: Matrix4.identity()..rotateY(math.pi),
                  alignment: Alignment.center,
                  child: _buildCardContent(context, isBack: true),
                )
              : _buildCardContent(context, isBack: false),
        );
      },
    );
  }

  Widget _buildCardContent(BuildContext context, {required bool isBack}) {
    final colors = context.vocaColors;
    final reading = card.reading ?? card.pinyin ?? card.romanization;
    final hasContext = card.contextSentence != null &&
        card.contextSentence!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: VocaRadius.roundedXl,
        border: Border.all(
          color: isBack
              ? colors.accentPrimary.withValues(alpha: 0.35)
              : colors.borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(VocaSpace.spaceBase + 2),
      child: Column(
        children: [
          // 1. Top Bar (POS, Stage, Mark as Known, Audio Speaker)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (card.partOfSpeech != null &&
                        card.partOfSpeech!.trim().isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: VocaRadius.roundedXs,
                          border: Border.all(color: colors.borderColorLight),
                        ),
                        child: Text(
                          _formatPartOfSpeech(card.partOfSpeech!),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(child: _buildStageBadge(context, card, colors)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onMarkAsKnown != null) ...[
                    _buildMarkKnownButton(context, card, colors),
                    const SizedBox(width: 6),
                  ],
                  _buildAudioButton(card, colors),
                ],
              ),
            ],
          ),

          // 2. Center Headword & Meaning Section
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (reading != null && reading.trim().isNotEmpty) ...[
                      Text(
                        reading,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      card.word,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        height: 1.2,
                      ),
                    ),
                    if (isBack) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: VocaRadius.roundedMd,
                          border: Border.all(color: colors.borderColorLight),
                        ),
                        child: Text(
                          card.meaning,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.35,
                          ),
                        ),
                      ),
                      if (card.notes != null && card.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          card.notes!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 3. Sentence Quote at bottom
          if (hasContext) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.bgSecondary,
                borderRadius: VocaRadius.roundedMd,
                border: Border.all(color: colors.borderColorLight),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isBack)
                    Text(
                      card.contextSentence!.replaceAll(card.word, '[ _____ ]'),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    )
                  else ...[
                    RichText(
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      text: _buildHighlightedSentence(
                        card.contextSentence!,
                        card.word,
                        colors,
                      ),
                    ),
                    if (card.contextTranslation != null &&
                        card.contextTranslation!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        card.contextTranslation!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // 4. Tap to flip hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isBack ? Icons.flip_to_back_outlined : Icons.touch_app_outlined,
                size: 13,
                color: colors.textMuted,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  isBack
                      ? context.t('flashcards.tapBackHint', null, 'Tap card to flip back')
                      : context.t('study.tapToFlip', null, 'Tap card to flip'),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageBadge(BuildContext context, Flashcard card, VocaColorPalette colors) {
    final normLevel = card.level.toLowerCase().trim();
    if (normLevel == 'known' || normLevel == 'mastered') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: colors.wordKnownBg,
          borderRadius: VocaRadius.roundedPill,
          border: Border.all(color: colors.wordKnownText.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 11, color: colors.wordKnownText),
            const SizedBox(width: 4),
            Text(
              context.t('study.known', null, 'Known'),
              style: TextStyle(
                color: colors.wordKnownText,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (normLevel == 'new') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: colors.wordNewBg,
          borderRadius: VocaRadius.roundedPill,
          border: Border.all(color: colors.wordNewText.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco_rounded, size: 11, color: colors.wordNewText),
            const SizedBox(width: 4),
            Text(
              context.t('study.new', null, 'New'),
              style: TextStyle(
                color: colors.wordNewText,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Learning stage
    final repText = card.srsRepetition > 0
        ? context.t('study.repetitionCount', {'count': (card.srsRepetition + 1).toString()}, 'Review #${card.srsRepetition + 1}')
        : context.t('study.learning', null, 'Learning');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: colors.wordLearningBg,
        borderRadius: VocaRadius.roundedPill,
        border: Border.all(color: colors.wordLearningText.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timelapse_rounded, size: 11, color: colors.wordLearningText),
          const SizedBox(width: 4),
          Text(
            repText,
            style: TextStyle(
              color: colors.wordLearningText,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkKnownButton(BuildContext context, Flashcard card, VocaColorPalette colors) {
    final isAlreadyKnown = card.level == 'known' || card.level == 'mastered';

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isAlreadyKnown ? colors.wordKnownBg : colors.bgSurface,
        shape: BoxShape.circle,
        border: Border.all(
          color: isAlreadyKnown
              ? colors.wordKnownText.withValues(alpha: 0.4)
              : colors.borderColorLight,
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(
          isAlreadyKnown ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
          size: 16,
          color: isAlreadyKnown ? colors.wordKnownText : colors.textSecondary,
        ),
        tooltip: context.t('study.markKnown', null, 'Mark as Known'),
        onPressed: isAlreadyKnown ? null : onMarkAsKnown,
      ),
    );
  }

  Widget _buildAudioButton(Flashcard card, VocaColorPalette colors) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        shape: BoxShape.circle,
        border: Border.all(color: colors.borderColorLight),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(Icons.volume_up_rounded, size: 16, color: colors.accentPrimary),
        tooltip: 'Listen pronunciation',
        onPressed: () {
          final text = card.reading?.isNotEmpty == true ? card.reading! : card.word;
          AudioService.instance.playWord(text, language: card.language);
        },
      ),
    );
  }

  InlineSpan _buildHighlightedSentence(
    String sentence,
    String word,
    VocaColorPalette colors,
  ) {
    if (!sentence.contains(word)) {
      return TextSpan(
        text: sentence,
        style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
      );
    }

    final spans = <InlineSpan>[];
    final parts = sentence.split(word);

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(
          text: parts[i],
          style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
        ));
      }
      if (i < parts.length - 1) {
        spans.add(TextSpan(
          text: word,
          style: TextStyle(
            color: colors.accentPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
            decoration: TextDecoration.underline,
            decorationColor: colors.accentPrimary.withValues(alpha: 0.5),
          ),
        ));
      }
    }

    return TextSpan(children: spans);
  }

  String _formatPartOfSpeech(String pos) {
    final lower = pos.toLowerCase().trim();
    switch (lower) {
      case 'verb':
        return 'VERB';
      case 'noun':
        return 'NOUN';
      case 'adjective':
      case 'adj':
        return 'ADJ';
      case 'adverb':
      case 'adv':
        return 'ADV';
      default:
        return pos.toUpperCase();
    }
  }
}
