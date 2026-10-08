// lib/ui/explore/widgets/playlist_feed_card.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../models/voca_models.dart';
import '../../../services/i18n_service.dart';
import '../../widgets/voca_level_badge.dart';

/// Official Material 3 Playlist Feed Card with outlined border, 16:9 thumbnail, and structured metadata.
class PlaylistFeedCard extends StatelessWidget {
  final PlaylistItem playlist;
  final VoidCallback onTap;

  const PlaylistFeedCard({
    super.key,
    required this.playlist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final videoCount = playlist.videoIds.length;
    final thumbnailUrl = (playlist.thumbnail != null && playlist.thumbnail!.isNotEmpty)
        ? playlist.thumbnail!
        : (playlist.videoIds.isNotEmpty
            ? 'https://i.ytimg.com/vi/${playlist.videoIds.first}/hqdefault.jpg'
            : null);

    Widget thumbnailWidget = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnailUrl != null)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                cacheWidth: 480,
                cacheHeight: 270,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: colors.bgSecondary,
                  child: Center(
                    child: Icon(
                      Icons.playlist_play_rounded,
                      color: colors.accentPrimary,
                      size: 48,
                    ),
                  ),
                ),
              )
            else
              Container(
                color: colors.bgSecondary,
                child: Center(
                  child: Icon(
                    Icons.playlist_play_rounded,
                    color: colors.accentPrimary,
                    size: 48,
                  ),
                ),
              ),

            // Level Badge (Bottom-Left)
            if (playlist.level != null && playlist.level!.isNotEmpty)
              Positioned(
                bottom: 8,
                left: 8,
                child: VocaLevelBadge(
                  level: playlist.level!,
                  size: LevelBadgeSize.small,
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
    );

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              thumbnailWidget,

              // Title, Subtitle, and Level Info
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 2, right: 2, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: colors.accentPrimarySoft,
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
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            playlist.description?.isNotEmpty == true
                                ? playlist.description!
                                : '${context.t('playlist.playlist', null, 'Playlist')} • $videoCount ${videoCount == 1 ? context.t('history.videoSingular', null, 'video') : context.t('history.videoPlural', null, 'video')}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
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
}
