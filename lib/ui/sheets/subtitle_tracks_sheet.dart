// lib/ui/sheets/subtitle_tracks_sheet.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import '../../state/player_state.dart';
import '../widgets/circle_flag.dart';
import 'ai_generation_sheet.dart';
import 'voca_bottom_sheet.dart';

/// Modal bottom sheet for selecting subtitle tracks or triggering AI Whisper generation.
/// Ported 1:1 from lingua-tube's video-header trackOptions and showTracksSheet.
class SubtitleTracksSheet extends StatelessWidget {
  final VideoPlayerController controller;
  final VoidCallback? onTriggerAI;

  const SubtitleTracksSheet({
    super.key,
    required this.controller,
    this.onTriggerAI,
  });

  static Future<void> show(
    BuildContext context, {
    required VideoPlayerController controller,
    VoidCallback? onTriggerAI,
  }) {
    return showVocaBottomSheet(
      context: context,
      title: context.t('subtitle.tracksTitle', null, 'Subtitle Tracks'),
      showCloseButton: true,
      maxHeightFactor: 0.80,
      contentPadding: EdgeInsets.zero,
      builder: (ctx) => SubtitleTracksSheet(
        controller: controller,
        onTriggerAI: onTriggerAI,
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code.toLowerCase()) {
      case 'ja':
        return 'Japanese (日本語)';
      case 'zh':
        return 'Chinese (中文)';
      case 'ko':
        return 'Korean (한국어)';
      case 'en':
        return 'English';
      case 'vi':
        return 'Vietnamese (Tiếng Việt)';
      case 'es':
        return 'Spanish (Español)';
      case 'fr':
        return 'French (Français)';
      case 'de':
        return 'German (Deutsch)';
      default:
        return code.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final activeLang = controller.activeLanguage.value;
    final isAIGenerated = controller.isAIGenerated.value;
    final isOff = !controller.showFurigana.value && !controller.showTranslation.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Off option
          _buildTrackOption(
            context: context,
            title: context.t('player.subtitlesOff', null, 'Off'),
            subtitle: context.t('subtitle.hideCaptions', null, 'Hide subtitles display'),
            leading: Icon(Icons.block_rounded, size: 20, color: colors.textMuted),
            isSelected: isOff,
            onTap: () {
              controller.showFurigana.value = false;
              controller.showTranslation.value = false;
              Navigator.pop(context);
            },
          ),

          Divider(height: 1, color: colors.borderColor),

          // 2. Active / Native Learning Language Track
          _buildTrackOption(
            context: context,
            title: _getLanguageName(activeLang),
            subtitle: isAIGenerated
                ? '${activeLang.toUpperCase()} • Whisper AI'
                : '${activeLang.toUpperCase()} • Native Subtitles',
            leading: CircleFlag(code: activeLang, size: 22),
            isSelected: !isOff,
            badge: isAIGenerated ? 'AI' : null,
            badgeColor: colors.colorDiamond,
            onTap: () {
              controller.showFurigana.value = true;
              Navigator.pop(context);
            },
          ),

          // 3. Alternative available language tracks
          for (final lang in ['ja', 'zh', 'ko', 'en'])
            if (lang != activeLang.toLowerCase())
              _buildTrackOption(
                context: context,
                title: _getLanguageName(lang),
                subtitle: '${lang.toUpperCase()} • Native Subtitles',
                leading: CircleFlag(code: lang, size: 22),
                isSelected: false,
                onTap: () {
                  AppState.instance.setLanguage(lang);
                  controller.loadVideo(controller.videoId, language: lang);
                  Navigator.pop(context);
                },
              ),

          Divider(height: 1, color: colors.borderColor),

          // 4. Generate with AI Option
          _buildTrackOption(
            context: context,
            title: context.t('subtitle.generateAi', null, 'Generate with AI'),
            subtitle: 'Whisper AI • High accuracy transcript',
            leading: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.colorDiamond.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.auto_awesome_rounded, size: 16, color: colors.colorDiamond),
            ),
            isSelected: false,
            badge: '1 💎',
            badgeColor: colors.colorDiamond,
            onTap: () {
              Navigator.pop(context);
              if (onTriggerAI != null) {
                onTriggerAI!();
              } else {
                AiGenerationSheet.show(
                  context,
                  videoId: controller.videoId,
                  videoTitle: controller.videoTitle.value,
                  language: activeLang,
                  onGenerated: () {
                    controller.loadVideo(controller.videoId);
                  },
                );
              }
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTrackOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget leading,
    required bool isSelected,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    final colors = context.vocaColors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: isSelected ? colors.accentPrimarySoft.withValues(alpha: 0.08) : Colors.transparent,
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? colors.accentPrimary : colors.textPrimary,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: (badgeColor ?? colors.colorDiamond).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeColor ?? colors.colorDiamond,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, size: 20, color: colors.accentPrimary),
          ],
        ),
      ),
    );
  }
}
