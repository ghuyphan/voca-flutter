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
  bool _ownsControllers = false;
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

  StreamSubscription? _videoStateSubscription;
  StreamSubscription? _controllerSubscription;
  Timer? _doubleTapSeekDebounceTimer;
  DateTime _lastLoopSeekTime = DateTime.fromMillisecondsSinceEpoch(0);

  Timer? _controlsAutoHideTimer;
  Timer? _seekFeedbackTimer;
  DateTime? _lastLeftTapTime;
  DateTime? _lastRightTapTime;
  Timer? _pendingSingleTapTimer;
  double _accumulatedDragDown = 0.0;
  final ScrollController _bodyScrollController = ScrollController();
  final GlobalKey<VideoMoreFeedState> _moreFeedKey = GlobalKey<VideoMoreFeedState>();
  bool _isTablet = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isTablet = MediaQuery.sizeOf(context).width >= VocaTokens.tabletBreakpoint;
  }

  @override
  void initState() {
    super.initState();

    if (widget.sharedPlayerController != null && widget.sharedYtController != null) {
      _playerController = widget.sharedPlayerController!;
      _ytController = widget.sharedYtController!;
      _ownsControllers = false;
    } else {
      _ownsControllers = true;
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

    _videoStateSubscription = _ytController.videoStateStream.listen((state) {
      if (!mounted) return;
      final time = state.position.inMilliseconds / 1000.0;
      _playerController.currentTime.value = time;
      _bufferedFraction.value = state.loadedFraction;

      // Sentence / Cue Looping with seek cooldown
      if (_playerController.isLoopingCue.value) {
        final loopCue =
            _playerController.loopingCue.value ?? _playerController.activeCue.value;
        if (loopCue != null && loopCue.duration > 0.3) {
          final cueEnd = loopCue.start + loopCue.duration;
          if (time >= cueEnd || time < loopCue.start - 0.5) {
            final now = DateTime.now();
            if (now.difference(_lastLoopSeekTime).inMilliseconds >= 500) {
              _lastLoopSeekTime = now;
              _ytController.seekTo(seconds: loopCue.start, allowSeekAhead: true);
              _playerController.handleSeek(loopCue.start);
            }
          }
        }
      }

      // Periodic Watch History Tracking (every 30 seconds)
      final now = DateTime.now();
      if (now.difference(_lastHistorySave).inSeconds >= 30) {
        _lastHistorySave = now;
        PlayerCoordinator.instance.saveWatchHistory();
      }
    });

    _controllerSubscription = _ytController.listen((value) {
      if (!mounted) return;

      // Sync fullscreen state & system orientation
      final isFs = value.fullScreenOption.enabled;
      if (_playerController.isFullscreen.value != isFs) {
        _playerController.isFullscreen.value = isFs;
        if (!isFs) {
          if (_isTablet) {
            SystemChrome.setPreferredOrientations(DeviceOrientation.values);
          } else {
            SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
          }
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
        if (_playerError != null) {
          setState(() {
            _playerError = null;
          });
        }
        PlayerCoordinator.disableNativeCaptions(_ytController);
        _scheduleControlsAutoHide();
      } else if (value.playerState == PlayerState.buffering) {
        _isBuffering.value = true;
        if (_playerError != null) {
          setState(() {
            _playerError = null;
          });
        }
      } else if (value.playerState == PlayerState.paused) {
        if (_isFullscreenTransitioning) {
          // Pause-guard: spurious pause from WebView relayout during fullscreen orientation transition
          _ytController.playVideo();
        } else {
          _playerController.isPlaying.value = false;
          _isBuffering.value = false;
          PlayerCoordinator.instance.saveWatchHistory();
        }
      } else if (value.playerState == PlayerState.ended) {
        _playerController.isPlaying.value = false;
        _isBuffering.value = false;
        _isEnded.value = true;
        _areControlsVisible.value = true;
        PlayerCoordinator.instance.saveWatchHistory();
      }

      final newError = value.error == YoutubeError.none ? null : value.error;
      final isFatal = newError == YoutubeError.notEmbeddable ||
          newError == YoutubeError.sameAsNotEmbeddable ||
          newError == YoutubeError.sameAsNotEmbeddable2 ||
          newError == YoutubeError.videoNotFound ||
          newError == YoutubeError.cannotFindVideo ||
          newError == YoutubeError.html5Error;

      if (newError != null && isFatal) {
        if (newError != _playerError) {
          debugPrint('[VideoPlayerScreen] YouTube Player Fatal Error: $newError (${value.error})');
          setState(() {
            _playerError = newError;
          });
        }
      } else if (newError == null && _playerError != null) {
        setState(() {
          _playerError = null;
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
    final isLeft = x < boxWidth * 0.38;
    final isRight = x > boxWidth * 0.62;

    if (isLeft || isRight) {
      _handleSideTap(isLeft: isLeft, now: now);
    } else {
      // Center zone (38% to 62%): cancel any pending side single-tap and toggle controls immediately
      _pendingSingleTapTimer?.cancel();
      _pendingSingleTapTimer = null;
      _toggleControls();
    }
  }

  void _handleSideTap({required bool isLeft, required DateTime now}) {
    final lastTime = isLeft ? _lastLeftTapTime : _lastRightTapTime;
    final isFeedbackActive = isLeft ? _leftSeekFeedback.value : _rightSeekFeedback.value;
    final isConsecutive = isFeedbackActive ||
        (lastTime != null && now.difference(lastTime).inMilliseconds < 350);

    if (isLeft) {
      _lastLeftTapTime = now;
    } else {
      _lastRightTapTime = now;
    }

    if (isConsecutive) {
      // Consecutive tap of double-tap: cancel pending single-tap so controls NEVER flicker!
      _pendingSingleTapTimer?.cancel();
      _pendingSingleTapTimer = null;
      _seekRelative(isLeft ? -10 : 10);
      _triggerSeekFeedback(isLeft: isLeft);
      if (_areControlsVisible.value) {
        _areControlsVisible.value = false;
      }
    } else {
      // First tap: DO NOT toggle controls immediately. Wait 260ms to confirm if a 2nd tap follows.
      _pendingSingleTapTimer?.cancel();
      _pendingSingleTapTimer = Timer(const Duration(milliseconds: 260), () {
        if (mounted) {
          _pendingSingleTapTimer = null;
          _toggleControls();
        }
      });
    }
  }

  void _seekRelative(int seconds) {
    final cur = _playerController.currentTime.value;
    final total = _ytController.metadata.duration.inSeconds.toDouble();
    final target = (cur + seconds).clamp(0.0, total > 0 ? total : double.infinity);
    _playerController.currentTime.value = target;
    PlayerCoordinator.instance.currentTime.value = target;

    _doubleTapSeekDebounceTimer?.cancel();
    _doubleTapSeekDebounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        _ytController.seekTo(seconds: target, allowSeekAhead: true);
        _playerController.handleSeek(target);
      }
    });
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
      final isTablet = MediaQuery.sizeOf(context).width >= VocaTokens.tabletBreakpoint;
      if (isTablet) {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
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
    _videoStateSubscription?.cancel();
    _controllerSubscription?.cancel();
    _doubleTapSeekDebounceTimer?.cancel();
    _fullscreenTransitionTimer?.cancel();
    _controlsAutoHideTimer?.cancel();
    _seekFeedbackTimer?.cancel();
    _pendingSingleTapTimer?.cancel();
    PlayerCoordinator.instance.saveWatchHistory();
    if (_ytController.value.fullScreenOption.enabled) {
      _ytController.exitFullScreen();
    }
    if (_isTablet) {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    } else {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (_ownsControllers) {
      _ytController.close();
      _playerController.dispose();
    }
    _bodyScrollController.dispose();
    super.dispose();
  }

  Widget _buildCustomControlsOverlay(BuildContext context, bool isFullscreen, double inlineWidth) {
    final effectiveWidth = isFullscreen ? MediaQuery.sizeOf(context).width : inlineWidth;
    final totalDuration = _ytController.metadata.duration.inSeconds.toDouble();

    return Watch((context) {
      final isPlaying = _playerController.isPlaying.value;
      final areVisible = _areControlsVisible.value;
      final isEnded = _isEnded.value;
      final isBuffering = _isBuffering.value;
      final leftFeedback = _leftSeekFeedback.value;
      final rightFeedback = _rightSeekFeedback.value;
      final seekAcc = _seekAccumulator.value;

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
              if (velocity > 180 || _accumulatedDragDown > 35) {
                if (isFullscreen) {
                  _toggleFullscreen();
                } else {
                  _handleMinimize();
                }
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
              curve: Curves.easeInOut,
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
                  if (velocity > 180 || _accumulatedDragDown > 35) {
                    if (isFullscreen) {
                      _toggleFullscreen();
                    } else {
                      _handleMinimize();
                    }
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
                        Colors.black.withValues(alpha: 0.75),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85),
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
                                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                padding: const EdgeInsets.all(8),
                                onPressed: _handleMinimize,
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.subtitles_rounded, color: Colors.white, size: 20),
                                tooltip: context.t('subtitle.tracksTitle', null, 'Subtitle Tracks'),
                                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                padding: const EdgeInsets.all(8),
                                onPressed: () => SubtitleTracksSheet.show(
                                  context,
                                  controller: _playerController,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
                                tooltip: context.t('player.settings', null, 'Settings'),
                                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                padding: const EdgeInsets.all(8),
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
                                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                padding: const EdgeInsets.all(8),
                                onPressed: _toggleFullscreen,
                              ),
                              const SizedBox(width: 8),
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
                                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                padding: const EdgeInsets.all(8),
                                onPressed: () => SubtitleTracksSheet.show(
                                  context,
                                  controller: _playerController,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
                                tooltip: context.t('player.settings', null, 'Settings'),
                                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                padding: const EdgeInsets.all(8),
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

                      // Bottom Controls: Scrub bar + VideoBottomBar (isolated Watch for playback time ticks)
                      Watch((context) {
                        final curTime = _playerController.currentTime.value;
                        final bufferedFrac = _bufferedFraction.value;
                        final showDual = _playerController.showTranslation.value;
                        final subsVisible = _playerController.showFurigana.value || showDual;

                        return Column(
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
                                PlayerCoordinator.instance.currentTime.value = newSeconds;
                                _playerController.handleSeek(newSeconds);
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
                        );
                      }),
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
    final isRestricted = _playerError == YoutubeError.notEmbeddable ||
        _playerError == YoutubeError.sameAsNotEmbeddable ||
        _playerError == YoutubeError.sameAsNotEmbeddable2 ||
        _playerError == YoutubeError.html5Error;
    final isUnavailable = _playerError == YoutubeError.videoNotFound ||
        _playerError == YoutubeError.cannotFindVideo;
    final isFatalError = isRestricted || isUnavailable;

    if (_playerError != null && isFatalError) {
      final title = isRestricted
          ? context.t('player.restrictedTitle', null, 'Playback Restricted by Owner')
          : (isUnavailable
              ? context.t('player.videoUnavailableTitle', null, 'Video Unavailable')
              : context.t('player.playbackErrorTitle', null, 'Playback Error'));

      final description = isRestricted
          ? context.t(
              'player.embedErrorHelp',
              null,
              'YouTube owner disabled third-party embedding for this track. You can open it in YouTube while using Voca for subtitles & vocabulary.',
            )
          : (isUnavailable
              ? context.t(
                  'player.videoUnavailableHelp',
                  null,
                  'This video is private, removed, or not available.',
                )
              : context.t(
                  'player.playbackErrorHelp',
                  null,
                  'Unable to load video stream. Please check your connection and retry.',
                ));

      final icon = isRestricted
          ? Icons.lock_outline_rounded
          : (isUnavailable ? Icons.videocam_off_outlined : Icons.wifi_off_rounded);

      final errorWidget = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (details) {
          if (details.delta.dy > 0) {
            _accumulatedDragDown += details.delta.dy;
          }
        },
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0.0;
          if (velocity > 180 || _accumulatedDragDown > 35) {
            if (isFullscreen) {
              _toggleFullscreen();
            } else {
              _handleMinimize();
            }
          }
          _accumulatedDragDown = 0.0;
        },
        onVerticalDragCancel: () => _accumulatedDragDown = 0.0,
        child: Container(
          color: colors.bgPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: IconButton(
                  icon: Icon(
                    isFullscreen ? Icons.arrow_back_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: isFullscreen ? 24 : 28,
                  ),
                  tooltip: isFullscreen
                      ? 'Exit Fullscreen'
                      : context.t('player.minimize', null, 'Minimize'),
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  padding: const EdgeInsets.all(8),
                  onPressed: isFullscreen ? _toggleFullscreen : _handleMinimize,
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: colors.accentPrimary,
                      size: 32,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        if (!isRestricted && !isUnavailable)
                          FilledButton.icon(
                            onPressed: () {
                              setState(() {
                                _playerError = null;
                              });
                              _ytController.loadVideoById(videoId: widget.videoId);
                            },
                            icon: const Icon(Icons.refresh_rounded, size: 14),
                            label: Text(context.t('player.retry', null, 'Thử lại')),
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.accentPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              minimumSize: const Size(0, 34),
                              shape: const StadiumBorder(),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        OutlinedButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse('https://www.youtube.com/watch?v=${widget.videoId}'),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 14, color: Colors.white),
                          label: Text(
                            context.t('player.watchOnYouTube', null, 'Xem trên YouTube'),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            minimumSize: const Size(0, 34),
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      if (isFullscreen) {
        return SizedBox.expand(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (details) {
              if (details.delta.dy > 0) {
                _accumulatedDragDown += details.delta.dy;
              }
            },
            onVerticalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0.0;
              if (velocity > 180 || _accumulatedDragDown > 35) {
                _toggleFullscreen();
              }
              _accumulatedDragDown = 0.0;
            },
            onVerticalDragCancel: () => _accumulatedDragDown = 0.0,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: errorWidget,
              ),
            ),
          ),
        );
      }

      return AspectRatio(
        aspectRatio: 16 / 9,
        child: errorWidget,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;

        final playerWidget = AspectRatio(
          aspectRatio: 16 / 9,
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
      final isMiniplayer = PlayerCoordinator.instance.isMiniplayer.value;
      final colors = context.vocaColors;

      return PopScope(
        canPop: isMiniplayer,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_ytController.value.fullScreenOption.enabled || isFullscreen) {
            _toggleFullscreen();
          } else if (!isMiniplayer) {
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
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
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
                                        context.t('player.moreVideos', null, context.t('playlist.forYou', null, 'For You')),
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
