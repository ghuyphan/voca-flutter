// lib/ui/sheets/add_to_playlist_sheet.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/i18n_service.dart';
import '../../services/toast_service.dart';
import '../../state/app_state.dart';
import '../widgets/voca_empty_state.dart';
import 'create_playlist_sheet.dart';
import 'voca_bottom_sheet.dart';

/// Bottom sheet allowing users to add/remove a video from their custom playlists.
/// Ported from lingua-tube's AddToPlaylistDialogComponent.
class AddToPlaylistSheet extends StatefulWidget {
  final String videoId;
  final String? videoTitle;

  const AddToPlaylistSheet({
    super.key,
    required this.videoId,
    this.videoTitle,
  });

  static Future<void> show(
    BuildContext context, {
    required String videoId,
    String? videoTitle,
  }) {
    return showVocaBottomSheet(
      context: context,
      title: context.t('playlist.addToPlaylist', null, 'Add to Playlist'),
      showCloseButton: true,
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      builder: (ctx) => AddToPlaylistSheet(
        videoId: videoId,
        videoTitle: videoTitle,
      ),
    );
  }

  @override
  State<AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<AddToPlaylistSheet> {
  List<PlaylistItem> _playlists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() => _isLoading = true);
    try {
      final playlists = await AppState.instance.supabaseService.getPlaylists();
      if (mounted) {
        setState(() {
          _playlists = playlists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isSavedInPlaylist(PlaylistItem playlist) {
    return playlist.videoIds.contains(widget.videoId);
  }

  Future<void> _togglePlaylist(PlaylistItem playlist) async {
    final supabase = AppState.instance.supabaseService;
    final isSaved = _isSavedInPlaylist(playlist);

    try {
      if (isSaved) {
        await supabase.removeVideoFromPlaylist(
          playlistId: playlist.id,
          videoId: widget.videoId,
        );
        if (mounted) {
          ToastService.info(
            context,
            context.t('playlist.removedSuccess', {'title': playlist.title}, 'Removed from ${playlist.title}'),
          );
        }
      } else {
        await supabase.addVideoToPlaylist(
          playlistId: playlist.id,
          videoId: widget.videoId,
        );
        if (mounted) {
          ToastService.success(
            context,
            context.t('playlist.addedSuccess', {'title': playlist.title}, 'Added to ${playlist.title}'),
          );
        }
      }
      _loadPlaylists();
    } catch (e) {
      if (mounted) {
        ToastService.error(
          context,
          context.t('playlist.updateFailed', {'error': e.toString()}, 'Failed to update playlist: $e'),
        );
      }
    }
  }

  Future<void> _openCreatePlaylist() async {
    final created = await CreatePlaylistSheet.show(context);
    if (created == true) {
      _loadPlaylists();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // New Playlist Button Header
          InkWell(
            onTap: _openCreatePlaylist,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.accentPrimarySoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.accentPrimary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.accentPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.t('playlist.newPlaylist', null, 'Create New Playlist'),
                      style: TextStyle(
                        color: colors.accentPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.accentPrimary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.accentPrimary,
                ),
              ),
            )
          else if (_playlists.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: VocaEmptyState(
                icon: Icons.queue_music_rounded,
                title: context.t('playlist.empty.title', null, 'No playlists found'),
                description: context.t('playlist.emptyDesc', null, 'Create custom playlists to organize immersion videos by topic or exam tier.'),
                actionLabel: context.t('playlist.createFirst', null, '+ Create First Playlist'),
                onAction: _openCreatePlaylist,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _playlists.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final pl = _playlists[index];
                final isSaved = _isSavedInPlaylist(pl);

                return Semantics(
                  button: true,
                  checked: isSaved,
                  label: pl.title,
                  child: InkWell(
                    onTap: () => _togglePlaylist(pl),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSaved ? colors.accentPrimarySoft : colors.bgSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSaved ? colors.accentPrimary.withValues(alpha: 0.4) : colors.borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSaved ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                            color: isSaved ? colors.accentPrimary : colors.textMuted,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pl.title,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${pl.videoCount} ${context.t('playlist.videoCountSuffix', null, 'videos')} • ${pl.language.toUpperCase()}',
                                  style: TextStyle(color: colors.textMuted, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
