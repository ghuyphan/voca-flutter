// lib/ui/vocabulary/word_detail_sheet.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Word', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to remove "${_card.word}" from your vocabulary notebook?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
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
    final levelColor = _getLevelColor(_card.level);
    final readingDisplay = _card.reading ?? _card.pinyin ?? _card.romanization;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              color: Colors.white24,
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
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
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
                                        color: Color(0xFF94A3B8),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  Text(
                                    _card.word,
                                    style: const TextStyle(
                                      color: Colors.white,
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
                                        color: Colors.white38,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Audio Pronunciation Button
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
                                        ? const Color(0xFF6366F1)
                                        : const Color(0xFF334155),
                                    foregroundColor: Colors.white,
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
                            // Level Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: levelColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: levelColor.withOpacity(0.4)),
                              ),
                              child: Text(
                                _card.level.toUpperCase(),
                                style: TextStyle(
                                  color: levelColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // Part of Speech Badge
                            if (_card.partOfSpeech != null && _card.partOfSpeech!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _card.partOfSpeech!.toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFFCBD5E1),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                            // Language Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _card.language.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white54,
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
                      color: Color(0xFF64748B),
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
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      _card.meaning.isNotEmpty ? _card.meaning : 'No definition available',
                      style: const TextStyle(
                        color: Color(0xFFF1F5F9),
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
                            color: Color(0xFF64748B),
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
                          child: const Row(
                            children: [
                              Icon(Icons.volume_up, size: 16, color: Color(0xFF6366F1)),
                              SizedBox(width: 4),
                              Text(
                                'Listen',
                                style: TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _card.contextSentence!,
                            style: const TextStyle(
                              color: Colors.white,
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
                                color: Color(0xFF94A3B8),
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
                      color: Color(0xFF64748B),
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
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        _buildStatRow(
                          icon: Icons.repeat,
                          label: 'Repetitions',
                          value: '${_card.srsRepetition} times',
                        ),
                        const Divider(color: Colors.white10, height: 16),
                        _buildStatRow(
                          icon: Icons.calendar_today,
                          label: 'Current Interval',
                          value: '${_card.srsInterval} days',
                        ),
                        const Divider(color: Colors.white10, height: 16),
                        _buildStatRow(
                          icon: Icons.trending_up,
                          label: 'Ease Factor',
                          value: _card.srsEaseFactor.toStringAsFixed(2),
                        ),
                        const Divider(color: Colors.white10, height: 16),
                        _buildStatRow(
                          icon: Icons.alarm,
                          label: 'Next Review',
                          value: '${_formatDate(_card.srsNextReviewAt)} (${_formatRelativeDays(_card.srsNextReviewAt)})',
                          highlight: _card.srsNextReviewAt.isBefore(DateTime.now()),
                        ),
                        if (_card.srsLastReviewedAt != null) ...[
                          const Divider(color: Colors.white10, height: 16),
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
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['new', 'learning', 'known', 'mastered'].map((lvl) {
                      final isSelected = _card.level == lvl;
                      final col = _getLevelColor(lvl);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: OutlinedButton(
                            onPressed: _isSaving ? null : () => _updateLevel(lvl),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isSelected ? col.withOpacity(0.2) : Colors.transparent,
                              side: BorderSide(
                                color: isSelected ? col : Colors.white24,
                                width: isSelected ? 2 : 1,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              lvl[0].toUpperCase() + lvl.substring(1),
                              style: TextStyle(
                                color: isSelected ? col : Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
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
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF10B981),
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
                          backgroundColor: const Color(0xFFEF4444).withOpacity(0.15),
                          foregroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.all(14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
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
        Icon(icon, size: 16, color: highlight ? const Color(0xFFEF4444) : Colors.white54),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: highlight ? const Color(0xFFF87171) : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
