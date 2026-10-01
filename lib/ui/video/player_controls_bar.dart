// lib/ui/video/player_controls_bar.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/voca_models.dart';
import '../../state/player_state.dart';

class PlayerControlsBar extends StatelessWidget {
  final VideoPlayerController controller;
  final YoutubePlayerController ytController;
  final VoidCallback? onBookmark;

  const PlayerControlsBar({
    super.key,
    required this.controller,
    required this.ytController,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final isTranscript = controller.isTranscriptMode.value;
      final isLooping = controller.isLoopingCue.value;
      final rate = controller.playbackRate.value;
      final showFurigana = controller.showFurigana.value;
      final showTranslation = controller.showTranslation.value;
      final subtitleSize = controller.subtitleSize.value;

      String sizeLabel;
      switch (subtitleSize) {
        case SubtitleSize.small:
          sizeLabel = 'S';
          break;
        case SubtitleSize.medium:
          sizeLabel = 'M';
          break;
        case SubtitleSize.large:
          sizeLabel = 'L';
          break;
      }

      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF0B132B),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.08)),
            bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. View Mode Switch (Subtitle Overlay vs Full Transcript List)
              InkWell(
                onTap: controller.toggleTranscriptMode,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isTranscript
                        ? const Color(0xFF6366F1).withOpacity(0.25)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isTranscript
                          ? const Color(0xFF818CF8)
                          : Colors.white12,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isTranscript
                            ? Icons.format_list_bulleted_rounded
                            : Icons.subtitles_rounded,
                        size: 16,
                        color: isTranscript
                            ? const Color(0xFF818CF8)
                            : Colors.white70,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isTranscript ? 'Transcript' : 'Subtitles',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isTranscript
                              ? const Color(0xFF818CF8)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),
              _buildDivider(),
              const SizedBox(width: 8),

              // 2. Previous Cue Button (<)
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded, size: 22),
                color: Colors.white,
                tooltip: 'Previous sentence',
                onPressed: () {
                  controller.seekToPreviousCue(
                    onSeek: (s) => ytController.seekTo(
                      seconds: s,
                      allowSeekAhead: true,
                    ),
                  );
                },
              ),

              // 3. Loop Current Cue Button
              IconButton(
                icon: Icon(
                  isLooping
                      ? Icons.repeat_one_rounded
                      : Icons.repeat_rounded,
                  size: 22,
                ),
                color: isLooping ? const Color(0xFFF59E0B) : Colors.white60,
                tooltip: isLooping
                    ? 'Looping active sentence (tap to stop)'
                    : 'Loop active sentence',
                style: isLooping
                    ? IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B).withOpacity(0.2),
                      )
                    : null,
                onPressed: controller.toggleLoopCurrentCue,
              ),

              // 4. Next Cue Button (>)
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, size: 22),
                color: Colors.white,
                tooltip: 'Next sentence',
                onPressed: () {
                  controller.seekToNextCue(
                    onSeek: (s) => ytController.seekTo(
                      seconds: s,
                      allowSeekAhead: true,
                    ),
                  );
                },
              ),

              const SizedBox(width: 6),
              _buildDivider(),
              const SizedBox(width: 8),

              // 5. Playback Speed Button Popup (0.75x, 1.0x, 1.25x, 1.5x)
              PopupMenuButton<double>(
                initialValue: rate,
                tooltip: 'Playback Speed',
                onSelected: (newRate) {
                  controller.playbackRate.value = newRate;
                  ytController.setPlaybackRate(newRate);
                },
                color: const Color(0xFF1E293B),
                itemBuilder: (context) => [
                  _buildSpeedMenuItem(0.75, '0.75x', rate),
                  _buildSpeedMenuItem(1.0, '1.0x (Normal)', rate),
                  _buildSpeedMenuItem(1.25, '1.25x', rate),
                  _buildSpeedMenuItem(1.5, '1.5x', rate),
                ],
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${rate}x',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 6. Toggle Furigana / Ruby Display
              InkWell(
                onTap: controller.toggleFurigana,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: showFurigana
                        ? const Color(0xFF38BDF8).withOpacity(0.18)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: showFurigana
                          ? const Color(0xFF38BDF8).withOpacity(0.5)
                          : Colors.white10,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '振',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: showFurigana
                              ? const Color(0xFF38BDF8)
                              : Colors.white38,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        showFurigana ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: showFurigana
                              ? const Color(0xFF38BDF8)
                              : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 7. Toggle Translation Display
              InkWell(
                onTap: controller.toggleTranslation,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: showTranslation
                        ? const Color(0xFF10B981).withOpacity(0.18)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: showTranslation
                          ? const Color(0xFF10B981).withOpacity(0.5)
                          : Colors.white10,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.translate_rounded,
                        size: 14,
                        color: showTranslation
                            ? const Color(0xFF10B981)
                            : Colors.white38,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        showTranslation ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: showTranslation
                              ? const Color(0xFF10B981)
                              : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 8. Font Size Scaler
              InkWell(
                onTap: controller.cycleSubtitleSize,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.format_size_rounded,
                        size: 15,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        sizeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // 9. Bookmark Button
              IconButton(
                icon: const Icon(Icons.bookmark_border_rounded, size: 20),
                color: Colors.white70,
                tooltip: 'Bookmark current sentence',
                onPressed: onBookmark,
              ),
            ],
          ),
        ),
      );
    });
  }

  PopupMenuItem<double> _buildSpeedMenuItem(
    double speed,
    String label,
    double currentRate,
  ) {
    final isSelected = (currentRate == speed);
    return PopupMenuItem<double>(
      value: speed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF38BDF8) : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_rounded,
              color: Color(0xFF38BDF8),
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 22,
      color: Colors.white12,
    );
  }
}
