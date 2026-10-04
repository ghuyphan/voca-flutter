// lib/ui/library/library_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../state/app_state.dart';
import '../../state/player_coordinator.dart';

class LibraryScreen extends StatefulWidget {
  final VoidCallback? onNavigateToExplore;
  final int initialTabIndex;

  const LibraryScreen({
    super.key,
    this.onNavigateToExplore,
    this.initialTabIndex = 0,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<Map<String, dynamic>> _historyItems = [];
  List<PlaylistItem> _playlists = [];
  bool _isLoadingHistory = true;
  bool _isLoadingPlaylists = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _loadHistory();
    _loadPlaylists();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await AppState.instance.supabaseService.getHistory(limit: 50);
      if (mounted) {
        setState(() {
          _historyItems = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _loadPlaylists() async {
    setState(() => _isLoadingPlaylists = true);
    try {
      final playlists = await AppState.instance.supabaseService.getPlaylists();
      if (mounted) {
        setState(() {
          _playlists = playlists;
          _isLoadingPlaylists = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPlaylists = false);
    }
  }

  Future<void> _deleteHistoryItem(String id) async {
    await AppState.instance.supabaseService.deleteHistoryItem(id);
    _loadHistory();
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Clear Watch History', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to remove all videos from your watch history?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AppState.instance.supabaseService.clearHistory();
      _loadHistory();
    }
  }

  Future<void> _showCreatePlaylistDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedLang = AppState.instance.activeLanguage.value;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text('New Playlist', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Playlist Title',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'e.g. JLPT N3 Grammar Lessons',
                    hintStyle: TextStyle(color: Colors.white30),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6366F1)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: TextStyle(color: Colors.white70),
                    hintText: 'Short summary of this collection',
                    hintStyle: TextStyle(color: Colors.white30),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF6366F1)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Language', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: selectedLang,
                  dropdownColor: const Color(0xFF1E293B),
                  isExpanded: true,
                  underline: Container(height: 1, color: Colors.white24),
                  items: const [
                    DropdownMenuItem(value: 'ja', child: Text('🇯🇵 Japanese', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'zh', child: Text('🇨🇳 Chinese', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'ko', child: Text('🇰🇷 Korean', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'en', child: Text('🇺🇸 English', style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedLang = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  Navigator.of(ctx).pop(true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (created == true && titleController.text.trim().isNotEmpty) {
      await AppState.instance.supabaseService.createPlaylist(
        title: titleController.text.trim(),
        description: descController.text.trim().isEmpty ? null : descController.text.trim(),
        language: selectedLang,
      );
      _loadPlaylists();
    }
  }

  void _openPlaylistDetails(PlaylistItem playlist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlist.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (playlist.description != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                playlist.description!,
                                style: const TextStyle(color: Colors.white60, fontSize: 13),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '${playlist.videoCount} videos',
                              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (playlist.id != 'default_saved')
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            await AppState.instance.supabaseService.deletePlaylist(playlist.id);
                            _loadPlaylists();
                          },
                        ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  Expanded(
                    child: playlist.videoIds.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.playlist_remove_rounded, color: Colors.white24, size: 48),
                                SizedBox(height: 12),
                                Text(
                                  'This playlist is empty',
                                  style: TextStyle(color: Colors.white70, fontSize: 15),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Bookmark videos from Explore or Player to save them here.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: playlist.videoIds.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, idx) {
                              final vid = playlist.videoIds[idx];
                              return ListTile(
                                tileColor: const Color(0xFF0F172A),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    'https://i.ytimg.com/vi/$vid/hqdefault.jpg',
                                    width: 72,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 72,
                                      height: 48,
                                      color: Colors.black26,
                                      child: const Icon(Icons.play_arrow, color: Colors.white38),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  'Video $vid',
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.play_circle_outline, color: Color(0xFF6366F1)),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  final playlistVideos = playlist.videoIds.asMap().entries.map((entry) {
                                    final i = entry.key;
                                    final v = entry.value;
                                    return PlaylistVideo(
                                      videoId: v,
                                      title: 'Video ${i + 1}',
                                      thumbnail: 'https://img.youtube.com/vi/$v/hqdefault.jpg',
                                      level: playlist.level,
                                      position: i,
                                    );
                                  }).toList();

                                  PlayerCoordinator.instance.openVideo(
                                    context,
                                    videoId: vid,
                                    title: 'Video ${idx + 1}',
                                    level: playlist.level,
                                    playlistTitle: playlist.title,
                                    playlistIndex: idx,
                                    playlistTotal: playlist.videoIds.length,
                                    playlist: playlistVideos,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatWatchedDate(dynamic dateVal) {
    if (dateVal == null) return '';
    DateTime? dt;
    if (dateVal is DateTime) {
      dt = dateVal;
    } else {
      dt = DateTime.tryParse(dateVal.toString());
    }
    if (dt == null) return '';

    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return diff.inMinutes <= 1 ? 'Just now' : '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dt);
    }
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '0:00';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VocaTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: VocaTokens.bgPrimary,
        elevation: 0,
        title: const Text(
          'Library',
          style: TextStyle(color: VocaTokens.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_tabController.index == 0 && _historyItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white70),
              tooltip: 'Clear History',
              onPressed: _clearAllHistory,
            ),
          if (_tabController.index == 1)
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF38BDF8)),
              tooltip: 'New Playlist',
              onPressed: _showCreatePlaylistDialog,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: VocaTokens.accentPrimary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(icon: Icon(Icons.history_rounded, size: 20), text: 'Watch History'),
            Tab(icon: Icon(Icons.playlist_play_rounded, size: 22), text: 'Playlists / Saved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Watch History
          _buildWatchHistoryTab(),

          // Tab 2: Playlists / Saved
          _buildPlaylistsTab(),
        ],
      ),
    );
  }

  Widget _buildWatchHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }

    if (_historyItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E293B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history_toggle_off_rounded, color: Colors.white30, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'No watch history yet',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Start watching immersion videos with interactive subtitles to track your learning progress.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 13.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (widget.onNavigateToExplore != null) {
                    widget.onNavigateToExplore!();
                  }
                },
                icon: const Icon(Icons.explore_outlined, size: 18),
                label: const Text('Explore Videos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: const Color(0xFF6366F1),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _historyItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _historyItems[index];
          final videoId = item['video_id'] as String? ?? '';
          final title = item['title'] as String? ?? 'Untitled Video';
          final channel = item['channel'] as String? ?? 'YouTube';
          final duration = (item['duration'] as num?)?.toInt() ?? 0;
          final progress = (item['progress'] as num?)?.toDouble() ?? 0.0;
          final watchedAt = item['watched_at'];
          final id = item['id'] as String? ?? videoId;
          final progressPercent = (progress * 100).clamp(0, 100).toInt();

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // One-tap resume: resume at watched progress
                  PlayerCoordinator.instance.openVideo(
                    context,
                    videoId: videoId,
                    title: title,
                  );
                  _loadHistory();
                },
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video Thumbnail with Duration badge & Progress Bar
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 120,
                              height: 68,
                              child: Image.network(
                                'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.black38,
                                  child: const Icon(Icons.broken_image, color: Colors.white30),
                                ),
                              ),
                            ),
                          ),
                          // Duration badge
                          if (duration > 0)
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          // Progress Bar along bottom of thumbnail
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 3,
                                backgroundColor: Colors.black45,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Metadata & Resume info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              channel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$progressPercent% watched',
                                    style: const TextStyle(
                                      color: Color(0xFF818CF8),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (watchedAt != null)
                                  Text(
                                    _formatWatchedDate(watchedAt),
                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // More options (Remove from history)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white60, size: 18),
                        color: const Color(0xFF1E293B),
                        onSelected: (val) {
                          if (val == 'delete') {
                            _deleteHistoryItem(id);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                SizedBox(width: 8),
                                Text('Remove', style: TextStyle(color: Colors.redAccent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaylistsTab() {
    if (_isLoadingPlaylists) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }

    return RefreshIndicator(
      onRefresh: _loadPlaylists,
      color: const Color(0xFF6366F1),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header with Create Playlist Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${_playlists.length} Playlists',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _showCreatePlaylistDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Playlist'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Playlists Grid / Cards
          ..._playlists.map((playlist) {
            final isDefault = playlist.id == 'default_saved';
            final thumbUrl = playlist.thumbnail ??
                (playlist.videoIds.isNotEmpty
                    ? 'https://i.ytimg.com/vi/${playlist.videoIds.first}/hqdefault.jpg'
                    : null);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDefault ? const Color(0xFF6366F1).withOpacity(0.4) : Colors.white12,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openPlaylistDetails(playlist),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Playlist Thumbnail or Icon
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDefault
                                    ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                                    : [const Color(0xFF334155), const Color(0xFF1E293B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: thumbUrl != null
                                ? Image.network(
                                    thumbUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Icon(
                                        isDefault ? Icons.bookmark_rounded : Icons.playlist_play_rounded,
                                        color: Colors.white70,
                                        size: 32,
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      isDefault ? Icons.bookmark_rounded : Icons.playlist_play_rounded,
                                      color: Colors.white70,
                                      size: 32,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title, details, count
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isDefault)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 6),
                                      child: Icon(Icons.star_rounded, color: Colors.amberAccent, size: 16),
                                    ),
                                  Expanded(
                                    child: Text(
                                      playlist.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (playlist.description != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  playlist.description!,
                                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.video_library_rounded, size: 13, color: Color(0xFF38BDF8)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${playlist.videoCount} videos',
                                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12),
                                  ),
                                  const SizedBox(width: 12),
                                  if (playlist.language != 'all')
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        playlist.language.toUpperCase(),
                                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const Icon(Icons.chevron_right_rounded, color: Colors.white30),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
