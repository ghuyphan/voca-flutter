// lib/ui/study/widgets/deck_settings_sheet.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/haptic_service.dart';
import '../../../services/i18n_service.dart';
import '../../sheets/voca_bottom_sheet.dart';
import '../study_session_controller.dart';

class DeckSettingsSheet extends StatefulWidget {
  final StudySessionController controller;
  final VoidCallback onApply;

  const DeckSettingsSheet({
    super.key,
    required this.controller,
    required this.onApply,
  });

  static Future<void> show(BuildContext context, StudySessionController controller, VoidCallback onApply) {
    return showVocaBottomSheet(
      context: context,
      title: context.t('study.settingsTitle', null, 'Deck Configuration'),
      showCloseButton: true,
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      builder: (_) => DeckSettingsSheet(controller: controller, onApply: onApply),
    );
  }

  @override
  State<DeckSettingsSheet> createState() => _DeckSettingsSheetState();
}

class _DeckSettingsSheetState extends State<DeckSettingsSheet> {
  late String _subDeck;
  late int? _sessionSize;
  late bool _dueOnly;

  @override
  void initState() {
    super.initState();
    _subDeck = widget.controller.subDeck.value;
    _sessionSize = widget.controller.sessionSize.value;
    _dueOnly = widget.controller.dueOnly.value;
  }

  void _handleApply() {
    final changed = _subDeck != widget.controller.subDeck.value ||
        _sessionSize != widget.controller.sessionSize.value ||
        _dueOnly != widget.controller.dueOnly.value;

    widget.controller.setSubDeck(_subDeck);
    widget.controller.setSessionSize(_sessionSize);
    widget.controller.dueOnly.value = _dueOnly;

    if (!widget.controller.isSessionActive.value || changed) {
      widget.controller.startSession(dueOnlyMode: _dueOnly);
    }
    Navigator.of(context).pop();
    widget.onApply();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final totalCards = widget.controller.allCards.value.length;
    final due = widget.controller.dueCount.value;
    final fresh = widget.controller.newCount.value;
    final learning = widget.controller.learningCount.value;
    final known = widget.controller.knownCount.value;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),

          // 1. Sub-Deck Filter (All / Words / Grammar)
          Text(
            context.t('study.contentType', null, 'CONTENT TYPE'),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTypeChip('all', context.t('study.allTypes', null, 'All Items'), Icons.layers_outlined, colors),
              const SizedBox(width: 8),
              _buildTypeChip('words', context.t('study.wordsOnly', null, 'Words Only'), Icons.text_fields_rounded, colors),
              const SizedBox(width: 8),
              _buildTypeChip('grammar', context.t('study.grammarOnly', null, 'Grammar Only'), Icons.menu_book_rounded, colors),
            ],
          ),
          const SizedBox(height: 18),

          // 2. Session Batch Size
          Text(
            context.t('study.batchSize', null, 'BATCH SIZE'),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildSizeChip(5, context.t('study.cardsCount', {'count': 5}, '5 cards'), colors),
              const SizedBox(width: 8),
              _buildSizeChip(10, context.t('study.cardsCount', {'count': 10}, '10 cards'), colors),
              const SizedBox(width: 8),
              _buildSizeChip(20, context.t('study.cardsCount', {'count': 20}, '20 cards'), colors),
              const SizedBox(width: 8),
              _buildSizeChip(null, context.t('study.allCards', null, 'All'), colors),
            ],
          ),
          const SizedBox(height: 18),

          // 3. Due Only Switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderColorLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('study.reviewDueOnly', null, 'Review Due Cards Only'),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.t('study.reviewDueOnlyDesc', null, 'Study strictly what SM-2 scheduled for today'),
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _dueOnly,
                  onChanged: (val) => setState(() => _dueOnly = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 4. Anki Deck Distribution Forecast
          Text(
            context.t('study.deckMasteryStatus', {'total': totalCards}, 'DECK MASTERY STATUS ($totalCards TOTAL)'),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderColorLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatPill(context.t('study.new', null, 'New'), fresh, colors.wordNewText, colors),
                _buildStatPill(context.t('study.learning', null, 'Learning'), learning, colors.wordLearningText, colors),
                _buildStatPill(context.t('study.due', null, 'Due'), due, colors.colorGrammar, colors),
                _buildStatPill(context.t('study.known', null, 'Known'), known, colors.wordKnownText, colors),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Apply Button
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _handleApply,
              style: FilledButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                context.t('study.applyAndStart', null, 'Apply & Start Deck'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon, VocaColorPalette colors) {
    final isSelected = _subDeck == type;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              HapticService.selection();
              setState(() => _subDeck = type);
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary.withValues(alpha: 0.12) : colors.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? colors.accentPrimary : colors.borderColorLight,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? colors.accentPrimary : colors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? colors.accentPrimary : colors.textSecondary,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSizeChip(int? size, String label, VocaColorPalette colors) {
    final isSelected = _sessionSize == size;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              HapticService.selection();
              setState(() => _sessionSize = size);
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimary.withValues(alpha: 0.12) : colors.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? colors.accentPrimary : colors.borderColorLight,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? colors.accentPrimary : colors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, int count, Color color, VocaColorPalette colors) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
