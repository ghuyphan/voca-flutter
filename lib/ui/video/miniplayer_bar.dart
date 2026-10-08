// lib/ui/video/miniplayer_bar.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../state/player_coordinator.dart';

/// Floating docked Miniplayer Bar matching YouTube Mobile and VOCA M3:
/// - Fixed above bottom navigation bar or docked at bottom
/// - 16:9 video thumbnail on left with subtle border
/// - Video title & channel name with ellipsis
/// - Play/Pause/Replay toggle button
/// - Close button to dismiss and stop playback
/// - 2.5dp linear progress indicator along bottom edge
/// - Tap or swipe up to expand back into full VideoPlayerScreen
/// - Swipe down to dismiss with synchronous height collapse (0 blank space!)
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

class _MiniplayerBarState extends State<MiniplayerBar> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _springCurve = CurvedAnimation(
    parent: _animController,
    curve: Curves.easeOutCubic,
  );

  double _dragOffsetY = 0.0;
  double _springStartOffsetY = 0.0;
  bool _isDismissing = false;
  bool _isCardPressed = false;
  double _dismissStartOffsetY = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _animController.addListener(() {
      if (mounted) setState(() {});
    });
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isDismissing) {
        widget.onClose();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerDismiss({double startVelocity = 0.0}) {
    if (_isDismissing) return;
    _isDismissing = true;
    _dismissStartOffsetY = _dragOffsetY;
    _animController.forward(from: 0.0);
  }

  void _springBack() {
    if (_dragOffsetY == 0.0) return;
    _isDismissing = false;
    _springStartOffsetY = _dragOffsetY;
    _animController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _springStartOffsetY = 0.0;
          _dragOffsetY = 0.0;
        });
      }
    });
  }

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

    // Calculate dynamic layout, translation, opacity, and height factor
    double heightFactor = 1.0;
    double opacity = 1.0;
    double translationY = 0.0;

    if (_isDismissing) {
      final t = _animController.value;
      heightFactor = (1.0 - t).clamp(0.0, 1.0);
      opacity = (1.0 - t * 1.2).clamp(0.0, 1.0);
      translationY = _dismissStartOffsetY + (t * 36.0);
    } else {
      final currentOffset = (_springStartOffsetY != 0.0)
          ? (_springStartOffsetY * (1.0 - _springCurve.value))
          : _dragOffsetY;
      translationY = currentOffset.clamp(0.0, 60.0);

      if (currentOffset > 0) {
        // Dragging downwards: smoothly shrink height and fade in real-time
        final downRatio = (currentOffset / 100.0).clamp(0.0, 1.0);
        heightFactor = (1.0 - downRatio * 0.45).clamp(0.0, 1.0);
        opacity = (1.0 - downRatio * 0.45).clamp(0.0, 1.0);
      }
    }

    return RepaintBoundary(
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: heightFactor,
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0.0, translationY),
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (!_isDismissing) widget.onTap();
                  },
                  onVerticalDragStart: (details) {
                    if (_isDismissing) return;
                    if (_animController.isAnimating) {
                      _animController.stop();
                    }
                    _springStartOffsetY = 0.0;
                    setState(() => _isCardPressed = true);
                  },
                  onVerticalDragUpdate: (details) {
                    if (_isDismissing) return;
                    setState(() {
                      _dragOffsetY = (_dragOffsetY + details.delta.dy).clamp(-60.0, 100.0);
                    });
                  },
                  onVerticalDragEnd: (details) {
                    if (_isDismissing) return;
                    setState(() => _isCardPressed = false);

                    final vy = details.velocity.pixelsPerSecond.dy;

                    // 1. Swipe up to expand
                    if (vy < -180 || _dragOffsetY < -35) {
                      _springBack();
                      widget.onTap();
                      return;
                    }

                    // 2. Swipe down to dismiss (smoothly collapse height with zero blank gap)
                    if (vy > 180 || _dragOffsetY > 30) {
                      _triggerDismiss(startVelocity: vy);
                      return;
                    }

                    // 3. Reset position if under dismiss threshold
                    _springBack();
                  },
                  onVerticalDragCancel: () {
                    if (_isDismissing) return;
                    setState(() => _isCardPressed = false);
                    _springBack();
                  },
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

                                  return IconButton(
                                    tooltip: ended
                                        ? context.t('player.replay', null, 'Replay')
                                        : (playing
                                            ? context.t('player.pause', null, 'Pause')
                                            : context.t('player.play', null, 'Play')),
                                    onPressed: widget.onPlayPause,
                                    icon: AnimatedSwitcher(
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

                                // 4. Close (X) Button (triggering smooth downward dismiss with zero blank space)
                                IconButton(
                                  tooltip: context.t('player.closeVideo', null, 'Close'),
                                  onPressed: () => _triggerDismiss(),
                                  icon: Icon(
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
          ),
        ),
      ),
    );
  }
}
