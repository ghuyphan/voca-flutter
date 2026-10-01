// lib/ui/video/video_player_screen.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../config/voca_theme.dart';
import '../../state/app_state.dart';
import '../../state/player_state.dart';
import '../../utils/cyrb53_hasher.dart';
import '../widgets/interactive_subtitle_view.dart';
import '../sheets/dictionary_bottom_sheet.dart';
import '../sheets/grammar_bottom_sheet.dart';
import 'player_controls_bar.dart';
import 'transcript_view.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final YoutubePlayerController _ytController;
  late final VideoPlayerController _playerController;
  YoutubeError? _playerError;
  DateTime _lastHistorySave = DateTime.now();

  @override
  void initState() {
    super.initState();
    _playerController = VideoPlayerController(
      apiClient: AppState.instance.apiClient,
      grammarEngine: AppState.instance.grammarEngine,
    );

    // Rule 2: Standard controller initialization without hardcoded key
    _ytController = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        enableCaption: false,
        origin: 'https://www.youtube-nocookie.com',
        privacyEnhancedMode: true,
        userAgent:
            'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
      ),
    );

    _ytController.loadVideoById(videoId: widget.videoId);

    // Listen to video position
    _ytController.videoStateStream.listen((state) {
      final time = state.position.inMilliseconds / 1000.0;
      _playerController.currentTime.value = time;

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

    // Listen to player state & errors
    _ytController.listen((value) {
      if (value.playerState == PlayerState.paused ||
          value.playerState == PlayerState.ended) {
        _saveWatchHistory();
      }

      if (value.playerState == PlayerState.playing) {
        _playerController.isPlaying.value = true;
      } else if (value.playerState == PlayerState.paused ||
          value.playerState == PlayerState.ended) {
        _playerController.isPlaying.value = false;
      }

      if (value.error != YoutubeError.none && value.error != _playerError) {
        setState(() {
          _playerError = value.error;
        });
      }
    });

    // Load subtitles
    _playerController.loadVideo(widget.videoId);
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
      final author = _ytController.metadata.author;
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

  void _handleBookmark() {
    final active = _playerController.activeCue.value;
    if (active == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: VocaTokens.bgCard,
          content: Text(
            'No active sentence to bookmark',
            style: TextStyle(color: VocaTokens.textPrimary),
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: VocaTokens.bgCard,
        content: Row(
          children: [
            const Icon(
              Icons.bookmark_added_rounded,
              color: VocaTokens.accentPrimary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bookmarked: ${active.text}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: VocaTokens.textPrimary),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _saveWatchHistory();
    _ytController.close();
    super.dispose();
  }

  Widget _buildVideoPlayer() {
    if (_playerError != null && _playerError != YoutubeError.none) {
      return Container(
        height: 220,
        color: VocaTokens.bgPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: VocaTokens.warning,
                size: 36,
              ),
              const SizedBox(height: 8),
              const Text(
                'Playback Restricted by Owner',
                style: TextStyle(
                  color: VocaTokens.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'YouTube owner disabled third-party embedding for this track. You can open it in YouTube while using Voca for subtitles & vocabulary.',
                style: TextStyle(
                  color: VocaTokens.textSecondary,
                  fontSize: 11.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse(
                    'https://www.youtube.com/watch?v=${widget.videoId}',
                  ),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new, size: 14),
                label: const Text(
                  'Watch on YouTube',
                  style: TextStyle(fontSize: 12.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VocaTokens.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return YoutubePlayer(
      controller: _ytController,
      aspectRatio: 16 / 9,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildSubtitleArea() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          // Loading / Status indicator
          Watch((context) {
            final isLoading = _playerController.isLoading.value;
            final status = _playerController.statusMessage.value;
            if (isLoading && status != null) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VocaTokens.bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: VocaTokens.borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: VocaTokens.accentPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      status,
                      style: const TextStyle(
                        color: VocaTokens.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Language Mismatch Alert Banner
          Watch((context) {
            final isMismatch = _playerController.languageMismatch.value;
            final available = _playerController.availableLanguages.value;
            if (!isMismatch) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: VocaTokens.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: VocaTokens.accentTertiary.withOpacity(0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: VocaTokens.accentTertiary,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'No captions in selected language',
                        style: TextStyle(
                          color: VocaTokens.accentTertiary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Available native captions: ${available.native.join(", ")}',
                    style: const TextStyle(
                      color: VocaTokens.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (available.native.isNotEmpty)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              AppState.instance
                                  .setLanguage(available.native.first);
                              _playerController.loadVideo(widget.videoId);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: VocaTokens.textPrimary,
                              side: const BorderSide(
                                color: VocaTokens.borderColor,
                              ),
                            ),
                            child: Text(
                              'Switch to ${available.native.first}',
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _playerController.loadVideo(
                              widget.videoId,
                              preferAI: true,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VocaTokens.accentPrimary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('AI Transcribe'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          // Interactive Subtitle Overlay
          Watch((context) {
            final activeCue = _playerController.activeCue.value;
            final grammarMatches =
                _playerController.activeGrammarMatches.value;
            final showFurigana =
                _playerController.showFurigana.value;
            final showTranslation =
                _playerController.showTranslation.value;
            final subtitleSize =
                _playerController.subtitleSize.value;

            if (activeCue == null) {
              return Container(
                constraints: const BoxConstraints(minHeight: 76),
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Listening...',
                  style: TextStyle(
                    color: VocaTokens.textMuted,
                    fontSize: 14,
                  ),
                ),
              );
            }

            return InteractiveSubtitleView(
              cue: activeCue,
              grammarMatches: grammarMatches,
              showFurigana: showFurigana,
              showTranslation: showTranslation,
              subtitleSize: subtitleSize,
              onTokenTap: (token) {
                _ytController.pauseVideo();
                DictionaryBottomSheet.show(
                  context,
                  token: token,
                  sourceLang: AppState.instance.activeLanguage.value,
                  contextSentence: activeCue.text,
                  contextTranslation: activeCue.translation,
                );
              },
              onGrammarTap: (pattern) {
                _ytController.pauseVideo();
                GrammarBottomSheet.show(context, pattern);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTranscriptArea() {
    return TranscriptView(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTabletOrLandscape =
        mediaQuery.size.width >= VocaTokens.tabletBreakpoint ||
            mediaQuery.orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: VocaTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: VocaTokens.bgPrimary,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            color: VocaTokens.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: const IconThemeData(color: VocaTokens.textPrimary),
      ),
      body: SafeArea(
        child: isTabletOrLandscape
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Pane (flex 3): 16:9 Youtube player + sticky subtitle display + PlayerControlsBar
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildVideoPlayer(),
                        PlayerControlsBar(
                          controller: _playerController,
                          ytController: _ytController,
                          onBookmark: _handleBookmark,
                          showTranscriptToggle: false,
                        ),
                        Expanded(
                          child: _buildSubtitleArea(),
                        ),
                      ],
                    ),
                  ),

                  // Right Pane (flex 2): Synchronized TranscriptView panel
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: VocaTokens.bgPrimary,
                        border: Border(
                          left: BorderSide(color: VocaTokens.borderColor),
                        ),
                      ),
                      child: _buildTranscriptArea(),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  // 16:9 Youtube player
                  _buildVideoPlayer(),

                  // Player Controls Bar (with transcript toggle on mobile)
                  PlayerControlsBar(
                    controller: _playerController,
                    ytController: _ytController,
                    onBookmark: _handleBookmark,
                    showTranscriptToggle: true,
                  ),

                  // Main Content Area: Subtitle Overlay view OR Transcript List view
                  Expanded(
                    child: Watch((context) {
                      final isTranscript =
                          _playerController.isTranscriptMode.value;
                      if (isTranscript) {
                        return _buildTranscriptArea();
                      }
                      return _buildSubtitleArea();
                    }),
                  ),
                ],
              ),
      ),
    );
  }
}
