// lib/ui/video/video_player_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import '../../state/player_coordinator.dart';
import '../../state/player_state.dart';
import '../../utils/cyrb53_hasher.dart';
import '../sheets/dictionary_bottom_sheet.dart';
import '../sheets/grammar_bottom_sheet.dart';
import '../sheets/video_settings_sheet.dart';
import '../widgets/interactive_subtitle_view.dart';
import 'center_controls.dart';
import 'subtitle_controls_bar.dart';
import 'transcript_view.dart';
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
      // Left 35%: Rewind 10s zone
      _pendingSingleTapTimer?.cancel();
      _pendingSingleTapTimer = null;

      if (_lastLeftTapTime != null && now.difference(_lastLeftTapTime!).inMilliseconds < 250) {
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
      // Right 35%: Forward 10s zone
      _pendingSingleTapTimer?.cancel();
      _pendingSingleTapTimer = null;

      if (_lastRightTapTime != null && now.difference(_lastRightTapTime!).inMilliseconds < 250) {
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
        _leftSeekFeedback = true;
        _rightSeekFeedback = false;
      } else {
        _rightSeekFeedback = true;
        _leftSeekFeedback = false;
      }
    });
    _seekFeedbackTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() {
          _leftSeekFeedback = false;
          _rightSeekFeedback = false;
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



  @override
  void dispose() {
    _controlsAutoHideTimer?.cancel();
    _seekFeedbackTimer?.cancel();
    _pendingSingleTapTimer?.cancel();
    _saveWatchHistory();
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fast_rewind_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 4),
                          Text(
                            '10s',
                            style: TextStyle(
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '10s',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.fast_forward_rounded, color: Colors.white, size: 20),
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

                              // Bottom Controls Row (Time, CC toggle, Dual Sub toggle, Settings, Miniplayer)
                              VideoBottomBar(
                                isPlaying: isPlaying,
                                isEnded: _isEnded,
                                currentTime: curTime,
                                duration: totalDuration,
                                showPlayPause: false, // NO duplicate play/pause with CenterControls!
                                subtitlesVisible: subsVisible,
                                showDualSubtitles: showDual,
                                isCJKLanguage: ['ja', 'zh', 'ko'].contains(AppState.instance.activeLanguage.value),
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

  Widget _buildSubtitleView() {
    return Watch((context) {
      final activeCue = _playerController.activeCue.value;
      final grammarMatches = _playerController.activeGrammarMatches.value;
      final showFurigana = _playerController.showFurigana.value;
      final showTranslation = _playerController.showTranslation.value;
      final subtitleSize = _playerController.subtitleSize.value;

      return InteractiveSubtitleView(
        cue: activeCue,
        grammarMatches: grammarMatches,
        showFurigana: showFurigana,
        showTranslation: showTranslation,
        subtitleSize: subtitleSize,
        isLooping: _playerController.isLoopingCue.value,
        hasSubtitles: _playerController.cues.value.isNotEmpty,
        isLoading: _playerController.isLoading.value,
        isAIGenerating: _playerController.isAIGenerated.value && _playerController.cues.value.isEmpty,
        onTokenTap: (token) {
          _ytController.pauseVideo();
          DictionaryBottomSheet.show(
            context,
            token: token,
            sourceLang: AppState.instance.activeLanguage.value,
            contextSentence: activeCue?.text,
            contextTranslation: activeCue?.translation,
          );
        },
        onGrammarTap: (pattern) {
          _ytController.pauseVideo();
          GrammarBottomSheet.show(context, pattern);
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTabletOrLandscape =
        mediaQuery.size.width >= VocaTokens.tabletBreakpoint ||
            mediaQuery.orientation == Orientation.landscape;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleMinimize();
      },
      child: Scaffold(
        backgroundColor: context.vocaColors.bgPrimary,
        body: SafeArea(
          child: isTabletOrLandscape
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Pane (flex 3): 16:9 Youtube player + VideoHeader + sticky subtitle view + subtitle controls bar
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
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildSubtitleView(),
                            ),
                          ),
                          SubtitleControlsBar(
                            controller: _playerController,
                            ytController: _ytController,
                          ),
                        ],
                      ),
                    ),

                    // Right Pane (flex 2): Synchronized TranscriptView
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.vocaColors.bgPrimary,
                          border: Border(
                            left: BorderSide(color: context.vocaColors.borderColor),
                          ),
                        ),
                        child: TranscriptView(
                          controller: _playerController,
                          onSeek: (seconds) => _ytController.seekTo(
                            seconds: seconds,
                            allowSeekAhead: true,
                          ),
                          onTokenTap: (token) {
                            _ytController.pauseVideo();
                            final active = _playerController.activeCue.value;
                            DictionaryBottomSheet.show(
                              context,
                              token: token,
                              sourceLang: AppState.instance.activeLanguage.value,
                              contextSentence: active?.text,
                              contextTranslation: active?.translation,
                            );
                          },
                          onGrammarTap: (pattern) {
                            _ytController.pauseVideo();
                            GrammarBottomSheet.show(context, pattern);
                          },
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    // 1. 16:9 Youtube Player with Gesture Detector, Center Controls & Bottom Bar
                    _buildVideoPlayerArea(),

                    // 2. VideoHeader (Title, channel, level badge, tracks, share, close)
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

                    // 3. Active Subtitle Cue Card (Comfortable fixed height matching lingua-tube)
                    _buildSubtitleView(),

                    // 4. Synchronized Subtitle Cue List (flex scroll area)
                    Expanded(
                      child: TranscriptView(
                        controller: _playerController,
                        onSeek: (seconds) => _ytController.seekTo(
                          seconds: seconds,
                          allowSeekAhead: true,
                        ),
                        onTokenTap: (token) {
                          _ytController.pauseVideo();
                          final active = _playerController.activeCue.value;
                          DictionaryBottomSheet.show(
                            context,
                            token: token,
                            sourceLang: AppState.instance.activeLanguage.value,
                            contextSentence: active?.text,
                            contextTranslation: active?.translation,
                          );
                        },
                        onGrammarTap: (pattern) {
                          _ytController.pauseVideo();
                          GrammarBottomSheet.show(context, pattern);
                        },
                      ),
                    ),

                    // 5. Authentic Subtitle Controls Toolbar ([Loop 1/3], [Added (count)], [Quiz], [Options])
                    SubtitleControlsBar(
                      controller: _playerController,
                      ytController: _ytController,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
