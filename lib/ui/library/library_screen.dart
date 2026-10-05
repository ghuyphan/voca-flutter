// lib/ui/library/library_screen.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../settings/settings_screen.dart';
import '../sheets/create_playlist_sheet.dart';
import '../widgets/voca_confirm_dialog.dart';
import '../widgets/voca_empty_state.dart';
import 'widgets/history_filter_toolbar.dart';
import 'widgets/history_video_card.dart';
import 'widgets/library_playlist_card.dart';
import 'widgets/library_top_bar.dart';

/// Rebuilt Library Screen matching lingua-tube's history-page and playlist-page 1:1.
/// Features a sleek top segmented switcher, solid filter toolbar, and responsive feeds.
class LibraryScreen extends StatefulWidget {
  final VoidCallback? onNavigateToExplore;
  final int initialTabIndex;

  const LibraryScreen({
    super.key,
    this.onNavigateToExplore,
    this.initialTabIndex = 0,
  });

  @override
  State<LibraryScreen> createState() => LibraryScreenState();
}

class LibraryScreenState extends State<LibraryScreen> {
  int _currentTab = 0; // 0: Watch History, 1: Playlists

  List<Map<String, dynamic>> _historyItems = [];
  List<PlaylistItem> _playlists = [];
  bool _isLoadingHistory = true;
  bool _isLoadingPlaylists = true;

  // History Filter & Search State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedLangFilter = 'all';
  String _selectedLevelFilter = 'all';
  bool _showOnlyFavorites = false;
  Set<String> _savedVideoIds = {};

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTabIndex.clamp(0, 1);
    _searchController.addListener(_onSearchChanged);
    _loadHistory();
    _loadPlaylists();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void switchToPlaylists() {
    if (_currentTab != 1) setState(() => _currentTab = 1);
  }

  void switchToHistory() {
    if (_currentTab != 0) setState(() => _currentTab = 0);
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await AppState.instance.supabaseService.getHistory(limit: 100);
      if (mounted) {
        setState(() {
          _historyItems = history;
          _isLoadingHistory = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _loadPlaylists() async {
    setState(() => _isLoadingPlaylists = true);
    try {
      final playlists = await AppState.instance.supabaseService.getPlaylists();
      final defaultSaved = playlists.firstWhere(
        (p) => p.id == 'default_saved',
        orElse: () => PlaylistItem(
          id: 'default_saved',
          userId: 'guest',
          title: 'Saved Videos',
          language: 'all',
          videoIds: const [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (mounted) {
        setState(() {
          _playlists = playlists;
          _savedVideoIds = Set.from(defaultSaved.videoIds);
          _isLoadingPlaylists = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPlaylists = false);
    }
  }

  Future<void> _toggleFavorite(Map<String, dynamic> item) async {
    final videoId = item['video_id'] as String? ?? item['videoId'] as String? ?? '';
    if (videoId.isEmpty) return;

    final isFav = _savedVideoIds.contains(videoId);
    setState(() {
      if (isFav) {
        _savedVideoIds.remove(videoId);
      } else {
        _savedVideoIds.add(videoId);
      }
    });

    if (isFav) {
      await AppState.instance.supabaseService.removeVideoFromPlaylist(
        playlistId: 'default_saved',
        videoId: videoId,
      );
    } else {
      await AppState.instance.supabaseService.addVideoToPlaylist(
        playlistId: 'default_saved',
        videoId: videoId,
        thumbnail: item['thumbnail'] as String?,
      );
    }
  }

  Future<void> _removeHistoryItem(Map<String, dynamic> item) async {
    final id = item['id'] as String? ?? item['video_id'] as String? ?? '';
    final index = _historyItems.indexOf(item);

    setState(() => _historyItems.remove(item));
    await AppState.instance.supabaseService.deleteHistoryItem(id);

    if (!mounted) return;
    final colors = context.vocaColors;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colors.bgCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colors.borderColor),
        ),
        content: Text(
          'Video removed from history',
          style: TextStyle(color: colors.textPrimary, fontSize: 13),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: colors.accentPrimary,
          onPressed: () async {
            setState(() {
              if (index >= 0 && index <= _historyItems.length) {
                _historyItems.insert(index, item);
              } else {
                _historyItems.add(item);
              }
            });
            await AppState.instance.supabaseService.saveHistory(
              id: id,
              videoId: item['video_id'] as String? ?? '',
              title: item['title'] as String? ?? '',
              thumbnail: item['thumbnail'] as String? ?? '',
              channel: item['channel'] as String? ?? '',
              duration: (item['duration'] as num?)?.toInt() ?? 0,
              language: item['language'] as String? ?? 'ja',
              progress: (item['progress'] as num?)?.toDouble() ?? 0.0,
            );
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showVocaConfirmDialog(
      context: context,
      title: context.t('history.clearConfirm', null, 'Clear Watch History'),
      message: context.t(
        'history.clearAllWarning',
        null,
        'This will permanently remove all videos from your watch history.',
      ),
      confirmText: context.t('history.clearAll', null, 'Clear All'),
      variant: ConfirmDialogVariant.danger,
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed == true) {
      await AppState.instance.supabaseService.clearHistory();
      if (mounted) {
        setState(() => _historyItems.clear());
        ToastService.info(context, 'Watch history cleared');
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredHistory() {
    return _historyItems.where((item) {
      final title = (item['title'] as String? ?? '').toLowerCase();
      final channel = (item['channel'] as String? ?? '').toLowerCase();
      final lang = (item['language'] as String? ?? '').toLowerCase();
      final videoId = item['video_id'] as String? ?? item['videoId'] as String? ?? '';

      if (_searchQuery.isNotEmpty && !title.contains(_searchQuery) && !channel.contains(_searchQuery)) {
        return false;
      }
      if (_selectedLangFilter != 'all' && lang != _selectedLangFilter) {
        return false;
      }
      if (_selectedLevelFilter != 'all') {
        final level = (item['level'] as String? ?? '').replaceAll(' ', '').toUpperCase();
        final filter = _selectedLevelFilter.replaceAll(' ', '').toUpperCase();
        if (level.isNotEmpty && !level.contains(filter)) {
          return false;
        }
      }
      if (_showOnlyFavorites && !_savedVideoIds.contains(videoId)) {
        return false;
      }
      return true;
    }).toList();
  }

  // ==========================================
  // TAB 1: WATCH HISTORY VIEW
  // ==========================================
  Widget _buildHistoryTab(VocaColorPalette colors) {
    if (_isLoadingHistory) {
      return Center(child: CircularProgressIndicator(color: colors.accentPrimary));
    }

    final filteredItems = _getFilteredHistory();

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: colors.accentPrimary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // Filter Toolbar
          SliverToBoxAdapter(
            child: HistoryFilterToolbar(
              searchController: _searchController,
              searchQuery: _searchQuery,
              selectedLang: _selectedLangFilter,
              selectedLevel: _selectedLevelFilter,
              showOnlyFavorites: _showOnlyFavorites,
              hasHistoryItems: _historyItems.isNotEmpty,
              onClearHistory: _clearAllHistory,
              onLangChanged: (lang) => setState(() {
                _selectedLangFilter = lang;
                _selectedLevelFilter = 'all';
              }),
              onLevelChanged: (lvl) => setState(() => _selectedLevelFilter = lvl),
              onFavoritesChanged: (favs) => setState(() => _showOnlyFavorites = favs),
            ),
          ),

          // History Video List or Empty State
          if (filteredItems.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyHistoryState(colors),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filteredItems[index];
                    final videoId = item['video_id'] as String? ?? item['videoId'] as String? ?? '';
                    final isFav = _savedVideoIds.contains(videoId);

                    return HistoryVideoCard(
                      item: item,
                      isFavorite: isFav,
                      onToggleFavorite: () => _toggleFavorite(item),
                      onRemove: () => _removeHistoryItem(item),
                    );
                  },
                  childCount: filteredItems.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState(VocaColorPalette colors) {
    final hasActiveFilter = _searchQuery.isNotEmpty || _selectedLangFilter != 'all' || _selectedLevelFilter != 'all';

    if (hasActiveFilter) {
      return Center(
        child: VocaEmptyState(
          icon: Icons.search_off_rounded,
          variant: EmptyStateIconVariant.neutral,
          compact: true,
          title: context.t('history.noMatchesFound', null, 'No matches found'),
          description: context.t('history.noMatchesHint', null, 'Try adjusting your search keywords or active filters.'),
          actionLabel: context.t('history.clearFilters', null, 'Clear Filters'),
          onAction: () {
            _searchController.clear();
            setState(() {
              _selectedLangFilter = 'all';
              _selectedLevelFilter = 'all';
              _showOnlyFavorites = false;
            });
          },
        ),
      );
    }

    if (_showOnlyFavorites) {
      return Center(
        child: VocaEmptyState(
          icon: Icons.favorite_border_rounded,
          variant: EmptyStateIconVariant.neutral,
          compact: true,
          title: context.t('history.noFavorites', null, 'No favorites yet'),
          description: context.t('history.noFavoritesHint', null, 'Tap the heart icon on any video in your history to save it here.'),
          actionLabel: context.t('history.exploreVideos', null, 'Browse Videos'),
          onAction: () => widget.onNavigateToExplore?.call(),
        ),
      );
    }

    return Center(
      child: VocaEmptyState(
        icon: Icons.history_rounded,
        variant: EmptyStateIconVariant.neutral,
        compact: true,
        title: context.t('history.noHistory', null, 'No watch history'),
        description: context.t('history.noHistoryHint', null, 'Videos you watch with interactive subtitles will appear here.'),
        actionLabel: context.t('history.exploreVideos', null, 'Browse Videos'),
        onAction: () => widget.onNavigateToExplore?.call(),
      ),
    );
  }

  // ==========================================
  // TAB 2: PLAYLISTS VIEW
  // ==========================================
  Widget _buildPlaylistsTab(VocaColorPalette colors) {
    if (_isLoadingPlaylists) {
      return Center(child: CircularProgressIndicator(color: colors.accentPrimary));
    }

    if (_playlists.isEmpty) {
      return Center(
        child: VocaEmptyState(
          icon: Icons.playlist_play_rounded,
          variant: EmptyStateIconVariant.neutral,
          compact: true,
          title: context.t('playlist.empty.myTitle', null, 'No playlists yet'),
          description: context.t('playlist.empty.myHint', null, 'Create custom playlists to organize immersion videos for your learning goals.'),
          actionLabel: context.t('playlist.newPlaylist', null, 'Create Playlist'),
          onAction: () {
            CreatePlaylistSheet.show(context, onSaved: _loadPlaylists);
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPlaylists,
      color: colors.accentPrimary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        children: [
          // Header Row with "Create Playlist" Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_playlists.length} ${context.t('nav.playlists', null, 'Playlists')}',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  CreatePlaylistSheet.show(
                    context,
                    onSaved: _loadPlaylists,
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(context.t('playlist.newPlaylist', null, 'New Playlist')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Hydrated Playlist Cards
          ..._playlists.map((playlist) {
            return LibraryPlaylistCard(
              playlist: playlist,
              onRefresh: _loadPlaylists,
              onTap: () {
                LibraryPlaylistDetailSheet.show(
                  context,
                  playlist: playlist,
                  onUpdated: _loadPlaylists,
                );
              },
            );
          }),
        ],
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
            // 1. Sleek Top Bar (Segmented Control + Settings Gear)
            LibraryTopBar(
              currentTab: _currentTab,
              onTabChanged: (index) => setState(() => _currentTab = index),
              onSettingsPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),

            // 2. Active Tab Content (Watch History vs Playlists)
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _currentTab == 0
                    ? _buildHistoryTab(colors)
                    : _buildPlaylistsTab(colors),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
