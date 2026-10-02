// lib/ui/explore/explore_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import '../../state/player_coordinator.dart';
import '../../utils/youtube_url_parser.dart';
import '../sheets/category_filter_sheet.dart';
import '../widgets/voca_level_badge.dart';
import '../widgets/voca_shimmer.dart';

enum ExploreTab { videos, playlists }

class ExploreScreen extends StatefulWidget {
  final VoidCallback? onOpenPlaylists;

  const ExploreScreen({super.key, this.onOpenPlaylists});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late final AnimationController _searchBarAnimController;
  late final Animation<double> _searchBarAnimation;
  bool _isSearchBarVisible = true;

  ExploreTab _currentTab = ExploreTab.videos;
  List<Map<String, dynamic>> _videos = [];
  List<PlaylistItem> _playlists = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedCategory = 'All';
  String _selectedLevel = 'All';
  String _searchQuery = '';

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
    _searchBarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _searchBarAnimation = CurvedAnimation(
      parent: _searchBarAnimController,
      curve: Curves.easeInOut,
    );

    _searchController.addListener(_onSearchInputChanged);
    _searchFocusNode.addListener(_onFocusChanged);
    _loadFeed();
  }

  @override
  void dispose() {
    _searchBarAnimController.dispose();
    _searchController.removeListener(_onSearchInputChanged);
    _searchFocusNode.removeListener(_onFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) {
      if (_searchFocusNode.hasFocus && !_isSearchBarVisible) {
        _isSearchBarVisible = true;
        _searchBarAnimController.forward();
      }
      setState(() {});
    }
  }

  void _onSearchInputChanged() {
    if (_searchController.text.isNotEmpty && !_isSearchBarVisible) {
      _isSearchBarVisible = true;
      _searchBarAnimController.forward();
    }
    setState(() {});

    final text = _searchController.text.trim();
    // Direct YouTube link auto-detection
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

  void _navigateToPlayer(String videoId, String title, {String? channel, String? level}) {
    PlayerCoordinator.instance.openVideo(
      context,
      videoId: videoId,
      title: title,
      channel: channel,
      level: level,
    );
  }

  Future<void> _handleDirectUrlOrSearch(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final directId = YouTubeUrlParser.extractVideoId(trimmed);
    if (directId != null) {
      _searchController.clear();
      _searchFocusNode.unfocus();
      _navigateToPlayer(directId, 'YouTube Video');
      return;
    }

    _searchFocusNode.unfocus();
    setState(() {
      _searchQuery = trimmed;
    });
    await _loadVideos();
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
        if (level == 'HSK 3' || level == 'HSK 4') return 'intermediate';
        if (level == 'HSK 5') return 'upper_intermediate';
        if (level == 'HSK 6') return 'advanced';
        break;
      case 'ko':
        if (level == 'TOPIK 1') return 'beginner';
        if (level == 'TOPIK 2') return 'elementary';
        if (level == 'TOPIK 3' || level == 'TOPIK 4') return 'intermediate';
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

  Future<void> _loadFeed({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final lang = AppState.instance.activeLanguage.value;

    if (_currentTab == ExploreTab.playlists) {
      try {
        final allPlaylists = await AppState.instance.supabaseService.getExplorePlaylists(language: lang);
        List<PlaylistItem> result = allPlaylists;

        if (_selectedLevel != 'All') {
          final normalizedLevel = _selectedLevel.replaceAll(' ', '').toUpperCase();
          result = result.where((p) {
            final lvl = (p.level ?? '').replaceAll(' ', '').toUpperCase();
            return lvl.contains(normalizedLevel);
          }).toList();
        }

        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          result = result.where((p) {
            final title = p.title.toLowerCase();
            final desc = (p.description ?? '').toLowerCase();
            return title.contains(q) || desc.contains(q);
          }).toList();
        }

        if (mounted) {
          setState(() {
            _playlists = result;
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
      return;
    }

    // Videos tab
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
        refresh: refresh,
      );

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

  Future<void> _loadVideos({bool refresh = false}) => _loadFeed(refresh: refresh);

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

  String _getCategoryLabel(BuildContext context, String category) {
    switch (category) {
      case 'All':
        return context.t('explore.topicAll', null, 'All');
      case 'Trending':
        return context.t('explore.topicTrending', null, 'Trending');
      case 'Anime & Drama':
        return context.t('explore.topicAnimeDrama', null, 'Anime & Drama');
      case 'Music':
        return context.t('explore.topicMusic', null, 'Music');
      case 'News':
        return context.t('explore.topicNews', null, 'News');
      case 'Vlog':
        return context.t('explore.topicVlog', null, 'Vlog');
      case 'Conversation':
        return context.t('explore.topicConversation', null, 'Conversation');
      default:
        return category;
    }
  }

  void _openFilterSheet() {
    final currentLang = AppState.instance.activeLanguage.value;
    final levels = _getLevelsForLanguage(currentLang);

    CategoryFilterSheet.show(
      context,
      selectedCategory: _selectedCategory,
      selectedLevel: _selectedLevel,
      availableLevels: levels,
      categories: _categories,
      onApply: (category, level) {
        setState(() {
          _selectedCategory = category;
          _selectedLevel = level;
          _currentTab = ExploreTab.videos;
        });
        _loadFeed();
      },
    );
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (_searchFocusNode.hasFocus) return false;

    if (notification.metrics.pixels <= 10) {
      if (!_isSearchBarVisible) {
        _isSearchBarVisible = true;
        _searchBarAnimController.forward();
      }
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > 2 && notification.metrics.pixels > 30) {
        if (_isSearchBarVisible) {
          _isSearchBarVisible = false;
          _searchBarAnimController.reverse();
        }
      } else if (delta < -2) {
        if (!_isSearchBarVisible) {
          _isSearchBarVisible = true;
          _searchBarAnimController.forward();
        }
      }
    } else if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse && notification.metrics.pixels > 30) {
        if (_isSearchBarVisible) {
          _isSearchBarVisible = false;
          _searchBarAnimController.reverse();
        }
      } else if (notification.direction == ScrollDirection.forward) {
        if (!_isSearchBarVisible) {
          _isSearchBarVisible = true;
          _searchBarAnimController.forward();
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final currentLang = AppState.instance.activeLanguage.value;
    final levels = _getLevelsForLanguage(currentLang).where((l) => l != 'All').toList();
    final rawInput = _searchController.text.trim();
    final directVideoId = YouTubeUrlParser.extractVideoId(rawInput);
    final hasSearchFocus = _searchFocusNode.hasFocus;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Spotlight Search Bar (Collapses smoothly on scroll down)
            SizeTransition(
              sizeFactor: _searchBarAnimation,
              axisAlignment: -1.0,
              child: FadeTransition(
                opacity: _searchBarAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSpotlightBar(colors, directVideoId, hasSearchFocus, rawInput),

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
                              color: colors.accentPrimarySoft,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: colors.accentPrimary.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: colors.accentPrimary, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    context.t('explore.videoDetected', {'id': directVideoId}, 'Valid YouTube Video ($directVideoId) detected!'),
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${context.t('explore.watchNow', null, 'Watch Now')} →',
                                  style: TextStyle(
                                    color: colors.accentPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 2. Search Results Header (Only shown when searching)
            if (_searchQuery.isNotEmpty)
              _buildFeedHeader(colors),

            // 3. Filter button + Active Category pill + Level chips
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _buildChipsBar(colors, levels),
            ),

            // 4. Virtualized Video/Playlist Feed List / Skeleton Results
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScrollNotification,
                child: _buildMainFeed(currentLang, colors),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Authentic Spotlight Search Bar matching lingua-tube's .spotlight-bar
  Widget _buildSpotlightBar(
    VocaColorPalette colors,
    String? directVideoId,
    bool hasSearchFocus,
    String rawInput,
  ) {
    return Container(
      height: 52,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: (directVideoId != null || hasSearchFocus)
              ? colors.accentPrimary
              : colors.borderColor,
          width: (directVideoId != null || hasSearchFocus) ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(colors.isDark ? 0.35 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            directVideoId != null ? Icons.link_rounded : Icons.search_rounded,
            color: (directVideoId != null || hasSearchFocus)
                ? colors.accentPrimary
                : colors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              cursorColor: colors.accentPrimary,
              textInputAction: TextInputAction.search,
              onSubmitted: _handleDirectUrlOrSearch,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: context.t('explore.searchHint', null, 'Paste YouTube URL or search...'),
                hintStyle: TextStyle(color: colors.textMuted, fontSize: 13.5),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty) ...[
            // Clear button
            Tooltip(
              message: context.t('common.clear', null, 'Clear'),
              child: InkWell(
                onTap: _clearSearch,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, size: 15, color: colors.textMuted),
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Load / Search primary button
            ElevatedButton(
              onPressed: () => _handleDirectUrlOrSearch(rawInput),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 34),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    directVideoId != null ? Icons.arrow_forward_rounded : Icons.search_rounded,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    directVideoId != null
                        ? context.t('player.load', null, 'Load')
                        : context.t('player.search', null, 'Search'),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Search Results Header (Only shown when searching)
  Widget _buildFeedHeader(VocaColorPalette colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 19, color: colors.accentPrimary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${context.t('playlist.searchResultsFor', null, 'Results for')} "$_searchQuery"',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: _clearSearch,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close_rounded, size: 12, color: colors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    context.t('common.clear', null, 'Clear'),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Single, clean horizontal chips bar:
  /// 1. (☷ Filter ⌄) Pill Chip (FIRST - before All filter)
  /// 2. (▶ All) Pill Chip
  /// 3. (≡ Playlists) Pill Chip
  /// 4. Level chips (N5, N4, N3, etc.)
  Widget _buildChipsBar(VocaColorPalette colors, List<String> levels) {
    final hasActiveCategory = _selectedCategory != 'All';
    final hasActiveFilter = hasActiveCategory || (_selectedLevel != 'All' && _currentTab == ExploreTab.videos);
    final isAllSelected = _currentTab == ExploreTab.videos && _selectedLevel == 'All' && !hasActiveCategory;
    final isPlaylistsSelected = _currentTab == ExploreTab.playlists;

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // 1. Filter Button (FIRST - before All filter)
          InkWell(
            onTap: _openFilterSheet,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: hasActiveFilter ? colors.accentPrimarySoft : colors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasActiveFilter ? colors.accentPrimary : colors.borderColor,
                  width: hasActiveFilter ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasActiveCategory
                        ? _getCategoryIcon(_selectedCategory)
                        : Icons.tune_rounded,
                    size: 14,
                    color: hasActiveFilter ? colors.accentPrimary : colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hasActiveCategory
                        ? _getCategoryLabel(context, _selectedCategory)
                        : context.t('explore.filter', null, 'Filters'),
                    style: TextStyle(
                      color: hasActiveFilter ? colors.accentPrimary : colors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: hasActiveFilter ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: hasActiveFilter ? colors.accentPrimary : colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 2. (▶ All) Pill Chip
          InkWell(
            onTap: () {
              setState(() {
                _currentTab = ExploreTab.videos;
                _selectedLevel = 'All';
                _selectedCategory = 'All';
              });
              _loadFeed();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isAllSelected
                    ? (colors.isDark ? Colors.white : Colors.black)
                    : colors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isAllSelected
                      ? (colors.isDark ? Colors.white : Colors.black)
                      : colors.borderColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    size: 16,
                    color: isAllSelected
                        ? (colors.isDark ? Colors.black : Colors.white)
                        : colors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    context.t('common.all', null, 'All'),
                    style: TextStyle(
                      color: isAllSelected
                          ? (colors.isDark ? Colors.black : Colors.white)
                          : colors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: isAllSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 3. (≡ Playlists) Pill Chip
          InkWell(
            onTap: () {
              setState(() {
                _currentTab = isPlaylistsSelected ? ExploreTab.videos : ExploreTab.playlists;
              });
              _loadFeed();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: isPlaylistsSelected
                    ? (colors.isDark ? Colors.white : Colors.black)
                    : colors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPlaylistsSelected
                      ? (colors.isDark ? Colors.white : Colors.black)
                      : colors.borderColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.format_list_bulleted_rounded,
                    size: 15,
                    color: isPlaylistsSelected
                        ? (colors.isDark ? Colors.black : Colors.white)
                        : colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.t('playlist.title', null, 'Playlists'),
                    style: TextStyle(
                      color: isPlaylistsSelected
                          ? (colors.isDark ? Colors.black : Colors.white)
                          : colors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: isPlaylistsSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Proficiency Level Chips (e.g. N5, N4, N3, etc.)
          ...levels.map((lvl) {
            final isSelected = _selectedLevel == lvl;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildLevelFilterChip(lvl, isSelected, colors),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLevelFilterChip(String level, bool isSelected, VocaColorPalette colors) {
    final info = LevelColorInfo.forLevel(level, isDark: colors.isDark);

    return FilterChip(
      selected: isSelected,
      label: Text(level),
      onSelected: (_) {
        setState(() {
          _selectedLevel = isSelected ? 'All' : level;
        });
        _loadFeed();
      },
      backgroundColor: colors.bgCard,
      selectedColor: info.bg,
      labelStyle: TextStyle(
        color: isSelected ? info.text : colors.textSecondary,
        fontSize: 12.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? info.border : colors.borderColor,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
    );
  }

  /// Skeleton Loading Card with Shimmer
  Widget _buildSkeletonCard(VocaColorPalette colors) {
    return Container(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: VocaShimmer.box(
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 2, right: 2, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VocaShimmer.circle(size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VocaShimmer.line(height: 14),
                      const SizedBox(height: 6),
                      VocaShimmer.line(width: 160, height: 14),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          VocaShimmer.line(width: 90, height: 12),
                          const SizedBox(width: 8),
                          const VocaLevelBadge(isLoading: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Virtualized Skeleton Loading Feed
  Widget _buildSkeletonFeed(VocaColorPalette colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = width >= VocaTokens.tabletBreakpoint;

        if (!isTablet) {
          return ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (_, __) => _buildSkeletonCard(colors),
          );
        }

        final crossAxisCount = width >= 1100 ? 3 : 2;
        const double spacing = 20.0;
        const double horizontalPadding = 16.0 * 2;
        final cardWidth = (width - horizontalPadding - spacing * (crossAxisCount - 1)) / crossAxisCount;
        final cardHeight = (cardWidth / (16 / 9)) + 100.0;
        final childAspectRatio = cardWidth / cardHeight;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => _buildSkeletonCard(colors),
        );
      },
    );
  }

  /// 1:1 Video Card matching lingua-tube's yt-video-card and user screenshot
  Widget _buildVideoCard(Map<String, dynamic> item, String currentLang, VocaColorPalette colors) {
    final videoId = item['videoId'] as String? ?? '';
    final title = item['title'] as String? ?? 'YouTube Video';
    final channel = item['channel'] as String? ?? 'YouTube Creator';
    final channelAvatar = item['channelAvatar'] as String?;
    final duration = item['duration'] as int? ?? 0;
    final levelTag = _getVideoLevel(item, currentLang);
    final durationStr = _formatDuration(duration);
    final double? resumeProgress = (item['resumeProgress'] as num?)?.toDouble() ??
        (item['progress'] as num?)?.toDouble();

    final thumbnailUrl = (item['thumbnail'] as String?)?.isNotEmpty == true
        ? item['thumbnail'] as String
        : 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

    return Container(
      color: Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _navigateToPlayer(videoId, title, channel: channel, level: levelTag),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 16:9 Thumbnail with Duration & Resume Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: colors.bgSecondary,
                          child: Center(
                            child: Icon(Icons.play_circle_outline_rounded, color: colors.textTertiary, size: 48),
                          ),
                        ),
                      ),
                    ),

                    // Duration Badge (Bottom-Right)
                    if (durationStr.isNotEmpty)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xCC000000),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            durationStr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),

                    // Resume progress bar at bottom of thumbnail
                    if (resumeProgress != null && resumeProgress > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          value: resumeProgress.clamp(0.0, 1.0),
                          backgroundColor: Colors.black38,
                          valueColor: AlwaysStoppedAnimation<Color>(colors.accentPrimary),
                          minHeight: 3.5,
                        ),
                      ),
                  ],
                ),
              ),

              // Title, Channel, and Level Info
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 2, right: 2, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (channelAvatar != null && channelAvatar.isNotEmpty)
                      ClipOval(
                        child: Image.network(
                          channelAvatar,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => CircleAvatar(
                            radius: 18,
                            backgroundColor: colors.bgSurface,
                            child: Icon(Icons.person, size: 18, color: colors.textSecondary),
                          ),
                        ),
                      )
                    else
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colors.bgSurface,
                        child: Icon(Icons.smart_display_rounded, size: 18, color: colors.textSecondary),
                      ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            channel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (levelTag.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            VocaLevelBadge(
                              level: levelTag,
                              size: LevelBadgeSize.small,
                            ),
                          ],
                        ],
                      ),
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

  /// Unified Main Feed routing between Video Feed and Explore Playlists Feed
  Widget _buildMainFeed(String currentLang, VocaColorPalette colors) {
    if (_isLoading) {
      return _buildSkeletonFeed(colors);
    }

    if (_errorMessage != null) {
      return _buildErrorView(colors);
    }

    if (_currentTab == ExploreTab.playlists) {
      if (_playlists.isEmpty) {
        return _buildEmptyView(colors);
      }
      return _buildPlaylistFeed(colors);
    }

    if (_videos.isEmpty) {
      return _buildEmptyView(colors);
    }

    return _buildVideoFeed(currentLang, colors);
  }

  /// Virtualized Playlist Feed
  Widget _buildPlaylistFeed(VocaColorPalette colors) {
    return RefreshIndicator(
      onRefresh: () => _loadFeed(refresh: true),
      color: colors.accentPrimary,
      backgroundColor: colors.bgCard,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isTablet = width >= VocaTokens.tabletBreakpoint;

          if (!isTablet) {
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              itemCount: _playlists.length,
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                return _buildPlaylistCard(_playlists[index], colors);
              },
            );
          }

          final crossAxisCount = width >= 1100 ? 3 : 2;
          const double spacing = 20.0;
          const double horizontalPadding = 16.0 * 2;
          final cardWidth = (width - horizontalPadding - spacing * (crossAxisCount - 1)) / crossAxisCount;
          final cardHeight = (cardWidth / (16 / 9)) + 100.0;
          final childAspectRatio = cardWidth / cardHeight;

          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: _playlists.length,
            itemBuilder: (context, index) {
              return _buildPlaylistCard(_playlists[index], colors);
            },
          );
        },
      ),
    );
  }

  /// 1:1 Playlist Card matching lingua-tube's .yt-video-card--playlist
  Widget _buildPlaylistCard(PlaylistItem playlist, VocaColorPalette colors) {
    final videoCount = playlist.videoIds.length;
    final thumbnailUrl = (playlist.thumbnail != null && playlist.thumbnail!.isNotEmpty)
        ? playlist.thumbnail!
        : (playlist.videoIds.isNotEmpty
            ? 'https://i.ytimg.com/vi/${playlist.videoIds.first}/hqdefault.jpg'
            : null);

    return Container(
      color: Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (playlist.videoIds.isNotEmpty) {
              PlayerCoordinator.instance.openVideo(
                context,
                videoId: playlist.videoIds.first,
                title: playlist.title,
                level: playlist.level,
                playlistTitle: playlist.title,
                playlistIndex: 0,
                playlistTotal: playlist.videoIds.length,
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 16:9 Thumbnail with Playlist Count Badge
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: thumbnailUrl != null
                          ? Image.network(
                              thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: colors.bgSecondary,
                                child: Center(
                                  child: Icon(Icons.playlist_play_rounded, color: colors.accentPrimary, size: 48),
                                ),
                              ),
                            )
                          : Container(
                              color: colors.bgSecondary,
                              child: Center(
                                child: Icon(Icons.playlist_play_rounded, color: colors.accentPrimary, size: 48),
                              ),
                            ),
                    ),

                    // Playlist Count Badge (Bottom-Right)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xCC000000),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.format_list_bulleted_rounded,
                              color: Colors.white70,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$videoCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Title, Subtitle, and Level Info
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 2, right: 2, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: colors.bgSurface,
                      child: Icon(Icons.playlist_play_rounded, size: 20, color: colors.accentPrimary),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            playlist.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            playlist.description?.isNotEmpty == true
                                ? playlist.description!
                                : '${context.t('playlist.playlist', null, 'Playlist')} • $videoCount ${videoCount == 1 ? context.t('history.videoSingular', null, 'video') : context.t('history.videoPlural', null, 'videos')}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (playlist.level != null && playlist.level!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            VocaLevelBadge(
                              level: playlist.level!,
                              size: LevelBadgeSize.small,
                            ),
                          ],
                        ],
                      ),
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

  /// Virtualized Video Feed
  Widget _buildVideoFeed(String currentLang, VocaColorPalette colors) {
    return RefreshIndicator(
      onRefresh: () => _loadFeed(refresh: true),
      color: colors.accentPrimary,
      backgroundColor: colors.bgCard,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isTablet = width >= VocaTokens.tabletBreakpoint;

          if (!isTablet) {
            // Mobile (< 720dp): Virtualized ListView with recycled cards
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              itemCount: _videos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                return _buildVideoCard(_videos[index], currentLang, colors);
              },
            );
          }

          // Tablet (>= 720dp): 2 or 3 column virtualized GridView
          final crossAxisCount = width >= 1100 ? 3 : 2;
          const double spacing = 20.0;
          const double horizontalPadding = 16.0 * 2;
          final cardWidth = (width - horizontalPadding - spacing * (crossAxisCount - 1)) / crossAxisCount;
          final cardHeight = (cardWidth / (16 / 9)) + 100.0;
          final childAspectRatio = cardWidth / cardHeight;

          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: _videos.length,
            itemBuilder: (context, index) {
              return _buildVideoCard(_videos[index], currentLang, colors);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyView(VocaColorPalette colors) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.bgCard,
                shape: BoxShape.circle,
                border: Border.all(color: colors.borderColor),
              ),
              child: Icon(Icons.search_off_rounded, color: colors.textSecondary, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              context.t('explore.noVideos', null, 'No immersion videos found'),
              style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results for "$_searchQuery". Paste a direct YouTube link or try different keywords.'
                  : 'No videos found with the selected filters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                  _selectedCategory = 'All';
                  _selectedLevel = 'All';
                  _currentTab = ExploreTab.videos;
                });
                _loadFeed();
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: Text(context.t('explore.resetFilters', null, 'Reset All Filters')),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.bgCard,
                foregroundColor: colors.accentPrimary,
                side: BorderSide(color: colors.accentPrimary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(VocaColorPalette colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, color: colors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Could not load videos',
              style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Network request failed. Please check your connection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _loadFeed(refresh: true),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.t('common.retry', null, 'Retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
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
