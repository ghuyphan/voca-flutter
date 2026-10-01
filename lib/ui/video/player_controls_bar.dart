// lib/ui/video/player_controls_bar.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../state/player_state.dart';

class PlayerControlsBar extends StatelessWidget {
  final VideoPlayerController controller;
  final YoutubePlayerController ytController;
  final VoidCallback? onBookmark;
  final bool showTranscriptToggle;

  const PlayerControlsBar({
    super.key,
    required this.controller,
    required this.ytController,
    this.onBookmark,
    this.showTranscriptToggle = true,
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
        decoration: const BoxDecoration(
          color: VocaTokens.bgPrimary,
          border: Border(
            top: BorderSide(color: VocaTokens.borderColor),
            bottom: BorderSide(color: VocaTokens.borderColor),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Mobile/Stacked View Mode Switch: Subtitle Overlay vs Full Transcript List
              if (showTranscriptToggle) ...[
                InkWell(
                  onTap: controller.toggleTranscriptMode,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isTranscript
                          ? VocaTokens.accentPrimarySoft
                          : VocaTokens.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isTranscript
                            ? VocaTokens.accentPrimary
                            : VocaTokens.borderColor,
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
                              ? VocaTokens.accentPrimary
                              : VocaTokens.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isTranscript ? 'Transcript' : 'Subtitles',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isTranscript
                                ? VocaTokens.accentPrimary
                                : VocaTokens.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _buildDivider(),
                const SizedBox(width: 6),
              ],

              // 2. Previous Cue Button (<)
              _buildIconButton(
                icon: Icons.skip_previous_rounded,
                tooltip: 'Previous sentence',
                onTap: () {
                  controller.seekToPreviousCue(
                    onSeek: (s) => ytController.seekTo(
                      seconds: s,
                      allowSeekAhead: true,
                    ),
                  );
                },
              ),

              const SizedBox(width: 6),

              // 3. Loop Current Cue Button
              InkWell(
                onTap: controller.toggleLoopCurrentCue,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isLooping
                        ? VocaTokens.accentPrimarySoft
                        : VocaTokens.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isLooping
                          ? VocaTokens.accentPrimary
                          : VocaTokens.borderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLooping
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        size: 18,
                        color: isLooping
                            ? VocaTokens.accentPrimary
                            : VocaTokens.textMuted,
                      ),
                      if (isLooping) ...[
                        const SizedBox(width: 4),
                        const Text(
                          'LOOP',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: VocaTokens.accentPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // 4. Next Cue Button (>)
              _buildIconButton(
                icon: Icons.skip_next_rounded,
                tooltip: 'Next sentence',
                onTap: () {
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
              const SizedBox(width: 6),

              // 5. Playback Speed Button Popup (0.75x, 1.0x, 1.25x, 1.5x)
              PopupMenuButton<double>(
                initialValue: rate,
                tooltip: 'Playback Speed',
                onSelected: (newRate) {
                  controller.playbackRate.value = newRate;
                  ytController.setPlaybackRate(newRate);
                },
                color: VocaTokens.bgCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: VocaTokens.borderColor),
                ),
                itemBuilder: (context) => [
                  _buildSpeedMenuItem(0.75, '0.75x', rate),
                  _buildSpeedMenuItem(1.0, '1.0x (Normal)', rate),
                  _buildSpeedMenuItem(1.25, '1.25x', rate),
                  _buildSpeedMenuItem(1.5, '1.5x', rate),
                ],
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: rate != 1.0
                        ? VocaTokens.accentPrimarySoft
                        : VocaTokens.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: rate != 1.0
                          ? VocaTokens.accentPrimary
                          : VocaTokens.borderColor,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${rate}x',
                    style: TextStyle(
                      color: rate != 1.0
                          ? VocaTokens.accentPrimary
                          : VocaTokens.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // 6. Toggle Furigana / Ruby Display (振)
              InkWell(
                onTap: controller.toggleFurigana,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  decoration: BoxDecoration(
                    color: showFurigana
                        ? VocaTokens.accentPrimarySoft
                        : VocaTokens.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: showFurigana
                          ? VocaTokens.accentPrimary
                          : VocaTokens.borderColor,
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
                              ? VocaTokens.accentPrimary
                              : VocaTokens.textMuted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        showFurigana ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: showFurigana
                              ? VocaTokens.accentPrimary
                              : VocaTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // 7. Toggle Translation Display (文)
              InkWell(
                onTap: controller.toggleTranslation,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  decoration: BoxDecoration(
                    color: showTranslation
                        ? VocaTokens.accentPrimarySoft
                        : VocaTokens.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: showTranslation
                          ? VocaTokens.accentPrimary
                          : VocaTokens.borderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '文',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: showTranslation
                              ? VocaTokens.accentPrimary
                              : VocaTokens.textMuted,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        showTranslation ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: showTranslation
                              ? VocaTokens.accentPrimary
                              : VocaTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // 8. Font Size Scaler (S / M / L)
              InkWell(
                onTap: controller.cycleSubtitleSize,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  decoration: BoxDecoration(
                    color: VocaTokens.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: VocaTokens.borderColor),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.format_size_rounded,
                        size: 15,
                        color: VocaTokens.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        sizeLabel,
                        style: const TextStyle(
                          color: VocaTokens.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // 9. Bookmark Button
              InkWell(
                onTap: onBookmark,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 36,
                  width: 36,
                  decoration: BoxDecoration(
                    color: VocaTokens.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: VocaTokens.borderColor),
                  ),
                  child: const Icon(
                    Icons.bookmark_border_rounded,
                    size: 18,
                    color: VocaTokens.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: VocaTokens.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: VocaTokens.borderColor),
          ),
          child: Icon(
            icon,
            size: 20,
            color: VocaTokens.textPrimary,
          ),
        ),
      ),
    );
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
              color: isSelected
                  ? VocaTokens.accentPrimary
                  : VocaTokens.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_rounded,
              color: VocaTokens.accentPrimary,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: VocaTokens.borderColor,
    );
  }
}
