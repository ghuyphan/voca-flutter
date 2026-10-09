// lib/ui/vocabulary/word_detail_sheet.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/audio_service.dart';
import '../../services/i18n_service.dart';
import '../../services/srs_service.dart';
import '../../services/toast_service.dart';
import '../../services/vocabulary_service.dart';
import '../sheets/voca_bottom_sheet.dart';
import '../widgets/voca_confirm_dialog.dart';

class WordDetailSheet extends StatefulWidget {
  final Flashcard card;
  final VoidCallback? onCardUpdated;
  final VoidCallback? onCardDeleted;

  const WordDetailSheet({
    super.key,
    required this.card,
    this.onCardUpdated,
    this.onCardDeleted,
  });

  static Future<void> show(
    BuildContext context, {
    required Flashcard card,
    VoidCallback? onCardUpdated,
    VoidCallback? onCardDeleted,
  }) {
    return showVocaBottomSheet(
      context: context,
      showCloseButton: true,
      maxHeightFactor: 0.90,
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      builder: (ctx) => WordDetailSheet(
        card: card,
        onCardUpdated: onCardUpdated,
        onCardDeleted: onCardDeleted,
      ),
    );
  }

  @override
  State<WordDetailSheet> createState() => _WordDetailSheetState();
}

class _WordDetailSheetState extends State<WordDetailSheet> {
  late Flashcard _card;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _card = widget.card;
  }

  ({Color bg, Color text}) _getMasteryColors(String level, VocaColorPalette colors) {
    switch (WordLevels.normalize(level)) {
      case 'known':
        return (bg: colors.wordKnownBg, text: colors.wordKnownText);
      case 'learning':
        return (bg: colors.wordLearningBg, text: colors.wordLearningText);
      case 'ignored':
        return (bg: colors.bgSurface, text: colors.textMuted);
      case 'new':
      default:
        return (bg: colors.wordNewBg, text: colors.wordNewText);
    }
  }

  Future<void> _updateLevel(String newLevel) async {
    setState(() => _isSaving = true);
    final normLevel = WordLevels.normalize(newLevel);
    final seed = SpacedRepetitionService.seedSrsParamsForLevel(normLevel);
    final updated = _card.copyWith(
      level: normLevel,
      srsRepetition: seed.repetition,
      srsInterval: seed.interval,
      srsEaseFactor: seed.easeFactor,
      srsNextReviewAt: seed.nextReviewAt,
    );

    await VocabularyService.instance.upsertCard(updated);
    if (mounted) {
      setState(() {
        _card = updated;
        _isSaving = false;
      });
      widget.onCardUpdated?.call();
      ToastService.success(context, 'Stage updated to ${normLevel.toUpperCase()}');
    }
  }

  Future<void> _deleteCard() async {
    final confirmed = await showVocaConfirmDialog(
      context: context,
      title: context.t('vocab.deleteWord', null, 'Delete Word'),
      message: context.t('vocab.deleteWordConfirm', {'word': _card.word}, 'Are you sure you want to remove "${_card.word}" from your vocabulary notebook?'),
      variant: ConfirmDialogVariant.danger,
      confirmText: context.t('common.delete', null, 'Delete'),
    );

    if (confirmed && mounted) {
      setState(() => _isSaving = true);
      await VocabularyService.instance.deleteCard(_card);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCardDeleted?.call();
        ToastService.info(context, context.t('vocab.wordRemoved', null, 'Word removed from vocabulary'));
      }
    }
  }

  Future<void> _editNotes() async {
    final controller = TextEditingController(text: _card.notes ?? '');
    final colors = context.vocaColors;

    String? newNotes;
    try {
      newNotes = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: colors.bgCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colors.borderColor),
            ),
            title: Text(context.t('vocab.editNotes', null, 'Edit Notes'), style: TextStyle(color: colors.textPrimary)),
            content: TextField(
              controller: controller,
              maxLines: 4,
              style: TextStyle(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: context.t('vocab.notesHint', null, 'Add personal mnemonic or memory hook...'),
                hintStyle: TextStyle(color: colors.textMuted),
                filled: true,
                fillColor: colors.bgSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: colors.accentPrimary),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.t('common.cancel', null, 'Cancel'), style: TextStyle(color: colors.textSecondary)),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.t('common.save', null, 'Save')),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }

    if (newNotes != null && mounted) {
      setState(() => _isSaving = true);
      final updated = _card.copyWith(notes: newNotes);
      await VocabularyService.instance.upsertCard(updated);
      if (mounted) {
        setState(() {
          _card = updated;
          _isSaving = false;
        });
        widget.onCardUpdated?.call();
      }
    }
  }

  String _formatDate(DateTime dt) {
    return DateFormat('MMM d, yyyy').format(dt);
  }

  String _formatRelativeDays(DateTime dt) {
    final now = DateTime.now();
    final difference = dt.difference(now).inDays;
    if (dt.isBefore(now)) {
      return context.t('study.dueNow', null, 'Due now');
    } else if (difference == 0) {
      return context.t('study.today', null, 'Today');
    } else if (difference == 1) {
      return context.t('study.tomorrow', null, 'Tomorrow');
    } else if (difference >= 365) {
      return 'In 1 year';
    } else if (difference >= 30) {
      return 'In ${(difference / 30).round()} months';
    } else {
      return context.t('study.inDays', {'days': difference.toString()}, 'In $difference days');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final mastery = _getMasteryColors(_card.level, colors);
    final readingDisplay = _card.reading ?? _card.pinyin ?? _card.romanization;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= VocaTokens.tabletBreakpoint;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 600 : double.infinity,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Word Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (readingDisplay != null && readingDisplay.isNotEmpty) ...[
                      Text(
                        readingDisplay,
                        style: TextStyle(
                          color: colors.accentPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _card.word,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                              fontFamily: switch (_card.language.toLowerCase()) {
                                'ja' || 'japanese' => 'Kosugi Maru',
                                'zh' || 'chinese' => 'Noto Sans SC',
                                'ko' || 'korean' => 'Noto Sans KR',
                                _ => null,
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Audio Pronunciation Button Inline (Clear of top-right close button)
                        ValueListenableBuilder<String?>(
                          valueListenable: AudioService.instance.currentPlaying,
                          builder: (context, playing, _) {
                            final isPlaying = playing == _card.word;
                            return IconButton.filled(
                              onPressed: () {
                                AudioService.instance.playWord(
                                  _card.word,
                                  language: _card.language,
                                  fallbackAudioUrl: _card.audio,
                                );
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: isPlaying
                                    ? colors.accentPrimary
                                    : colors.bgSurface,
                                foregroundColor: isPlaying
                                    ? Colors.white
                                    : colors.accentPrimary,
                                side: BorderSide(color: colors.borderColor),
                                padding: const EdgeInsets.all(8),
                                minimumSize: const Size(36, 36),
                              ),
                              icon: Icon(
                                isPlaying ? Icons.volume_up : Icons.volume_up_outlined,
                                size: 19,
                              ),
                              tooltip: context.t('audio.pronounce', null, 'Listen pronunciation'),
                            );
                          },
                        ),
                      ],
                    ),
                    if (_card.reading != null && _card.romanization != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _card.romanization!,
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Badges Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        // Level Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: mastery.bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: mastery.text.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            _card.level.toUpperCase(),
                            style: TextStyle(
                              color: mastery.text,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        // Part of Speech Badge
                        if (_card.partOfSpeech != null && _card.partOfSpeech!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.bgSurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colors.borderColorLight),
                            ),
                            child: Text(
                              _card.partOfSpeech!.toUpperCase(),
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                        // Language Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.bgSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.borderColorLight),
                          ),
                          child: Text(
                            _card.language.toUpperCase(),
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Definition Section
              Text(
                context.t('dict.definitions', null, 'DEFINITIONS').toUpperCase(),
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Text(
                  _card.meaning.isNotEmpty ? _card.meaning : context.t('vocab.noDefinition', null, 'No definition available'),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ),

              // Context Sentence Section
              if (_card.contextSentence != null && _card.contextSentence!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.t('vocab.videoContextSentence', null, 'VIDEO CONTEXT SENTENCE').toUpperCase(),
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        AudioService.instance.playWord(
                          _card.contextSentence!,
                          language: _card.language,
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.volume_up, size: 16, color: colors.accentPrimary),
                            const SizedBox(width: 4),
                            Text(
                              'Listen',
                              style: TextStyle(
                                color: colors.accentPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _card.contextSentence!,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      if (_card.contextTranslation != null &&
                          _card.contextTranslation!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _card.contextTranslation!,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // SRS Statistics Section
              Text(
                context.t('vocab.srsStats', null, 'SPACED REPETITION (SM-2) STATS').toUpperCase(),
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Column(
                  children: [
                    _buildStatRow(
                      icon: Icons.repeat,
                      label: context.t('study.repetitions', null, 'Repetitions'),
                      value: '${_card.srsRepetition} ${context.t('study.times', null, 'times')}',
                      colors: colors,
                    ),
                    Divider(color: colors.borderColorLight, height: 16),
                    _buildStatRow(
                      icon: Icons.calendar_today,
                      label: context.t('study.currentInterval', null, 'Current Interval'),
                      value: '${_card.srsInterval.clamp(0, 365)} ${context.t('study.days', null, 'days')}',
                      colors: colors,
                    ),
                    Divider(color: colors.borderColorLight, height: 16),
                    _buildStatRow(
                      icon: Icons.trending_up,
                      label: context.t('study.easeFactor', null, 'Ease Factor'),
                      value: _card.srsEaseFactor.toStringAsFixed(2),
                      colors: colors,
                    ),
                    Divider(color: colors.borderColorLight, height: 16),
                    _buildStatRow(
                      icon: Icons.alarm,
                      label: context.t('study.nextReview', null, 'Next Review'),
                      value: '${_formatDate(_card.srsNextReviewAt)} (${_formatRelativeDays(_card.srsNextReviewAt)})',
                      highlight: _card.srsNextReviewAt.isBefore(DateTime.now()),
                      colors: colors,
                    ),
                    if (_card.srsLastReviewedAt != null) ...[
                      Divider(color: colors.borderColorLight, height: 16),
                      _buildStatRow(
                        icon: Icons.history,
                        label: context.t('study.lastReviewed', null, 'Last Reviewed'),
                        value: _formatDate(_card.srsLastReviewedAt!),
                        colors: colors,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Mastery Level Quick Picker
              Text(
                context.t('vocab.setMasteryStage', null, 'SET MASTERY STAGE').toUpperCase(),
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: WordLevels.all.map((lvl) {
                  final isSelected = WordLevels.normalize(_card.level) == lvl;
                  final col = _getMasteryColors(lvl, colors);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => _updateLevel(lvl),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isSelected ? col.bg : Colors.transparent,
                          side: BorderSide(
                            color: isSelected ? col.text : colors.borderColor,
                            width: isSelected ? 1.6 : 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          lvl[0].toUpperCase() + lvl.substring(1),
                          style: TextStyle(
                            color: isSelected ? col.text : colors.textSecondary,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  // Edit Notes Primary Action
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _isSaving ? null : _editNotes,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.bgSurface,
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: Icon(Icons.edit_note_rounded, size: 20, color: colors.accentPrimary),
                      label: Text(
                        _card.notes?.isNotEmpty == true
                            ? context.t('vocab.editNotes', null, 'Edit Notes')
                            : context.t('vocab.addNotes', null, 'Add Notes / Mnemonic'),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Delete Card Button
                  IconButton.outlined(
                    onPressed: _isSaving ? null : _deleteCard,
                    style: IconButton.styleFrom(
                      foregroundColor: colors.error,
                      backgroundColor: colors.bgSurface,
                      side: BorderSide(color: colors.error.withValues(alpha: 0.35)),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    tooltip: context.t('vocab.deleteWord', null, 'Delete word'),
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

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required VocaColorPalette colors,
    bool highlight = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: highlight ? colors.error : colors.textMuted),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: highlight ? colors.error : colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
