// lib/ui/vocabulary/vocabulary_screen.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/audio_service.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import 'word_detail_sheet.dart';

enum VocabFilter { all, isNew, learning, mastered }
enum VocabSort { dateAdded, alphabetical, masteryLevel, interval }

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  List<Flashcard> _cards = [];
  bool _isLoading = true;
  String _searchQuery = '';
  VocabFilter _activeFilter = VocabFilter.all;
  VocabSort _activeSort = VocabSort.dateAdded;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVocabulary() async {
    setState(() => _isLoading = true);
    final supabase = AppState.instance.supabaseService;
    final lang = AppState.instance.activeLanguage.value;

    try {
      final list = await supabase.getVocabularyCards(language: lang);
      if (mounted) {
        setState(() {
          _cards = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteCard(String id) async {
    await AppState.instance.supabaseService.deleteVocabularyCard(id);
    _loadVocabulary();
  }

  ({Color bg, Color text}) _getMasteryColors(String level, VocaColorPalette colors) {
    switch (level.toLowerCase()) {
      case 'mastered':
        return (bg: colors.wordMasteredBg, text: colors.wordMasteredText);
      case 'known':
        return (bg: colors.wordKnownBg, text: colors.wordKnownText);
      case 'learning':
        return (bg: colors.wordLearningBg, text: colors.wordLearningText);
      case 'new':
      default:
        return (bg: colors.wordNewBg, text: colors.wordNewText);
    }
  }

  int _getLevelRank(String level) {
    switch (level.toLowerCase()) {
      case 'mastered':
        return 4;
      case 'known':
        return 3;
      case 'learning':
        return 2;
      case 'new':
      default:
        return 1;
    }
  }

  List<Flashcard> _filterAndSortCards() {
    // 1. Filter by tab
    List<Flashcard> list = _cards.where((c) {
      switch (_activeFilter) {
        case VocabFilter.all:
          return true;
        case VocabFilter.isNew:
          return c.level.toLowerCase() == 'new';
        case VocabFilter.learning:
          return c.level.toLowerCase() == 'learning' || c.level.toLowerCase() == 'known';
        case VocabFilter.mastered:
          return c.level.toLowerCase() == 'mastered';
      }
    }).toList();

    // 2. Search query filter
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((c) {
        final wordMatch = c.word.toLowerCase().contains(query);
        final meaningMatch = c.meaning.toLowerCase().contains(query);
        final readingMatch = (c.reading?.toLowerCase().contains(query) ?? false) ||
            (c.romanization?.toLowerCase().contains(query) ?? false) ||
            (c.pinyin?.toLowerCase().contains(query) ?? false);
        return wordMatch || meaningMatch || readingMatch;
      }).toList();
    }

    // 3. Sorting
    switch (_activeSort) {
      case VocabSort.dateAdded:
        list.sort((a, b) {
          final da = a.createdAt ?? a.srsNextReviewAt;
          final db = b.createdAt ?? b.srsNextReviewAt;
          return db.compareTo(da);
        });
        break;
      case VocabSort.alphabetical:
        list.sort((a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
        break;
      case VocabSort.masteryLevel:
        list.sort((a, b) => _getLevelRank(b.level).compareTo(_getLevelRank(a.level)));
        break;
      case VocabSort.interval:
        list.sort((a, b) => b.srsInterval.compareTo(a.srsInterval));
        break;
    }

    return list;
  }

  String _formatInterval(int days) {
    if (days == 0) return '<10m';
    if (days >= 30) return '${(days / 30).round()}mo';
    return '${days}d';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final filtered = _filterAndSortCards();
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= VocaTokens.tabletBreakpoint;

    // Counts for filter pills
    final countAll = _cards.length;
    final countNew = _cards.where((c) => c.level.toLowerCase() == 'new').length;
    final countLearning = _cards.where((c) => c.level.toLowerCase() == 'learning' || c.level.toLowerCase() == 'known').length;
    final countMastered = _cards.where((c) => c.level.toLowerCase() == 'mastered').length;

    Widget contentWidget;
    if (_isLoading) {
      contentWidget = const Center(child: CircularProgressIndicator());
    } else if (filtered.isEmpty) {
      contentWidget = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 56, color: colors.textTertiary),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No matching words found for "$_searchQuery"'
                    : context.t('words.empty', null, 'No vocabulary saved in this category yet'),
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                context.t('words.emptyHint', null, 'Tap on words while watching videos to add them!'),
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    } else if (isTablet) {
      // Tablet: 2-column responsive GridView of word cards
      contentWidget = GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 116,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _buildWordCard(filtered[index], colors),
      );
    } else {
      // Mobile: 1 column list of word cards
      contentWidget = ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildWordCard(filtered[index], colors),
      );
    }

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: colors.bgPrimary,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, color: colors.accentPrimary, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                context.t('words.title', null, 'Vocabulary Notebook'),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colors.textSecondary),
            tooltip: context.t('words.refreshTooltip', null, 'Refresh words'),
            onPressed: _loadVocabulary,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              children: [
                // Search Input Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: context.t('words.searchPlaceholder', null, 'Search words, readings, or meanings...'),
                      hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: colors.textMuted, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: colors.textMuted, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colors.bgCard,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: colors.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: colors.accentPrimary),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),

                // Filter Tabs (All, New, Learning, Mastered)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      _buildFilterTab(VocabFilter.all, context.t('words.filterAll', null, 'All'), countAll, colors),
                      const SizedBox(width: 8),
                      _buildFilterTab(VocabFilter.isNew, context.t('words.filterNew', null, 'New'), countNew, colors),
                      const SizedBox(width: 8),
                      _buildFilterTab(VocabFilter.learning, context.t('words.filterLearning', null, 'Learning'), countLearning, colors),
                      const SizedBox(width: 8),
                      _buildFilterTab(VocabFilter.mastered, context.t('words.filterMastered', null, 'Mastered'), countMastered, colors),
                    ],
                  ),
                ),

                // Controls Bar: Count Header + Sort Dropdown
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${filtered.length} ${filtered.length == 1 ? 'word' : 'words'} found',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Sort Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.bgCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<VocabSort>(
                            value: _activeSort,
                            dropdownColor: colors.bgCard,
                            icon: Icon(Icons.sort, color: colors.accentPrimary, size: 18),
                            style: TextStyle(color: colors.textPrimary, fontSize: 12),
                            isDense: true,
                            items: [
                              DropdownMenuItem(
                                value: VocabSort.dateAdded,
                                child: Text(context.t('words.sortDateAdded', null, 'Date Added')),
                              ),
                              DropdownMenuItem(
                                value: VocabSort.alphabetical,
                                child: Text(context.t('words.sortAlpha', null, 'Alphabetical')),
                              ),
                              DropdownMenuItem(
                                value: VocabSort.masteryLevel,
                                child: Text(context.t('words.sortMastery', null, 'Mastery Level')),
                              ),
                              DropdownMenuItem(
                                value: VocabSort.interval,
                                child: Text(context.t('words.sortInterval', null, 'SRS Interval')),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _activeSort = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Vocabulary Content (Mobile 1-column list or Tablet 2-column grid)
                Expanded(child: contentWidget),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(VocabFilter filter, String label, int count, VocaColorPalette colors) {
    final isSelected = _activeFilter == filter;
    return InkWell(
      onTap: () => setState(() => _activeFilter = filter),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.accentPrimaryHover : colors.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : colors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : colors.bgSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordCard(Flashcard card, VocaColorPalette colors) {
    final reading = card.reading ?? card.pinyin ?? card.romanization;
    final mastery = _getMasteryColors(card.level, colors);

    return Dismissible(
      key: Key(card.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              context.t('common.delete', null, 'Delete'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete_outline, color: Colors.white),
          ],
        ),
      ),
      onDismissed: (_) => _deleteCard(card.id),
      child: InkWell(
        onTap: () => WordDetailSheet.show(
          context,
          card: card,
          onCardUpdated: _loadVocabulary,
          onCardDeleted: _loadVocabulary,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderColor),
            boxShadow: [
              BoxShadow(
                color: context.isDarkMode ? Colors.black26 : Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Word & Meaning Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (reading != null && reading.isNotEmpty) ...[
                      Text(
                        reading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      card.word,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.meaning,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Audio & Badges Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Interval badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: colors.borderColorLight),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 11,
                              color: colors.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formatInterval(card.srsInterval),
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Quick Audio Preview Button
                      ValueListenableBuilder<String?>(
                        valueListenable: AudioService.instance.currentPlaying,
                        builder: (context, playing, _) {
                          final isPlaying = playing == card.word;
                          return InkWell(
                            onTap: () {
                              AudioService.instance.playWord(
                                card.word,
                                language: card.language,
                                fallbackAudioUrl: card.audio,
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isPlaying
                                    ? colors.accentPrimary
                                    : colors.bgSurface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isPlaying
                                      ? colors.accentPrimary
                                      : colors.borderColorLight,
                                ),
                              ),
                              child: Icon(
                                isPlaying
                                    ? Icons.volume_up
                                    : Icons.volume_up_outlined,
                                size: 16,
                                color: isPlaying ? Colors.white : colors.accentPrimary,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // SRS Level Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: mastery.bg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: mastery.text.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      card.level.toUpperCase(),
                      style: TextStyle(
                        color: mastery.text,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
