// lib/ui/video/video_player_screen.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import '../../state/player_coordinator.dart';
import '../../state/player_state.dart';
import '../../utils/cyrb53_hasher.dart';
import '../sheets/subtitle_tracks_sheet.dart';
import '../sheets/video_settings_sheet.dart';
import 'center_controls.dart';
import 'double_tap_seek_ripple.dart';
import 'playlist/mobile_playlist_bar.dart';
import 'subtitle_panel.dart';
import 'video_bottom_bar.dart';
import 'video_header.dart';
import 'video_more_feed.dart';
import 'video_progress_bar.dart';
import 'fullscreen_subtitle.dart';

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
  final _ytPlayerGlobalKey = GlobalKey();
  final bool _ownsControllers = false;
  YoutubeError? _playerError;
  DateTime _lastHistorySave = DateTime.now();

  // Fullscreen transition pause-guard
  bool _isFullscreenTransitioning = false;
  Timer? _fullscreenTransitionTimer;

  // Custom Player Overlay & Gesture States using Signals
  final _areControlsVisible = signal<bool>(true);
  final _leftSeekFeedback = signal<bool>(false);
  final _rightSeekFeedback = signal<bool>(false);
  final _seekAccumulator = signal<int>(10);
  final _isBuffering = signal<bool>(false);
  final _isEnded = signal<bool>(false);
  final _bufferedFraction = signal<double>(0.0);

  Timer? _controlsAutoHideTimer;
  Timer? _seekFeedbackTimer;
  DateTime? _lastLeftTapTime;
  DateTime? _lastRightTapTime;
  Timer? _pendingSingleTapTimer;
  double _accumulatedDragDown = 0.0;
  final ScrollController _bodyScrollController = ScrollController();
  final GlobalKey<VideoMoreFeedState> _moreFeedKey = GlobalKey<VideoMoreFeedState>();

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

      // Rule 2 Invariant & Strict clean embed:
      // Remove all native controls, buttons, annotations, and pointer events
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
          captionLanguage: '',
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
      _bufferedFraction.value = state.loadedFraction;

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

      // Sync fullscreen state & system orientation
      final isFs = value.fullScreenOption.enabled;
      if (_playerController.isFullscreen.value != isFs) {
        _playerController.isFullscreen.value = isFs;
        if (!isFs) {
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        } else {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        }
      }

      if (value.playerState == PlayerState.playing) {
        _playerController.isPlaying.value = true;
        _isBuffering.value = false;
        _isEnded.value = false;
        PlayerCoordinator.disableNativeCaptions(_ytController);
        _scheduleControlsAutoHide();
      } else if (value.playerState == PlayerState.buffering) {
        _isBuffering.value = true;
      } else if (value.playerState == PlayerState.paused) {
        if (_isFullscreenTransitioning) {
          // Pause-guard: spurious pause from WebView relayout during fullscreen orientation transition
          _ytController.playVideo();
        } else {
          _playerController.isPlaying.value = false;
          _isBuffering.value = false;
          _saveWatchHistory();
        }
      } else if (value.playerState == PlayerState.ended) {
        _playerController.isPlaying.value = false;
        _isBuffering.value = false;
        _isEnded.value = true;
        _areControlsVisible.value = true;
        _saveWatchHistory();
      }

      final newError = value.error == YoutubeError.none ? null : value.error;
      if (newError != _playerError) {
        setState(() {
          _playerError = newError;
        });
      }
    });

    _scheduleControlsAutoHide();
  }

  void _scheduleControlsAutoHide() {
    _controlsAutoHideTimer?.cancel();
    if (!_areControlsVisible.value) return;
    _controlsAutoHideTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted && _playerController.isPlaying.value && !_isBuffering.value && !_isEnded.value) {
        _areControlsVisible.value = false;
      }
    });
  }

  void _toggleControls() {
    _areControlsVisible.value = !_areControlsVisible.value;
    if (_areControlsVisible.value) {
      _scheduleControlsAutoHide();
    } else {
      _controlsAutoHideTimer?.cancel();
    }
  }

  void _handleSpatialTap(TapUpDetails details, double boxWidth) {
    final x = details.localPosition.dx;
    final now = DateTime.now();
    final isLeft = x < boxWidth * 0.40;
    final isRight = x > boxWidth * 0.60;

    _pendingSingleTapTimer?.cancel();
    _pendingSingleTapTimer = null;

    if (isLeft) {
      if (_leftSeekFeedback.value ||
          (_lastLeftTapTime != null && now.difference(_lastLeftTapTime!).inMilliseconds < 350)) {
        // Second or consecutive tap -> Seek & show ripple immediately
        _lastLeftTapTime = now;
        _seekRelative(-10);
        _triggerSeekFeedback(isLeft: true);
        if (_areControlsVisible.value) {
          _areControlsVisible.value = false;
        }
      } else {
        // First tap: record timestamp and toggle controls instantly without delay!
        _lastLeftTapTime = now;
        _toggleControls();
      }
    } else if (isRight) {
      if (_rightSeekFeedback.value ||
          (_lastRightTapTime != null && now.difference(_lastRightTapTime!).inMilliseconds < 350)) {
        // Second or consecutive tap -> Seek & show ripple immediately
        _lastRightTapTime = now;
        _seekRelative(10);
        _triggerSeekFeedback(isLeft: false);
        if (_areControlsVisible.value) {
          _areControlsVisible.value = false;
        }
      } else {
        // First tap: record timestamp and toggle controls instantly without delay!
        _lastRightTapTime = now;
        _toggleControls();
      }
    } else {
      // Center zone (40% to 60%): toggle controls instantly
      _toggleControls();
    }
  }

  void _seekRelative(int seconds) {
    final cur = _playerController.currentTime.value;
    final total = _ytController.metadata.duration.inSeconds.toDouble();
    final target = (cur + seconds).clamp(0.0, total > 0 ? total : double.infinity);
    _ytController.seekTo(seconds: target, allowSeekAhead: true);
    _playerController.currentTime.value = target;
  }

  void _triggerSeekFeedback({required bool isLeft}) {
    if (isLeft) {
      if (_leftSeekFeedback.value) {
        _seekAccumulator.value += 10;
      } else {
        _seekAccumulator.value = 10;
        _leftSeekFeedback.value = true;
      }
    } else {
      if (_rightSeekFeedback.value) {
        _seekAccumulator.value += 10;
      } else {
        _seekAccumulator.value = 10;
        _rightSeekFeedback.value = true;
      }
    }

    _seekFeedbackTimer?.cancel();
    _seekFeedbackTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        _leftSeekFeedback.value = false;
        _rightSeekFeedback.value = false;
        _seekAccumulator.value = 10;
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
      final channel = widget.channel ?? _ytController.metadata.author;
      final thumbnail = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
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
    final isFs = _ytController.value.fullScreenOption.enabled;
    _isFullscreenTransitioning = true;
    _fullscreenTransitionTimer?.cancel();
    _fullscreenTransitionTimer = Timer(const Duration(milliseconds: 1000), () {
      _isFullscreenTransitioning = false;
    });

    if (isFs) {
      _ytController.exitFullScreen();
      _playerController.isFullscreen.value = false;
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      _ytController.enterFullScreen();
      _playerController.isFullscreen.value = true;
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    _fullscreenTransitionTimer?.cancel();
    _controlsAutoHideTimer?.cancel();
    _seekFeedbackTimer?.cancel();
    _pendingSingleTapTimer?.cancel();
    _saveWatchHistory();
    if (_ytController.value.fullScreenOption.enabled) {
      _ytController.exitFullScreen();
    }
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (_ownsControllers) {
      _ytController.close();
    }
    _bodyScrollController.dispose();
    super.dispose();
  }

  Widget _buildCustomControlsOverlay(BuildContext context, bool isFullscreen, double inlineWidth) {
    final effectiveWidth = isFullscreen ? MediaQuery.sizeOf(context).width : inlineWidth;
    final totalDuration = _ytController.metadata.duration.inSeconds.toDouble();

    return Watch((context) {
      final isPlaying = _playerController.isPlaying.value;
      final curTime = _playerController.currentTime.value;
      final showDual = _playerController.showTranslation.value;
      final subsVisible = _playerController.showFurigana.value || showDual;
      final areVisible = _areControlsVisible.value;
      final isEnded = _isEnded.value;
      final isBuffering = _isBuffering.value;
      final leftFeedback = _leftSeekFeedback.value;
      final rightFeedback = _rightSeekFeedback.value;
      final seekAcc = _seekAccumulator.value;
      final bufferedFrac = _bufferedFraction.value;

      return Stack(
        fit: StackFit.expand,
        children: [
          // 1. Spatial Gesture Detector Layer (Double Tap Seek & Single Tap Controls + Swipe Down Minimize)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) => _handleSpatialTap(details, effectiveWidth),
            onVerticalDragUpdate: (details) {
              if (details.delta.dy > 0) {
                _accumulatedDragDown += details.delta.dy;
              }
            },
            onVerticalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0.0;
              if ((velocity > 250 || _accumulatedDragDown > 50) && !isFullscreen) {
                _handleMinimize();
              }
              _accumulatedDragDown = 0.0;
            },
            onVerticalDragCancel: () => _accumulatedDragDown = 0.0,
            child: const SizedBox.expand(),
          ),

          // 2. Left Double-Tap Seek Feedback Overlay (-10s)
          if (leftFeedback)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: effectiveWidth * 0.45,
              child: IgnorePointer(
                child: DoubleTapSeekRipple(
                  isLeft: true,
                  seconds: seekAcc,
                ),
              ),
            ),

          // 3. Right Double-Tap Seek Feedback Overlay (+10s)
          if (rightFeedback)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: effectiveWidth * 0.45,
              child: IgnorePointer(
                child: DoubleTapSeekRipple(
                  isLeft: false,
                  seconds: seekAcc,
                ),
              ),
            ),

          // 4. Custom Controls Overlay with Smooth Fade Transition
          IgnorePointer(
            ignoring: !areVisible,
            child: AnimatedOpacity(
              opacity: areVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (details) => _handleSpatialTap(details, effectiveWidth),
                onVerticalDragUpdate: (details) {
                  if (details.delta.dy > 0) {
                    _accumulatedDragDown += details.delta.dy;
                  }
                },
                onVerticalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0.0;
                  if ((velocity > 250 || _accumulatedDragDown > 50) && !isFullscreen) {
                    _handleMinimize();
                  }
                  _accumulatedDragDown = 0.0;
                },
                onVerticalDragCancel: () => _accumulatedDragDown = 0.0,
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
                      // Top Bar inside overlay
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            if (!isFullscreen) ...[
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 28),
                                tooltip: context.t('player.minimize', null, 'Minimize'),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _handleMinimize,
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.subtitles_rounded, color: Colors.white, size: 20),
                                tooltip: context.t('subtitle.tracksTitle', null, 'Subtitle Tracks'),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => SubtitleTracksSheet.show(
                                  context,
                                  controller: _playerController,
                                ),
                              ),
                              const SizedBox(width: 14),
                              IconButton(
                                icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
                                tooltip: context.t('player.settings', null, 'Settings'),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => VideoSettingsSheet.show(
                                  context,
                                  controller: _playerController,
                                  ytController: _ytController,
                                ),
                              ),
                            ] else ...[
                              IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                                tooltip: 'Exit Fullscreen',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _toggleFullscreen,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.title.isNotEmpty ? widget.title : _playerController.videoTitle.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.subtitles_rounded, color: Colors.white, size: 20),
                                tooltip: context.t('subtitle.tracksTitle', null, 'Subtitle Tracks'),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => SubtitleTracksSheet.show(
                                  context,
                                  controller: _playerController,
                                ),
                              ),
                              const SizedBox(width: 14),
                              IconButton(
                                icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
                                tooltip: context.t('player.settings', null, 'Settings'),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => VideoSettingsSheet.show(
                                  context,
                                  controller: _playerController,
                                  ytController: _ytController,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Center Controls (Play/Pause, Buffering loader, Replay, Prev/Next skip)
                      CenterControls(
                        isPlaying: isPlaying,
                        isBuffering: isBuffering,
                        isEnded: isEnded,
                        areControlsVisible: areVisible,
                        hasPlaylist: PlayerCoordinator.instance.hasPlaylist,
                        canPlayPrev: PlayerCoordinator.instance.canPlayPrev,
                        canPlayNext: PlayerCoordinator.instance.canPlayNext,
                        onPrev: () => PlayerCoordinator.instance.playPrevious(context),
                        onNext: () => PlayerCoordinator.instance.playNext(context),
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
                      ),

                      // Bottom Controls: Scrub bar + VideoBottomBar
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VideoProgressBar(
                            currentTime: curTime,
                            duration: totalDuration,
                            bufferedFraction: bufferedFrac,
                            onSeekStarted: () {
                              _controlsAutoHideTimer?.cancel();
                            },
                            onSeekEnded: (newSeconds) {
                              _ytController.seekTo(seconds: newSeconds, allowSeekAhead: true);
                              _playerController.currentTime.value = newSeconds;
                              _scheduleControlsAutoHide();
                            },
                          ),
                          VideoBottomBar(
                            isPlaying: isPlaying,
                            isEnded: isEnded,
                            currentTime: curTime,
                            duration: totalDuration,
                            showPlayPause: false,
                            subtitlesVisible: subsVisible,
                            showDualSubtitles: showDual,
                            isCJKLanguage: true,
                            isFullscreen: isFullscreen,
                            showSubtitlesToggle: isFullscreen,
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 5. Fullscreen Subtitles Overlay (Frosted glass card with ruby, interactive tokens, drag handle)
          if (isFullscreen)
            FullscreenSubtitle(
              controller: _playerController,
              ytController: _ytController,
              areControlsVisible: areVisible,
            ),
        ],
      );
    });
  }

  Widget _buildVideoPlayerArea({bool isFullscreen = false}) {
    final colors = context.vocaColors;
    if (_playerError != null && _playerError != YoutubeError.none) {
      return Container(
        height: isFullscreen ? MediaQuery.sizeOf(context).height : 220,
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

        final playerWidget = AspectRatio(
          aspectRatio: 16 / 9,
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              // YouTube-style swipe down to minimize gesture
              if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                _handleMinimize();
              }
            },
            child: YoutubePlayer(
              key: _ytPlayerGlobalKey,
              controller: _ytController,
              aspectRatio: 16 / 9,
              backgroundColor: Colors.black,
              enableFullScreenOnVerticalDrag: false,
              autoFullScreen: false,
              gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
              controlsBuilder: (context, isFs) {
                return _buildCustomControlsOverlay(context, isFs || isFullscreen, boxWidth);
              },
            ),
          ),
        );

        if (isFullscreen) {
          return SizedBox.expand(
            child: Center(
              child: playerWidget,
            ),
          );
        }

        return playerWidget;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final mediaQuery = MediaQuery.of(context);
      final isTablet = mediaQuery.size.width >= VocaTokens.tabletBreakpoint;
      final isFullscreen = _playerController.isFullscreen.value;
      final colors = context.vocaColors;

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_ytController.value.fullScreenOption.enabled || isFullscreen) {
            _toggleFullscreen();
          } else {
            _handleMinimize();
          }
        },
        child: Scaffold(
          backgroundColor: isFullscreen ? Colors.black : context.vocaColors.bgPrimary,
          body: SafeArea(
            top: !isFullscreen,
            bottom: !isFullscreen,
            left: !isFullscreen,
            right: !isFullscreen,
            child: isFullscreen
                ? _buildVideoPlayerArea(isFullscreen: true)
                : (isTablet
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Pane (flex 3): 16:9 Youtube player + VideoHeader + Playlist
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                _buildVideoPlayerArea(isFullscreen: false),
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
                                    onCloseTap: () => PlayerCoordinator.instance.closeVideo(),
                                    onVerticalDragDown: _handleMinimize,
                                  );
                                }),
                                Watch((context) {
                                  final coord = PlayerCoordinator.instance;
                                  if (!coord.hasPlaylist) return const SizedBox.shrink();
                                  return MobilePlaylistBar(
                                    title: coord.activePlaylistTitle.value ?? 'Playlist',
                                    currentIndex: coord.activePlaylistIndex.value ?? 0,
                                    totalVideos: coord.playlistTotal,
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
                          // 1. Pinned 16:9 Youtube Player Area
                          _buildVideoPlayerArea(isFullscreen: false),

                          // 2. Scrollable Lower Body (Header + Compact Subtitle + More Feed)
                          Expanded(
                            child: NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (notification is ScrollUpdateNotification) {
                                  if (notification.metrics.extentAfter < 300) {
                                    _moreFeedKey.currentState?.loadMore();
                                  }
                                }
                                return false;
                              },
                              child: SingleChildScrollView(
                                controller: _bodyScrollController,
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // VideoHeader (Title, channel, level badge, tracks [cc], share, close [x])
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
                                        onCloseTap: () => PlayerCoordinator.instance.closeVideo(),
                                        onVerticalDragDown: _handleMinimize,
                                      );
                                    }),

                                    // Compact Playlist Bar (If part of a playlist)
                                    Watch((context) {
                                      final coord = PlayerCoordinator.instance;
                                      if (!coord.hasPlaylist) return const SizedBox.shrink();
                                      return MobilePlaylistBar(
                                        title: coord.activePlaylistTitle.value ?? 'Playlist',
                                        currentIndex: coord.activePlaylistIndex.value ?? 0,
                                        totalVideos: coord.playlistTotal,
                                      );
                                    }),

                                    // Compact SubtitlePanel (3-line timeline)
                                    SubtitlePanel(
                                      controller: _playerController,
                                      ytController: _ytController,
                                      isCompact: true,
                                      onSeek: (seconds) => _ytController.seekTo(
                                        seconds: seconds,
                                        allowSeekAhead: true,
                                      ),
                                    ),

                                    // Clean Section Header
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                                      child: Text(
                                        context.t('forYou', null, 'For You'),
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: colors.textPrimary,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),

                                    // Infinite scroll feed with VideoFeedCard cards
                                    Watch((context) {
                                      return VideoMoreFeed(
                                        key: _moreFeedKey,
                                        currentVideoId: widget.videoId,
                                        currentTitle: widget.title.isNotEmpty
                                            ? widget.title
                                            : _playerController.videoTitle.value,
                                        currentChannel: widget.channel ?? _ytController.metadata.author,
                                        language: _playerController.activeLanguage.value,
                                        tier: widget.level ?? _playerController.difficultyLevel.value,
                                        onVideoTap: (vidId, title, channel, level) {
                                          PlayerCoordinator.instance.openVideo(
                                            context,
                                            videoId: vidId,
                                            title: title,
                                            channel: channel,
                                            level: level,
                                          );
                                        },
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )),
          ),
        ),
      );
    });
  }
}
