// lib/ui/video/video_header.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../state/player_state.dart';
import '../sheets/subtitle_tracks_sheet.dart';
import '../sheets/video_level_sheet.dart';
import '../widgets/voca_level_badge.dart';
import '../widgets/voca_shimmer.dart';

/// VideoHeader Widget
///
/// Ported from lingua-tube's app-video-header:
/// - Title (clamped 1 line with tooltip)
/// - Channel name (clamped 1 line with tooltip)
/// - Level Badge (`VocaLevelBadge` / clickable pill opening `VideoLevelSheet`,
///   with evaluating shimmer if level is loading)
/// - Subtitle Track Picker button (`subtitles` or `subtitles-ai` icon)
/// - Share button (clipboard copy with floating snackbar)
/// - Close button (`x`)
/// - Shimmer skeleton state matching Angular when title/channel are empty or loading:
///   `VocaShimmer.line(width: 220, height: 16)` (for title)
///   `VocaShimmer.line(width: 120, height: 12)` (for channel)
class VideoHeader extends StatelessWidget {
  final String? title;
  final String? channel;
  final String? videoId;
  final String? level;
  final String? tier;
  final bool isLevelLoading;
  final bool isAIGenerated;
  final bool hasTracks;
  final VoidCallback? onSubtitleTap;
  final VoidCallback? onShareTap;
  final VoidCallback? onCloseTap;
  final VoidCallback? onLevelTap;
  final VideoPlayerController? controller;
  final YoutubePlayerController? ytController;
  final List<Widget>? extraActions;

  const VideoHeader({
    super.key,
    this.title,
    this.channel,
    this.videoId,
    this.level,
    this.tier,
    this.isLevelLoading = false,
    this.isAIGenerated = false,
    this.hasTracks = true,
    this.onSubtitleTap,
    this.onShareTap,
    this.onCloseTap,
    this.onLevelTap,
    this.controller,
    this.ytController,
    this.extraActions,
  });

  void _handleShare(BuildContext context) {
    if (onShareTap != null) {
      onShareTap!();
      return;
    }
    if (videoId == null || videoId!.isEmpty) return;
    Clipboard.setData(
        ClipboardData(text: 'https://www.youtube.com/watch?v=$videoId'));
    final colors = context.vocaColors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colors.bgSurface,
        content: Row(
          children: [
            Icon(Icons.check_circle_outline,
                color: colors.colorGrammar, size: 18),
            const SizedBox(width: 10),
            Text(
              context.t(
                  'video.linkCopied', null, 'Video link copied to clipboard!'),
              style: TextStyle(color: colors.textPrimary),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleClose(BuildContext context) {
    if (onCloseTap != null) {
      onCloseTap!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _handleSubtitleTap(BuildContext context) {
    if (onSubtitleTap != null) {
      onSubtitleTap!();
    } else if (controller != null) {
      SubtitleTracksSheet.show(
        context,
        controller: controller!,
      );
    }
  }

  void _handleLevelTap(BuildContext context) {
    if (onLevelTap != null) {
      onLevelTap!();
      return;
    }
    final effectiveLevel = level ?? controller?.difficultyLevel.value;
    if (effectiveLevel != null && effectiveLevel.isNotEmpty) {
      VideoLevelSheet.show(
        context,
        level: effectiveLevel,
        tier: tier,
        grammarCount: controller?.activeGrammarMatches.value.length ?? 0,
        grammarMatches: controller?.activeGrammarMatches.value ?? const [],
      );
    }
  }

  Widget _buildRoundIconButton({
    required Widget icon,
    required String tooltip,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final colors = context.vocaColors;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        shape: BoxShape.circle,
        border: Border.all(color: colors.borderColor),
      ),
      child: IconButton(
        icon: icon,
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  Widget _buildSubtitleIcon(BuildContext context, bool isAI) {
    final colors = context.vocaColors;
    if (!isAI) {
      return Icon(Icons.subtitles_rounded, size: 16, color: colors.textSecondary);
    }
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Icon(Icons.subtitles_rounded, size: 16, color: colors.textSecondary),
        Positioned(
          right: -5,
          top: -3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
            decoration: BoxDecoration(
              color: colors.colorDiamond,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final hasTitleAndChannel = title != null &&
        title!.isNotEmpty &&
        title != 'YouTube Video' &&
        channel != null &&
        channel!.isNotEmpty;

    if (!hasTitleAndChannel) {
      // Angular skeleton loading state with shimmer effect
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  VocaShimmer.line(width: 220, height: 16),
                  const SizedBox(height: 6),
                  VocaShimmer.line(width: 120, height: 12),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final effectiveIsAI = isAIGenerated || (controller?.isAIGenerated.value ?? false);
    final effectiveIsLevelLoading =
        isLevelLoading || (level == null && (controller?.isLoading.value ?? false));
    final effectiveLevel = level ?? controller?.difficultyLevel.value;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Title + Channel & Level Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title (clamped 1 line with tooltip)
                Tooltip(
                  message: title!,
                  child: Text(
                    title!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),

                // Channel + Level Badge row
                Row(
                  children: [
                    Flexible(
                      child: Tooltip(
                        message: channel!,
                        child: Text(
                          channel!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textMuted,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (effectiveLevel != null && effectiveLevel.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      VocaLevelBadge(
                        level: effectiveLevel,
                        size: LevelBadgeSize.small,
                        onTap: () => _handleLevelTap(context),
                      ),
                    ] else if (effectiveIsLevelLoading) ...[
                      const SizedBox(width: 8),
                      VocaLevelBadge(
                        isLoading: true,
                        size: LevelBadgeSize.small,
                        customTitle: context.t(
                            'level.evaluating', null, 'Evaluating level...'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right: Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasTracks) ...[
                _buildRoundIconButton(
                  icon: _buildSubtitleIcon(context, effectiveIsAI),
                  tooltip: context.t(
                      'subtitle.tracksTitle', null, 'Subtitle Tracks'),
                  onTap: () => _handleSubtitleTap(context),
                  context: context,
                ),
                const SizedBox(width: 8),
              ],
              if (extraActions != null) ...[
                for (final action in extraActions!) ...[
                  action,
                  const SizedBox(width: 8),
                ],
              ],
              _buildRoundIconButton(
                icon: Icon(Icons.share_rounded,
                    size: 16, color: colors.textSecondary),
                tooltip: context.t('player.share', null, 'Share video'),
                onTap: () => _handleShare(context),
                context: context,
              ),
              const SizedBox(width: 8),
              _buildRoundIconButton(
                icon: Icon(Icons.close_rounded,
                    size: 18, color: colors.textSecondary),
                tooltip: context.t('player.closeVideo', null, 'Close'),
                onTap: () => _handleClose(context),
                context: context,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
