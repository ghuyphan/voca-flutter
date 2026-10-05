// lib/ui/study/widgets/cloze_face.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../models/voca_models.dart';
import '../../../services/i18n_service.dart';

class ClozeFace extends StatelessWidget {
  final Flashcard card;
  final bool isRevealed;
  final bool isCurrent;

  const ClozeFace({
    super.key,
    required this.card,
    required this.isRevealed,
    this.isCurrent = true,
  });

  String _getClozeSentence(Flashcard card) {
    if (card.contextSentence != null &&
        card.contextSentence!.trim().isNotEmpty &&
        card.contextSentence!.contains(card.word)) {
      return card.contextSentence!;
    }
    return card.contextSentence?.trim().isNotEmpty == true
        ? card.contextSentence!
        : '${card.word} - ${card.meaning}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final rawSentence = _getClozeSentence(card);
    final hasBlank = rawSentence.contains(card.word);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: VocaRadius.roundedLg,
        border: Border.all(
          color: isRevealed
              ? colors.accentPrimary.withValues(alpha: 0.35)
              : colors.borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(VocaSpace.spaceBase + 2),
      child: Column(
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.accentPrimary.withValues(alpha: 0.12),
                  borderRadius: VocaRadius.roundedPill,
                  border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_off_outlined, size: 12, color: colors.accentPrimary),
                    const SizedBox(width: 4),
                    if (isCurrent)
                      Text(
                        context.t('flashcards.clozeTest', null, 'CLOZE TEST'),
                        style: TextStyle(
                          color: colors.accentPrimary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              if (card.partOfSpeech != null && card.partOfSpeech!.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: VocaRadius.roundedXs,
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
          ),

          // Center Cloze Sentence with Blank or Highlighted Word
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: hasBlank
                    ? (isRevealed
                        ? RichText(
                            textAlign: TextAlign.center,
                            text: _buildRevealedSpan(rawSentence, card.word, colors),
                          )
                        : RichText(
                            textAlign: TextAlign.center,
                            text: _buildBlankSpan(rawSentence, card.word, colors),
                          ))
                    : Text(
                        rawSentence,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),

          // Meaning reveal container at bottom
          if (isRevealed) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: VocaRadius.roundedBase,
                border: Border.all(color: colors.borderColorLight),
              ),
              child: Column(
                children: [
                  Text(
                    card.word,
                    style: TextStyle(
                      color: colors.accentPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.meaning,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Footer hint
          Text(
            isRevealed
                ? context.t('study.clozeRevealedHint', null, 'Rate your recall below')
                : context.t('study.clozeTapHint', null, 'Tap or press Reveal Word & Context below'),
            style: TextStyle(color: colors.textMuted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }

  InlineSpan _buildBlankSpan(String sentence, String word, VocaColorPalette colors) {
    final parts = sentence.split(word);
    final spans = <InlineSpan>[];

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(
          text: parts[i],
          style: TextStyle(color: colors.textPrimary, fontSize: 19, height: 1.5),
        ));
      }
      if (i < parts.length - 1) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: colors.accentPrimary.withValues(alpha: 0.14),
              borderRadius: VocaRadius.roundedSm,
              border: Border.all(color: colors.accentPrimary, width: 1.5),
            ),
            child: Text(
              '[ _____ ]',
              style: TextStyle(
                color: colors.accentPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ));
      }
    }
    return TextSpan(children: spans);
  }

  InlineSpan _buildRevealedSpan(String sentence, String word, VocaColorPalette colors) {
    final parts = sentence.split(word);
    final spans = <InlineSpan>[];

    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        spans.add(TextSpan(
          text: parts[i],
          style: TextStyle(color: colors.textPrimary, fontSize: 19, height: 1.5),
        ));
      }
      if (i < parts.length - 1) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colors.colorGrammar.withValues(alpha: 0.16),
              borderRadius: VocaRadius.roundedSm,
              border: Border.all(color: colors.colorGrammar, width: 1.5),
            ),
            child: Text(
              word,
              style: TextStyle(
                color: colors.colorGrammar,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ));
      }
    }
    return TextSpan(children: spans);
  }
}
