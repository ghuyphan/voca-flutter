// lib/ui/vocabulary/vocabulary_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/audio_service.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../services/vocabulary_service.dart';
import '../../state/app_state.dart';
import '../sheets/dictionary_bottom_sheet.dart';
import '../sheets/grammar_bottom_sheet.dart';
import '../sheets/voca_bottom_sheet.dart';
import '../widgets/voca_empty_state.dart';
import '../widgets/voca_option_picker.dart';
import '../widgets/voca_shimmer.dart';
import '../widgets/voca_sliding_segmented_bar.dart';
import '../widgets/voca_audio_pulse_button.dart';
import 'word_detail_sheet.dart';

enum VocabTypeFilter { all, words, grammar }

/// Fully signal-reactive, Material 3 Vocabulary Screen.
/// Synchronized across all tabs (Video subtitles, Dictionary, and Study deck) in real-time.
class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _hasClipboardText = false;

  VocabTypeFilter _selectedType = VocabTypeFilter.all;
  String _selectedLevel = 'all'; // 'all', 'new', 'learning', 'known', 'ignored'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _checkClipboard();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    AudioService.instance.stop();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _searchQuery) {
      setState(() => _searchQuery = query);
    }
  }

  Future<void> _checkClipboard() async {
    try {
      final hasStrings = await Clipboard.hasStrings();
      if (mounted && hasStrings != _hasClipboardText) {
        setState(() => _hasClipboardText = hasStrings);
      }
    } catch (_) {}
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.isNotEmpty) {
        _searchController.text = text;
        _searchFocusNode.unfocus();
      }
    } catch (_) {}
  }

  List<Flashcard> _filterCards(List<Flashcard> allCards, String currentLang) {
    var list = allCards.where((c) {
      final l = c.language.trim().toLowerCase();
      final target = currentLang.trim().toLowerCase();
      return l == target || l.startsWith('$target-') || target.startsWith('$l-');
    }).toList();

    // 1. Filter by Type (All / Words / Grammar)
    final vocabService = VocabularyService.instance;
    if (_selectedType == VocabTypeFilter.grammar) {
      list = list.where(vocabService.isGrammarCard).toList();
    } else if (_selectedType == VocabTypeFilter.words) {
      list = list.where((c) => !vocabService.isGrammarCard(c)).toList();
    }

    // 2. Filter by Level (all / new / learning / known / ignored)
    if (_selectedLevel != 'all') {
      list = list.where((c) {
        final normLevel = WordLevels.normalize(c.level);
        return normLevel == _selectedLevel;
      }).toList();
    }

    // 3. Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((c) {
        final wordMatch = c.word.toLowerCase().contains(q);
        final meaningMatch = c.meaning.toLowerCase().contains(q);
        final readingMatch = (c.reading?.toLowerCase().contains(q) ?? false) ||
            (c.pinyin?.toLowerCase().contains(q) ?? false) ||
            (c.romanization?.toLowerCase().contains(q) ?? false);
        return wordMatch || meaningMatch || readingMatch;
      }).toList();
    }

    // 4. Sort newest first
    list.sort((a, b) {
      final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });

    // 5. Deduplicate identical words
    final seen = <String>{};
    return list.where((c) => seen.add(c.word.trim().toLowerCase())).toList();
  }

  void _deleteCard(Flashcard card) async {
    final vocabService = VocabularyService.instance;
    await vocabService.deleteCard(card);

    if (!mounted) return;
    ToastService.success(
      context,
      context.t('vocab.deleteSuccess', {'word': card.word}, 'Deleted "${card.word}"'),
      actionLabel: context.t('common.undo', null, 'Undo'),
      onAction: () async {
        await vocabService.undoLastDelete();
      },
    );
  }

  void _openLevelPicker(Flashcard card) async {
    final colors = context.vocaColors;
    final selected = await showVocaOptionPicker(
      context: context,
      title: context.t('vocab.changeLevel', null, 'Change level'),
      selectedValue: WordLevels.normalize(card.level),
      options: [
        OptionItem(
          value: 'new',
          label: context.t('vocab.new', null, 'New'),
          iconData: Icons.add_circle_outline_rounded,
          badge: 'New',
          badgeColor: colors.wordNewText,
        ),
        OptionItem(
          value: 'learning',
          label: context.t('vocab.learning', null, 'Learning'),
          iconData: Icons.psychology_outlined,
          badge: 'Learning',
          badgeColor: colors.wordLearningText,
        ),
        OptionItem(
          value: 'known',
          label: context.t('vocab.known', null, 'Known'),
          iconData: Icons.check_circle_outline_rounded,
          badge: 'Known',
          badgeColor: colors.wordKnownText,
        ),
        OptionItem(
          value: 'ignored',
          label: context.t('vocab.ignored', null, 'Ignored'),
          iconData: Icons.visibility_off_outlined,
          badge: 'Ignored',
          badgeColor: colors.textMuted,
        ),
      ],
    );

    if (selected != null && selected != WordLevels.normalize(card.level)) {
      await VocabularyService.instance.updateLevel(card.id, selected);
      if (mounted) {
        ToastService.success(context, 'Stage updated to ${selected.toUpperCase()}');
      }
    }
  }

  void _openDictionaryLookup([String? query]) {
    final effectiveQuery = (query != null && query.trim().isNotEmpty)
        ? query.trim()
        : _searchQuery.trim();
    if (effectiveQuery.isEmpty) {
      _searchFocusNode.requestFocus();
      ToastService.info(
        context,
        context.t('vocab.typeWordToSearch', null, 'Type a word in the search bar above to look up'),
      );
      return;
    }
    final currentLang = AppState.instance.activeLanguage.value;
    DictionaryBottomSheet.show(
      context,
      token: Token(
        surface: effectiveQuery,
        baseForm: effectiveQuery,
      ),
      sourceLang: currentLang,
    );
  }

  Future<void> _openImportDialog() async {
    final colors = context.vocaColors;
    final textController = TextEditingController();

    try {
      await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: colors.bgCard,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: colors.borderColor),
          ),
          title: Row(
            children: [
              Icon(Icons.upload_file_rounded, color: colors.accentPrimary, size: 22),
              const SizedBox(width: 8),
              Text(
                context.t('vocab.import', null, 'Import Vocabulary'),
                style: TextStyle(color: colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste your exported JSON data below to restore or merge saved cards.',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 5,
                style: TextStyle(color: colors.textPrimary, fontSize: 12, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: '[{"word": "猫", "meaning": "cat", ...}]',
                  hintStyle: TextStyle(color: colors.textMuted, fontSize: 12),
                  filled: true,
                  fillColor: colors.bgSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.accentPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    textController.text = data!.text!;
                  }
                },
                icon: const Icon(Icons.content_paste_rounded, size: 16),
                label: const Text('Paste from Clipboard'),
                style: TextButton.styleFrom(foregroundColor: colors.accentPrimary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(context.t('common.cancel', null, 'Cancel'), style: TextStyle(color: colors.textSecondary)),
            ),
            FilledButton(
              onPressed: () async {
                final input = textController.text.trim();
                if (input.isEmpty) return;
                Navigator.of(ctx).pop();

                final count = await VocabularyService.instance.importFromJson(
                  input,
                  defaultLanguage: AppState.instance.activeLanguage.value,
                );

                if (!mounted) return;
                if (count > 0) {
                  ToastService.success(context, 'Successfully imported $count cards!');
                } else {
                  ToastService.error(context, 'Invalid JSON format. No cards imported.');
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(context.t('vocab.import', null, 'Import')),
            ),
          ],
        );
      },
    );
    } finally {
      textController.dispose();
    }
  }

  void _openOptionsMenu() {
    final colors = context.vocaColors;
    final currentLang = AppState.instance.activeLanguage.value;

    showVocaBottomSheet(
      context: context,
      title: context.t('vocab.options', null, 'Vocabulary Options'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      builder: (ctx) {
        return Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.download_rounded, color: colors.accentPrimary),
                title: Text(
                  context.t('vocab.exportJson', null, 'Export as JSON'),
                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Copy JSON data to clipboard',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  final jsonStr = VocabularyService.instance.exportAsJson(language: currentLang);
                  Clipboard.setData(ClipboardData(text: jsonStr));
                  ToastService.success(context, 'Exported cards to clipboard as JSON');
                },
              ),
              Divider(height: 1, color: colors.borderColorLight),
              ListTile(
                leading: Icon(Icons.style_outlined, color: colors.accentSecondary),
                title: Text(
                  context.t('vocab.exportAnki', null, 'Export to Anki'),
                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Copy TSV flashcard format for Anki import',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  final ankiStr = VocabularyService.instance.exportAsAnki(language: currentLang);
                  Clipboard.setData(ClipboardData(text: ankiStr));
                  ToastService.success(context, 'Exported cards to clipboard for Anki');
                },
              ),
              Divider(height: 1, color: colors.borderColorLight),
              ListTile(
                leading: Icon(Icons.upload_file_rounded, color: colors.colorGrammar),
                title: Text(
                  context.t('vocab.import', null, 'Import JSON'),
                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Paste or restore cards from exported JSON',
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openImportDialog();
                },
              ),
              Divider(height: 1, color: colors.borderColorLight),
              ListTile(
                leading: Icon(Icons.refresh_rounded, color: colors.textSecondary),
                title: Text(
                  context.t('words.refreshTooltip', null, 'Refresh Vocabulary'),
                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  VocabularyService.instance.syncVocabulary(language: currentLang);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  ({Color bg, Color text, Color border}) _resolveLevelColors(String level, VocaColorPalette colors) {
    final norm = WordLevels.normalize(level);
    switch (norm) {
      case 'known':
        return (
          bg: colors.wordKnownBg,
          text: colors.wordKnownText,
          border: colors.wordKnownText.withValues(alpha: 0.35),
        );
      case 'learning':
        return (
          bg: colors.wordLearningBg,
          text: colors.wordLearningText,
          border: colors.wordLearningText.withValues(alpha: 0.35),
        );
      case 'ignored':
        return (
          bg: colors.bgSurface,
          text: colors.textMuted,
          border: colors.borderColor,
        );
      case 'new':
      default:
        return (
          bg: colors.wordNewBg,
          text: colors.wordNewText,
          border: colors.wordNewText.withValues(alpha: 0.35),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final isTablet = MediaQuery.of(context).size.width >= VocaTokens.tabletBreakpoint;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Watch((context) {
          final vocabService = VocabularyService.instance;
          final allCards = vocabService.cards.value;
          final isSyncing = vocabService.isSyncing.value;
          final currentLang = AppState.instance.activeLanguage.value;

          final langCards = vocabService.getCardsForLanguage(currentLang);
          final grammarCount = langCards.where(vocabService.isGrammarCard).length;
          final wordCount = langCards.where((c) => !vocabService.isGrammarCard(c)).length;
          final hasGrammarItems = grammarCount > 0;

          // Type counts
          final typeAllCount = langCards.length;
          final typeWordCount = wordCount;
          final typeGrammarCount = grammarCount;

          // Filter items based on active type for level counts
          final typeFilteredItems = _selectedType == VocabTypeFilter.grammar
              ? langCards.where(vocabService.isGrammarCard).toList()
              : _selectedType == VocabTypeFilter.words
                  ? langCards.where((c) => !vocabService.isGrammarCard(c)).toList()
                  : langCards;

          final levelAllCount = typeFilteredItems.length;
          final levelNewCount = typeFilteredItems.where((c) => WordLevels.normalize(c.level) == 'new').length;
          final levelLearningCount = typeFilteredItems.where((c) => WordLevels.normalize(c.level) == 'learning').length;
          final levelKnownCount = typeFilteredItems.where((c) => WordLevels.normalize(c.level) == 'known').length;
          final levelIgnoredCount = typeFilteredItems.where((c) => WordLevels.normalize(c.level) == 'ignored').length;

          // Display counts & title
          final displayCount = _selectedType == VocabTypeFilter.grammar
              ? typeGrammarCount
              : _selectedType == VocabTypeFilter.words
                  ? typeWordCount
                  : typeAllCount;

          final filtered = _filterCards(allCards, currentLang);

          return Column(
            children: [
              // 1. Top Bar: Native Sliding Segmented Bar + Options Button
              _buildTopBar(
                allCount: typeAllCount,
                wordsCount: typeWordCount,
                grammarCount: typeGrammarCount,
                hasGrammar: hasGrammarItems,
                colors: colors,
              ),

              // 2. Official Material 3 SearchBar with StadiumBorder
              _buildM3SearchBar(colors),

              // 3. Level Filter Strip (All, New, Learning, Known, Ignored) + Quick Dictionary Action
              _buildLevelFilterStrip(
                allCount: levelAllCount,
                newCount: levelNewCount,
                learningCount: levelLearningCount,
                knownCount: levelKnownCount,
                ignoredCount: levelIgnoredCount,
                colors: colors,
              ),

              // 4. Responsive Word Cards / Empty State
              Expanded(
                child: _buildBody(
                  filtered: filtered,
                  totalCount: displayCount,
                  isSyncing: isSyncing && allCards.isEmpty,
                  isTablet: isTablet,
                  colors: colors,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// 1. Top Bar: Native Sliding Segmented Bar + 38px Circular Options Button
  /// Matches LibraryTopBar and DeckOverview's 38px pattern.
  Widget _buildTopBar({
    required int allCount,
    required int wordsCount,
    required int grammarCount,
    required bool hasGrammar,
    required VocaColorPalette colors,
  }) {
    final values = hasGrammar ? ['words', 'grammar', 'all'] : ['words', 'all'];
    final labels = hasGrammar
        ? [
            context.t('vocab.filterWords', null, 'Words'),
            context.t('vocab.filterGrammar', null, 'Grammar'),
            context.t('vocab.filterAll', null, 'All'),
          ]
        : [
            context.t('vocab.filterWords', null, 'Words'),
            context.t('vocab.filterAll', null, 'All'),
          ];

    final currentVal = _selectedType == VocabTypeFilter.grammar
        ? 'grammar'
        : _selectedType == VocabTypeFilter.words
            ? 'words'
            : 'all';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          // Sliding Segmented Bar
          Expanded(
            child: VocaSlidingSegmentedBar(
              values: values,
              labels: labels,
              selectedValue: currentVal,
              colors: colors,
              height: 38,
              onSelected: (val) {
                setState(() {
                  if (val == 'grammar') {
                    _selectedType = VocabTypeFilter.grammar;
                  } else if (val == 'words') {
                    _selectedType = VocabTypeFilter.words;
                  } else {
                    _selectedType = VocabTypeFilter.all;
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 10),

          // 38px Circular Options Action Button
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.bgSurface,
              shape: BoxShape.circle,
              border: Border.all(color: colors.borderColor),
            ),
            child: IconButton(
              icon: Icon(Icons.more_vert_rounded, color: colors.textSecondary, size: 19),
              padding: EdgeInsets.zero,
              tooltip: context.t('vocab.options', null, 'Options'),
              onPressed: _openOptionsMenu,
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Official Material 3 SearchBar matching ExploreSpotlightBar
  Widget _buildM3SearchBar(VocaColorPalette colors) {
    final hasText = _searchController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: SearchBar(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        constraints: const BoxConstraints(minHeight: 44, maxHeight: 44),
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(colors.bgCard),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          StadiumBorder(
            side: BorderSide(
              color: _searchFocusNode.hasFocus ? colors.accentPrimary : colors.borderColor,
              width: 1.0,
            ),
          ),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.only(left: 14, right: 8)),
        hintText: context.t('vocab.search', null, 'Search words, readings, meanings...'),
        hintStyle: WidgetStatePropertyAll(
          TextStyle(
            color: colors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        textStyle: WidgetStatePropertyAll(
          TextStyle(
            color: colors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: Icon(
          Icons.search_rounded,
          color: _searchFocusNode.hasFocus ? colors.accentPrimary : colors.textMuted,
          size: 19,
        ),
        trailing: [
          if (hasText)
            IconButton(
              onPressed: () {
                _searchController.clear();
                _searchFocusNode.unfocus();
              },
              tooltip: context.t('common.clear', null, 'Clear'),
              iconSize: 16,
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: colors.bgSurface,
                foregroundColor: colors.textMuted,
                padding: EdgeInsets.zero,
                minimumSize: const Size(28, 28),
              ),
              icon: const Icon(Icons.close_rounded),
            )
          else if (_hasClipboardText)
            IconButton(
              onPressed: _pasteFromClipboard,
              tooltip: context.t('commandPalette.paste', null, 'Paste from clipboard'),
              iconSize: 16,
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: colors.bgSurface,
                foregroundColor: colors.textSecondary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(28, 28),
              ),
              icon: const Icon(Icons.content_paste_rounded),
            ),
        ],
      ),
    );
  }

  /// 3. Level Filter Chips Strip (All, New, Learning, Known, Ignored) + Dictionary Action
  Widget _buildLevelFilterStrip({
    required int allCount,
    required int newCount,
    required int learningCount,
    required int knownCount,
    required int ignoredCount,
    required VocaColorPalette colors,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: Row(
        children: [
          _buildM3FilterChip(
            label: context.t('history.all', null, 'All'),
            count: allCount,
            isSelected: _selectedLevel == 'all',
            onSelected: (_) => setState(() => _selectedLevel = 'all'),
            colors: colors,
          ),
          const SizedBox(width: 6),
          _buildM3FilterChip(
            label: context.t('vocab.new', null, 'New'),
            count: newCount,
            statusColor: colors.wordNewText,
            statusBgColor: colors.wordNewBg,
            isSelected: _selectedLevel == 'new',
            onSelected: (_) => setState(() => _selectedLevel = 'new'),
            colors: colors,
          ),
          const SizedBox(width: 6),
          _buildM3FilterChip(
            label: context.t('vocab.learning', null, 'Learning'),
            count: learningCount,
            statusColor: colors.wordLearningText,
            statusBgColor: colors.wordLearningBg,
            isSelected: _selectedLevel == 'learning',
            onSelected: (_) => setState(() => _selectedLevel = 'learning'),
            colors: colors,
          ),
          const SizedBox(width: 6),
          _buildM3FilterChip(
            label: context.t('vocab.known', null, 'Known'),
            count: knownCount,
            statusColor: colors.wordKnownText,
            statusBgColor: colors.wordKnownBg,
            isSelected: _selectedLevel == 'known',
            onSelected: (_) => setState(() => _selectedLevel = 'known'),
            colors: colors,
          ),
          if (ignoredCount > 0) ...[
            const SizedBox(width: 6),
            _buildM3FilterChip(
              label: context.t('vocab.ignored', null, 'Ignored'),
              count: ignoredCount,
              statusColor: colors.textMuted,
              statusBgColor: colors.bgSurface,
              isSelected: _selectedLevel == 'ignored',
              onSelected: (_) => setState(() => _selectedLevel = 'ignored'),
              colors: colors,
            ),
          ],
          const SizedBox(width: 8),
          // Quick Dictionary Action Chip
          ActionChip(
            onPressed: () => _openDictionaryLookup(),
            avatar: Icon(
              Icons.menu_book_rounded,
              size: 14,
              color: colors.accentPrimary,
            ),
            label: Text(
              context.t('dictionary.title', null, 'Dictionary'),
              style: TextStyle(
                color: colors.accentPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: colors.accentPrimarySoft,
            surfaceTintColor: Colors.transparent,
            side: BorderSide(color: colors.accentPrimary.withValues(alpha: 0.3)),
            shape: const StadiumBorder(),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  /// Official M3 FilterChip with StadiumBorder & Soft Tonal States matching ExploreChipsBar
  Widget _buildM3FilterChip({
    required String label,
    required int count,
    IconData? icon,
    Color? statusColor,
    Color? statusBgColor,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
    required VocaColorPalette colors,
  }) {
    final activeColor = statusColor ?? colors.accentPrimary;
    final activeBg = statusBgColor ?? colors.accentPrimarySoft;

    return FilterChip(
      selected: isSelected,
      onSelected: onSelected,
      showCheckmark: false,
      avatar: statusColor != null
          ? Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : statusColor,
                shape: BoxShape.circle,
              ),
            )
          : (icon != null
              ? Icon(
                  icon,
                  size: 13,
                  color: isSelected ? activeColor : colors.textSecondary,
                )
              : null),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : colors.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withValues(alpha: 0.15) : colors.bgSurface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: isSelected ? activeColor : colors.textMuted,
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return activeBg;
        }
        return colors.bgCard;
      }),
      surfaceTintColor: Colors.transparent,
      side: WidgetStateBorderSide.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return BorderSide(color: activeColor, width: 1.5);
        }
        return BorderSide(color: colors.borderColor, width: 1.0);
      }),
      shape: const StadiumBorder(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      visualDensity: VisualDensity.compact,
    );
  }

  /// 4. Main Body: Skeleton Loading, VocaEmptyState, or Word Cards
  Widget _buildBody({
    required List<Flashcard> filtered,
    required int totalCount,
    required bool isSyncing,
    required bool isTablet,
    required VocaColorPalette colors,
  }) {
    if (isSyncing) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, _) => _buildSkeletonCard(colors),
      );
    }

    if (filtered.isEmpty) {
      if (totalCount == 0) {
        final isGrammar = _selectedType == VocabTypeFilter.grammar;
        return Center(
          child: VocaEmptyState(
            icon: isGrammar ? Icons.auto_awesome_rounded : Icons.menu_book_rounded,
            title: isGrammar
                ? context.t('grammar.noGrammarSaved', null, 'No grammar patterns saved yet')
                : context.t('vocab.noWordsSaved', null, 'No words saved yet'),
            description: isGrammar
                ? context.t('grammar.clickGrammarToSave', null, 'Save grammar patterns while watching videos or browsing the dictionary to practice them here.')
                : context.t('vocab.clickWordsToSave', null, 'Save words while watching videos or browsing the dictionary to practice them here.'),
            compact: true,
            actionLabel: context.t('dictionary.searchInDict', null, 'Search Dictionary'),
            onAction: () => _openDictionaryLookup(),
          ),
        );
      } else {
        return Center(
          child: VocaEmptyState(
            icon: Icons.search_off_rounded,
            title: context.t('vocab.noMatchesFound', null, 'No matches found'),
            description: context.t('dictionary.tryDifferent', null, 'Try a different search term or level filter.'),
            compact: true,
            actionLabel: context.t('common.clear', null, 'Show All'),
            onAction: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedLevel = 'all';
                _selectedType = VocabTypeFilter.all;
              });
            },
          ),
        );
      }
    }

    if (isTablet) {
      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: 235,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _buildWordCard(filtered[index], colors),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildWordCard(filtered[index], colors),
    );
  }

  /// Skeleton Loading Item with smooth shimmer effect
  Widget _buildSkeletonCard(VocaColorPalette colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VocaShimmer.box(width: 70, height: 24, borderRadius: BorderRadius.circular(999)),
              VocaShimmer.box(width: 28, height: 28, borderRadius: BorderRadius.circular(999)),
            ],
          ),
          const SizedBox(height: 10),
          VocaShimmer.box(width: 120, height: 20, borderRadius: BorderRadius.circular(6)),
          const SizedBox(height: 6),
          VocaShimmer.box(width: 220, height: 14, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }

  /// High-Craft Material 3 Word Card matching lingua-tube's vocab-item
  Widget _buildWordCard(Flashcard card, VocaColorPalette colors) {
    final reading = (card.reading != null && card.reading!.isNotEmpty)
        ? card.reading!
        : (card.pinyin != null && card.pinyin!.isNotEmpty)
            ? card.pinyin!
            : (card.romanization != null && card.romanization!.isNotEmpty)
                ? card.romanization!
                : null;
    final isPinyin = card.pinyin != null && card.pinyin!.isNotEmpty;
    final showReading = reading != null && reading != card.word;
    final levelStyle = _resolveLevelColors(card.level, colors);
    final normLevel = WordLevels.normalize(card.level);

    final fontFam = switch (card.language.toLowerCase()) {
      'ja' || 'japanese' => 'Kosugi Maru',
      'zh' || 'chinese' => 'Noto Sans SC',
      'ko' || 'korean' => 'Noto Sans KR',
      _ => null,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          GrammarPattern? pattern;
          try {
            pattern = AppState.instance.grammarEngine.findPattern(card.word, card.language);
          } catch (_) {}

          if (pattern != null) {
            GrammarBottomSheet.show(context, pattern);
          } else {
            WordDetailSheet.show(context, card: card);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: colors.isDark ? 0.25 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Level Tonal Chip + POS Tag + SRS Interval + Audio + Delete
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Level Badge with Status Dot (Tapping opens Level Picker directly)
                          InkWell(
                            onTap: () => _openLevelPicker(card),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              height: 26,
                              padding: const EdgeInsets.symmetric(horizontal: 9),
                              decoration: BoxDecoration(
                                color: levelStyle.bg,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: levelStyle.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: levelStyle.text,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    context.t('vocab.$normLevel', null, normLevel.toUpperCase()),
                                    style: TextStyle(
                                      color: levelStyle.text,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 14,
                                    color: levelStyle.text.withValues(alpha: 0.8),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Part of Speech tag (if available)
                          if (card.partOfSpeech != null && card.partOfSpeech!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              height: 24,
                              padding: const EdgeInsets.symmetric(horizontal: 7),
                              decoration: BoxDecoration(
                                color: colors.bgSurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: colors.borderColorLight),
                              ),
                              child: Center(
                                child: Text(
                                  card.partOfSpeech!,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          // SRS Interval Indicator (if > 0)
                          if (card.srsInterval > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              height: 24,
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              decoration: BoxDecoration(
                                color: colors.bgSurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: colors.borderColorLight),
                              ),
                              child: Center(
                                child: Text(
                                  '${card.srsInterval.clamp(0, 365)}d',
                                  style: TextStyle(
                                    color: colors.textMuted,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Audio Pronunciation Button
                  ValueListenableBuilder<String?>(
                    valueListenable: AudioService.instance.currentPlaying,
                    builder: (context, playingWord, _) {
                      final isPlaying = playingWord == card.word;
                      return VocaAudioPulseButton(
                        isPlaying: isPlaying,
                        tooltip: context.t('study.listen', null, 'Listen'),
                        size: 30,
                        iconSize: 15,
                        onPressed: () {
                          AudioService.instance.playWord(
                            card.word,
                            language: card.language,
                            fallbackAudioUrl: card.audio,
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(width: 4),

                  // Direct Delete Button
                  IconButton(
                    onPressed: () => _deleteCard(card),
                    tooltip: context.t('vocab.deleteWord', null, 'Delete word'),
                    iconSize: 15,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: colors.bgSurface,
                      foregroundColor: colors.textMuted,
                      side: BorderSide(color: colors.borderColorLight),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(30, 30),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Word with Furigana/Pinyin stacked directly above Kanji/Hanzi
              if (showReading)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reading,
                      style: TextStyle(
                        color: isPinyin ? colors.accentPrimary : colors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.15,
                        letterSpacing: isPinyin ? 0.3 : 0.0,
                        fontFamily: fontFam,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.word,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.2,
                        fontFamily: fontFam,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  card.word,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.2,
                    fontFamily: fontFam,
                  ),
                ),

              // Meaning
              if (card.meaning.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  card.meaning,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              // Authentic Context Sentence
              if (card.contextSentence != null && card.contextSentence!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.bgSurface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        color: colors.accentPrimary.withValues(alpha: 0.5),
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '“${card.contextSentence!}”',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                          fontFamily: fontFam,
                        ),
                      ),
                      if (card.contextTranslation != null && card.contextTranslation!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          card.contextTranslation!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 11.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
