// lib/ui/sheets/grammar_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../../state/player_coordinator.dart';
import '../../utils/cyrb53_hasher.dart';
import '../widgets/voca_level_badge.dart';
import 'dictionary_bottom_sheet.dart';
import 'voca_bottom_sheet.dart';

/// Modal bottom sheet for inspecting grammar patterns.
/// Ported 1:1 from lingua-tube's grammar-popup component:
/// - Title & 5-tier educational level badge
/// - Formation section with formula box
/// - Explanation section with collapsible "More details" for extended explanations
/// - Numbered authentic example sentences (sentence, romanization, translation)
/// - Footer actions: "+ Save Grammar" (with saved checkmark toggle) + "Dictionary" lookup button
class GrammarBottomSheet extends StatefulWidget {
  final GrammarPattern pattern;

  const GrammarBottomSheet({super.key, required this.pattern});

  static Future<void> show(BuildContext context, GrammarPattern pattern) {
    return showVocaBottomSheet(
      context: context,
      showCloseButton: true,
      maxHeightFactor: 0.88,
      contentPadding: EdgeInsets.zero,
      builder: (ctx) => GrammarBottomSheet(pattern: pattern),
    );
  }

  @override
  State<GrammarBottomSheet> createState() => _GrammarBottomSheetState();
}

class _GrammarBottomSheetState extends State<GrammarBottomSheet> {
  bool _isMoreDetailsOpen = false;
  bool _isSaved = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
    _loadTranslationIfNeeded();
  }

  void _loadTranslationIfNeeded() {
    final uiLang = I18nService.instance.currentLanguage.value;
    if (uiLang != 'en') {
      AppState.instance.grammarEngine.loadTranslation(widget.pattern.language, uiLang);
    }
  }

  void _checkSavedStatus() {
    try {
      final supabase = AppState.instance.supabaseService;
      final existingCard = supabase.getCardByWord(
        widget.pattern.pattern,
        language: widget.pattern.language,
      );
      if (existingCard != null) {
        setState(() {
          _isSaved = true;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveGrammar() async {
    if (_isSaving || _isSaved) return;
    setState(() => _isSaving = true);

    try {
      final supabase = AppState.instance.supabaseService;
      final userId = supabase.currentUser?.id ?? 'guest';
      final uiLang = I18nService.instance.currentLanguage.value;
      final p = AppState.instance.grammarEngine.getLocalizedPattern(widget.pattern, uiLang);

      final id = generateDeterministicRecordId([
        userId,
        p.pattern.toLowerCase(),
        p.language,
      ]);

      final card = Flashcard(
        id: id,
        userId: userId,
        word: p.pattern,
        meaning: p.shortExplanation.isNotEmpty ? p.shortExplanation : p.title,
        language: p.language,
        level: 'new',
        partOfSpeech: 'grammar',
        contextSentence: p.examples.isNotEmpty ? p.examples.first.sentence : null,
        contextTranslation: p.examples.isNotEmpty ? p.examples.first.translation : null,
        notes: p.formation.isNotEmpty ? 'Formation: ${p.formation}' : null,
        srsNextReviewAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await AppState.instance.vocabularyService.upsertCard(card, notifyGamification: true);

      final playerCtrl = PlayerCoordinator.instance.playerController;
      if (playerCtrl != null) {
        playerCtrl.savedWordCount.value++;
      }

      if (mounted) {
        setState(() {
          _isSaved = true;
          _isSaving = false;
        });
        ToastService.success(
          context,
          context.t(
            'grammar.saveSuccess',
            {'pattern': p.pattern},
            'Added "${p.pattern}" to grammar notebook',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ToastService.error(context, 'Failed to save grammar: $e');
      }
    }
  }

  void _lookupInDictionary() {
    Navigator.of(context).pop();
    DictionaryBottomSheet.show(
      context,
      token: Token(
        surface: widget.pattern.pattern,
        baseForm: widget.pattern.pattern,
        partOfSpeech: 'grammar',
      ),
      sourceLang: widget.pattern.language,
    );
  }

  bool _hasLongDetails(GrammarPattern p) {
    return p.longExplanation.isNotEmpty &&
        p.longExplanation != p.shortExplanation &&
        p.longExplanation.length > p.shortExplanation.length + 30;
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final colors = context.vocaColors;
      final uiLang = I18nService.instance.currentLanguage.value;
      // Re-evaluate reactively when translation pack finishes loading
      AppState.instance.grammarEngine.loadedTranslations.value;

      final p = AppState.instance.grammarEngine.getLocalizedPattern(widget.pattern, uiLang);

      return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scrollable Body
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header (Centered: Pattern Name + Standard Level Badge underneath)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p.pattern,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (p.level.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        VocaLevelBadge(
                          level: p.level,
                          size: LevelBadgeSize.medium,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Formation Section
                if (p.formation.isNotEmpty) ...[
                  Text(
                    context.t('grammar.formation', null, 'Cấu trúc'),
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: Text(
                      p.formation,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. Explanation Section
                Text(
                  context.t('grammar.explanation', null, 'Giải thích'),
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  p.shortExplanation.isNotEmpty ? p.shortExplanation : p.longExplanation,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14.5,
                    height: 1.5,
                  ),
                ),

                // Collapsible "More details"
                if (_hasLongDetails(p)) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isMoreDetailsOpen = !_isMoreDetailsOpen;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.t('grammar.moreDetails', null, 'Chi tiết thêm'),
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isMoreDetailsOpen
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isMoreDetailsOpen) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.borderColor),
                      ),
                      child: Text(
                        p.longExplanation,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 16),

                // 4. Examples Section
                if (p.examples.isNotEmpty) ...[
                  Text(
                    context.t('grammar.examples', null, 'Ví dụ'),
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...p.examples.take(3).toList().asMap().entries.map((entry) {
                    final idx = entry.key;
                    final ex = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(top: 2, right: 10),
                            decoration: BoxDecoration(
                              color: colors.bgSurface,
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.borderColor),
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ex.sentence,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    height: 1.35,
                                  ),
                                ),
                                if (ex.romanization != null && ex.romanization!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    ex.romanization!,
                                    style: TextStyle(
                                      color: colors.textMuted,
                                      fontSize: 12.5,
                                      fontStyle: FontStyle.italic,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 2),
                                Text(
                                  ex.translation,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 13.5,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),

        // 5. Sticky Bottom Footer Actions (Save Grammar + Dictionary)
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            color: colors.bgCard,
            border: Border(top: BorderSide(color: colors.borderColorLight)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Save Grammar / Saved button
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 48,
                    child: _isSaved
                        ? Container(
                            decoration: BoxDecoration(
                              color: colors.bgSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.borderColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded, color: colors.success, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  context.t('grammar.saved', null, 'Saved'),
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: _isSaving ? null : _saveGrammar,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.bookmark_add_outlined, size: 18),
                            label: Text(
                              context.t('grammar.savePattern', null, 'Save Grammar'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.accentPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),

                // Open in Dictionary button
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _lookupInDictionary,
                      icon: Icon(Icons.menu_book_rounded, size: 18, color: colors.textPrimary),
                      label: Text(
                        context.t('dictionary.title', null, 'Dictionary'),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.borderColor),
                        backgroundColor: colors.bgSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    });
  }
}
