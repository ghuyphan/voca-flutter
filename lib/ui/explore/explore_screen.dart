// lib/ui/explore/explore_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../state/app_state.dart';
import '../../utils/youtube_url_parser.dart';
import '../video/video_player_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> _videos = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedCategory = 'All';
  String _selectedLevel = 'All';
  String _searchQuery = '';
  final Set<String> _bookmarkedIds = {};

  static const List<String> _categories = [
    'All',
    'Trending',
    'Anime & Drama',
    'Music',
    'News',
    'Vlog',
    'Conversation',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchInputChanged);
    _loadVideos();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchInputChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchInputChanged() {
    setState(() {});

    final text = _searchController.text.trim();
    // If user pasted a full YouTube URL into the search field directly
    if (text.startsWith('http://') ||
        text.startsWith('https://') ||
        text.startsWith('youtu.be') ||
        text.startsWith('youtube.com')) {
      final videoId = YouTubeUrlParser.extractVideoId(text);
      if (videoId != null) {
        _searchController.clear();
        _searchFocusNode.unfocus();
        _navigateToPlayer(videoId, 'YouTube Video');
      }
    }
  }

  void _navigateToPlayer(String videoId, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          videoId: videoId,
          title: title,
        ),
      ),
    );
  }

  Future<void> _handleDirectUrlOrSearch(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Check if input is a valid YouTube URL or raw video ID
    final directId = YouTubeUrlParser.extractVideoId(trimmed);
    if (directId != null) {
      _searchController.clear();
      _searchFocusNode.unfocus();
      _navigateToPlayer(directId, 'YouTube Video');
      return;
    }

    // Otherwise, perform catalog search
    _searchFocusNode.unfocus();
    setState(() {
      _searchQuery = trimmed;
    });
    await _loadVideos();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clipboard is empty'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Check if clipboard contains a direct YouTube URL or video ID
    final directId = YouTubeUrlParser.extractVideoId(text);
    if (directId != null) {
      _searchController.clear();
      _searchFocusNode.unfocus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening video: $directId'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _navigateToPlayer(directId, 'YouTube Video');
      return;
    }

    // Otherwise, populate search bar and execute query
    _searchController.text = text;
    await _handleDirectUrlOrSearch(text);
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    if (_searchQuery.isNotEmpty) {
      setState(() {
        _searchQuery = '';
      });
      _loadVideos();
    }
  }

  List<String> _getLevelsForLanguage(String lang) {
    switch (lang) {
      case 'ja':
        return const ['All', 'N5', 'N4', 'N3', 'N2', 'N1'];
      case 'zh':
        return const ['All', 'HSK 1', 'HSK 2', 'HSK 3', 'HSK 4', 'HSK 5', 'HSK 6'];
      case 'ko':
        return const ['All', 'TOPIK 1', 'TOPIK 2', 'TOPIK 3', 'TOPIK 4', 'TOPIK 5', 'TOPIK 6'];
      case 'en':
        return const ['All', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
      default:
        return const ['All', 'Beginner', 'Elementary', 'Intermediate', 'Advanced'];
    }
  }

  String? _mapLevelToTier(String lang, String level) {
    if (level == 'All') return null;
    switch (lang) {
      case 'ja':
        if (level == 'N5') return 'beginner';
        if (level == 'N4') return 'elementary';
        if (level == 'N3') return 'intermediate';
        if (level == 'N2') return 'upper_intermediate';
        if (level == 'N1') return 'advanced';
        break;
      case 'zh':
        if (level == 'HSK 1') return 'beginner';
        if (level == 'HSK 2') return 'elementary';
        if (level == 'HSK 3') return 'intermediate';
        if (level == 'HSK 4') return 'intermediate';
        if (level == 'HSK 5') return 'upper_intermediate';
        if (level == 'HSK 6') return 'advanced';
        break;
      case 'ko':
        if (level == 'TOPIK 1') return 'beginner';
        if (level == 'TOPIK 2') return 'elementary';
        if (level == 'TOPIK 3') return 'intermediate';
        if (level == 'TOPIK 4') return 'intermediate';
        if (level == 'TOPIK 5') return 'upper_intermediate';
        if (level == 'TOPIK 6') return 'advanced';
        break;
      case 'en':
        if (level == 'A1') return 'beginner';
        if (level == 'A2') return 'elementary';
        if (level == 'B1') return 'intermediate';
        if (level == 'B2') return 'upper_intermediate';
        if (level == 'C1' || level == 'C2') return 'advanced';
        break;
    }
    return null;
  }

  String? _getCategoryKeyword(String category) {
    switch (category) {
      case 'Anime & Drama':
        return 'anime';
      case 'Music':
        return 'music';
      case 'News':
        return 'news';
      case 'Vlog':
        return 'vlog';
      case 'Conversation':
        return 'conversation';
      default:
        return null;
    }
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final lang = AppState.instance.activeLanguage.value;
    final tier = _mapLevelToTier(lang, _selectedLevel);

    String? query;
    if (_searchQuery.isNotEmpty) {
      query = _searchQuery;
    } else if (_selectedCategory != 'All' && _selectedCategory != 'Trending') {
      query = _getCategoryKeyword(_selectedCategory);
    }

    try {
      final list = await AppState.instance.apiClient.getRecommendedVideos(
        lang: lang,
        tier: tier,
        query: query,
        limit: 30,
      );

      // Client-side filtering enhancement: if a specific difficulty level is selected,
      // prioritize videos explicitly tagged with this level
      List<Map<String, dynamic>> resultList = list;
      if (_selectedLevel != 'All') {
        final normalizedLevel = _selectedLevel.replaceAll(' ', '').toUpperCase();
        final levelFiltered = list.where((item) {
          final itemLevel = _getVideoLevel(item, lang).replaceAll(' ', '').toUpperCase();
          final itemTier = (item['tier'] as String? ?? '').toLowerCase();
          return itemLevel.contains(normalizedLevel) || (tier != null && itemTier == tier);
        }).toList();

        if (levelFiltered.isNotEmpty) {
          resultList = levelFiltered;
        }
      }

      if (mounted) {
        setState(() {
          _videos = resultList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getVideoLevel(Map<String, dynamic> item, String lang) {
    final directLevel = item['level'] as String?;
    if (directLevel != null && directLevel.isNotEmpty) {
      return directLevel;
    }

    final levels = item['levels'] as Map<String, dynamic>?;
    if (levels != null && levels[lang] != null) {
      return levels[lang].toString();
    }

    final tier = item['tier'] as String?;
    if (tier != null) {
      switch (lang) {
        case 'ja':
          if (tier == 'beginner') return 'JLPT N5';
          if (tier == 'elementary') return 'JLPT N4';
          if (tier == 'intermediate') return 'JLPT N3';
          if (tier == 'upper_intermediate') return 'JLPT N2';
          if (tier == 'advanced') return 'JLPT N1';
          break;
        case 'zh':
          if (tier == 'beginner') return 'HSK 1';
          if (tier == 'elementary') return 'HSK 2';
          if (tier == 'intermediate') return 'HSK 3';
          if (tier == 'upper_intermediate') return 'HSK 5';
          if (tier == 'advanced') return 'HSK 6';
          break;
        case 'ko':
          if (tier == 'beginner') return 'TOPIK 1';
          if (tier == 'elementary') return 'TOPIK 2';
          if (tier == 'intermediate') return 'TOPIK 3';
          if (tier == 'upper_intermediate') return 'TOPIK 5';
          if (tier == 'advanced') return 'TOPIK 6';
          break;
        case 'en':
          if (tier == 'beginner') return 'CEFR A1';
          if (tier == 'elementary') return 'CEFR A2';
          if (tier == 'intermediate') return 'CEFR B1';
          if (tier == 'upper_intermediate') return 'CEFR B2';
          if (tier == 'advanced') return 'CEFR C1';
          break;
      }
      return tier.toUpperCase();
    }

    return 'ALL LEVELS';
  }

  Color _getLevelColor(String levelStr) {
    final l = levelStr.toUpperCase().replaceAll(' ', '');
    if (l.contains('N5') ||
        l.contains('HSK1') ||
        l.contains('TOPIK1') ||
        l.contains('A1') ||
        l.contains('BEGINNER')) {
      return const Color(0xFF10B981); // Emerald
    }
    if (l.contains('N4') ||
        l.contains('HSK2') ||
        l.contains('TOPIK2') ||
        l.contains('A2') ||
        l.contains('ELEMENTARY')) {
      return const Color(0xFF06B6D4); // Cyan
    }
    if (l.contains('N3') ||
        l.contains('HSK3') ||
        l.contains('HSK4') ||
        l.contains('TOPIK3') ||
        l.contains('TOPIK4') ||
        l.contains('B1') ||
        l.contains('INTERMEDIATE')) {
      return const Color(0xFF6366F1); // Indigo
    }
    if (l.contains('N2') ||
        l.contains('HSK5') ||
        l.contains('TOPIK5') ||
        l.contains('B2') ||
        l.contains('UPPER')) {
      return const Color(0xFFF59E0B); // Amber
    }
    if (l.contains('N1') ||
        l.contains('HSK6') ||
        l.contains('TOPIK6') ||
        l.contains('C1') ||
        l.contains('C2') ||
        l.contains('ADVANCED')) {
      return const Color(0xFFEF4444); // Red
    }
    return const Color(0xFF6366F1); // Default Indigo
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remMins = minutes % 60;
      return '$hours:${remMins.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _toggleBookmark(String videoId, String title) {
    setState(() {
      if (_bookmarkedIds.contains(videoId)) {
        _bookmarkedIds.remove(videoId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from bookmarks'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _bookmarkedIds.add(videoId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved "$title" to bookmarks'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Trending':
        return Icons.local_fire_department_rounded;
      case 'Anime & Drama':
        return Icons.movie_filter_rounded;
      case 'Music':
        return Icons.music_note_rounded;
      case 'News':
        return Icons.newspaper_rounded;
      case 'Vlog':
        return Icons.videocam_rounded;
      case 'Conversation':
        return Icons.forum_rounded;
      default:
        return Icons.explore_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = AppState.instance.activeLanguage.value;
    final levels = _getLevelsForLanguage(currentLang);
    final rawInput = _searchController.text.trim();
    final directVideoId = YouTubeUrlParser.extractVideoId(rawInput);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.explore_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Discover',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          // Language Selector Dropdown
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: DropdownButton<String>(
              value: currentLang,
              dropdownColor: const Color(0xFF1E293B),
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 18),
              items: const [
                DropdownMenuItem(value: 'ja', child: Text('🇯🇵 Japanese', style: TextStyle(color: Colors.white, fontSize: 13))),
                DropdownMenuItem(value: 'zh', child: Text('🇨🇳 Chinese', style: TextStyle(color: Colors.white, fontSize: 13))),
                DropdownMenuItem(value: 'ko', child: Text('🇰🇷 Korean', style: TextStyle(color: Colors.white, fontSize: 13))),
                DropdownMenuItem(value: 'en', child: Text('🇺🇸 English', style: TextStyle(color: Colors.white, fontSize: 13))),
              ],
              onChanged: (val) {
                if (val != null && val != currentLang) {
                  AppState.instance.setLanguage(val);
                  setState(() {
                    _selectedLevel = 'All';
                    _searchQuery = '';
                    _searchController.clear();
                  });
                  _loadVideos();
                }
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Search & Direct YouTube URL Input Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: directVideoId != null ? const Color(0xFF6366F1) : Colors.white12,
                    width: directVideoId != null ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _handleDirectUrlOrSearch,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search keyword, channel, or paste YouTube link...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (directVideoId != null)
                          IconButton(
                            icon: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF6366F1)),
                            tooltip: 'Watch YouTube Video',
                            onPressed: () => _handleDirectUrlOrSearch(rawInput),
                          ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                            tooltip: 'Clear',
                            onPressed: _clearSearch,
                          ),
                        IconButton(
                          icon: const Icon(Icons.content_paste_rounded, color: Color(0xFF818CF8), size: 19),
                          tooltip: 'Paste URL or Video ID',
                          onPressed: _pasteFromClipboard,
                        ),
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),

            // Direct Video Detected Banner
            if (directVideoId != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: InkWell(
                  onTap: () => _handleDirectUrlOrSearch(rawInput),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF818CF8), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Valid YouTube Video ($directVideoId) detected!',
                            style: const TextStyle(color: Color(0xFFC7D2FE), fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Text(
                          'Watch Now →',
                          style: TextStyle(color: Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Category Pills
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return _buildCategoryPill(cat, isSelected);
                },
              ),
            ),

            const SizedBox(height: 6),

            // Difficulty Level Filters
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: levels.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final level = levels[index];
                  final isSelected = _selectedLevel == level;
                  return _buildLevelFilterChip(level, isSelected);
                },
              ),
            ),

            const SizedBox(height: 6),

            // Video Feed List / Results
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF6366F1)),
                          SizedBox(height: 12),
                          Text('Finding immersion videos...', style: TextStyle(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorView()
                      : _videos.isEmpty
                          ? _buildEmptyView()
                          : RefreshIndicator(
                              onRefresh: _loadVideos,
                              color: const Color(0xFF6366F1),
                              backgroundColor: const Color(0xFF1E293B),
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                itemCount: _videos.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  return _buildVideoCard(_videos[index], currentLang);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String category, bool isSelected) {
    return FilterChip(
      selected: isSelected,
      avatar: Icon(
        _getCategoryIcon(category),
        size: 15,
        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
      ),
      label: Text(category),
      onSelected: (_) {
        setState(() {
          _selectedCategory = category;
        });
        _loadVideos();
      },
      backgroundColor: const Color(0xFF1E293B),
      selectedColor: const Color(0xFF6366F1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
      ),
      checkmarkColor: Colors.white,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.white12,
        ),
      ),
    );
  }

  Widget _buildLevelFilterChip(String level, bool isSelected) {
    final levelColor = level == 'All' ? const Color(0xFF6366F1) : _getLevelColor(level);

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (level != 'All')
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : levelColor,
                shape: BoxShape.circle,
              ),
            ),
          Text(level),
        ],
      ),
      onSelected: (_) {
        setState(() {
          _selectedLevel = level;
        });
        _loadVideos();
      },
      backgroundColor: const Color(0xFF1E293B),
      selectedColor: levelColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.white12,
        ),
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> item, String currentLang) {
    final videoId = item['videoId'] as String? ?? '';
    final title = item['title'] as String? ?? 'YouTube Video';
    final channel = item['channel'] as String? ?? 'YouTube Creator';
    final channelAvatar = item['channelAvatar'] as String?;
    final duration = item['duration'] as int? ?? 0;
    final levelTag = _getVideoLevel(item, currentLang);
    final levelColor = _getLevelColor(levelTag);
    final durationStr = _formatDuration(duration);
    final isBookmarked = _bookmarkedIds.contains(videoId);

    final thumbnailUrl = (item['thumbnail'] as String?)?.isNotEmpty == true
        ? item['thumbnail'] as String
        : 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToPlayer(videoId, title),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail with Duration, Level Badge, and Bookmark Action
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF0F172A),
                        child: const Center(
                          child: Icon(Icons.play_circle_outline_rounded, color: Colors.white24, size: 48),
                        ),
                      ),
                    ),
                  ),

                  // Gradient overlay on thumbnail for better readability
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                            Colors.black.withOpacity(0.6),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Difficulty Level Badge (Top-Left)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: levelColor,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        levelTag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  // Bookmark Button (Top-Right)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _toggleBookmark(videoId, title),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: isBookmarked ? const Color(0xFFFBBF24) : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Duration Badge (Bottom-Right)
                  if (durationStr.isNotEmpty)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_filled_rounded, color: Colors.white70, size: 11),
                            const SizedBox(width: 4),
                            Text(
                              durationStr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // Title and Channel Information
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Channel Avatar + Name & Watch Action Button
                    Row(
                      children: [
                        // Channel avatar or fallback
                        if (channelAvatar != null && channelAvatar.isNotEmpty)
                          ClipOval(
                            child: Image.network(
                              channelAvatar,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const CircleAvatar(
                                radius: 12,
                                backgroundColor: Color(0xFF334155),
                                child: Icon(Icons.person, size: 14, color: Colors.white70),
                              ),
                            ),
                          )
                        else
                          const CircleAvatar(
                            radius: 12,
                            backgroundColor: Color(0xFF334155),
                            child: Icon(Icons.smart_display_rounded, size: 14, color: Colors.white70),
                          ),
                        const SizedBox(width: 8),

                        // Channel name
                        Expanded(
                          child: Text(
                            channel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        // Watch Now Button
                        ElevatedButton.icon(
                          onPressed: () => _navigateToPlayer(videoId, title),
                          icon: const Icon(Icons.play_arrow_rounded, size: 16),
                          label: const Text('Watch Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.search_off_rounded, color: Colors.white38, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'No immersion videos found',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results for "$_searchQuery". Paste a direct YouTube link or try different keywords.'
                  : 'No videos found with the selected filters.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _selectedCategory = 'All';
                  _selectedLevel = 'All';
                });
                _loadVideos();
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset All Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: const Color(0xFF818CF8),
                side: const BorderSide(color: Color(0xFF6366F1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Could not load videos',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Network request failed. Please check your connection.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadVideos,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
