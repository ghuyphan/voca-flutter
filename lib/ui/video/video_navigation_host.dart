// lib/ui/video/video_navigation_host.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../state/player_coordinator.dart';
import 'miniplayer_bar.dart';
import 'video_player_screen.dart';

/// YouTube Mobile-style Stack Navigation Host
///
/// Encapsulates all video player presentation with native 60fps hardware-accelerated
/// slide and fade transitions:
/// - Single Player Invariant: VideoPlayerScreen is maintained continuously in the widget
///   tree without being unmounted or recreated during minimize/expand transitions.
///   This prevents the underlying WebView/PlatformView from reloading the HTML iframe,
///   eliminating YouTube Error 150 ("Playback Restricted by Owner") and audio stutter.
/// - When a video is opened/expanded: Slides smoothly up from the bottom dock to full bleed
///   (covering the bottom navigation bar).
/// - When minimized: Smoothly slides down to dock the MiniplayerBar above the bottom navigation bar.
/// - Signal reactivity isolation: Playback timer ticks (4Hz) are isolated to leaf widgets
///   in MiniplayerBar and VideoPlayerScreen, never rebuilding this root host.
class VideoNavigationHost extends StatefulWidget {
  final Widget child;
  final double bottomNavHeight;

  const VideoNavigationHost({
    super.key,
    required this.child,
    this.bottomNavHeight = 80.0,
  });

  @override
  State<VideoNavigationHost> createState() => _VideoNavigationHostState();
}

class _VideoNavigationHostState extends State<VideoNavigationHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _miniplayerFade;
  bool _hasBeenMinimized = false;
  void Function()? _disposer;

  @override
  void initState() {
    super.initState();
    final coordinator = PlayerCoordinator.instance;
    final hasActive = coordinator.hasActiveVideo;
    final isMini = coordinator.isMiniplayer.value;
    _hasBeenMinimized = isMini;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: (hasActive && !isMini) ? 1.0 : 0.0,
    );

    final curved = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(curved);

    _miniplayerFade = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(curved);

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted && _hasBeenMinimized) {
          setState(() {
            _hasBeenMinimized = false;
          });
        }
      }
    });

    _disposer = effect(() {
      final active = coordinator.hasActiveVideo;
      final mini = coordinator.isMiniplayer.value;

      if (!active) {
        _hasBeenMinimized = false;
        if (_animController.value != 0.0) {
          _animController.value = 0.0;
        }
      } else if (mini) {
        _hasBeenMinimized = true;
        if (_animController.value > 0.0 && !_animController.isAnimating) {
          _animController.reverse();
        } else if (_animController.status == AnimationStatus.forward) {
          _animController.reverse();
        }
      } else {
        if (_animController.value < 1.0 && !_animController.isAnimating) {
          _animController.forward();
        } else if (_animController.status == AnimationStatus.reverse) {
          _animController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _disposer?.call();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final coordinator = PlayerCoordinator.instance;
      final hasActive = coordinator.hasActiveVideo;
      final videoId = coordinator.activeVideoId.value;

      return Stack(
        fit: StackFit.expand,
        children: [
          // 1. Base App Content (Tabs, Scaffold with Bottom Nav)
          widget.child,

          // 2. Docked Miniplayer Bar (Fades in/out at bottomNavHeight)
          if (hasActive && videoId != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: widget.bottomNavHeight,
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final mini = coordinator.isMiniplayer.value;
                  final opacity = (mini || _hasBeenMinimized) ? _miniplayerFade.value : 0.0;
                  if (opacity <= 0.01) return const SizedBox.shrink();
                  return IgnorePointer(
                    ignoring: opacity < 0.5,
                    child: Opacity(
                      opacity: opacity,
                      child: child,
                    ),
                  );
                },
                child: MiniplayerBar(
                  videoId: videoId,
                  title: coordinator.activeTitle.value,
                  channel: coordinator.activeChannel.value ?? 'YouTube',
                  thumbnail: coordinator.activeThumbnail.value,
                  // Omit currentTime & isPlaying: MiniplayerBar subscribes in leaf Watch blocks
                  onTap: () => coordinator.expand(context),
                  onPlayPause: () => coordinator.togglePlayPause(),
                  onClose: () => coordinator.close(),
                ),
              ),
            ),

          // 3. Full-Bleed Video Screen (Hardware-accelerated slide up/down without unmounting)
          if (hasActive && videoId != null && coordinator.ytController != null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final isHidden = _animController.value == 0.0;
                  return IgnorePointer(
                    ignoring: isHidden,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: child,
                    ),
                  );
                },
                child: VideoPlayerScreen(
                  key: ValueKey(videoId),
                  videoId: videoId,
                  title: coordinator.activeTitle.value,
                  channel: coordinator.activeChannel.value,
                  level: coordinator.activeLevel.value,
                  playlistTitle: coordinator.activePlaylistTitle.value,
                  playlistIndex: coordinator.activePlaylistIndex.value,
                  playlistTotal: coordinator.hasPlaylist ? coordinator.playlistTotal : null,
                  sharedPlayerController: coordinator.playerController,
                  sharedYtController: coordinator.ytController,
                ),
              ),
            ),
        ],
      );
    });
  }
}
