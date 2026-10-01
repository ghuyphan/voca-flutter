// lib/ui/video/video_player_screen.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
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
  YoutubeError? _playerError;

  @override
  void initState() {
    super.initState();
    _playerController = VideoPlayerController(
      apiClient: AppState.instance.apiClient,
      grammarEngine: AppState.instance.grammarEngine,
    );

    _ytController = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
        enableCaption: false,
        origin: 'https://www.youtube.com',
        privacyEnhancedMode: false,
      ),
    );

    // Listen to video position
    _ytController.videoStateStream.listen((state) {
      _playerController.currentTime.value = state.position.inMilliseconds / 1000.0;
    });

    // Listen to player errors (e.g. embed restrictions)
    _ytController.listen((value) {
      if (value.error != YoutubeError.none && value.error != _playerError) {
        setState(() {
          _playerError = value.error;
        });
      }
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
            // YouTube Player
            if (_playerError != null && _playerError != YoutubeError.none)
              Container(
                height: 220,
                color: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline_rounded, color: Color(0xFFF59E0B), size: 36),
                      const SizedBox(height: 8),
                      const Text(
                        'Playback Restricted by Owner',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'YouTube owner disabled third-party embedding for this track. You can open it in YouTube while using Voca for subtitles & vocabulary.',
                        style: TextStyle(color: Colors.white70, fontSize: 11.5),
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
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              YoutubePlayer(
                controller: _ytController,
                aspectRatio: 16 / 9,
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
