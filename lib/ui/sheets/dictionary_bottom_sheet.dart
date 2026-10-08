// lib/ui/sheets/dictionary_bottom_sheet.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/audio_service.dart';
import '../../services/i18n_service.dart';
import '../../services/srs_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../../state/player_coordinator.dart';
import '../../utils/cyrb53_hasher.dart';
import '../../utils/pos_utils.dart';
import '../widgets/voca_empty_state.dart';
import '../widgets/voca_option_picker.dart';
import 'voca_bottom_sheet.dart';

class TargetLangInfo {
  final String code;
  final String name;
  final String flag;

  const TargetLangInfo({
    required this.code,
    required this.name,
    required this.flag,
  });
}

/// Modal bottom sheet for looking up words from subtitle tokens.
/// Faithfully ported from lingua-tube's word-popup component:
/// - Single unified header provided by showVocaBottomSheet (drag handle + close button)
/// - Centered reading, headword, base form, and circular audio pronunciation button
/// - Language target selector with country flag dropdown and "Translate All" button
/// - Shimmer loading skeleton, error states with retry, empty state with manual save
/// - Sense tabs (Sense 1, Sense 2) when multiple entries exist
/// - Centered badges (localized Part of Speech & exam level badge: JLPT/HSK/TOPIK)
/// - Numbered definition list with inline translation results
/// - Formatted authentic example sentences
/// - Sticky bottom footer with "+ Save Word" CTA or "Saved" state + Level Selector
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
  static const List<TargetLangInfo> _supportedTargetLangs = [
    TargetLangInfo(code: 'vi', name: 'Tiếng Việt', flag: '🇻🇳'),
    TargetLangInfo(code: 'en', name: 'English', flag: '🇬🇧'),
    TargetLangInfo(code: 'ja', name: '日本語', flag: '🇯🇵'),
    TargetLangInfo(code: 'zh', name: '中文', flag: '🇨🇳'),
    TargetLangInfo(code: 'ko', name: '한국어', flag: '🇰🇷'),
    TargetLangInfo(code: 'es', name: 'Español', flag: '🇪🇸'),
    TargetLangInfo(code: 'fr', name: 'Français', flag: '🇫🇷'),
    TargetLangInfo(code: 'de', name: 'Deutsch', flag: '🇩🇪'),
    TargetLangInfo(code: 'id', name: 'Bahasa Indonesia', flag: '🇮🇩'),
    TargetLangInfo(code: 'ru', name: 'Русский', flag: '🇷🇺'),
    TargetLangInfo(code: 'th', name: 'ไทย', flag: '🇹🇭'),
  ];

  late String _currentTargetLang;
  DictionaryResult? _result;
  int _activeEntryIndex = 0;
  bool _isLoading = true;
  String? _error;
  bool _isSaved = false;
  String _currentLevel = 'new';
  Flashcard? _savedCard;
  bool _isSaving = false;

  // Translation states for definitions
  final Map<int, String> _definitionTranslations = {};
  final Set<int> _translationErrors = {};
  bool _isTranslatingAll = false;

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
    // Use user's current UI language if supported as target lang, otherwise explanationLang
    final uiLang = I18nService.instance.currentLanguage.value;
    _currentTargetLang = _supportedTargetLangs.any((l) => l.code == uiLang)
        ? uiLang
        : widget.explanationLang;

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
    setState(() {
      _isLoading = true;
      _error = null;
      _definitionTranslations.clear();
      _translationErrors.clear();
    });

    final word = (widget.token.baseForm != null && widget.token.baseForm!.trim().isNotEmpty)
        ? widget.token.baseForm!.trim()
        : widget.token.surface.trim();

    try {
      final res = await AppState.instance.apiClient.lookupDictionary(
        word: word,
        from: widget.sourceLang,
        to: _currentTargetLang,
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
            to: _currentTargetLang,
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

  Future<void> _translateDefinition(int index, String definition) async {
    if (definition.trim().isEmpty) return;
    setState(() {
      _translationErrors.remove(index);
    });

    try {
      final res = await AppState.instance.apiClient.translateBatch(
        texts: [definition],
        sourceLang: 'en',
        targetLang: _currentTargetLang,
      );
      if (mounted) {
        setState(() {
          _definitionTranslations[index] = res.isNotEmpty ? res.first : definition;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _translationErrors.add(index);
        });
      }
    }
  }

  Future<void> _translateAllDefinitions() async {
    final entry = _activeEntry;
    if (entry == null || entry.definitions.isEmpty || _isTranslatingAll) return;

    setState(() {
      _isTranslatingAll = true;
      _translationErrors.clear();
    });

    try {
      final definitions = entry.definitions;
      final results = await AppState.instance.apiClient.translateBatch(
        texts: definitions,
        sourceLang: 'en',
        targetLang: _currentTargetLang,
      );

      if (mounted) {
        setState(() {
          for (int i = 0; i < definitions.length && i < results.length; i++) {
            _definitionTranslations[i] = results[i];
          }
          _isTranslatingAll = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTranslatingAll = false;
        });
        ToastService.error(context, context.t('popup.failed', null, 'Translation failed'));
      }
    }
  }

  Future<void> _showTargetLangPicker() async {
    final options = _supportedTargetLangs.map((lang) {
      return OptionItem(
        label: '${lang.flag}  ${lang.name}',
        value: lang.code,
      );
    }).toList();

    final val = await showVocaOptionPicker(
      context: context,
      title: context.t('popup.translationLang', null, 'Translation Language'),
      options: options,
      selectedValue: _currentTargetLang,
    );

    if (val != null && val != _currentTargetLang && mounted) {
      setState(() {
        _currentTargetLang = val;
        _activeEntryIndex = 0;
      });
      _fetchDefinition();
    }
  }

  Future<void> _showLevelPicker() async {
    final options = [
      OptionItem(label: '🌱  ${context.t('vocab.new', null, 'New')}', value: 'new'),
      OptionItem(label: '📖  ${context.t('vocab.learning', null, 'Learning')}', value: 'learning'),
      OptionItem(label: '✨  ${context.t('vocab.known', null, 'Known')}', value: 'known'),
      OptionItem(label: '🏆  ${context.t('vocab.mastered', null, 'Mastered')}', value: 'mastered'),
    ];

    final val = await showVocaOptionPicker(
      context: context,
      title: context.t('vocab.changeLevel', null, 'Change level'),
      options: options,
      selectedValue: _currentLevel,
    );

    if (val != null && mounted) {
      _updateCardLevel(val);
    }
  }

  Future<void> _saveWord() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final supabase = AppState.instance.supabaseService;
      final userId = supabase.currentUser?.id ?? 'guest';

      final base = widget.token.baseForm?.trim();
      final word = (base != null && base.isNotEmpty) ? base : widget.token.surface;
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

      final playerCtrl = PlayerCoordinator.instance.playerController;
      if (playerCtrl != null) {
        playerCtrl.savedWordCount.value++;
      }

      if (mounted) {
        setState(() {
          _isSaved = true;
          _savedCard = card;
          _currentLevel = 'new';
          _isSaving = false;
        });
        ToastService.success(context, 'Added "$word" to your vocabulary');
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
      final seed = SpacedRepetitionService.seedSrsParamsForLevel(newLevel);
      final updated = _savedCard!.copyWith(
        level: newLevel,
        srsRepetition: seed.repetition,
        srsInterval: seed.interval,
        srsEaseFactor: seed.easeFactor,
        srsNextReviewAt: seed.nextReviewAt,
      );
      await AppState.instance.supabaseService.upsertVocabularyCard(updated);
      if (mounted) {
        setState(() {
          _currentLevel = newLevel;
          _savedCard = updated;
        });
      }
    } catch (_) {}
  }

  TargetLangInfo get _currentLangInfo {
    return _supportedTargetLangs.firstWhere(
      (l) => l.code == _currentTargetLang,
      orElse: () => _supportedTargetLangs.first,
    );
  }

  Color _getLevelColor(String level, VocaColorPalette colors) {
    switch (level) {
      case 'new':
        return colors.wordNewText;
      case 'learning':
        return colors.wordLearningText;
      case 'known':
        return colors.wordKnownText;
      case 'mastered':
        return colors.accentSecondary;
      default:
        return colors.textSecondary;
    }
  }

  String _getLevelLabel(String level) {
    switch (level) {
      case 'new':
        return context.t('vocab.new', null, 'New');
      case 'learning':
        return context.t('vocab.learning', null, 'Learning');
      case 'known':
        return context.t('vocab.known', null, 'Known');
      case 'mastered':
        return context.t('vocab.mastered', null, 'Mastered');
      default:
        return level;
    }
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
                // 1. Main Word Row (Centered: Surface + (Base) + Audio Button)
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
                      const SizedBox(width: 6),
                      Text(
                        '(${widget.token.baseForm})',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
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
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isPlaying
                                      ? colors.accentPrimary
                                      : colors.borderColor,
                                ),
                              ),
                              child: Icon(
                                isPlaying ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                                color: isPlaying ? colors.accentPrimary : colors.textSecondary,
                                size: 18,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // 2. Reading (Centered below the word)
                if (reading != null && reading.isNotEmpty && reading != widget.token.surface) ...[
                  const SizedBox(height: 4),
                  Text(
                    reading,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 10),

                // 3. Translation Controls Row (Target Lang Flag Dropdown + Translate All Button)
                _buildTranslationControlsRow(context),
                const SizedBox(height: 12),

                // 4. Badges Row (Centered: Part of Speech & JLPT / Exam Level)
                _buildBadgesRow(context),
                const SizedBox(height: 14),

                // 5. Entry Tabs (if multiple entries)
                if (_result != null && _result!.entries.length > 1) ...[
                  _buildEntryTabs(context),
                  const SizedBox(height: 14),
                ],

                // 6. Content Area: Loading Shimmer, Error, Empty, or Definitions & Examples
                if (_isLoading)
                  _buildShimmerLoading(context)
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: VocaEmptyState(
                      icon: Icons.error_outline_rounded,
                      title: context.t('subtitle.networkErrorTitle', null, 'Connection Error'),
                      description: context.t('subtitle.networkErrorHint', null, 'Please check your internet connection and try again.'),
                      actionLabel: context.t('common.retry', null, 'Retry'),
                      onAction: _fetchDefinition,
                    ),
                  )
                else if (_activeEntry == null || _activeEntry!.definitions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: VocaEmptyState(
                      icon: Icons.search_off_rounded,
                      title: context.t('popup.noDictionaryEntry', null, 'No definition found'),
                      description: context.t('popup.saveManually', null, 'You can still save it to your vocabulary'),
                    ),
                  )
                else ...[
                  _buildDefinitionsList(context, _activeEntry!),
                  if (_activeEntry!.examples.isNotEmpty)
                    _buildExamplesBox(context, _activeEntry!),
                ],
              ],
            ),
          ),
        ),

        // 9. Sticky Bottom Footer
        _buildBottomFooter(context),
      ],
    );
  }

  Widget _buildTranslationControlsRow(BuildContext context) {
    final colors = context.vocaColors;
    final info = _currentLangInfo;
    final hasDefinitions = _activeEntry != null && _activeEntry!.definitions.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Target Language Selector Button (Flag + Chevron only matching lingua-tube)
        InkWell(
          onTap: _showTargetLangPicker,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(info.flag, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: colors.textMuted),
              ],
            ),
          ),
        ),

        // Translate All Button ([文A Dịch] pill)
        if (hasDefinitions) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: _isTranslatingAll ? null : _translateAllDefinitions,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isTranslatingAll)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: colors.textSecondary,
                      ),
                    )
                  else
                    Icon(Icons.translate_rounded, size: 13, color: colors.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    context.t('popup.translate', null, 'Translate'),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBadgesRow(BuildContext context) {
    final colors = context.vocaColors;
    final entry = _activeEntry;
    final posRaw = widget.token.partOfSpeech ?? entry?.partOfSpeech;
    final posTags = formatPartOfSpeech(posRaw, _currentTargetLang);
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
          final entry = item.value;
          final isSelected = idx == _activeEntryIndex;

          final label = entry.word != null && entry.word!.isNotEmpty
              ? '${idx + 1}. ${entry.word}'
              : 'Sense ${idx + 1}';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => setState(() {
                _activeEntryIndex = idx;
                _definitionTranslations.clear();
                _translationErrors.clear();
              }),
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
                  label,
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

  Widget _buildShimmerLoading(BuildContext context) {
    final colors = context.vocaColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: List.generate(3, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 18,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors.bgSurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
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
        final translated = _definitionTranslations[index];
        final hasError = _translationErrors.contains(index);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
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
                    '${index + 1}',
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
                      def,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (translated != null && translated.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: colors.borderColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          translated,
                          style: TextStyle(
                            color: colors.accentPrimary,
                            fontSize: 13.5,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ] else if (hasError) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.error_outline_rounded, size: 12, color: colors.error),
                          const SizedBox(width: 4),
                          Text(
                            context.t('popup.failed', null, 'Failed'),
                            style: TextStyle(color: colors.error, fontSize: 12),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () => _translateDefinition(index, def),
                            child: Text(
                              context.t('popup.retry', null, 'Retry'),
                              style: TextStyle(
                                color: colors.accentPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
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
            final romanization = (ex['romanization'] ?? '').toString();

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
                  if (romanization.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        romanization,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
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
      child: FilledButton.icon(
        onPressed: _isSaving ? null : _saveWord,
        style: FilledButton.styleFrom(
          backgroundColor: colors.accentPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colors.accentPrimary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.add_rounded, size: 20),
        label: Text(
          context.t('popup.saveWord', null, 'Save Word'),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSavedControl(BuildContext context) {
    final colors = context.vocaColors;
    final dotColor = _getLevelColor(_currentLevel, colors);
    final levelLabel = _getLevelLabel(_currentLevel);

    return Row(
      children: [
        // Saved status pill (disabled secondary)
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
                  context.t('popup.saved', null, 'Saved'),
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

        // Mastery Level Selector Button with color dot & chevron
        Expanded(
          flex: 4,
          child: InkWell(
            onTap: _showLevelPicker,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        levelLabel,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_drop_down_rounded, color: colors.textMuted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
