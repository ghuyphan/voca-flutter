// lib/ui/video/subtitle_controls_bar.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import '../../state/player_state.dart';
import '../sheets/saved_words_sheet.dart';
import '../sheets/subtitle_options_sheet.dart';

/// The horizontal controls toolbar situated at the bottom of the subtitle display.
/// Ported 1:1 from lingua-tube's .subtitle-controls in subtitle-display.component.html:
/// - [Loop]: repeat-1 icon + "Loop" + inline badge (e.g. 1/3)
/// - [Added]: bookmark-plus icon + "Added" + count badge -> opens SavedWordsSheet
/// - [Quiz]: RPG crossed swords / quiz icon + "Quiz"
/// - [Options]: settings / tune icon + "Options" -> opens SubtitleOptionsSheet
class SubtitleControlsBar extends StatelessWidget {
  final VideoPlayerController controller;
  final YoutubePlayerController? ytController;
  final VoidCallback? onToggleQuiz;
  final bool isQuizActive;

  const SubtitleControlsBar({
    super.key,
    required this.controller,
    this.ytController,
    this.onToggleQuiz,
    this.isQuizActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(
          top: BorderSide(color: colors.borderColor, width: 1),
        ),
      ),
      child: Watch((context) {
        final isLooping = controller.isLoopingCue.value;
        final hasCues = controller.cues.value.isNotEmpty;
        final currentLang = AppState.instance.activeLanguage.value;
        final videoId = controller.videoId;

        return Row(
          children: [
            // 1. Loop Button: [repeat-1] Loop [1/3]
            Expanded(
              child: _buildCtrlButton(
                context: context,
                icon: isLooping ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                label: context.t('subtitle.loop', null, 'Loop'),
                isActive: isLooping,
                badge: isLooping ? '1' : null,
                onTap: hasCues ? () => controller.toggleLoopCurrentCue() : null,
              ),
            ),
            const SizedBox(width: 4),

            // 2. Added Words Button: [bookmark-plus] Added [count]
            Expanded(
              child: _buildCtrlButton(
                context: context,
                icon: Icons.bookmark_added_rounded,
                label: context.t('nav.added', null, 'Added'),
                isActive: false,
                onTap: () {
                  SavedWordsSheet.show(
                    context,
                    videoId: videoId,
                    language: currentLang,
                  );
                },
              ),
            ),
            const SizedBox(width: 4),

            // 3. Quiz Button: [quiz] Quiz
            Expanded(
              child: _buildCtrlButton(
                context: context,
                icon: Icons.quiz_rounded,
                label: context.t('quiz.short', null, 'Quiz'),
                isActive: isQuizActive,
                onTap: onToggleQuiz,
              ),
            ),
            const SizedBox(width: 4),

            // 4. Options Button: [tune] Options
            Expanded(
              child: _buildCtrlButton(
                context: context,
                icon: Icons.tune_rounded,
                label: context.t('vocab.options', null, 'Options'),
                isActive: false,
                onTap: () {
                  if (ytController != null) {
                    SubtitleOptionsSheet.show(
                      context,
                      controller: controller,
                      ytController: ytController!,
                    );
                  }
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCtrlButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    String? badge,
    VoidCallback? onTap,
  }) {
    final colors = context.vocaColors;
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isActive ? colors.accentPrimary : colors.bgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? colors.accentPrimary : colors.borderColor,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: colors.accentPrimary.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: !isEnabled
                  ? colors.textMuted
                  : (isActive ? Colors.white : colors.textSecondary),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: !isEnabled
                      ? colors.textMuted
                      : (isActive ? Colors.white : colors.textPrimary),
                ),
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : colors.accentPrimary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive ? colors.accentPrimary : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
