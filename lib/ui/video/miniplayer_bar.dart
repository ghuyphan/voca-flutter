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
class MiniplayerBar extends StatefulWidget {
  final String videoId;
  final String title;
  final String channel;
  final String? thumbnail;
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
    this.thumbnail,
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
  State<MiniplayerBar> createState() => _MiniplayerBarState();
}

class _MiniplayerBarState extends State<MiniplayerBar> {
  bool _isCardPressed = false;

  String _resolveTitle(String activeT, BuildContext context) {
    if (widget.title.isNotEmpty && widget.title != 'YouTube Video') return widget.title;
    if (activeT.isNotEmpty && activeT != 'YouTube Video') return activeT;
    if (widget.title.isNotEmpty) return widget.title;
    if (activeT.isNotEmpty) return activeT;
    return context.t('player.loadingVideo', null, 'Loading...');
  }

  String _resolveChannel(String? activeC) {
    if (widget.channel.isNotEmpty && widget.channel != 'YouTube') return widget.channel;
    if (activeC != null && activeC.isNotEmpty && activeC != 'YouTube') return activeC;
    if (widget.channel.isNotEmpty) return widget.channel;
    return activeC ?? 'YouTube';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return RepaintBoundary(
      child: Dismissible(
        key: ValueKey('miniplayer_${widget.videoId}'),
        direction: DismissDirection.down,
        onDismissed: (_) => widget.onClose(),
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isCardPressed = true),
            onTapUp: (_) => setState(() => _isCardPressed = false),
            onTapCancel: () => setState(() => _isCardPressed = false),
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedScale(
              scale: _isCardPressed ? 0.985 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              child: Container(
                height: 64,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: colors.isDark ? 0.40 : 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
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
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: widget.videoWidget ??
                                Watch((context) {
                                  final coord = PlayerCoordinator.instance;
                                  final rawThumb = (widget.thumbnail != null && widget.thumbnail!.trim().isNotEmpty)
                                      ? widget.thumbnail!.trim()
                                      : ((coord.activeThumbnail.value != null && coord.activeThumbnail.value!.trim().isNotEmpty)
                                          ? coord.activeThumbnail.value!.trim()
                                          : (widget.videoId.isNotEmpty ? 'https://img.youtube.com/vi/${widget.videoId}/mqdefault.jpg' : ''));

                                  if (rawThumb.isEmpty) {
                                    return Container(
                                      width: 80,
                                      height: 48,
                                      color: colors.bgTertiary,
                                      child: Icon(
                                        Icons.play_circle_fill_rounded,
                                        color: colors.accentPrimary,
                                        size: 24,
                                      ),
                                    );
                                  }

                                  return Image.network(
                                    rawThumb,
                                    width: 80,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                      if (wasSynchronouslyLoaded) return child;
                                      return AnimatedOpacity(
                                        opacity: frame == null ? 0.0 : 1.0,
                                        duration: const Duration(milliseconds: 220),
                                        curve: Curves.easeOut,
                                        child: child,
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => Image.network(
                                      widget.videoId.isNotEmpty ? 'https://img.youtube.com/vi/${widget.videoId}/0.jpg' : '',
                                      width: 80,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                        if (wasSynchronouslyLoaded) return child;
                                        return AnimatedOpacity(
                                          opacity: frame == null ? 0.0 : 1.0,
                                          duration: const Duration(milliseconds: 220),
                                          curve: Curves.easeOut,
                                          child: child,
                                        );
                                      },
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 80,
                                        height: 48,
                                        color: colors.bgTertiary,
                                        child: Icon(
                                          Icons.play_circle_fill_rounded,
                                          color: colors.accentPrimary,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                          ),
                          const SizedBox(width: 10),

                          // 2. Video Title & Channel Meta (Reactively bound to PlayerCoordinator)
                          Expanded(
                            child: Watch((context) {
                              final coord = PlayerCoordinator.instance;
                              final displayTitle = _resolveTitle(coord.activeTitle.value, context);
                              final displayChannel = _resolveChannel(coord.activeChannel.value);

                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayTitle,
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
                                    displayChannel,
                                    style: TextStyle(
                                      color: colors.textMuted,
                                      fontSize: 11.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              );
                            }),
                          ),

                          // 3. Play / Pause / Replay Button (Reactively bound with micro-interaction)
                          Watch((context) {
                            final coord = PlayerCoordinator.instance;
                            final playing = widget.isPlaying ?? coord.isPlaying.value;
                            final ended = widget.isEnded || coord.isEnded.value;

                            return _MiniplayerIconButton(
                              tooltip: ended
                                  ? context.t('player.replay', null, 'Replay')
                                  : (playing
                                      ? context.t('player.pause', null, 'Pause')
                                      : context.t('player.play', null, 'Play')),
                              onPressed: widget.onPlayPause,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 150),
                                transitionBuilder: (child, anim) => FadeTransition(
                                  opacity: anim,
                                  child: ScaleTransition(scale: anim, child: child),
                                ),
                                child: Icon(
                                  ended
                                      ? Icons.replay_rounded
                                      : (playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                  key: ValueKey(ended ? 'replay' : (playing ? 'pause' : 'play')),
                                  color: colors.textPrimary,
                                  size: 24,
                                ),
                              ),
                            );
                          }),

                          // 4. Close (X) Button (with tactile press feedback)
                          _MiniplayerIconButton(
                            tooltip: context.t('player.closeVideo', null, 'Close'),
                            onPressed: widget.onClose,
                            child: Icon(
                              Icons.close_rounded,
                              color: colors.textMuted,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),

                    // 5. 2.5dp Bottom Progress Line (Reactively & Paint-boundary isolated)
                    RepaintBoundary(
                      child: Watch((context) {
                        final coord = PlayerCoordinator.instance;
                        final cur = widget.currentTime ?? coord.currentTime.value;
                        final dur = widget.duration ?? coord.duration.value;
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniplayerIconButton extends StatefulWidget {
  final Widget child;
  final String tooltip;
  final VoidCallback onPressed;

  const _MiniplayerIconButton({
    required this.child,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_MiniplayerIconButton> createState() => _MiniplayerIconButtonState();
}

class _MiniplayerIconButtonState extends State<_MiniplayerIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: IconButton(
          icon: widget.child,
          tooltip: widget.tooltip,
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}
