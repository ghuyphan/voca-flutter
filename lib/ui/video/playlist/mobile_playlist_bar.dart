// lib/ui/video/playlist/mobile_playlist_bar.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/i18n_service.dart';
import '../../../state/player_coordinator.dart';
import '../../sheets/playlist_queue_sheet.dart';

/// Compact Mobile Playlist Bar (Matching video-page.component.html:10-39 & SCSS)
/// - Height: 48dp
/// - Coral-tinted playlist icon badge on the left
/// - Title & "Curated/You • X / Y" subtitle
/// - Chevron button on the right
/// - Tapping opens the interactive Playlist Queue bottom sheet
class MobilePlaylistBar extends StatelessWidget {
  final String title;
  final int currentIndex;
  final int totalVideos;
  final bool isOwner;

  const MobilePlaylistBar({
    super.key,
    required this.title,
    required this.currentIndex,
    required this.totalVideos,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final coordinator = PlayerCoordinator.instance;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          final currentVid = coordinator.activeVideoId.value ?? '';
          PlaylistQueueSheet.show(
            context,
            playlistTitle: title,
            currentVideoId: currentVid,
            currentIndex: currentIndex,
            totalCount: totalVideos,
            isPlaying: coordinator.isPlaying.value,
            isShuffled: coordinator.isShuffled.value,
            isLooping: coordinator.isLooping.value,
            initialVideos: coordinator.playlistVideos.value
                .map((v) => {
                      'id': v.videoId,
                      'videoId': v.videoId,
                      'title': v.title,
                      'channel': v.channel,
                      'thumbnail': v.thumbnail,
                    })
                .toList(),
            onSelectVideo: (videoId, title, index) {
              coordinator.jumpToPlaylistIndex(index, context);
            },
            onToggleShuffle: () => coordinator.toggleShuffle(),
            onToggleLoop: () => coordinator.toggleLoop(),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              // 1. Coral-tinted playlist icon badge
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.accentPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.playlist_play_rounded,
                  color: colors.accentPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),

              // 2. Playlist title & counter
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isNotEmpty ? title : context.t('playlist.playlist', null, 'Playlist'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${isOwner ? context.t('playlist.you', null, 'You') : context.t('playlist.curated', null, 'Curated')} • ${currentIndex + 1} / $totalVideos',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // 3. Chevron trigger button
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: colors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
