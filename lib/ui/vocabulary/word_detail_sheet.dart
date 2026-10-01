// lib/ui/vocabulary/word_detail_sheet.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/audio_service.dart';
import '../../state/app_state.dart';

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
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

  Future<void> _updateLevel(String newLevel) async {
    setState(() => _isSaving = true);
    final updated = _card.copyWith(
      level: newLevel,
      srsRepetition: newLevel == 'mastered' ? 5 : _card.srsRepetition,
      srsInterval: newLevel == 'mastered' ? 15 : _card.srsInterval,
    );

    await AppState.instance.supabaseService.upsertVocabularyCard(updated);
    if (mounted) {
      setState(() {
        _card = updated;
        _isSaving = false;
      });
      widget.onCardUpdated?.call();
    }
  }

  Future<void> _toggleMastery() async {
    final nextLevel = _card.level == 'mastered' ? 'learning' : 'mastered';
    await _updateLevel(nextLevel);
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VocaTokens.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: VocaTokens.borderColor),
        ),
        title: const Text('Delete Word', style: TextStyle(color: VocaTokens.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove "${_card.word}" from your vocabulary notebook?',
          style: const TextStyle(color: VocaTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: VocaTokens.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: VocaTokens.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.of(context).pop();
      await AppState.instance.supabaseService.deleteVocabularyCard(_card.id);
      widget.onCardDeleted?.call();
    }
  }

  String _formatDate(DateTime dt) {
    return DateFormat('MMM d, yyyy').format(dt);
  }

  String _formatRelativeDays(DateTime dt) {
    final now = DateTime.now();
    final difference = dt.difference(now).inDays;
    if (dt.isBefore(now)) {
      return 'Due now';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else {
      return 'In $difference days';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mastery = _getMasteryColors(_card.level);
    final readingDisplay = _card.reading ?? _card.pinyin ?? _card.romanization;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= VocaTokens.tabletBreakpoint;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 600 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: VocaTokens.bgPrimary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: VocaTokens.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: VocaTokens.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Word Header Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: VocaTokens.bgCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: VocaTokens.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (readingDisplay != null && readingDisplay.isNotEmpty) ...[
                                        Text(
                                          readingDisplay,
                                          style: const TextStyle(
                                            color: VocaTokens.textSecondary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                      ],
                                      Text(
                                        _card.word,
                                        style: const TextStyle(
                                          color: VocaTokens.textPrimary,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      if (_card.reading != null && _card.romanization != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          _card.romanization!,
                                          style: const TextStyle(
                                            color: VocaTokens.textTertiary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Audio Pronunciation Button (Radiant Coral accent)
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
                                            ? VocaTokens.accentPrimary
                                            : VocaTokens.bgSurface,
                                        foregroundColor: isPlaying
                                            ? Colors.white
                                            : VocaTokens.accentPrimary,
                                        side: const BorderSide(color: VocaTokens.borderColor),
                                        padding: const EdgeInsets.all(12),
                                      ),
                                      icon: Icon(
                                        isPlaying ? Icons.volume_up : Icons.volume_up_outlined,
                                        size: 22,
                                      ),
                                      tooltip: 'Listen pronunciation',
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Badges Row
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                // Level Badge with authentic LinguaTube colors
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: mastery.bg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: mastery.text.withOpacity(0.35)),
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
                                      color: VocaTokens.bgSurface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: VocaTokens.borderColorLight),
                                    ),
                                    child: Text(
                                      _card.partOfSpeech!.toUpperCase(),
                                      style: const TextStyle(
                                        color: VocaTokens.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                // Language Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: VocaTokens.bgSurface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: VocaTokens.borderColorLight),
                                  ),
                                  child: Text(
                                    _card.language.toUpperCase(),
                                    style: const TextStyle(
                                      color: VocaTokens.textMuted,
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
                      const Text(
                        'DEFINITIONS',
                        style: TextStyle(
                          color: VocaTokens.textMuted,
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
                          color: VocaTokens.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: VocaTokens.borderColor),
                        ),
                        child: Text(
                          _card.meaning.isNotEmpty ? _card.meaning : 'No definition available',
                          style: const TextStyle(
                            color: VocaTokens.textPrimary,
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
                            const Text(
                              'VIDEO CONTEXT SENTENCE',
                              style: TextStyle(
                                color: VocaTokens.textMuted,
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
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(Icons.volume_up, size: 16, color: VocaTokens.accentPrimary),
                                    SizedBox(width: 4),
                                    Text(
                                      'Listen',
                                      style: TextStyle(
                                        color: VocaTokens.accentPrimary,
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
                            color: VocaTokens.bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: VocaTokens.accentPrimary.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _card.contextSentence!,
                                style: const TextStyle(
                                  color: VocaTokens.textPrimary,
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
                                  style: const TextStyle(
                                    color: VocaTokens.textSecondary,
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
                      const Text(
                        'SPACED REPETITION (SM-2) STATS',
                        style: TextStyle(
                          color: VocaTokens.textMuted,
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
                          color: VocaTokens.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: VocaTokens.borderColor),
                        ),
                        child: Column(
                          children: [
                            _buildStatRow(
                              icon: Icons.repeat,
                              label: 'Repetitions',
                              value: '${_card.srsRepetition} times',
                            ),
                            const Divider(color: VocaTokens.borderColorLight, height: 16),
                            _buildStatRow(
                              icon: Icons.calendar_today,
                              label: 'Current Interval',
                              value: '${_card.srsInterval} days',
                            ),
                            const Divider(color: VocaTokens.borderColorLight, height: 16),
                            _buildStatRow(
                              icon: Icons.trending_up,
                              label: 'Ease Factor',
                              value: _card.srsEaseFactor.toStringAsFixed(2),
                            ),
                            const Divider(color: VocaTokens.borderColorLight, height: 16),
                            _buildStatRow(
                              icon: Icons.alarm,
                              label: 'Next Review',
                              value: '${_formatDate(_card.srsNextReviewAt)} (${_formatRelativeDays(_card.srsNextReviewAt)})',
                              highlight: _card.srsNextReviewAt.isBefore(DateTime.now()),
                            ),
                            if (_card.srsLastReviewedAt != null) ...[
                              const Divider(color: VocaTokens.borderColorLight, height: 16),
                              _buildStatRow(
                                icon: Icons.history,
                                label: 'Last Reviewed',
                                value: _formatDate(_card.srsLastReviewedAt!),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Mastery Level Quick Picker
                      const Text(
                        'SET MASTERY STAGE',
                        style: TextStyle(
                          color: VocaTokens.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: ['new', 'learning', 'known', 'mastered'].map((lvl) {
                          final isSelected = _card.level.toLowerCase() == lvl;
                          final col = _getMasteryColors(lvl);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: OutlinedButton(
                                onPressed: _isSaving ? null : () => _updateLevel(lvl),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: isSelected ? col.bg : Colors.transparent,
                                  side: BorderSide(
                                    color: isSelected ? col.text : VocaTokens.borderColor,
                                    width: isSelected ? 1.8 : 1,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(
                                  lvl[0].toUpperCase() + lvl.substring(1),
                                  style: TextStyle(
                                    color: isSelected ? col.text : VocaTokens.textSecondary,
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
                          // Toggle Mastery Button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _toggleMastery,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _card.level == 'mastered'
                                    ? VocaTokens.warning
                                    : VocaTokens.colorGrammar,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: Icon(
                                _card.level == 'mastered' ? Icons.undo : Icons.check_circle_outline,
                                size: 18,
                              ),
                              label: Text(
                                _card.level == 'mastered' ? 'Move to Learning' : 'Mark as Mastered',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Delete Button
                          IconButton.filled(
                            onPressed: _isSaving ? null : _confirmDelete,
                            style: IconButton.styleFrom(
                              backgroundColor: VocaTokens.error.withOpacity(0.12),
                              foregroundColor: VocaTokens.error,
                              padding: const EdgeInsets.all(14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: VocaTokens.error.withOpacity(0.5), width: 1.2),
                              ),
                            ),
                            icon: const Icon(Icons.delete_outline, size: 20),
                            tooltip: 'Delete word',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
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
    bool highlight = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: highlight ? VocaTokens.error : VocaTokens.textMuted),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: VocaTokens.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: highlight ? VocaTokens.error : VocaTokens.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
