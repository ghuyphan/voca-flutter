// lib/ui/video/video_player_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import '../../state/player_coordinator.dart';
import '../../state/player_state.dart';
import '../../utils/cyrb53_hasher.dart';
import '../sheets/video_settings_sheet.dart';
import 'center_controls.dart';
import 'subtitle_panel.dart';
import 'video_bottom_bar.dart';
import 'video_header.dart';
import 'video_progress_bar.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;
  final String? channel;
  final String? level;
  final String? playlistTitle;
  final int? playlistIndex;
  final int? playlistTotal;
  final VideoPlayerController? sharedPlayerController;
  final YoutubePlayerController? sharedYtController;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
    this.channel,
    this.level,
    this.playlistTitle,
    this.playlistIndex,
    this.playlistTotal,
    this.sharedPlayerController,
    this.sharedYtController,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final YoutubePlayerController _ytController;
  late final VideoPlayerController _playerController;
  final bool _ownsControllers = false;

  YoutubeError? _playerError;
  DateTime _lastHistorySave = DateTime.now();

  // Custom Player Overlay & Gesture States
  bool _areControlsVisible = true;
  Timer? _controlsAutoHideTimer;

  bool _leftSeekFeedback = false;
  bool _rightSeekFeedback = false;
  int _seekAccumulator = 10;
  Timer? _seekFeedbackTimer;
  DateTime? _lastLeftTapTime;
  DateTime? _lastRightTapTime;
  Timer? _pendingSingleTapTimer;

  bool _isBuffering = false;
  bool _isEnded = false;
  double _bufferedFraction = 0.0;

  @override
  void initState() {
    super.initState();

    if (widget.sharedPlayerController != null && widget.sharedYtController != null) {
      _playerController = widget.sharedPlayerController!;
      _ytController = widget.sharedYtController!;
    } else {
      _playerController = VideoPlayerController(
        apiClient: AppState.instance.apiClient,
        grammarEngine: AppState.instance.grammarEngine,
      );

      // Rule 2 Invariant: Standard initialization without hardcoded key.
      // pointerEvents: PointerEvents.none ensures touches pass directly to custom controls & gestures.
      _ytController = YoutubePlayerController(
        params: const YoutubePlayerParams(
          showControls: false,
          showFullscreenButton: false,
          pointerEvents: PointerEvents.none,
          showVideoAnnotations: false,
          strictRelatedVideos: true,
          enableKeyboard: false,
          playsInline: true,
          mute: false,
          enableCaption: false,
          origin: 'https://www.youtube-nocookie.com',
          privacyEnhancedMode: true,
          userAgent:
              'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
        ),
      );

      _ytController.loadVideoById(videoId: widget.videoId);
      _playerController.loadVideo(widget.videoId);
    }

    _ytController.videoStateStream.listen((state) {
      if (!mounted) return;
      final time = state.position.inMilliseconds / 1000.0;
      _playerController.currentTime.value = time;
      setState(() {
        _bufferedFraction = state.loadedFraction;
      });

      // Sentence / Cue Looping
      if (_playerController.isLoopingCue.value) {
        final loopCue =
            _playerController.loopingCue.value ?? _playerController.activeCue.value;
        if (loopCue != null && loopCue.duration > 0.3) {
          final cueEnd = loopCue.start + loopCue.duration;
          if (time >= cueEnd || time < loopCue.start - 0.5) {
            _ytController.seekTo(seconds: loopCue.start, allowSeekAhead: true);
          }
        }
      }

      // Periodic Watch History Tracking (every 30 seconds)
      final now = DateTime.now();
      if (now.difference(_lastHistorySave).inSeconds >= 30) {
        _lastHistorySave = now;
        _saveWatchHistory();
      }
    });

    _ytController.listen((value) {
      if (!mounted) return;
      if (value.playerState == PlayerState.playing) {
        _playerController.isPlaying.value = true;
        setState(() {
          _isBuffering = false;
          _isEnded = false;
        });
        _scheduleControlsAutoHide();
      } else if (value.playerState == PlayerState.buffering) {
        setState(() {
          _isBuffering = true;
        });
      } else if (value.playerState == PlayerState.paused) {
        _playerController.isPlaying.value = false;
        setState(() {
          _isBuffering = false;
        });
        _saveWatchHistory();
      } else if (value.playerState == PlayerState.ended) {
        _playerController.isPlaying.value = false;
        setState(() {
          _isBuffering = false;
          _isEnded = true;
          _areControlsVisible = true;
        });
        _saveWatchHistory();
      }

      if (value.error != YoutubeError.none && value.error != _playerError) {
        setState(() {
          _playerError = value.error;
        });
      }
    });

    _scheduleControlsAutoHide();
  }

  void _scheduleControlsAutoHide() {
    _controlsAutoHideTimer?.cancel();
    if (!_areControlsVisible) return;
    _controlsAutoHideTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted && _playerController.isPlaying.value && !_isBuffering && !_isEnded) {
        setState(() {
          _areControlsVisible = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _areControlsVisible = !_areControlsVisible;
    });
    if (_areControlsVisible) {
      _scheduleControlsAutoHide();
    } else {
      _controlsAutoHideTimer?.cancel();
    }
  }

  void _handleSpatialTap(TapUpDetails details, double boxWidth) {
    final x = details.localPosition.dx;
    final now = DateTime.now();

    if (x < boxWidth * 0.35) {
      // Left 35%: Rewind zone
      _pendingSingleTapTimer?.cancel();
      _pendingSingleTapTimer = null;

      if (_leftSeekFeedback || (_lastLeftTapTime != null && now.difference(_lastLeftTapTime!).inMilliseconds < 300)) {
        _lastLeftTapTime = null;
        _seekRelative(-10);
        _triggerSeekFeedback(isLeft: true);
      } else {
        _lastLeftTapTime = now;
        _pendingSingleTapTimer = Timer(const Duration(milliseconds: 260), () {
          _lastLeftTapTime = null;
          _toggleControls();
        });
      }
    } else if (x > boxWidth * 0.65) {
      // Right 35%: Forward zone
      _pendingSingleTapTimer?.cancel();
      _pendingSingleTapTimer = null;

      if (_rightSeekFeedback || (_lastRightTapTime != null && now.difference(_lastRightTapTime!).inMilliseconds < 300)) {
        _lastRightTapTime = null;
        _seekRelative(10);
        _triggerSeekFeedback(isLeft: false);
      } else {
        _lastRightTapTime = now;
        _pendingSingleTapTimer = Timer(const Duration(milliseconds: 260), () {
          _lastRightTapTime = null;
          _toggleControls();
        });
      }
    } else {
      // Center 30%: Instant controls toggle without delay
      _pendingSingleTapTimer?.cancel();
      _pendingSingleTapTimer = null;
      _lastLeftTapTime = null;
      _lastRightTapTime = null;
      _toggleControls();
    }
  }

  void _seekRelative(double deltaSeconds) {
    final cur = _playerController.currentTime.value;
    final dur = _ytController.metadata.duration.inSeconds.toDouble();
    final target = (cur + deltaSeconds).clamp(0.0, dur > 0 ? dur : double.infinity);
    _ytController.seekTo(seconds: target, allowSeekAhead: true);
    _playerController.currentTime.value = target;
  }

  void _triggerSeekFeedback({required bool isLeft}) {
    _seekFeedbackTimer?.cancel();
    setState(() {
      if (isLeft) {
        if (_leftSeekFeedback) {
          _seekAccumulator += 10;
        } else {
          _seekAccumulator = 10;
        }
        _leftSeekFeedback = true;
        _rightSeekFeedback = false;
      } else {
        if (_rightSeekFeedback) {
          _seekAccumulator += 10;
        } else {
          _seekAccumulator = 10;
        }
        _rightSeekFeedback = true;
        _leftSeekFeedback = false;
      }
    });
    _seekFeedbackTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _leftSeekFeedback = false;
          _rightSeekFeedback = false;
          _seekAccumulator = 10;
        });
      }
    });
  }

  void _handleMinimize() {
    final coordinator = PlayerCoordinator.instance;
    if (coordinator.hasActiveVideo) {
      coordinator.minimize(context);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _saveWatchHistory() async {
    try {
      final user = AppState.instance.supabaseService.currentUser;
      if (user == null) return;

      final videoId = widget.videoId;
      final id = generateDeterministicRecordId([user.id, videoId]);
      final title = widget.title.isNotEmpty
          ? widget.title
          : _playerController.videoTitle.value;
      final thumbnail = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
      final author = widget.channel ?? _ytController.metadata.author;
      final channel = author.isNotEmpty ? author : 'YouTube';
      final metaDur = _ytController.metadata.duration.inSeconds;
      final lastCue = _playerController.cues.value.isNotEmpty
          ? _playerController.cues.value.last
          : null;
      final fallbackDur =
          lastCue != null ? (lastCue.start + lastCue.duration).ceil() : 0;
      final dur = metaDur > 0 ? metaDur : fallbackDur;
      final currentSec = _playerController.currentTime.value;
      final progress = dur > 0 ? (currentSec / dur).clamp(0.0, 1.0) : 0.0;

      await AppState.instance.supabaseService.saveHistory(
        id: id,
        videoId: videoId,
        title: title,
        thumbnail: thumbnail,
        channel: channel,
        duration: dur,
        language: AppState.instance.activeLanguage.value,
        progress: progress,
      );
    } catch (e) {
      debugPrint('[VideoPlayerScreen] Error saving watch history: $e');
    }
  }



  void _toggleFullscreen() {
    final next = !_playerController.isFullscreen.value;
    _playerController.isFullscreen.value = next;
    if (next) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    _controlsAutoHideTimer?.cancel();
    _seekFeedbackTimer?.cancel();
    _pendingSingleTapTimer?.cancel();
    _saveWatchHistory();
    if (_playerController.isFullscreen.value) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    if (_ownsControllers) {
      _ytController.close();
    }
    super.dispose();
  }

  Widget _buildVideoPlayerArea() {
    final colors = context.vocaColors;
    if (_playerError != null && _playerError != YoutubeError.none) {
      return Container(
        height: 220,
        color: colors.bgCard,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: colors.accentTertiary,
                size: 36,
              ),
              const SizedBox(height: 8),
              Text(
                'Playback Restricted by Owner',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'YouTube owner disabled third-party embedding for this track. You can open it in YouTube while using Voca for subtitles & vocabulary.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse('https://www.youtube.com/watch?v=${widget.videoId}'),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text('Watch on YouTube', style: TextStyle(fontSize: 12.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;
        final totalDuration = _ytController.metadata.duration.inSeconds.toDouble();

        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. YouTube Player with pointerEvents: none (Touches handled exclusively by Flutter)
              YoutubePlayer(
                controller: _ytController,
                aspectRatio: 16 / 9,
                backgroundColor: Colors.black,
              ),

              // 2. Spatial Gesture Detector Layer (Double Tap Seek & Single Tap Controls)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) => _handleSpatialTap(details, boxWidth),
                child: const SizedBox.expand(),
              ),

              // 3. Left Double-Tap Seek Feedback Overlay (-10s)
              if (_leftSeekFeedback)
                Positioned(
                  left: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.fast_rewind_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${_seekAccumulator}s',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 4. Right Double-Tap Seek Feedback Overlay (+10s)
              if (_rightSeekFeedback)
                Positioned(
                  right: 20,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_seekAccumulator}s',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.fast_forward_rounded, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),

              // 5. Custom Controls Overlay with Smooth Fade Transition
              IgnorePointer(
                ignoring: !_areControlsVisible,
                child: AnimatedOpacity(
                  opacity: _areControlsVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.75),
                          Colors.transparent,
                          Colors.black.withOpacity(0.85),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Compact top bar inside overlay (minimize chevron)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 28),
                                tooltip: context.t('player.minimize', null, 'Minimize'),
                                onPressed: _handleMinimize,
                              ),
                            ],
                          ),
                        ),

                        // Center Controls (Play/Pause, Buffering loader, Replay)
                        Watch((context) {
                          final isPlaying = _playerController.isPlaying.value;
                          return CenterControls(
                            isPlaying: isPlaying,
                            isBuffering: _isBuffering,
                            isEnded: _isEnded,
                            areControlsVisible: _areControlsVisible,
                            hasPlaylist: widget.playlistTotal != null && widget.playlistTotal! > 1,
                            canPlayPrev: widget.playlistIndex != null && widget.playlistIndex! > 0,
                            canPlayNext: widget.playlistIndex != null &&
                                widget.playlistTotal != null &&
                                widget.playlistIndex! < widget.playlistTotal! - 1,
                            onPlayPause: () {
                              if (isPlaying) {
                                _ytController.pauseVideo();
                              } else {
                                _ytController.playVideo();
                              }
                            },
                            onReplay: () {
                              _ytController.seekTo(seconds: 0.0, allowSeekAhead: true);
                              _ytController.playVideo();
                            },
                          );
                        }),

                        // Bottom Controls: Scrub bar + VideoBottomBar (showPlayPause: false eliminates duplicate!)
                        Watch((context) {
                          final curTime = _playerController.currentTime.value;
                          final isPlaying = _playerController.isPlaying.value;
                          final showDual = _playerController.showTranslation.value;
                          final subsVisible = _playerController.showFurigana.value || showDual;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Smooth Touch Scrubber
                              VideoProgressBar(
                                currentTime: curTime,
                                duration: totalDuration,
                                bufferedFraction: _bufferedFraction,
                                onSeekStarted: () {
                                  _controlsAutoHideTimer?.cancel();
                                },
                                onSeekEnded: (newSeconds) {
                                  _ytController.seekTo(seconds: newSeconds, allowSeekAhead: true);
                                  _playerController.currentTime.value = newSeconds;
                                  _scheduleControlsAutoHide();
                                },
                              ),

                              // Bottom Controls Row (Time, CC toggle, Dual Sub toggle, Settings, Miniplayer, Fullscreen)
                              VideoBottomBar(
                                isPlaying: isPlaying,
                                isEnded: _isEnded,
                                currentTime: curTime,
                                duration: totalDuration,
                                showPlayPause: false, // NO duplicate play/pause with CenterControls!
                                subtitlesVisible: subsVisible,
                                showDualSubtitles: showDual,
                                isCJKLanguage: ['ja', 'zh', 'ko'].contains(AppState.instance.activeLanguage.value),
                                isFullscreen: _playerController.isFullscreen.value,
                                showSubtitlesToggle: _playerController.isFullscreen.value,
                                onPlayPause: () {
                                  if (isPlaying) {
                                    _ytController.pauseVideo();
                                  } else {
                                    _ytController.playVideo();
                                  }
                                },
                                onToggleSubtitles: () {
                                  _playerController.toggleFurigana();
                                },
                                onToggleDualSubtitles: () {
                                  _playerController.toggleTranslation();
                                },
                                onOpenSettings: () {
                                  VideoSettingsSheet.show(
                                    context,
                                    controller: _playerController,
                                    ytController: _ytController,
                                  );
                                },
                                onToggleMiniplayer: _handleMinimize,
                                onToggleFullscreen: _toggleFullscreen,
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final isFullscreen = _playerController.isFullscreen.value;
      final mediaQuery = MediaQuery.of(context);
      final isTablet = mediaQuery.size.width >= VocaTokens.tabletBreakpoint;
      final isLandscape = mediaQuery.orientation == Orientation.landscape;

      // 1. True Fullscreen (Landscape video-only view)
      if (isFullscreen || (isLandscape && !isTablet)) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _toggleFullscreen();
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: _buildVideoPlayerArea(),
            ),
          ),
        );
      }

      // 2. Normal View (Portrait Mobile or Tablet)
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _handleMinimize();
        },
        child: Scaffold(
          backgroundColor: context.vocaColors.bgPrimary,
          body: SafeArea(
            child: isTablet
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Pane (flex 3): 16:9 Youtube player + VideoHeader
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildVideoPlayerArea(),
                            Watch((context) {
                              return VideoHeader(
                                title: widget.title.isNotEmpty
                                    ? widget.title
                                    : _playerController.videoTitle.value,
                                channel: widget.channel ?? _ytController.metadata.author,
                                videoId: widget.videoId,
                                level: widget.level ?? _playerController.difficultyLevel.value,
                                controller: _playerController,
                                ytController: _ytController,
                                onCloseTap: _handleMinimize,
                              );
                            }),
                          ],
                        ),
                      ),

                      // Right Pane (flex 2): Unified SubtitlePanel
                      Expanded(
                        flex: 2,
                        child: SubtitlePanel(
                          controller: _playerController,
                          ytController: _ytController,
                          onSeek: (seconds) => _ytController.seekTo(
                            seconds: seconds,
                            allowSeekAhead: true,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      // 1. 16:9 Youtube Player with Gesture Detector, Center Controls & Bottom Bar
                      _buildVideoPlayerArea(),

                      // 2. VideoHeader (Title, channel, level badge, tracks [cc], share, close [x])
                      Watch((context) {
                        return VideoHeader(
                          title: widget.title.isNotEmpty
                              ? widget.title
                              : _playerController.videoTitle.value,
                          channel: widget.channel ?? _ytController.metadata.author,
                          videoId: widget.videoId,
                          level: widget.level ?? _playerController.difficultyLevel.value,
                          controller: _playerController,
                          ytController: _ytController,
                          onCloseTap: _handleMinimize,
                        );
                      }),

                      // 3. Unified SubtitlePanel (Active Subtitle + Cue List + 4-Pill Toolbar)
                      Expanded(
                        child: SubtitlePanel(
                          controller: _playerController,
                          ytController: _ytController,
                          onSeek: (seconds) => _ytController.seekTo(
                            seconds: seconds,
                            allowSeekAhead: true,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }
}
