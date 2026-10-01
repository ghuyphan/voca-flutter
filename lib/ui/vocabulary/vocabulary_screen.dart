// lib/ui/vocabulary/vocabulary_screen.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/audio_service.dart';
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
              const Icon(Icons.search_off, size: 56, color: VocaTokens.textTertiary),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No matching words found for "$_searchQuery"'
                    : 'No vocabulary saved in this category yet',
                textAlign: TextAlign.center,
                style: const TextStyle(color: VocaTokens.textSecondary, fontSize: 15),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap on words while watching videos to add them!',
                textAlign: TextAlign.center,
                style: TextStyle(color: VocaTokens.textMuted, fontSize: 13),
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
        itemBuilder: (context, index) => _buildWordCard(filtered[index]),
      );
    } else {
      // Mobile: 1 column list of word cards
      contentWidget = ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _buildWordCard(filtered[index]),
      );
    }

    return Scaffold(
      backgroundColor: VocaTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: VocaTokens.bgPrimary,
        elevation: 0,
        titleSpacing: 16,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book, color: VocaTokens.accentPrimary, size: 22),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Vocabulary Notebook',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: VocaTokens.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: VocaTokens.textSecondary),
            tooltip: 'Refresh words',
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
                    style: const TextStyle(color: VocaTokens.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search words, readings, or meanings...',
                      hintStyle: const TextStyle(color: VocaTokens.textMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: VocaTokens.textMuted, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: VocaTokens.textMuted, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: VocaTokens.bgCard,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: VocaTokens.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: VocaTokens.accentPrimary),
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
                      _buildFilterTab(VocabFilter.all, 'All', countAll),
                      const SizedBox(width: 8),
                      _buildFilterTab(VocabFilter.isNew, 'New', countNew),
                      const SizedBox(width: 8),
                      _buildFilterTab(VocabFilter.learning, 'Learning', countLearning),
                      const SizedBox(width: 8),
                      _buildFilterTab(VocabFilter.mastered, 'Mastered', countMastered),
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
                          style: const TextStyle(
                            color: VocaTokens.textSecondary,
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
                          color: VocaTokens.bgCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: VocaTokens.borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<VocabSort>(
                            value: _activeSort,
                            dropdownColor: VocaTokens.bgCard,
                            icon: const Icon(Icons.sort, color: VocaTokens.accentPrimary, size: 18),
                            style: const TextStyle(color: VocaTokens.textPrimary, fontSize: 12),
                            isDense: true,
                            items: const [
                              DropdownMenuItem(
                                value: VocabSort.dateAdded,
                                child: Text('Date Added'),
                              ),
                              DropdownMenuItem(
                                value: VocabSort.alphabetical,
                                child: Text('Alphabetical'),
                              ),
                              DropdownMenuItem(
                                value: VocabSort.masteryLevel,
                                child: Text('Mastery Level'),
                              ),
                              DropdownMenuItem(
                                value: VocabSort.interval,
                                child: Text('SRS Interval'),
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

  Widget _buildFilterTab(VocabFilter filter, String label, int count) {
    final isSelected = _activeFilter == filter;
    return InkWell(
      onTap: () => setState(() => _activeFilter = filter),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? VocaTokens.accentPrimary : VocaTokens.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? VocaTokens.accentPrimaryHover : VocaTokens.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : VocaTokens.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : VocaTokens.bgSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : VocaTokens.textMuted,
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

  Widget _buildWordCard(Flashcard card) {
    final reading = card.reading ?? card.pinyin ?? card.romanization;
    final mastery = _getMasteryColors(card.level);

    return Dismissible(
      key: Key(card.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: VocaTokens.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline, color: Colors.white),
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
            color: VocaTokens.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VocaTokens.borderColor),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 2),
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
                        style: const TextStyle(
                          color: VocaTokens.textMuted,
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
                      style: const TextStyle(
                        color: VocaTokens.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.meaning,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: VocaTokens.textSecondary,
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
                          color: VocaTokens.bgSurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: VocaTokens.borderColorLight),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 11,
                              color: VocaTokens.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formatInterval(card.srsInterval),
                              style: const TextStyle(
                                color: VocaTokens.textSecondary,
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
                                    ? VocaTokens.accentPrimary
                                    : VocaTokens.bgSurface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isPlaying
                                      ? VocaTokens.accentPrimary
                                      : VocaTokens.borderColorLight,
                                ),
                              ),
                              child: Icon(
                                isPlaying
                                    ? Icons.volume_up
                                    : Icons.volume_up_outlined,
                                size: 16,
                                color: isPlaying ? Colors.white : VocaTokens.accentPrimary,
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
