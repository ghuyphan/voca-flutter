// lib/ui/study/widgets/quiz_face.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../models/voca_models.dart';
import '../../../services/i18n_service.dart';

class QuizFace extends StatelessWidget {
  final Flashcard card;
  final List<String> options;
  final int? selectedOption;
  final bool isAnswered;
  final bool isCurrent;
  final ValueChanged<int> onSelectOption;

  const QuizFace({
    super.key,
    required this.card,
    required this.options,
    required this.selectedOption,
    required this.isAnswered,
    this.isCurrent = true,
    required this.onSelectOption,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final reading = card.reading ?? card.pinyin ?? card.romanization;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: VocaRadius.roundedLg,
        border: Border.all(
          color: isAnswered
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
      padding: const EdgeInsets.all(VocaSpace.spaceBase),
      child: Column(
        children: [
          // Prompt Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.accentSecondary.withValues(alpha: 0.14),
                  borderRadius: VocaRadius.roundedPill,
                  border: Border.all(color: colors.accentSecondary.withValues(alpha: 0.28)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.quiz_outlined, size: 12, color: colors.accentSecondary),
                    const SizedBox(width: 4),
                    Text(
                      context.t('flashcards.quizMode', null, 'QUIZ MODE'),
                      style: TextStyle(
                        color: colors.accentSecondary,
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

          const SizedBox(height: 12),

          // Headword Anchor
          if (reading != null && reading.trim().isNotEmpty) ...[
            Text(
              reading,
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            card.word,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          // Explicit prompt label (matches widget test finders!)
          if (isCurrent)
            Text(
              context.t('flashcards.chooseDefinition', null, 'Choose the correct definition:'),
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),

          const SizedBox(height: 12),

          // Options List
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: options.length,
              separatorBuilder: (context, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = selectedOption == index;
                final isCorrect = option == card.meaning.trim();

                Color itemBg = colors.bgSurface;
                Color itemBorder = colors.borderColorLight;
                Color textColor = colors.textPrimary;
                Widget? trailingIcon;

                if (isAnswered) {
                  if (isCorrect) {
                    itemBg = colors.colorGrammar.withValues(alpha: 0.15);
                    itemBorder = colors.colorGrammar;
                    textColor = colors.colorGrammar;
                    trailingIcon = Icon(Icons.check_circle_rounded, size: 18, color: colors.colorGrammar);
                  } else if (isSelected) {
                    itemBg = colors.error.withValues(alpha: 0.15);
                    itemBorder = colors.error;
                    textColor = colors.error;
                    trailingIcon = Icon(Icons.cancel_rounded, size: 18, color: colors.error);
                  }
                }

                return InkWell(
                  onTap: isAnswered ? null : () => onSelectOption(index),
                  borderRadius: VocaRadius.roundedMd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: itemBg,
                      borderRadius: VocaRadius.roundedMd,
                      border: Border.all(color: itemBorder, width: isSelected || (isAnswered && isCorrect) ? 1.5 : 1.0),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.bgCard,
                            border: Border.all(color: itemBorder),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + index), // A, B, C, D
                              style: TextStyle(
                                color: textColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
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
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (trailingIcon != null) trailingIcon,
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
}
