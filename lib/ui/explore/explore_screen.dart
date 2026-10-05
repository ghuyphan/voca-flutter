import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/i18n_service.dart';
import '../../services/video_level_service.dart';
import '../../state/app_state.dart';
import '../../state/player_coordinator.dart';
import '../../utils/youtube_url_parser.dart';
import '../sheets/category_filter_sheet.dart';
import '../widgets/voca_empty_state.dart';
import 'models/explore_category.dart';
import 'widgets/explore_chips_bar.dart';
import 'widgets/explore_responsive_feed.dart';
import 'widgets/explore_spotlight_bar.dart';
import 'widgets/playlist_feed_card.dart';
import 'widgets/video_feed_card.dart';

/// Clean, high-performance, signal-driven Explore Screen matching lingua-tube.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late final AnimationController _searchBarAnimController;
  late final Animation<double> _searchBarAnimation;
  late final Animation<Offset> _searchBarSlideAnimation;
  bool _isSearchBarVisible = true;
  double _accumulatedDelta = 0.0;

  // Reactive State Signals
  late final Signal<ExploreTab> _currentTab = signal(ExploreTab.videos);
  late final Signal<ExploreCategory> _selectedCategory = signal(ExploreCategory.all);
  late final Signal<String> _selectedLevel = signal('All');
  late final Signal<String> _searchQuery = signal('');
  late final Signal<String?> _directDetectedVideoId = signal(null);

  late final Signal<List<Map<String, dynamic>>> _videos = signal([]);
  late final Signal<List<PlaylistItem>> _playlists = signal([]);
  late final Signal<bool> _isLoading = signal(true);
  late final Signal<bool> _isLoadingMore = signal(false);
  late final Signal<bool> _hasMore = signal(true);
  late final Signal<String?> _errorMessage = signal(null);

  static const int _pageSize = 24;
  int _currentOffset = 0;
  VoidCallback? _langEffectDispose;
  int _requestSequenceId = 0;

  @override
  void initState() {
    super.initState();
    _searchBarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0,
    );
    _searchBarAnimation = CurvedAnimation(
      parent: _searchBarAnimController,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn,
    );
    _searchBarSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _searchBarAnimController,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn,
    ));

    _searchController.addListener(_onSearchInputChanged);

    // React to global activeLanguage changes
    _langEffectDispose = effect(() {
      final _ = AppState.instance.activeLanguage.value;
      _selectedLevel.value = 'All';
      _loadFeed(refresh: true);
    });
  }

  @override
  void dispose() {
    _langEffectDispose?.call();
    _searchBarAnimController.dispose();
    _searchController.removeListener(_onSearchInputChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchInputChanged() {
    final text = _searchController.text.trim();
    final directId = YouTubeUrlParser.extractVideoId(text);
    _directDetectedVideoId.value = directId;

    if (text.isNotEmpty && !_isSearchBarVisible) {
      _isSearchBarVisible = true;
      _searchBarAnimController.forward();
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    // Trigger infinite scroll when user scrolls within 350px of feed end
    if (notification.metrics.extentAfter < 350) {
      _loadMore();
    }

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;

      if (_searchFocusNode.hasFocus && delta.abs() > 3) {
        _searchFocusNode.unfocus();
      }

      if (notification.metrics.pixels <= 10) {
        _accumulatedDelta = 0;
        if (!_isSearchBarVisible) {
          _isSearchBarVisible = true;
          _searchBarAnimController.forward();
        }
        return false;
      }

      if (delta > 0) {
        if (_accumulatedDelta < 0) _accumulatedDelta = 0;
        _accumulatedDelta += delta;
      } else if (delta < 0) {
        if (_accumulatedDelta > 0) _accumulatedDelta = 0;
        _accumulatedDelta += delta;
      }

      if (_accumulatedDelta > 15 && notification.metrics.pixels > 30) {
        if (_isSearchBarVisible) {
          _isSearchBarVisible = false;
          _searchBarAnimController.reverse();
        }
      } else if (_accumulatedDelta < -12) {
        if (!_isSearchBarVisible) {
          _isSearchBarVisible = true;
          _searchBarAnimController.forward();
        }
      }
    } else if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.idle) {
        _accumulatedDelta = 0;
      }
    }
    return false;
  }

  List<String> _getLevelsForLanguage(String lang) {
    return VideoLevelService.getAvailableLevelFilters(lang);
  }

  String? _mapLevelToTier(String lang, String level) {
    if (level == 'All') return null;
    final tier = VideoLevelService.deriveLevelTier(level);
    return tier == ProficiencyLevelTier.upperIntermediate
        ? 'upper_intermediate'
        : tier.name;
  }

  Future<void> _loadFeed({bool refresh = false}) async {
    final currentSeq = ++_requestSequenceId;
    _currentOffset = 0;
    _hasMore.value = true;
    _isLoading.value = true;
    _errorMessage.value = null;

    final lang = AppState.instance.activeLanguage.value;

    if (_currentTab.value == ExploreTab.playlists) {
      try {
        final allPlaylists = await AppState.instance.supabaseService.getExplorePlaylists(language: lang);
        if (currentSeq != _requestSequenceId) return;

        List<PlaylistItem> result = allPlaylists;

        if (_selectedLevel.value != 'All') {
          final normalizedLevel = _selectedLevel.value.replaceAll(' ', '').toUpperCase();
          result = result.where((p) {
            final lvl = (p.level ?? '').replaceAll(' ', '').toUpperCase();
            return lvl.contains(normalizedLevel);
          }).toList();
        }

        if (_searchQuery.value.isNotEmpty) {
          final q = _searchQuery.value.toLowerCase();
          result = result.where((p) {
            final title = p.title.toLowerCase();
            final desc = (p.description ?? '').toLowerCase();
            return title.contains(q) || desc.contains(q);
          }).toList();
        }

        _playlists.value = result;
        _hasMore.value = false;
        _isLoading.value = false;
      } catch (e) {
        if (currentSeq != _requestSequenceId) return;
        _errorMessage.value = e.toString();
        _isLoading.value = false;
      }
      return;
    }

    // Videos tab
    final tier = _mapLevelToTier(lang, _selectedLevel.value);

    String? query;
    if (_searchQuery.value.isNotEmpty) {
      query = _searchQuery.value;
    } else if (_selectedCategory.value != ExploreCategory.all &&
        _selectedCategory.value != ExploreCategory.trending) {
      query = _selectedCategory.value.searchKeyword;
    }

    try {
      final list = await AppState.instance.apiClient.getRecommendedVideos(
        lang: lang,
        tier: tier,
        query: query,
        limit: _pageSize,
        offset: 0,
        refresh: refresh,
      );

      if (currentSeq != _requestSequenceId) return;

      List<Map<String, dynamic>> resultList = list;
      if (_selectedLevel.value != 'All') {
        final normalizedLevel = _selectedLevel.value.replaceAll(' ', '').toUpperCase();
        resultList = list.where((item) {
          final itemLevel = VideoFeedCard.resolveVideoLevel(item, lang).replaceAll(' ', '').toUpperCase();
          final itemTier = (item['tier'] as String? ?? '').toLowerCase();
          return itemLevel.contains(normalizedLevel) || (tier != null && itemTier == tier);
        }).toList();
      }

      _videos.value = resultList;
      _hasMore.value = list.length >= _pageSize;
      _isLoading.value = false;
    } catch (e) {
      if (currentSeq != _requestSequenceId) return;
      _errorMessage.value = e.toString();
      _isLoading.value = false;
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading.value || _isLoadingMore.value || !_hasMore.value) return;
    if (_currentTab.value == ExploreTab.playlists) return;

    final currentSeq = _requestSequenceId;
    _isLoadingMore.value = true;
    _currentOffset += _pageSize;

    final lang = AppState.instance.activeLanguage.value;
    final tier = _mapLevelToTier(lang, _selectedLevel.value);

    String? query;
    if (_searchQuery.value.isNotEmpty) {
      query = _searchQuery.value;
    } else if (_selectedCategory.value != ExploreCategory.all &&
        _selectedCategory.value != ExploreCategory.trending) {
      query = _selectedCategory.value.searchKeyword;
    }

    try {
      final list = await AppState.instance.apiClient.getRecommendedVideos(
        lang: lang,
        tier: tier,
        query: query,
        limit: _pageSize,
        offset: _currentOffset,
        refresh: false,
      );

      if (currentSeq != _requestSequenceId) return;

      if (list.isEmpty) {
        _hasMore.value = false;
      } else {
        List<Map<String, dynamic>> newItems = list;
        if (_selectedLevel.value != 'All') {
          final normalizedLevel = _selectedLevel.value.replaceAll(' ', '').toUpperCase();
          newItems = list.where((item) {
            final itemLevel = VideoFeedCard.resolveVideoLevel(item, lang).replaceAll(' ', '').toUpperCase();
            final itemTier = (item['tier'] as String? ?? '').toLowerCase();
            return itemLevel.contains(normalizedLevel) || (tier != null && itemTier == tier);
          }).toList();
        }

        final existingIds = _videos.value.map((v) => v['videoId']).toSet();
        final filtered = newItems.where((v) => !existingIds.contains(v['videoId'])).toList();
        _videos.value = [..._videos.value, ...filtered];
        _hasMore.value = list.length >= _pageSize;
      }
    } catch (e) {
      debugPrint('[ExploreScreen] Error loading more videos: $e');
    } finally {
      if (currentSeq == _requestSequenceId) {
        _isLoadingMore.value = false;
      }
    }
  }

  void _navigateToPlayer(String videoId, String title, {String? channel, String? level, String? thumbnail}) {
    PlayerCoordinator.instance.openVideo(
      context,
      videoId: videoId,
      title: title,
      channel: channel,
      level: level,
      thumbnail: thumbnail,
    );
  }

  void _onDirectVideoDetected(String videoId) {
    _searchController.clear();
    _searchFocusNode.unfocus();
    _directDetectedVideoId.value = null;
    _navigateToPlayer(videoId, 'YouTube Video');
  }

  void _handleSearchSubmitted(String query) {
    final directId = YouTubeUrlParser.extractVideoId(query);
    if (directId != null) {
      _onDirectVideoDetected(directId);
      return;
    }

    _searchFocusNode.unfocus();
    _searchQuery.value = query;
    _loadFeed();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    _directDetectedVideoId.value = null;
    if (_searchQuery.value.isNotEmpty) {
      _searchQuery.value = '';
      _loadFeed();
    }
  }

  void _resetFilters() {
    _searchController.clear();
    _searchQuery.value = '';
    _directDetectedVideoId.value = null;
    _selectedCategory.value = ExploreCategory.all;
    _selectedLevel.value = 'All';
    _currentTab.value = ExploreTab.videos;
    _loadFeed();
  }

  void _openFilterSheet() {
    final currentLang = AppState.instance.activeLanguage.value;
    final levels = _getLevelsForLanguage(currentLang);

    CategoryFilterSheet.show(
      context,
      selectedCategory: _selectedCategory.value.id,
      selectedLevel: _selectedLevel.value,
      availableLevels: levels,
      onApply: (category, level) {
        _selectedCategory.value = ExploreCategory.fromId(category);
        _selectedLevel.value = level;
        _currentTab.value = ExploreTab.videos;
        _loadFeed();
      },
    );
  }

  Widget _buildDirectVideoBanner(String videoId, VocaColorPalette colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _onDirectVideoDetected(videoId),
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
                  context.t('explore.videoDetected', {'id': videoId}, 'Valid YouTube Video ($videoId) detected!'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return Watch((context) {
      final currentLang = AppState.instance.activeLanguage.value;
      final levels = _getLevelsForLanguage(currentLang);
      final currentTab = _currentTab.value;
      final selectedCategory = _selectedCategory.value;
      final selectedLevel = _selectedLevel.value;
      final searchQuery = _searchQuery.value;
      final directVideoId = _directDetectedVideoId.value;
      final isLoading = _isLoading.value;
      final isLoadingMore = _isLoadingMore.value;
      final errorMessage = _errorMessage.value;
      final videos = _videos.value;
      final playlists = _playlists.value;

      return Scaffold(
        backgroundColor: colors.bgPrimary,
        body: SafeArea(
          child: Column(
            children: [
              // 1. Collapsing Spotlight Search Bar
              SizeTransition(
                sizeFactor: _searchBarAnimation,
                axisAlignment: -1.0,
                child: FadeTransition(
                  opacity: _searchBarAnimation,
                  child: SlideTransition(
                    position: _searchBarSlideAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ExploreSpotlightBar(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onSearchSubmitted: _handleSearchSubmitted,
                          onClear: _clearSearch,
                          onDirectVideoDetected: _onDirectVideoDetected,
                        ),
                        if (directVideoId != null)
                          _buildDirectVideoBanner(directVideoId, colors),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Chips Bar: Filter button, All, Playlists, Level chips
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: ExploreChipsBar(
                  selectedCategory: selectedCategory,
                  selectedLevel: selectedLevel,
                  currentTab: currentTab,
                  levels: levels,
                  onFilterPressed: _openFilterSheet,
                  onAllPressed: () {
                    _currentTab.value = ExploreTab.videos;
                    _selectedLevel.value = 'All';
                    _selectedCategory.value = ExploreCategory.all;
                    _loadFeed();
                  },
                  onPlaylistsPressed: () {
                    _currentTab.value = currentTab == ExploreTab.playlists
                        ? ExploreTab.videos
                        : ExploreTab.playlists;
                    _loadFeed();
                  },
                  onLevelSelected: (lvl) {
                    _selectedLevel.value = selectedLevel == lvl ? 'All' : lvl;
                    _loadFeed();
                  },
                ),
              ),

              // 4. Virtualized Main Feed (Scroll-notified for search bar collapse & infinite scroll)
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: _onScrollNotification,
                  child: Builder(
                    builder: (context) {
                      if (isLoading) {
                        return ExploreResponsiveFeed.buildSkeletonFeed(context);
                      }

                      if (errorMessage != null) {
                        return RefreshIndicator(
                          onRefresh: () => _loadFeed(refresh: true),
                          color: colors.accentPrimary,
                          backgroundColor: colors.bgCard,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 48),
                              child: VocaEmptyState(
                                icon: Icons.cloud_off_rounded,
                                variant: EmptyStateIconVariant.error,
                                title: context.t('explore.networkError', null, 'Could not load videos'),
                                description: errorMessage,
                                actionLabel: context.t('common.retry', null, 'Retry'),
                                onAction: () => _loadFeed(refresh: true),
                              ),
                            ),
                          ),
                        );
                      }

                      final coord = PlayerCoordinator.instance;
                      final isMiniActive = coord.hasActiveVideo && coord.isMiniplayer.value;
                      final feedBottomPadding = isMiniActive ? 168.0 : 96.0;

                      if (currentTab == ExploreTab.playlists) {
                        if (playlists.isEmpty) {
                          return RefreshIndicator(
                            onRefresh: () => _loadFeed(refresh: true),
                            color: colors.accentPrimary,
                            backgroundColor: colors.bgCard,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                                        child: VocaEmptyState(
                                          icon: Icons.search_off_rounded,
                                          variant: EmptyStateIconVariant.neutral,
                                          title: context.t('playlist.empty.title', null, 'No playlists found'),
                                          description: searchQuery.isNotEmpty
                                              ? 'No playlists match "$searchQuery". Try different keywords or reset filters.'
                                              : 'No playlists available for the selected level.',
                                          actionLabel: context.t('explore.resetFilters', null, 'Reset All Filters'),
                                          onAction: _resetFilters,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }

                        return ExploreResponsiveFeed(
                          itemCount: playlists.length,
                          bottomPadding: feedBottomPadding,
                          onRefresh: () => _loadFeed(refresh: true),
                          itemBuilder: (context, index) {
                            final item = playlists[index];
                            return PlaylistFeedCard(
                              playlist: item,
                              onTap: () {
                                if (item.videoIds.isNotEmpty) {
                                  final playlistVideos = item.videoIds.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final vid = entry.value;
                                    return PlaylistVideo(
                                      videoId: vid,
                                      title: idx == 0 ? item.title : '${item.title} #${idx + 1}',
                                      thumbnail: 'https://i.ytimg.com/vi/$vid/hqdefault.jpg',
                                      level: item.level,
                                      position: idx,
                                    );
                                  }).toList();

                                  PlayerCoordinator.instance.openVideo(
                                    context,
                                    videoId: item.videoIds.first,
                                    title: item.title,
                                    thumbnail: 'https://i.ytimg.com/vi/${item.videoIds.first}/hqdefault.jpg',
                                    level: item.level,
                                    playlistTitle: item.title,
                                    playlistIndex: 0,
                                    playlistTotal: item.videoIds.length,
                                    playlist: playlistVideos,
                                  );
                                }
                              },
                            );
                          },
                        );
                      }

                      // Videos tab
                      if (videos.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () => _loadFeed(refresh: true),
                          color: colors.accentPrimary,
                          backgroundColor: colors.bgCard,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                                      child: searchQuery.isNotEmpty
                                          ? VocaEmptyState(
                                              icon: Icons.search_off_rounded,
                                              variant: EmptyStateIconVariant.neutral,
                                              title: context.t('playlist.empty.searchTitle', null, 'No matching videos found'),
                                              description: context.t('playlist.empty.searchHint', null, 'Try different keywords or paste a YouTube link.'),
                                              actions: Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                alignment: WrapAlignment.center,
                                                children: [
                                                  OutlinedButton.icon(
                                                    onPressed: _clearSearch,
                                                    icon: Icon(Icons.close_rounded, size: 14, color: colors.textSecondary),
                                                    label: Text(context.t('common.clear', null, 'Clear search')),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: colors.textPrimary,
                                                      side: BorderSide(color: colors.borderColor),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                    ),
                                                  ),
                                                  ElevatedButton.icon(
                                                    onPressed: () async {
                                                      final uri = Uri.parse(
                                                        'https://www.youtube.com/results?search_query=${Uri.encodeComponent(searchQuery)}',
                                                      );
                                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                    },
                                                    icon: const Icon(Icons.open_in_new_rounded, size: 14, color: Colors.white),
                                                    label: Text(context.t('explore.searchOnYouTube', null, 'Search on YouTube')),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: colors.accentPrimary,
                                                      foregroundColor: Colors.white,
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : VocaEmptyState(
                                              icon: Icons.filter_alt_off_rounded,
                                              variant: EmptyStateIconVariant.neutral,
                                              title: context.t('explore.noVideos', null, 'No videos found'),
                                              description: context.t(
                                                'explore.noFilterVideosDesc',
                                                null,
                                                'No videos found with the selected filters.',
                                              ),
                                              actions: OutlinedButton(
                                                onPressed: _resetFilters,
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: colors.textPrimary,
                                                  side: BorderSide(color: colors.borderColor),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                ),
                                                child: Text(context.t('explore.resetFilters', null, 'Reset All Filters')),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }

                      return ExploreResponsiveFeed(
                        itemCount: videos.length,
                        isLoadingMore: isLoadingMore,
                        bottomPadding: feedBottomPadding,
                        onRefresh: () => _loadFeed(refresh: true),
                        itemBuilder: (context, index) {
                          final item = videos[index];
                          final videoId = item['videoId'] as String? ?? '';
                          final title = item['title'] as String? ?? 'YouTube Video';
                          final channel = item['channel'] as String? ?? 'YouTube Creator';
                          final levelTag = VideoFeedCard.resolveVideoLevel(item, currentLang);
                          final thumbnail = item['thumbnail'] as String?;

                          return VideoFeedCard(
                            video: item,
                            currentLang: currentLang,
                            onTap: () => _navigateToPlayer(
                              videoId,
                              title,
                              channel: channel,
                              level: levelTag,
                              thumbnail: thumbnail,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
