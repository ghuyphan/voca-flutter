// lib/ui/sheets/dictionary_bottom_sheet.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/audio_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../../utils/cyrb53_hasher.dart';
import '../../utils/pos_utils.dart';
import 'voca_bottom_sheet.dart';

/// Modal bottom sheet for looking up words from subtitle tokens.
/// Aligns with lingua-tube's word-popup component:
/// - Single unified header provided by showVocaBottomSheet (drag handle + close button)
/// - Centered reading, headword, base form, and circular audio pronunciation button
/// - Centered badges (localized Part of Speech & exam level badge)
/// - Numbered definition list
/// - Styled example sentences box
/// - Sticky bottom footer with full-width "Save Word" or "Saved" state
class DictionaryBottomSheet extends StatefulWidget {
  final Token token;
  final String sourceLang;
  final String explanationLang;
  final String? contextSentence;
  final String? contextTranslation;

  const DictionaryBottomSheet({
    super.key,
    required this.token,
    required this.sourceLang,
    this.explanationLang = 'vi',
    this.contextSentence,
    this.contextTranslation,
  });

  static Future<void> show(
    BuildContext context, {
    required Token token,
    required String sourceLang,
    String explanationLang = 'vi',
    String? contextSentence,
    String? contextTranslation,
  }) {
    return showVocaBottomSheet(
      context: context,
      showCloseButton: true,
      maxHeightFactor: 0.88,
      contentPadding: EdgeInsets.zero,
      builder: (ctx) => DictionaryBottomSheet(
        token: token,
        sourceLang: sourceLang,
        explanationLang: explanationLang,
        contextSentence: contextSentence,
        contextTranslation: contextTranslation,
      ),
    );
  }

  @override
  State<DictionaryBottomSheet> createState() => _DictionaryBottomSheetState();
}

class _DictionaryBottomSheetState extends State<DictionaryBottomSheet> {
  DictionaryResult? _result;
  int _activeEntryIndex = 0;
  bool _isLoading = true;
  String? _error;
  bool _isSaved = false;
  String _currentLevel = 'new';
  Flashcard? _savedCard;
  bool _isSaving = false;

  DictionaryEntry? get _activeEntry {
    if (_result == null || _result!.entries.isEmpty) return null;
    if (_activeEntryIndex >= 0 && _activeEntryIndex < _result!.entries.length) {
      return _result!.entries[_activeEntryIndex];
    }
    return _result!.entries.first;
  }

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
    _fetchDefinition();
  }

  void _checkSavedStatus() {
    try {
      final supabase = AppState.instance.supabaseService;
      final surface = widget.token.surface;
      final base = widget.token.baseForm;

      final existingCard = supabase.getCardByWord(surface, language: widget.sourceLang) ??
          (base != null ? supabase.getCardByWord(base, language: widget.sourceLang) : null);

      if (existingCard != null) {
        _isSaved = true;
        _currentLevel = existingCard.level;
        _savedCard = existingCard;
      }
    } catch (_) {}
  }

  Future<void> _fetchDefinition() async {
    final word = (widget.token.baseForm != null && widget.token.baseForm!.trim().isNotEmpty)
        ? widget.token.baseForm!.trim()
        : widget.token.surface.trim();

    try {
      final res = await AppState.instance.apiClient.lookupDictionary(
        word: word,
        from: widget.sourceLang,
        to: widget.explanationLang,
      );

      if (mounted) {
        setState(() {
          _result = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback: lookup surface if baseform failed
      if (widget.token.baseForm != null && widget.token.baseForm != widget.token.surface) {
        try {
          final fallbackRes = await AppState.instance.apiClient.lookupDictionary(
            word: widget.token.surface.trim(),
            from: widget.sourceLang,
            to: widget.explanationLang,
          );
          if (mounted) {
            setState(() {
              _result = fallbackRes;
              _isLoading = false;
            });
            return;
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveWord() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final supabase = AppState.instance.supabaseService;
      final userId = supabase.currentUser?.id ?? 'guest';

      final word = widget.token.surface;
      final reading = widget.token.reading ?? _activeEntry?.reading;
      final romanization = widget.token.romanization ?? _activeEntry?.romaji;
      final pinyin = widget.token.pinyin;
      final meaning = _activeEntry?.definitions.isNotEmpty == true
          ? _activeEntry!.definitions.first
          : (_result?.entries.firstOrNull?.definitions.join('; ') ?? '');
      final pos = widget.token.partOfSpeech ?? _activeEntry?.partOfSpeech;

      final id = generateDeterministicRecordId([userId, word.toLowerCase(), widget.sourceLang]);

      final card = Flashcard(
        id: id,
        userId: userId,
        word: word,
        reading: reading,
        romanization: romanization,
        pinyin: pinyin,
        meaning: meaning,
        language: widget.sourceLang,
        level: 'new',
        partOfSpeech: pos,
        contextSentence: widget.contextSentence,
        contextTranslation: widget.contextTranslation,
        srsNextReviewAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await supabase.upsertVocabularyCard(card);

      if (mounted) {
        setState(() {
          _isSaved = true;
          _savedCard = card;
          _currentLevel = 'new';
          _isSaving = false;
        });
        ToastService.success(context, 'Added "$word" to your study deck');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ToastService.error(context, 'Failed to save word: $e');
      }
    }
  }

  Future<void> _updateCardLevel(String newLevel) async {
    if (_savedCard == null) return;
    try {
      final updated = _savedCard!.copyWith(level: newLevel);
      await AppState.instance.supabaseService.upsertVocabularyCard(updated);
      if (mounted) {
        setState(() {
          _currentLevel = newLevel;
          _savedCard = updated;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final pronounceWord = (widget.token.baseForm != null && widget.token.baseForm!.isNotEmpty)
        ? widget.token.baseForm!
        : widget.token.surface;

    final reading = widget.token.reading ??
        widget.token.pinyin ??
        widget.token.romanization ??
        _activeEntry?.reading ??
        _activeEntry?.romaji;

    final showBaseForm = widget.token.baseForm != null &&
        widget.token.baseForm!.isNotEmpty &&
        widget.token.baseForm != widget.token.surface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scrollable Body
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Reading (Top Centered)
                if (reading != null && reading.isNotEmpty && reading != widget.token.surface) ...[
                  Text(
                    reading,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                ],

                // 2. Main Word Row (Centered: Surface + (Base) + Audio Button)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.token.surface,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (showBaseForm) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${widget.token.baseForm})',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(width: 10),
                    ValueListenableBuilder<String?>(
                      valueListenable: AudioService.instance.currentPlaying,
                      builder: (context, playingWord, _) {
                        final isPlaying = AudioService.instance.isPlaying(pronounceWord);
                        return Material(
                          color: isPlaying ? colors.accentPrimarySoft : colors.bgSurface,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              AudioService.instance.playWord(
                                pronounceWord,
                                language: widget.sourceLang,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isPlaying
                                      ? colors.accentPrimary
                                      : colors.borderColorHover,
                                ),
                              ),
                              child: Icon(
                                isPlaying ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                                color: isPlaying ? colors.accentPrimary : colors.textSecondary,
                                size: 20,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 3. Badges Row (Centered: Part of Speech & JLPT / Exam Level)
                _buildBadgesRow(context),
                const SizedBox(height: 16),

                // Entry Tabs (if multiple entries)
                if (_result != null && _result!.entries.length > 1) ...[
                  _buildEntryTabs(context),
                  const SizedBox(height: 14),
                ],

                // 4. Content Area: Loading, Error, or Definitions & Examples
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.accentPrimary,
                      ),
                    ),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Could not load definition: $_error',
                      style: TextStyle(color: colors.error, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (_activeEntry == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No definition found',
                      style: TextStyle(color: colors.textMuted, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  )
                else ...[
                  // 5. Numbered Definitions List
                  _buildDefinitionsList(context, _activeEntry!),

                  // 6. Styled Examples Box
                  if (_activeEntry!.examples.isNotEmpty)
                    _buildExamplesBox(context, _activeEntry!),
                ],
              ],
            ),
          ),
        ),

        // 7. Sticky Bottom Footer
        _buildBottomFooter(context),
      ],
    );
  }

  Widget _buildBadgesRow(BuildContext context) {
    final colors = context.vocaColors;
    final entry = _activeEntry;
    final posRaw = widget.token.partOfSpeech ?? entry?.partOfSpeech;
    final posTags = formatPartOfSpeech(posRaw, widget.explanationLang);
    final level = entry?.level;

    if (posTags.isEmpty && (level == null || level.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        // Part of Speech Chips
        for (final pos in posTags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colors.borderColor),
            ),
            child: Text(
              pos,
              style: TextStyle(
                color: colors.colorDiamond,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        // Level Badge (JLPT / HSK / TOPIK)
        if (level != null && level.isNotEmpty) ...[
          Builder(builder: (ctx) {
            final levelColor = LevelColorInfo.forLevel(level, isDark: ctx.isDarkMode);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: levelColor.bg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: levelColor.border),
              ),
              child: Text(
                level,
                style: TextStyle(
                  color: levelColor.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildEntryTabs(BuildContext context) {
    final colors = context.vocaColors;
    final entries = _result!.entries;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: entries.asMap().entries.map((item) {
          final idx = item.key;
          final isSelected = idx == _activeEntryIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() => _activeEntryIndex = idx),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentPrimarySoft : colors.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? colors.accentPrimary : colors.borderColor,
                  ),
                ),
                child: Text(
                  'Sense ${idx + 1}',
                  style: TextStyle(
                    color: isSelected ? colors.accentPrimary : colors.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDefinitionsList(BuildContext context, DictionaryEntry entry) {
    final colors = context.vocaColors;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entry.definitions.length,
      itemBuilder: (context, index) {
        final def = entry.definitions[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${index + 1}. ',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: Text(
                  def,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExamplesBox(BuildContext context, DictionaryEntry entry) {
    final colors = context.vocaColors;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded, size: 16, color: colors.textMuted),
              const SizedBox(width: 6),
              Text(
                'EXAMPLES',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...entry.examples.map((ex) {
            final sentence = (ex['sentence'] ?? ex['text'] ?? '').toString();
            final translation = (ex['translation'] ?? '').toString();

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• $sentence',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  if (translation.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        translation,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomFooter(BuildContext context) {
    final colors = context.vocaColors;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(top: BorderSide(color: colors.borderColorLight)),
      ),
      child: SafeArea(
        top: false,
        child: _isSaved ? _buildSavedControl(context) : _buildSaveButton(context),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    final colors = context.vocaColors;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveWord,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accentPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colors.accentPrimary.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_add_outlined, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Save Word',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSavedControl(BuildContext context) {
    final colors = context.vocaColors;

    return Row(
      children: [
        // Saved status pill
        Expanded(
          flex: 3,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
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
                  'Saved',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Mastery Level Selector
        Expanded(
          flex: 4,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _currentLevel,
                dropdownColor: colors.bgCard,
                icon: Icon(Icons.arrow_drop_down_rounded, color: colors.textMuted),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'new', child: Text('🌱 New')),
                  DropdownMenuItem(value: 'learning', child: Text('📖 Learning')),
                  DropdownMenuItem(value: 'known', child: Text('✨ Known')),
                  DropdownMenuItem(value: 'mastered', child: Text('🏆 Mastered')),
                ],
                onChanged: (val) {
                  if (val != null) _updateCardLevel(val);
                },
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
