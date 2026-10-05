// lib/ui/vocabulary/vocabulary_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/audio_service.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../sheets/dictionary_bottom_sheet.dart';
import '../sheets/grammar_bottom_sheet.dart';
import '../sheets/voca_bottom_sheet.dart';
import '../widgets/voca_empty_state.dart';
import '../widgets/voca_option_picker.dart';
import '../widgets/voca_shimmer.dart';
import 'word_detail_sheet.dart';

enum VocabTypeFilter { all, words, grammar }

/// Sleek, high-performance Vocabulary Screen matching lingua-tube & ExploreScreen design language.
class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  List<Flashcard> _cards = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  VocabTypeFilter _selectedType = VocabTypeFilter.all;
  String _selectedLevel = 'all'; // 'all', 'new', 'learning', 'known', 'ignored'

  VoidCallback? _langEffectDispose;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });

    // Proactively react to active language changes
    _langEffectDispose = effect(() {
      final _ = AppState.instance.activeLanguage.value;
      _loadVocabulary();
    });
  }

  @override
  void dispose() {
    _langEffectDispose?.call();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    AudioService.instance.stop();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
      });
    }
  }

  Future<void> _loadVocabulary() async {
    setState(() => _isLoading = true);
    final currentLang = AppState.instance.activeLanguage.value;

    try {
      final list = await AppState.instance.supabaseService.getVocabularyCards(
        language: currentLang,
      );
      if (mounted) {
        setState(() {
          _cards = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[VocabularyScreen] Error loading cards: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isGrammarCard(Flashcard card) {
    try {
      return AppState.instance.grammarEngine.isGrammar(card.word, card.language);
    } catch (_) {
      return false;
    }
  }

  List<Flashcard> _getFilteredCards() {
    final currentLang = AppState.instance.activeLanguage.value;
    var list = _cards.where((c) => c.language == currentLang).toList();

    // 1. Filter by Type (All / Words / Grammar)
    if (_selectedType == VocabTypeFilter.grammar) {
      list = list.where(_isGrammarCard).toList();
    } else if (_selectedType == VocabTypeFilter.words) {
      list = list.where((c) => !_isGrammarCard(c)).toList();
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
      final da = a.createdAt ?? a.srsNextReviewAt;
      final db = b.createdAt ?? b.srsNextReviewAt;
      return db.compareTo(da);
    });

    // 5. Deduplicate identical words
    final seen = <String>{};
    return list.where((c) => seen.add(c.word.trim().toLowerCase())).toList();
  }

  void _deleteCard(Flashcard card) async {
    setState(() {
      _cards.removeWhere((c) => c.id == card.id);
    });

    await AppState.instance.supabaseService.deleteVocabularyCard(card.id);

    if (!mounted) return;
    ToastService.success(
      context,
      context.t('vocab.deleteSuccess', {'word': card.word}, 'Deleted "${card.word}"'),
      actionLabel: context.t('common.undo', null, 'Undo'),
      onAction: () async {
        await AppState.instance.supabaseService.upsertVocabularyCard(card);
        _loadVocabulary();
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
      final updated = card.copyWith(level: selected);
      await AppState.instance.supabaseService.upsertVocabularyCard(updated);
      _loadVocabulary();
      if (mounted) {
        ToastService.success(context, 'Stage updated to ${selected.toUpperCase()}');
      }
    }
  }

  void _openDictionaryLookup([String? query]) {
    final currentLang = AppState.instance.activeLanguage.value;
    DictionaryBottomSheet.show(
      context,
      token: Token(
        surface: query?.trim() ?? '',
        baseForm: query?.trim() ?? '',
      ),
      sourceLang: currentLang,
    );
  }

  void _openOptionsMenu() {
    final colors = context.vocaColors;
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
                'Copy full vocabulary data to clipboard',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                Navigator.of(ctx).pop();
                final jsonStr = jsonEncode(_cards.map((c) => c.toRemoteJson()).toList());
                Clipboard.setData(ClipboardData(text: jsonStr));
                ToastService.success(context, 'Exported ${_cards.length} cards to clipboard as JSON');
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
                final ankiLines = _cards.map((item) {
                  final reading = item.reading ?? item.pinyin ?? item.romanization;
                  final front = item.word + (reading != null && reading.isNotEmpty ? ' [$reading]' : '');
                  final back = item.meaning;
                  return '$front\t$back';
                }).join('\n');
                Clipboard.setData(ClipboardData(text: ankiLines));
                ToastService.success(context, 'Exported ${_cards.length} cards to clipboard for Anki');
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
                _loadVocabulary();
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
          border: colors.wordKnownText.withOpacity(0.35),
        );
      case 'learning':
        return (
          bg: colors.wordLearningBg,
          text: colors.wordLearningText,
          border: colors.wordLearningText.withOpacity(0.35),
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
          border: colors.wordNewText.withOpacity(0.35),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final currentLang = AppState.instance.activeLanguage.value;
    final langCards = _cards.where((c) => c.language == currentLang).toList();

    final grammarCardsCount = langCards.where(_isGrammarCard).length;
    final wordCardsCount = langCards.where((c) => !_isGrammarCard(c)).length;
    final hasGrammarItems = grammarCardsCount > 0;

    // Type counts
    final typeAllCount = langCards.length;
    final typeWordCount = wordCardsCount;
    final typeGrammarCount = grammarCardsCount;

    // Filter items based on active type for level counts
    final typeFilteredItems = _selectedType == VocabTypeFilter.grammar
        ? langCards.where(_isGrammarCard).toList()
        : _selectedType == VocabTypeFilter.words
            ? langCards.where((c) => !_isGrammarCard(c)).toList()
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

    final displayTitle = _selectedType == VocabTypeFilter.grammar
        ? (context.t('grammar.grammar', null, 'Grammar'))
        : (context.t('vocab.savedTitle', null, 'Saved Vocabulary'));

    final filtered = _getFilteredCards();
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= VocaTokens.tabletBreakpoint;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Clean Top Header matching lingua-tube & ExploreScreen (NO generic AppBar!)
            _buildPanelHeader(
              title: displayTitle,
              count: displayCount,
              isGrammar: _selectedType == VocabTypeFilter.grammar,
              colors: colors,
            ),

            // 2. Sleek Spotlight Search Bar (matching ExploreSpotlightBar / VocaSearchInput)
            _buildSearchBar(colors),

            // 3. Filter Scroll Strip (Type & Level Chips)
            if (hasGrammarItems)
              _buildTypeFilterStrip(
                allCount: typeAllCount,
                wordsCount: typeWordCount,
                grammarCount: typeGrammarCount,
                colors: colors,
              ),

            _buildLevelFilterStrip(
              allCount: levelAllCount,
              newCount: levelNewCount,
              learningCount: levelLearningCount,
              knownCount: levelKnownCount,
              ignoredCount: levelIgnoredCount,
              colors: colors,
            ),

            // 4. Word List / Grid or Compact Empty State
            Expanded(
              child: _buildBody(
                filtered: filtered,
                totalCount: displayCount,
                isTablet: isTablet,
                colors: colors,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1. Clean Top Header Row (book-open / sparkle icon, "Saved Vocabulary", count badge, Dictionary link, Options)
  Widget _buildPanelHeader({
    required String title,
    required int count,
    required bool isGrammar,
    required VocaColorPalette colors,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          // Left: Icon + Title + Count Badge
          Expanded(
            child: Row(
              children: [
                Icon(
                  isGrammar ? Icons.auto_awesome_rounded : Icons.menu_book_rounded,
                  size: 20,
                  color: colors.accentPrimary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentPrimarySoft,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.accentPrimary.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: colors.accentPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right: Dictionary Link & Options Menu
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => _openDictionaryLookup(),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.t('dictionary.title', null, 'Dictionary'),
                        style: TextStyle(
                          color: colors.accentPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: colors.accentPrimary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: _openOptionsMenu,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.bgCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: 16,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. Reusable/sleek Spotlight search bar (matching ExploreSpotlightBar / VocaSearchInput)
  Widget _buildSearchBar(VocaColorPalette colors) {
    final isFocused = _searchFocusNode.hasFocus;
    final hasText = _searchController.text.isNotEmpty;

    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isFocused ? colors.accentPrimary : colors.borderColor,
          width: isFocused ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(colors.isDark ? 0.28 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: isFocused ? colors.accentPrimary : colors.textMuted,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              cursorColor: colors.accentPrimary,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: context.t('vocab.search', null, 'Search words, readings, meanings...'),
                hintStyle: TextStyle(
                  color: colors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (hasText)
            InkWell(
              onTap: () {
                _searchController.clear();
                _searchFocusNode.unfocus();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded, size: 13, color: colors.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  /// 3A. Type Filter Chips Strip (All, Words, Grammar)
  Widget _buildTypeFilterStrip({
    required int allCount,
    required int wordsCount,
    required int grammarCount,
    required VocaColorPalette colors,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          _buildPillChip(
            label: context.t('vocab.filterAll', null, 'All'),
            count: allCount,
            isSelected: _selectedType == VocabTypeFilter.all,
            onTap: () => setState(() => _selectedType = VocabTypeFilter.all),
            colors: colors,
          ),
          _buildPillChip(
            label: context.t('vocab.filterWords', null, 'Words'),
            count: wordsCount,
            icon: Icons.text_fields_rounded,
            isSelected: _selectedType == VocabTypeFilter.words,
            onTap: () => setState(() => _selectedType = VocabTypeFilter.words),
            colors: colors,
          ),
          _buildPillChip(
            label: context.t('vocab.filterGrammar', null, 'Grammar'),
            count: grammarCount,
            icon: Icons.auto_awesome_rounded,
            isSelected: _selectedType == VocabTypeFilter.grammar,
            onTap: () => setState(() => _selectedType = VocabTypeFilter.grammar),
            colors: colors,
          ),
        ],
      ),
    );
  }

  /// 3B. Level Filter Chips Strip (All, New, Learning, Known, Ignored)
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
      padding: const EdgeInsets.fromLTRB(16, 3, 16, 6),
      child: Row(
        children: [
          _buildPillChip(
            label: context.t('history.all', null, 'All'),
            count: allCount,
            isSelected: _selectedLevel == 'all',
            onTap: () => setState(() => _selectedLevel = 'all'),
            colors: colors,
          ),
          _buildPillChip(
            label: context.t('vocab.new', null, 'New'),
            count: newCount,
            isSelected: _selectedLevel == 'new',
            onTap: () => setState(() => _selectedLevel = 'new'),
            colors: colors,
          ),
          _buildPillChip(
            label: context.t('vocab.learning', null, 'Learning'),
            count: learningCount,
            isSelected: _selectedLevel == 'learning',
            onTap: () => setState(() => _selectedLevel = 'learning'),
            colors: colors,
          ),
          _buildPillChip(
            label: context.t('vocab.known', null, 'Known'),
            count: knownCount,
            isSelected: _selectedLevel == 'known',
            onTap: () => setState(() => _selectedLevel = 'known'),
            colors: colors,
          ),
          if (ignoredCount > 0)
            _buildPillChip(
              label: context.t('vocab.ignored', null, 'Ignored'),
              count: ignoredCount,
              isSelected: _selectedLevel == 'ignored',
              onTap: () => setState(() => _selectedLevel = 'ignored'),
              colors: colors,
            ),
        ],
      ),
    );
  }

  /// Sleek reusable Pill Chip matching lingua-tube's .filter-chip and ExploreChipsBar
  Widget _buildPillChip({
    required String label,
    required int count,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
    required VocaColorPalette colors,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? colors.accentPrimary : colors.bgCard,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? colors.accentPrimary : colors.borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? Colors.white : colors.textSecondary,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.25) : colors.bgSurface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : colors.textMuted,
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 4. Main Body: Skeleton Loading, Compact VocaEmptyState, or Word Cards (1-col mobile, 2-col tablet)
  Widget _buildBody({
    required List<Flashcard> filtered,
    required int totalCount,
    required bool isTablet,
    required VocaColorPalette colors,
  }) {
    if (_isLoading && _cards.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, _) => _buildSkeletonCard(colors),
      );
    }

    if (filtered.isEmpty) {
      if (totalCount == 0) {
        // Zero cards in the current learning language
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
        // Search query or level filter returned zero results
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
          mainAxisExtent: 185,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VocaShimmer.box(width: 60, height: 22, borderRadius: BorderRadius.circular(999)),
              VocaShimmer.box(width: 24, height: 24, borderRadius: BorderRadius.circular(999)),
            ],
          ),
          const SizedBox(height: 10),
          VocaShimmer.box(width: 110, height: 18, borderRadius: BorderRadius.circular(6)),
          const SizedBox(height: 6),
          VocaShimmer.box(width: 200, height: 14, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }

  /// Sleek Word Card (Level badge with status dot, POS tag, Audio speaker, more/delete, Stacked Ruby/Pinyin, definition, example sentence)
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

    return Dismissible(
      key: ValueKey(card.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.t('common.delete', null, 'Delete'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
      onDismissed: (_) => _deleteCard(card),
      child: Material(
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
              WordDetailSheet.show(
                context,
                card: card,
                onCardUpdated: _loadVocabulary,
                onCardDeleted: _loadVocabulary,
              );
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(colors.isDark ? 0.20 : 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Level Badge (Status dot + Chevron) + POS tag + Audio Button + Delete Button
                Row(
                  children: [
                    // Level Badge with Status Dot (Tapping opens Level Picker)
                    InkWell(
                      onTap: () => _openLevelPicker(card),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
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
                              context.t('vocab.${WordLevels.normalize(card.level)}', null, card.level.toUpperCase()),
                              style: TextStyle(
                                color: levelStyle.text,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 13,
                              color: levelStyle.text.withOpacity(0.8),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Part of Speech tag (if available)
                    if (card.partOfSpeech != null && card.partOfSpeech!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        height: 22,
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
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Audio Speaker Button
                    ValueListenableBuilder<String?>(
                      valueListenable: AudioService.instance.currentPlaying,
                      builder: (context, playingWord, _) {
                        final isPlaying = playingWord == card.word;
                        return InkWell(
                          onTap: () {
                            AudioService.instance.playWord(
                              card.word,
                              language: card.language,
                              fallbackAudioUrl: card.audio,
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: isPlaying ? colors.accentPrimary : colors.bgSurface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isPlaying ? colors.accentPrimary : colors.borderColorLight,
                              ),
                            ),
                            child: Icon(
                              isPlaying ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                              size: 14,
                              color: isPlaying ? Colors.white : colors.textMuted,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 4),

                    // Quick Delete Button
                    InkWell(
                      onTap: () => _deleteCard(card),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.borderColorLight),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 14,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Word with proper Ruby furigana / Pinyin stacked directly above Kanji/Hanzi
                if (showReading)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        reading,
                        style: TextStyle(
                          color: isPinyin ? colors.accentPrimary : colors.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          height: 1.15,
                          letterSpacing: isPinyin ? 0.3 : 0.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        card.word,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    card.word,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),

                // Clear definition text in textPrimary (14px)
                if (card.meaning.isNotEmpty) ...[
                  const SizedBox(height: 5),
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

                // Example sentence in italic textSecondary (12.5px) if available
                if (card.contextSentence != null && card.contextSentence!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: colors.accentPrimary.withOpacity(0.5),
                          width: 2,
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
                          ),
                        ),
                        if (card.contextTranslation != null && card.contextTranslation!.isNotEmpty) ...[
                          const SizedBox(height: 2),
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
      ),
    );
  }
}
