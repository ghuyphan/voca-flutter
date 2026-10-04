// lib/ui/video/miniplayer_bar.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../state/player_coordinator.dart';

/// Floating docked Miniplayer Bar matching YouTube Mobile and lingua-tube:
/// - Fixed above bottom navigation bar or docked at bottom
/// - 16:9 video thumbnail on left with subtle border
/// - Video title & channel name with ellipsis
/// - Play/Pause/Replay toggle button
/// - Close button to dismiss and stop playback
/// - 2.5dp linear progress indicator along bottom edge
/// - Tap anywhere on card to expand back into full VideoPlayerScreen
class MiniplayerBar extends StatelessWidget {
  final String videoId;
  final String title;
  final String channel;
  final double? currentTime;
  final double? duration;
  final bool? isPlaying;
  final bool isEnded;
  final Widget? videoWidget;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final VoidCallback onClose;

  const MiniplayerBar({
    super.key,
    required this.videoId,
    required this.title,
    required this.channel,
    this.currentTime,
    this.duration,
    this.isPlaying,
    this.isEnded = false,
    this.videoWidget,
    required this.onTap,
    required this.onPlayPause,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return Dismissible(
      key: ValueKey('miniplayer_$videoId'),
      direction: DismissDirection.down,
      onDismissed: (_) => onClose(),
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colors.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(colors.isDark ? 0.40 : 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // 1. Video Thumbnail / Live Video (16:9 aspect)
                      Container(
                        width: 80,
                        height: 48,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          image: videoWidget == null
                              ? DecorationImage(
                                  image: NetworkImage(
                                    'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: videoWidget,
                      ),
                      const SizedBox(width: 10),

                      // 2. Video Title & Channel Meta
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.isNotEmpty ? title : context.t('player.loadingVideo', null, 'Loading...'),
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              channel.isNotEmpty ? channel : 'YouTube',
                              style: TextStyle(
                                color: colors.textMuted,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // 3. Play / Pause / Replay Button (Reactively bound)
                      Watch((context) {
                        final coord = PlayerCoordinator.instance;
                        final playing = isPlaying ?? coord.isPlaying.value;
                        final ended = isEnded || coord.isEnded.value;

                        return IconButton(
                          icon: Icon(
                            ended
                                ? Icons.replay_rounded
                                : (playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                            color: colors.textPrimary,
                            size: 24,
                          ),
                          tooltip: ended
                              ? context.t('player.replay', null, 'Replay')
                              : (playing
                                  ? context.t('player.pause', null, 'Pause')
                                  : context.t('player.play', null, 'Play')),
                          onPressed: onPlayPause,
                        );
                      }),

                      // 4. Close (X) Button
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: colors.textMuted,
                          size: 20,
                        ),
                        tooltip: context.t('player.closeVideo', null, 'Close'),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                ),

                // 5. 2.5dp Bottom Progress Line (Reactively bound without rebuilding parent)
                Watch((context) {
                  final coord = PlayerCoordinator.instance;
                  final cur = currentTime ?? coord.currentTime.value;
                  final dur = duration ?? coord.duration.value;
                  final p = dur > 0 ? (cur / dur).clamp(0.0, 1.0) : 0.0;

                  return Container(
                    height: 2.5,
                    width: double.infinity,
                    color: colors.borderColorLight,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: p,
                      child: Container(color: colors.accentPrimary),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
