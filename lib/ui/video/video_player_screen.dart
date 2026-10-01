// lib/ui/video/video_player_screen.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../state/app_state.dart';
import '../../state/player_state.dart';
import '../widgets/interactive_subtitle_view.dart';
import '../sheets/dictionary_bottom_sheet.dart';
import '../sheets/grammar_bottom_sheet.dart';

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

  @override
  void initState() {
    super.initState();
    _playerController = VideoPlayerController(
      apiClient: AppState.instance.apiClient,
      grammarEngine: AppState.instance.grammarEngine,
    );

    _ytController = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );

    _ytController.loadVideoById(videoId: widget.videoId);

    // Listen to video position
    _ytController.videoStateStream.listen((state) {
      _playerController.currentTime.value = state.position.inMilliseconds / 1000.0;
    });

    // Load subtitles
    _playerController.loadVideo(widget.videoId);
  }

  @override
  void dispose() {
    _ytController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16, color: Colors.white),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // YouTube IFrame Player
            AspectRatio(
              aspectRatio: 16 / 9,
              child: YoutubePlayer(
                controller: _ytController,
                aspectRatio: 16 / 9,
              ),
            ),

            // Scrollable subtitle & status area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Loading / Status indicator
                    Watch((context) {
                      final isLoading = _playerController.isLoading.value;
                      final status = _playerController.statusMessage.value;
                      if (isLoading && status != null) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF38BDF8)),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                status,
                                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.amber.withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.amberAccent, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'No captions in selected language',
                                  style: TextStyle(
                                    color: Colors.amberAccent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Available native captions: ${available.native.join(", ")}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (available.native.isNotEmpty)
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        AppState.instance.setLanguage(available.native.first);
                                        _playerController.loadVideo(widget.videoId);
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: Colors.white30),
                                      ),
                                      child: Text('Switch to ${available.native.first}'),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _playerController.loadVideo(widget.videoId, preferAI: true);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6366F1),
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
                      final grammarMatches = _playerController.activeGrammarMatches.value;

                      if (activeCue == null) {
                        return Container(
                          constraints: const BoxConstraints(minHeight: 76),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          alignment: Alignment.center,
                          child: const Text(
                            'Listening...',
                            style: TextStyle(color: Colors.white24, fontSize: 14),
                          ),
                        );
                      }

                      return InteractiveSubtitleView(
                        cue: activeCue,
                        grammarMatches: grammarMatches,
                        onTokenTap: (token) {
                          _ytController.pauseVideo();
                          DictionaryBottomSheet.show(
                            context,
                            token: token,
                            sourceLang: AppState.instance.activeLanguage.value,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
