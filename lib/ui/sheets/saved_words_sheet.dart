// lib/ui/sheets/saved_words_sheet.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import 'dictionary_bottom_sheet.dart';
import 'voca_bottom_sheet.dart';

class SavedWordsSheet extends StatelessWidget {
  final String videoId;
  final String language;

  const SavedWordsSheet({
    super.key,
    required this.videoId,
    required this.language,
  });

  static Future<void> show(
    BuildContext context, {
    required String videoId,
    required String language,
  }) {
    return showVocaBottomSheet(
      context: context,
      title: context.t('vocab.savedWords', null, 'Saved Vocabulary'),
      showCloseButton: true,
      maxHeightFactor: 0.75,
      contentPadding: EdgeInsets.zero,
      builder: (_) => SavedWordsSheet(
        videoId: videoId,
        language: language,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return FutureBuilder<List<Flashcard>>(
      future: AppState.instance.supabaseService.getVocabularyCards(language: language),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.accentPrimary,
              ),
            ),
          );
        }

        final cards = snapshot.data ?? [];
        if (cards.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 48,
                    color: colors.textMuted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.t('vocab.noSavedWords', null, 'No saved words yet'),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.t('vocab.tapWordHint', null, 'Tap any word in the interactive subtitles to translate and save it to your SRS deck.'),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          shrinkWrap: true,
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final card = cards[index];

            return InkWell(
              onTap: () {
                final token = Token(
                  surface: card.word,
                  reading: card.reading,
                  romanization: card.romanization,
                  pinyin: card.pinyin,
                  partOfSpeech: card.partOfSpeech,
                );
                DictionaryBottomSheet.show(
                  context,
                  token: token,
                  sourceLang: language,
                  contextSentence: card.contextSentence,
                  contextTranslation: card.contextTranslation,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                card.word,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (card.reading != null && card.reading!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  card.reading!,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (card.meaning.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              card.meaning,
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 12.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.accentPrimarySoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        card.level.toUpperCase(),
                        style: TextStyle(
                          color: colors.accentPrimary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
