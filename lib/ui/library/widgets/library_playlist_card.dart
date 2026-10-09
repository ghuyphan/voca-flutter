// lib/ui/library/widgets/library_playlist_card.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../models/voca_models.dart';
import '../../../services/i18n_service.dart';
import '../../../services/toast_service.dart';
import '../../../state/app_state.dart';
import '../../../state/player_coordinator.dart';
import '../../sheets/create_playlist_sheet.dart';
import '../../sheets/voca_bottom_sheet.dart';
import '../../widgets/voca_confirm_dialog.dart';
import '../../widgets/voca_level_badge.dart';

/// Hydrated Playlist Card matching lingua-tube's yt-video-card--playlist.
class LibraryPlaylistCard extends StatelessWidget {
  final PlaylistItem playlist;
  final VoidCallback onTap;
  final VoidCallback onRefresh;

  const LibraryPlaylistCard({
    super.key,
    required this.playlist,
    required this.onTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final isDefault = playlist.id == 'default_saved';
    final videoCount = playlist.videoIds.length;
    final thumbUrl = playlist.thumbnail ??
        (playlist.videoIds.isNotEmpty
            ? 'https://i.ytimg.com/vi/${playlist.videoIds.first}/hqdefault.jpg'
            : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDefault ? colors.accentPrimary.withValues(alpha: 0.35) : colors.borderColor,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 16:9 Aspect Thumbnail with Video Count Badge
                SizedBox(
                  width: 104,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: isDefault ? colors.accentPrimarySoft : colors.bgSecondary,
                            child: thumbUrl != null
                                ? Image.network(
                                    thumbUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Icon(
                                        isDefault ? Icons.bookmark_rounded : Icons.playlist_play_rounded,
                                        color: colors.accentPrimary,
                                        size: 28,
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      isDefault ? Icons.bookmark_rounded : Icons.playlist_play_rounded,
                                      color: colors.accentPrimary,
                                      size: 28,
                                    ),
                                  ),
                          ),

                          // Count Badge (bottom-right)
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xD9000000),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.format_list_bulleted_rounded,
                                    color: Colors.white70,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$videoCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Details: Title, Description, Level
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isDefault)
                            Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: Icon(Icons.star_rounded, color: colors.accentTertiary, size: 16),
                            ),
                          Expanded(
                            child: Text(
                              playlist.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      Text(
                        playlist.description?.isNotEmpty == true
                            ? playlist.description!
                            : '$videoCount ${videoCount == 1 ? context.t('history.videoSingular', null, 'video') : context.t('history.videoPlural', null, 'videos')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 6),

                      Row(
                        children: [
                          if (playlist.level != null && playlist.level!.isNotEmpty) ...[
                            VocaLevelBadge(
                              level: playlist.level!,
                              size: LevelBadgeSize.small,
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (playlist.language != 'all' && playlist.language.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: colors.bgSurface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: colors.borderColor),
                              ),
                              child: Text(
                                playlist.language.toUpperCase(),
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Options Menu (Edit / Delete)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: colors.textMuted, size: 20),
                  color: colors.bgCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: colors.borderColor),
                  ),
                  onSelected: (val) async {
                    if (val == 'edit') {
                      CreatePlaylistSheet.show(
                        context,
                        playlist: playlist,
                        onSaved: onRefresh,
                      );
                    } else if (val == 'delete') {
                      final confirmed = await showVocaConfirmDialog(
                        context: context,
                        title: context.t('playlist.delete', null, 'Delete Playlist'),
                        message: 'Are you sure you want to delete "${playlist.title}"?',
                        confirmText: context.t('common.delete', null, 'Delete'),
                        variant: ConfirmDialogVariant.danger,
                        isDestructive: true,
                        icon: Icons.delete_outline_rounded,
                      );
                      if (confirmed == true) {
                        await AppState.instance.supabaseService.deletePlaylist(playlist.id);
                        onRefresh();
                        if (context.mounted) {
                          ToastService.info(context, 'Playlist deleted');
                        }
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16, color: colors.textPrimary),
                          const SizedBox(width: 8),
                          Text(context.t('playlist.edit', null, 'Edit')),
                        ],
                      ),
                    ),
                    if (!isDefault)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 16, color: colors.error),
                            const SizedBox(width: 8),
                            Text(context.t('common.delete', null, 'Delete'), style: TextStyle(color: colors.error)),
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
  }
}

/// Modal Sheet displaying playlist tracks with instant play and removal options.
class LibraryPlaylistDetailSheet extends StatefulWidget {
  final PlaylistItem playlist;
  final VoidCallback onUpdated;

  const LibraryPlaylistDetailSheet({
    super.key,
    required this.playlist,
    required this.onUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required PlaylistItem playlist,
    required VoidCallback onUpdated,
  }) {
    return showVocaBottomSheet(
      context: context,
      title: playlist.title,
      builder: (ctx) => LibraryPlaylistDetailSheet(
        playlist: playlist,
        onUpdated: onUpdated,
      ),
    );
  }

  @override
  State<LibraryPlaylistDetailSheet> createState() => _LibraryPlaylistDetailSheetState();
}

class _LibraryPlaylistDetailSheetState extends State<LibraryPlaylistDetailSheet> {
  late List<String> _videoIds;
  final Map<String, String> _videoTitles = {};

  @override
  void initState() {
    super.initState();
    _videoIds = List.from(widget.playlist.videoIds);
    _loadVideoTitles();
  }

  void _loadVideoTitles() async {
    for (final vid in _videoIds) {
      try {
        final info = await AppState.instance.apiClient.getVideoInfo(videoId: vid);
        final title = (info['title'] as String?)?.trim();
        if (title != null && title.isNotEmpty && mounted) {
          setState(() {
            _videoTitles[vid] = title;
          });
        }
      } catch (_) {}
    }
  }

  void _playAll() {
    Navigator.of(context).pop();
    final p = widget.playlist;
    final playlistVideos = _videoIds.asMap().entries.map((entry) {
      final i = entry.key;
      final v = entry.value;
      return PlaylistVideo(
        videoId: v,
        title: _videoTitles[v] ?? 'Video #${i + 1}',
        thumbnail: 'https://img.youtube.com/vi/$v/hqdefault.jpg',
        level: p.level,
        position: i,
      );
    }).toList();

    PlayerCoordinator.instance.openVideo(
      context,
      videoId: _videoIds.first,
      title: _videoTitles[_videoIds.first] ?? '',
      level: p.level,
      playlistTitle: p.title,
      playlistIndex: 0,
      playlistTotal: _videoIds.length,
      playlist: playlistVideos,
    );
  }

  void _playTrack(int index) {
    Navigator.of(context).pop();
    final p = widget.playlist;
    final vid = _videoIds[index];
    final playlistVideos = _videoIds.asMap().entries.map((entry) {
      final i = entry.key;
      final v = entry.value;
      return PlaylistVideo(
        videoId: v,
        title: _videoTitles[v] ?? 'Video #${i + 1}',
        thumbnail: 'https://img.youtube.com/vi/$v/hqdefault.jpg',
        level: p.level,
        position: i,
      );
    }).toList();

    PlayerCoordinator.instance.openVideo(
      context,
      videoId: vid,
      title: _videoTitles[vid] ?? '',
      level: p.level,
      playlistTitle: p.title,
      playlistIndex: index,
      playlistTotal: _videoIds.length,
      playlist: playlistVideos,
    );
  }

  Future<void> _removeVideo(String videoId) async {
    setState(() {
      _videoIds.remove(videoId);
    });
    await AppState.instance.supabaseService.removeVideoFromPlaylist(
      playlistId: widget.playlist.id,
      videoId: videoId,
    );
    widget.onUpdated();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final p = widget.playlist;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (p.description?.isNotEmpty == true) ...[
          Text(
            p.description!,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 10),
        ],

        // Play All Button
        if (_videoIds.isNotEmpty) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _playAll,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text('${context.t('playlist.playAll', null, 'Play All')} (${_videoIds.length})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Tracks List
        if (_videoIds.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.playlist_remove_rounded, color: colors.textMuted, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    context.t('playlist.empty.noVideosTitle', null, 'No videos yet'),
                    style: TextStyle(color: colors.textPrimary, fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Save immersion videos while watching to add them here.',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _videoIds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final vid = _videoIds[idx];
                return Container(
                  decoration: BoxDecoration(
                    color: colors.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        'https://i.ytimg.com/vi/$vid/hqdefault.jpg',
                        width: 68,
                        height: 42,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 68,
                          height: 42,
                          color: colors.bgSecondary,
                          child: Icon(Icons.play_arrow, color: colors.textMuted),
                        ),
                      ),
                    ),
                    title: Text(
                      _videoTitles[vid] ?? 'Video ${idx + 1}',
                      style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'ID: $vid',
                      style: TextStyle(color: colors.textMuted, fontSize: 11),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, color: colors.textMuted, size: 18),
                          onPressed: () => _removeVideo(vid),
                        ),
                        IconButton(
                          icon: Icon(Icons.play_circle_outline_rounded, color: colors.accentPrimary, size: 22),
                          onPressed: () => _playTrack(idx),
                        ),
                      ],
                    ),
                    onTap: () => _playTrack(idx),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
