// lib/state/player_coordinator.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'app_state.dart';
import 'player_state.dart';

/// Global Player Coordinator for managing persistent video playback,
/// seamless docked Miniplayer transitions, and full-screen immersion.
class PlayerCoordinator {
  static final PlayerCoordinator instance = PlayerCoordinator._();
  PlayerCoordinator._();

  // Active video session metadata signals
  final activeVideoId = signal<String?>(null);
  final activeTitle = signal<String>('');
  final activeChannel = signal<String?>('YouTube');
  final activeLevel = signal<String?>(null);
  final activePlaylistTitle = signal<String?>(null);
  final activePlaylistIndex = signal<int?>(null);
  final activePlaylistTotal = signal<int?>(null);

  // Playback & Miniplayer state signals
  final isMiniplayer = signal<bool>(false);
  final isPlaying = signal<bool>(false);
  final isEnded = signal<bool>(false);
  final currentTime = signal<double>(0.0);
  final duration = signal<double>(0.0);
  final bufferedFraction = signal<double>(0.0);

  // Controllers held across miniplayer & expanded screen
  VideoPlayerController? playerController;
  YoutubePlayerController? ytController;
  StreamSubscription? _videoStateSubscription;

  bool get hasActiveVideo => activeVideoId.value != null && activeVideoId.value!.isNotEmpty;

  /// Open and play a video.
  /// If the requested video is already the active video and is in miniplayer mode,
  /// this seamlessly expands the player back to full screen.
  Future<void> openVideo(
    BuildContext? context, {
    required String videoId,
    required String title,
    String? channel,
    String? level,
    String? playlistTitle,
    int? playlistIndex,
    int? playlistTotal,
  }) async {
    if (activeVideoId.value == videoId && ytController != null) {
      // Same video already active: just expand to full screen
      expand(context);
      return;
    }

    // Set new active session metadata
    activeVideoId.value = videoId;
    activeTitle.value = title;
    activeChannel.value = channel ?? 'YouTube';
    activeLevel.value = level;
    activePlaylistTitle.value = playlistTitle;
    activePlaylistIndex.value = playlistIndex;
    activePlaylistTotal.value = playlistTotal;
    isMiniplayer.value = false;
    currentTime.value = 0.0;
    duration.value = 0.0;

    // Clean up previous controllers
    _disposeControllers();

    // Initialize VideoPlayerController
    final newPlayerController = VideoPlayerController(
      apiClient: AppState.instance.apiClient,
      grammarEngine: AppState.instance.grammarEngine,
    );
    playerController = newPlayerController;

    // Initialize YoutubePlayerController without hardcoded key (Rule 2 invariant)
    final newYtController = YoutubePlayerController(
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
    ytController = newYtController;

    // Listen to video state stream
    _videoStateSubscription = newYtController.videoStateStream.listen((state) {
      final time = state.position.inMilliseconds / 1000.0;
      currentTime.value = time;
      bufferedFraction.value = state.loadedFraction;

      final metaDur = newYtController.metadata.duration.inSeconds.toDouble();
      if (metaDur > 0) {
        duration.value = metaDur;
      }

      newPlayerController.currentTime.value = time;
      newPlayerController.updatePlaybackTime(time);
    });

    // Listen to player state
    newYtController.listen((value) {
      if (value.playerState == PlayerState.playing) {
        isPlaying.value = true;
        isEnded.value = false;
        newPlayerController.isPlaying.value = true;
      } else if (value.playerState == PlayerState.paused) {
        isPlaying.value = false;
        newPlayerController.isPlaying.value = false;
      } else if (value.playerState == PlayerState.ended) {
        isPlaying.value = false;
        isEnded.value = true;
        newPlayerController.isPlaying.value = false;
        newPlayerController.handleVideoEnded();
      }
    });

    // Load video and captions
    newYtController.loadVideoById(videoId: videoId);
    newPlayerController.loadVideo(videoId);
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
      ytController!.pauseVideo();
    } else {
      ytController!.playVideo();
    }
  }

  /// Stop playback, clear the active video, and dismiss the miniplayer.
  void close() {
    _disposeControllers();
    activeVideoId.value = null;
    activeTitle.value = '';
    activeChannel.value = null;
    activeLevel.value = null;
    activePlaylistTitle.value = null;
    activePlaylistIndex.value = null;
    activePlaylistTotal.value = null;
    isMiniplayer.value = false;
    isPlaying.value = false;
    isEnded.value = false;
    currentTime.value = 0.0;
    duration.value = 0.0;
  }

  /// Alias for close() for backward compatibility
  void closeVideo() => close();

  void _disposeControllers() {
    _videoStateSubscription?.cancel();
    _videoStateSubscription = null;
    try {
      ytController?.close();
    } catch (_) {}
    ytController = null;
    playerController = null;
  }
}
