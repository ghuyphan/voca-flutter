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
import '../sheets/level_filter_sheet.dart';
import '../widgets/voca_empty_state.dart';
import 'models/explore_category.dart';
import 'widgets/explore_chips_bar.dart';
import 'widgets/explore_responsive_feed.dart';
import 'widgets/explore_spotlight_bar.dart';
import 'widgets/playlist_feed_card.dart';
import 'widgets/video_feed_card.dart';

/// Clean, high-performance, signal-driven Explore Screen with scoped reactivity & fluid transitions.
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
    ).animate(_searchBarAnimation);

    _searchController.addListener(_onSearchInputChanged);

    // React to global activeLanguage changes
    _langEffectDispose = effect(() {
      final _ = AppState.instance.activeLanguage.value;
      untracked(() {
        _selectedLevel.value = 'All';
        _selectedCategory.value = ExploreCategory.all;
        _searchController.clear();
        _searchQuery.value = '';
        _directDetectedVideoId.value = null;
        _loadFeed(refresh: true);
      });
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

      // Reset opposite direction momentum before accumulating
      if ((delta > 0 && _accumulatedDelta < 0) || (delta < 0 && _accumulatedDelta > 0)) {
        _accumulatedDelta = 0;
      }
      _accumulatedDelta += delta;

      if (_accumulatedDelta > 45 && notification.metrics.pixels > 80) {
        if (_isSearchBarVisible) {
          _isSearchBarVisible = false;
          _searchBarAnimController.reverse();
        }
      } else if (_accumulatedDelta < -20) {
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

  String? _mapLevelToTier(String level) {
    if (level == 'All') return null;
    return VideoLevelService.deriveLevelTier(level).apiTier;
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
          result = _filterPlaylistsByLevel(result, _selectedLevel.value);
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
    final tier = _mapLevelToTier(_selectedLevel.value);
    final category = _selectedCategory.value.serverCategory;
    final query = _searchQuery.value.isNotEmpty ? _searchQuery.value : null;

    try {
      final list = await AppState.instance.apiClient.getRecommendedVideos(
        lang: lang,
        tier: tier,
        category: category,
        query: query,
        limit: _pageSize,
        offset: 0,
        refresh: refresh,
      );

      if (currentSeq != _requestSequenceId) return;

      _videos.value = _filterVideosByTier(list, tier, lang);
      _hasMore.value = list.length >= _pageSize;
      _isLoading.value = false;
    } catch (e) {
      if (currentSeq != _requestSequenceId) return;
      _errorMessage.value = e.toString();
      _isLoading.value = false;
    }
  }

  List<PlaylistItem> _filterPlaylistsByLevel(
    List<PlaylistItem> playlists,
    String selectedLevel,
  ) {
    if (selectedLevel == 'All') return playlists;
    final targetTier = VideoLevelService.deriveLevelTier(selectedLevel);
    final normalizedTarget = selectedLevel.replaceAll(' ', '').toUpperCase();
    return playlists.where((p) {
      if (p.level != null && p.level!.isNotEmpty) {
        final pTier = VideoLevelService.deriveLevelTier(p.level!);
        if (pTier == targetTier) return true;
        final pNorm = p.level!.replaceAll(' ', '').toUpperCase();
        if (pNorm.contains(normalizedTarget)) return true;
      }
      final combined = '${p.title} ${p.description ?? ''}';
      if (combined.trim().isNotEmpty) {
        final metaTier = VideoLevelService.deriveLevelTier(combined);
        if (metaTier == targetTier) return true;
      }
      for (final tag in p.tags) {
        if (tag.isNotEmpty && VideoLevelService.deriveLevelTier(tag) == targetTier) {
          return true;
        }
      }
      return false;
    }).toList();
  }

  List<Map<String, dynamic>> _filterVideosByTier(
    List<Map<String, dynamic>> videos,
    String? tier,
    String lang,
  ) {
    if (_selectedLevel.value == 'All' || tier == null) return videos;
    return videos.where((item) {
      final itemTier = (item['tier'] as String? ?? '').toLowerCase().trim();
      if (itemTier.isNotEmpty && itemTier == tier) return true;

      final itemLevel = VideoFeedCard.resolveVideoLevel(item, lang);
      if (itemLevel.isNotEmpty) {
        final derived = VideoLevelService.deriveLevelTier(itemLevel);
        if (derived.apiTier == tier) return true;
      }
      return false;
    }).toList();
  }

  Future<void> _loadMore() async {
    if (_isLoading.value || _isLoadingMore.value || !_hasMore.value) return;
    if (_currentTab.value == ExploreTab.playlists) return;

    final currentSeq = _requestSequenceId;
    _isLoadingMore.value = true;
    _currentOffset += _pageSize;

    final lang = AppState.instance.activeLanguage.value;
    final tier = _mapLevelToTier(_selectedLevel.value);

    final category = _selectedCategory.value.serverCategory;
    final query = _searchQuery.value.isNotEmpty ? _searchQuery.value : null;

    try {
      final list = await AppState.instance.apiClient.getRecommendedVideos(
        lang: lang,
        tier: tier,
        category: category,
        query: query,
        limit: _pageSize,
        offset: _currentOffset,
        refresh: false,
      );

      if (currentSeq != _requestSequenceId) return;

      if (list.isEmpty) {
        _hasMore.value = false;
      } else {
        final newItems = _filterVideosByTier(list, tier, lang);
        final existingIds = _videos.value.map((v) => v['videoId']).toSet();
        final filtered = newItems.where((v) => !existingIds.contains(v['videoId'])).toList();
        _videos.value = [..._videos.value, ...filtered];
        _hasMore.value = list.length >= _pageSize;
      }
    } catch (e) {
      if (currentSeq == _requestSequenceId) {
        _currentOffset = (_currentOffset - _pageSize).clamp(0, double.infinity).toInt();
      }
      debugPrint('[ExploreScreen] Error loading more videos: $e');
    } finally {
      if (currentSeq == _requestSequenceId) {
        _isLoadingMore.value = false;
      }
    }
  }

  void _navigateToPlayer(String videoId, String title, {String? channel, String? level, String? thumbnail, int? duration}) {
    PlayerCoordinator.instance.openVideo(
      context,
      videoId: videoId,
      title: title,
      channel: channel,
      level: level,
      thumbnail: thumbnail,
      initialDuration: duration,
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
    _selectedCategory.value = ExploreCategory.all;
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
    final levels = VideoLevelService.getAvailableLevelFilters(currentLang);

    LevelFilterSheet.show(
      context,
      selectedLevel: _selectedLevel.value,
      availableLevels: levels,
      onApply: (level) {
        _selectedLevel.value = level;
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
            border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.4)),
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

  /// Reusable scrollable empty state wrapper to eliminate layout duplication
  Widget _buildEmptyFeedContainer({
    required VocaColorPalette colors,
    required Widget child,
  }) {
    return RefreshIndicator(
      onRefresh: () => _loadFeed(refresh: true),
      color: colors.accentPrimary,
      backgroundColor: colors.bgCard,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return Scaffold(
      backgroundColor: colors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 4),
            // 1. Collapsing Spotlight Search Bar with animated direct video detection banner
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
                      // Scoped Watch: Only direct video banner reacts to detected ID changes
                      Watch((context) {
                        final directId = _directDetectedVideoId.value;
                        return AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          child: directId != null
                              ? _buildDirectVideoBanner(directId, colors)
                              : const SizedBox.shrink(),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Chips Bar: Scoped Watch reading only filter selections
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Watch((context) {
                final currentTab = _currentTab.value;
                final selectedCategory = _selectedCategory.value;
                final selectedLevel = _selectedLevel.value;

                return ExploreChipsBar(
                  selectedCategory: selectedCategory,
                  selectedLevel: selectedLevel,
                  currentTab: currentTab,
                  onLevelFilterPressed: _openFilterSheet,
                  onAllPressed: () {
                    if (_currentTab.value == ExploreTab.videos &&
                        _selectedCategory.value == ExploreCategory.all) {
                      _loadFeed(refresh: true);
                    } else {
                      _currentTab.value = ExploreTab.videos;
                      _selectedCategory.value = ExploreCategory.all;
                      _loadFeed();
                    }
                  },
                  onPlaylistsPressed: () {
                    if (_searchController.text.isNotEmpty || _searchQuery.value.isNotEmpty) {
                      _searchController.clear();
                      _searchQuery.value = '';
                      _directDetectedVideoId.value = null;
                    }
                    if (_currentTab.value == ExploreTab.playlists) {
                      _loadFeed(refresh: true);
                    } else {
                      _currentTab.value = ExploreTab.playlists;
                      _loadFeed();
                    }
                  },
                  onCategorySelected: (cat) {
                    if (_searchController.text.isNotEmpty || _searchQuery.value.isNotEmpty) {
                      _searchController.clear();
                      _searchQuery.value = '';
                      _directDetectedVideoId.value = null;
                    }
                    if (_currentTab.value == ExploreTab.videos &&
                        _selectedCategory.value == cat) {
                      _selectedCategory.value = ExploreCategory.all;
                      _loadFeed();
                    } else {
                      _currentTab.value = ExploreTab.videos;
                      _selectedCategory.value = cat;
                      _loadFeed();
                    }
                  },
                );
              }),
            ),

            // 3. Virtualized Main Feed: Scoped Watch for feed content
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScrollNotification,
                child: Watch((context) {
                  final currentLang = AppState.instance.activeLanguage.value;
                  final currentTab = _currentTab.value;
                  final searchQuery = _searchQuery.value;
                  final isLoading = _isLoading.value;
                  final isLoadingMore = _isLoadingMore.value;
                  final errorMessage = _errorMessage.value;
                  final videos = _videos.value;
                  final playlists = _playlists.value;

                  const feedBottomPadding = 24.0;

                  Widget feedContent;

                  if (isLoading) {
                    feedContent = KeyedSubtree(
                      key: const ValueKey('feed_skeleton'),
                      child: ExploreResponsiveFeed.buildSkeletonFeed(context),
                    );
                  } else if (errorMessage != null) {
                    feedContent = KeyedSubtree(
                      key: const ValueKey('feed_error'),
                      child: RefreshIndicator(
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
                      ),
                    );
                  } else if (currentTab == ExploreTab.playlists) {
                    if (playlists.isEmpty) {
                      feedContent = KeyedSubtree(
                        key: const ValueKey('playlists_empty'),
                        child: _buildEmptyFeedContainer(
                          colors: colors,
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
                      );
                    } else {
                      feedContent = KeyedSubtree(
                        key: const ValueKey('playlists_list'),
                        child: ExploreResponsiveFeed(
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
                        ),
                      );
                    }
                  } else {
                    // Videos tab
                    if (videos.isEmpty) {
                      feedContent = KeyedSubtree(
                        key: const ValueKey('videos_empty'),
                        child: _buildEmptyFeedContainer(
                          colors: colors,
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
                                      FilledButton.icon(
                                        onPressed: () async {
                                          final uri = Uri.parse(
                                            'https://www.youtube.com/results?search_query=${Uri.encodeComponent(searchQuery)}',
                                          );
                                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        },
                                        icon: const Icon(Icons.open_in_new_rounded, size: 14, color: Colors.white),
                                        label: Text(context.t('explore.searchOnYouTube', null, 'Search on YouTube')),
                                        style: FilledButton.styleFrom(
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
                      );
                    } else {
                      feedContent = KeyedSubtree(
                        key: const ValueKey('videos_list'),
                        child: ExploreResponsiveFeed(
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
                            final duration = (item['duration'] as num?)?.toInt();

                            return VideoFeedCard(
                              video: item,
                              currentLang: currentLang,
                              onTap: () => _navigateToPlayer(
                                videoId,
                                title,
                                channel: channel,
                                level: levelTag,
                                thumbnail: thumbnail,
                                duration: duration,
                              ),
                            );
                          },
                        ),
                      );
                    }
                  }

                  // Smooth crossfade transition between loading, error, empty, and feed states
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    layoutBuilder: (currentChild, previousChildren) {
                      final seenKeys = <Key>{};
                      if (currentChild?.key != null) seenKeys.add(currentChild!.key!);
                      final uniquePrevious = <Widget>[];
                      for (final child in previousChildren) {
                        if (child.key == null || seenKeys.add(child.key!)) {
                          uniquePrevious.add(child);
                        }
                      }
                      return Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          ...uniquePrevious,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    child: feedContent,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
