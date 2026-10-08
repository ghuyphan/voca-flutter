// lib/state/player_coordinator.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/voca_models.dart';
import '../utils/cyrb53_hasher.dart';
import 'app_state.dart';
import 'player_state.dart';

/// Global Player Coordinator for managing persistent video playback,
/// seamless docked Miniplayer transitions, playlist queues, and full-screen immersion.
class PlayerCoordinator {
  static final PlayerCoordinator instance = PlayerCoordinator._();
  PlayerCoordinator._();

  // Active video session metadata signals
  final activeVideoId = signal<String?>(null);
  final activeTitle = signal<String>('');
  final activeChannel = signal<String?>('YouTube');
  final activeLevel = signal<String?>(null);
  final activeThumbnail = signal<String?>(null);

  // Playlist state signals
  final playlistVideos = signal<List<PlaylistVideo>>([]);
  final activePlaylistTitle = signal<String?>(null);
  final activePlaylistIndex = signal<int?>(null);
  final isLooping = signal<bool>(false);
  final isShuffled = signal<bool>(false);
  List<PlaylistVideo> _unshuffledVideos = [];

  // Playback & Miniplayer state signals
  final isMiniplayer = signal<bool>(false);
  final isPlaying = signal<bool>(false);
  final isEnded = signal<bool>(false);
  final currentTime = signal<double>(0.0);
  final duration = signal<double>(0.0);
  final bufferedFraction = signal<double>(0.0);

  // Completion & History tracking
  bool _hasAwardedVideoCompletion = false;

  // Controllers held across miniplayer & expanded screen
  VideoPlayerController? playerController;
  YoutubePlayerController? ytController;
  @visibleForTesting
  YoutubePlayerController? testYtController;
  StreamSubscription? _videoStateSubscription;
  StreamSubscription<YoutubePlayerValue>? _playerStateSubscription;
  void Function()? _cuesDisposer;
  Timer? _autoAdvanceTimer;

  bool get hasActiveVideo =>
      activeVideoId.value != null && activeVideoId.value!.isNotEmpty;

  bool get hasPlaylist => playlistVideos.value.isNotEmpty;

  int get playlistTotal => playlistVideos.value.length;

  bool get canPlayPrev {
    if (!hasPlaylist) return false;
    final idx = activePlaylistIndex.value ?? 0;
    return isLooping.value || idx > 0;
  }

  bool get canPlayNext {
    if (!hasPlaylist) return false;
    final idx = activePlaylistIndex.value ?? 0;
    return isLooping.value || idx < playlistVideos.value.length - 1;
  }

  /// Platform-appropriate User-Agent for the embedded YouTube iframe.
  static String get defaultPlayerUserAgent {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1';
    }
    return 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Mobile Safari/537.36';
  }

  /// Open and play a video.
  /// If the requested video is already the active video and is in miniplayer mode,
  /// this seamlessly expands the player back to full screen.
  void openVideo(
    BuildContext? context, {
    required String videoId,
    required String title,
    String? channel,
    String? level,
    String? thumbnail,
    String? playlistTitle,
    int? playlistIndex,
    int? playlistTotal,
    List<PlaylistVideo>? playlist,
    double? startSeconds,
  }) {
    _autoAdvanceTimer?.cancel();
    _hasAwardedVideoCompletion = false;

    if (playlist != null && playlist.isNotEmpty) {
      playlistVideos.value = List.from(playlist);
      _unshuffledVideos = List.from(playlist);
      activePlaylistTitle.value = playlistTitle ?? 'Playlist';
      activePlaylistIndex.value = playlistIndex ?? 0;
    } else if (playlistIndex != null) {
      activePlaylistIndex.value = playlistIndex;
    } else {
      // Opening standalone video -> cleanly clear previous playlist state
      playlistVideos.value = [];
      _unshuffledVideos = [];
      activePlaylistTitle.value = null;
      activePlaylistIndex.value = null;
    }

    if (activeVideoId.value == videoId && ytController != null) {
      if (startSeconds != null && startSeconds > 0) {
        ytController?.seekTo(seconds: startSeconds, allowSeekAhead: true);
        playerController?.updatePlaybackTime(startSeconds);
      }
      // Same video already active: just expand to full screen
      expand(context);
      return;
    }

    // Save history of currently playing video before switching
    _saveCurrentHistory();

    // Clean up previous controllers first
    _disposeControllers();

    // Initialize VideoPlayerController
    final newPlayerController = VideoPlayerController(
      apiClient: AppState.instance.apiClient,
      grammarEngine: AppState.instance.grammarEngine,
    );
    playerController = newPlayerController;

    // Initialize YoutubePlayerController without hardcoded key (Rule 2 & User requirements:
    // completely hide native controls, annotations, fullscreen buttons, and disable web pointer events)
    final newYtController = testYtController ??
        YoutubePlayerController(
          params: YoutubePlayerParams(
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
            userAgent: defaultPlayerUserAgent,
          ),
        );
    ytController = newYtController;

    // Set new active session metadata AFTER controllers are created
    // so any Watch / Signal reaction has valid controllers immediately
    activeTitle.value = title;
    activeChannel.value = channel ?? 'YouTube';
    activeLevel.value = level;
    activeThumbnail.value = thumbnail ?? 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
    if (playlistTitle != null) {
      activePlaylistTitle.value = playlistTitle;
    }
    isMiniplayer.value = false;
    currentTime.value = startSeconds ?? 0.0;
    duration.value = 0.0;
    activeVideoId.value = videoId;

    // Load video immediately
    if (startSeconds != null && startSeconds > 0) {
      newYtController.loadVideoById(videoId: videoId, startSeconds: startSeconds);
    } else {
      newYtController.loadVideoById(videoId: videoId);
    }
    newPlayerController.loadVideo(videoId);

    if (startSeconds != null && startSeconds > 0) {
      newPlayerController.updatePlaybackTime(startSeconds);
    } else {
      // Asynchronously seek to previous watch progress if available
      _resumeFromHistoryIfAvailable(videoId, newYtController, newPlayerController);
    }

    // Sync duration from cues if available before or alongside video metadata
    _cuesDisposer = newPlayerController.cues.subscribe((cList) {
      if (cList.isNotEmpty && duration.value <= 0) {
        final lastCue = cList.last;
        final estimatedDur = lastCue.start + lastCue.duration;
        if (estimatedDur > 0) {
          duration.value = estimatedDur;
        }
      }
    });

    // Listen to video state stream
    _videoStateSubscription = newYtController.videoStateStream.listen((state) {
      final time = state.position.inMilliseconds / 1000.0;
      currentTime.value = time;
      bufferedFraction.value = state.loadedFraction;

      final metaDur = newYtController.metadata.duration.inSeconds.toDouble();
      if (metaDur > 0) {
        duration.value = metaDur;
      } else if (duration.value <= 0 && newPlayerController.cues.value.isNotEmpty) {
        final lastCue = newPlayerController.cues.value.last;
        final estimatedDur = lastCue.start + lastCue.duration;
        if (estimatedDur > 0) {
          duration.value = estimatedDur;
        }
      }

      newPlayerController.currentTime.value = time;
      newPlayerController.updatePlaybackTime(time);

      // Check for >= 80% video completion to award XP and track gamification
      final effectiveDur = duration.value > 0 ? duration.value : metaDur;
      if (!_hasAwardedVideoCompletion && effectiveDur > 0 && (time / effectiveDur) >= 0.80) {
        _hasAwardedVideoCompletion = true;
        AppState.instance.gamificationService.recordVideoCompleted();
      }
    });

    // Listen to player state
    _playerStateSubscription = newYtController.listen((value) {
      if (value.playerState == PlayerState.playing) {
        isPlaying.value = true;
        isEnded.value = false;
        newPlayerController.isPlaying.value = true;
        disableNativeCaptions(newYtController);
        if (activeTitle.value.isEmpty || activeTitle.value == 'YouTube Video') {
          final metaTitle = newYtController.metadata.title;
          if (metaTitle.isNotEmpty) activeTitle.value = metaTitle;
        }
        if (activeChannel.value == null || activeChannel.value == 'YouTube') {
          final metaAuthor = newYtController.metadata.author;
          if (metaAuthor.isNotEmpty) activeChannel.value = metaAuthor;
        }
      } else if (value.playerState == PlayerState.paused) {
        isPlaying.value = false;
        newPlayerController.isPlaying.value = false;
        _saveCurrentHistory();
      } else if (value.playerState == PlayerState.ended) {
        isPlaying.value = false;
        isEnded.value = true;
        newPlayerController.isPlaying.value = false;
        newPlayerController.handleVideoEnded();

        if (!_hasAwardedVideoCompletion) {
          _hasAwardedVideoCompletion = true;
          AppState.instance.gamificationService.recordVideoCompleted();
        }
        _saveCurrentHistory();

        // Auto-advance to next video if part of a playlist
        _handleAutoAdvance();
      }
    });

  }

  void _resumeFromHistoryIfAvailable(
    String vId,
    YoutubePlayerController targetYt,
    VideoPlayerController targetPlayer,
  ) async {
    try {
      // 1. Fast local cache lookup first
      final localResume = await AppState.instance.supabaseService.getVideoResumeSeconds(vId);
      if (activeVideoId.value != vId) return; // Video changed in meantime
      if (localResume != null && localResume > 3) {
        targetYt.seekTo(seconds: localResume, allowSeekAhead: true);
        currentTime.value = localResume;
        targetPlayer.currentTime.value = localResume;
        return;
      }

      // 2. Fallback to Supabase remote history
      final historyList = await AppState.instance.supabaseService.getHistory(limit: 20);
      if (activeVideoId.value != vId) return; // Video changed in meantime
      final match = historyList.firstWhere(
        (item) => item['video_id'] == vId,
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty) {
        final rawProg = (match['progress'] as num?)?.toDouble() ?? 0.0;
        final progress = rawProg <= 1.0 && rawProg > 0.0 ? rawProg * 100.0 : rawProg;
        final dur = (match['duration'] as num?)?.toInt() ?? 0;
        if (progress > 0 && progress < 95 && dur > 0) {
          final calculated = (dur * progress / 100).round();
          if (calculated > 3) {
            targetYt.seekTo(seconds: calculated.toDouble(), allowSeekAhead: true);
            currentTime.value = calculated.toDouble();
            targetPlayer.currentTime.value = calculated.toDouble();
          }
        }
      }
    } catch (_) {}
  }

  void _handleAutoAdvance() {
    if (!hasPlaylist || !canPlayNext) return;
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(const Duration(milliseconds: 1200), () {
      playNext();
    });
  }

  /// Play next video in playlist
  void playNext([BuildContext? context]) {
    if (!hasPlaylist) return;
    final videos = playlistVideos.value;
    var nextIdx = (activePlaylistIndex.value ?? 0) + 1;
    if (nextIdx >= videos.length) {
      if (isLooping.value) {
        nextIdx = 0;
      } else {
        return;
      }
    }
    final nextVideo = videos[nextIdx];
    activePlaylistIndex.value = nextIdx;
    openVideo(
      context,
      videoId: nextVideo.videoId,
      title: nextVideo.title,
      channel: nextVideo.channel,
      level: nextVideo.level,
      playlistIndex: nextIdx,
    );
  }

  /// Play previous video in playlist
  void playPrevious([BuildContext? context]) {
    if (!hasPlaylist) return;
    final videos = playlistVideos.value;
    var prevIdx = (activePlaylistIndex.value ?? 0) - 1;
    if (prevIdx < 0) {
      if (isLooping.value) {
        prevIdx = videos.length - 1;
      } else {
        return;
      }
    }
    final prevVideo = videos[prevIdx];
    activePlaylistIndex.value = prevIdx;
    openVideo(
      context,
      videoId: prevVideo.videoId,
      title: prevVideo.title,
      channel: prevVideo.channel,
      level: prevVideo.level,
      playlistIndex: prevIdx,
    );
  }

  /// Jump directly to a specific video in the playlist
  void jumpToPlaylistIndex(int index, [BuildContext? context]) {
    final videos = playlistVideos.value;
    if (index < 0 || index >= videos.length) return;
    final video = videos[index];
    activePlaylistIndex.value = index;
    openVideo(
      context,
      videoId: video.videoId,
      title: video.title,
      channel: video.channel,
      level: video.level,
      playlistIndex: index,
    );
  }

  /// Toggle loop on playlist
  void toggleLoop() {
    isLooping.value = !isLooping.value;
  }

  /// Toggle shuffle on playlist
  void toggleShuffle() {
    isShuffled.value = !isShuffled.value;
    if (isShuffled.value) {
      final currentVId = activeVideoId.value;
      final shuffled = List<PlaylistVideo>.from(playlistVideos.value)..shuffle();
      // Keep current video at current index if possible
      if (currentVId != null) {
        final currentVid =
            shuffled.firstWhere((v) => v.videoId == currentVId, orElse: () => shuffled.first);
        shuffled.remove(currentVid);
        shuffled.insert(0, currentVid);
        activePlaylistIndex.value = 0;
      }
      playlistVideos.value = shuffled;
    } else {
      playlistVideos.value = List.from(_unshuffledVideos);
      final currentVId = activeVideoId.value;
      if (currentVId != null) {
        final idx =
            _unshuffledVideos.indexWhere((v) => v.videoId == currentVId);
        if (idx != -1) activePlaylistIndex.value = idx;
      }
    }
  }

  /// Minimize the full video screen into the persistent docked miniplayer bar.
  void minimize([BuildContext? context]) {
    if (!hasActiveVideo) return;
    isMiniplayer.value = true;
    playerController?.setMiniplayer(true);
  }

  /// Expand the docked miniplayer bar back into the full VideoPlayerScreen.
  void expand([BuildContext? context]) {
    if (!hasActiveVideo) return;
    isMiniplayer.value = false;
    playerController?.setMiniplayer(false);
  }

  /// Toggle play / pause directly from the miniplayer or global shortcut.
  void togglePlayPause() {
    if (ytController == null) return;
    if (isPlaying.value) {
      isPlaying.value = false;
      playerController?.isPlaying.value = false;
      ytController!.pauseVideo();
    } else {
      isPlaying.value = true;
      playerController?.isPlaying.value = true;
      if (isEnded.value) {
        ytController!.seekTo(seconds: 0.0, allowSeekAhead: true);
        isEnded.value = false;
      }
      ytController!.playVideo();
    }
  }

  /// Stop playback, clear the active video, and dismiss the miniplayer.
  void close() {
    _autoAdvanceTimer?.cancel();
    _saveCurrentHistory();
    _disposeControllers();
    activeVideoId.value = null;
    activeTitle.value = '';
    activeChannel.value = null;
    activeLevel.value = null;
    activeThumbnail.value = null;
    playlistVideos.value = [];
    _unshuffledVideos = [];
    activePlaylistTitle.value = null;
    activePlaylistIndex.value = null;
    isMiniplayer.value = false;
    isPlaying.value = false;
    isEnded.value = false;
    currentTime.value = 0.0;
    duration.value = 0.0;
  }

  /// Saves current video progress to watch history (local & Supabase)
  Future<void> saveWatchHistory() async {
    final vId = activeVideoId.value;
    if (vId == null || vId.isEmpty) return;
    try {
      final user = AppState.instance.supabaseService.currentUser;
      final userId = user?.id ?? 'guest';
      final id = generateDeterministicRecordId([userId, vId]);
      final dur = duration.value.round();
      final cur = currentTime.value;
      final progress = dur > 0 ? ((cur / dur) * 100).clamp(0.0, 100.0) : 0.0;
      await AppState.instance.supabaseService.saveHistory(
        id: id,
        videoId: vId,
        title: activeTitle.value.isNotEmpty ? activeTitle.value : 'YouTube Video',
        thumbnail: 'https://img.youtube.com/vi/$vId/hqdefault.jpg',
        channel: activeChannel.value ?? 'YouTube',
        duration: dur,
        language: AppState.instance.activeLanguage.value,
        progress: progress,
      );
    } catch (e) {
      debugPrint('[PlayerCoordinator] Error saving watch history: $e');
    }
  }

  Future<void> _saveCurrentHistory() => saveWatchHistory();
  Future<void> saveCurrentHistory() => saveWatchHistory();

  /// Alias for close() for backward compatibility
  void closeVideo() => close();

  void _disposeControllers() {
    _autoAdvanceTimer?.cancel();
    _videoStateSubscription?.cancel();
    _videoStateSubscription = null;
    _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    _cuesDisposer?.call();
    _cuesDisposer = null;
    try {
      ytController?.close();
    } catch (_) {}
    ytController = null;
    try {
      playerController?.dispose();
    } catch (_) {}
    playerController = null;
  }

  /// Disables native YouTube iframe closed captions so they never clash with
  /// Voca's custom interactive furigana/pinyin subtitles.
  static void disableNativeCaptions(YoutubePlayerController? controller) {
    if (controller == null) return;
    try {
      controller.webViewController.runJavaScript('''
        (function() {
          try {
            if (window.player && typeof window.player.setOption === 'function') {
              window.player.setOption('captions', 'track', {});
              window.player.setOption('captions', 'fontSize', 0);
            }
          } catch(e) {}
          try {
            if (window.player && typeof window.player.unloadModule === 'function') {
              window.player.unloadModule('captions');
              window.player.unloadModule('cc');
            }
          } catch(e) {}
          try {
            var style = document.getElementById('voca-hide-cc');
            if (!style) {
              style = document.createElement('style');
              style.id = 'voca-hide-cc';
              style.textContent = '.ytp-caption-window-bottom, .ytp-caption-segment, .caption-window { display: none !important; opacity: 0 !important; visibility: hidden !important; }';
              document.head.appendChild(style);
            }
          } catch(e) {}
        })();
      ''');
    } catch (_) {}
  }
}
