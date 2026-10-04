// lib/ui/video/video_header.dart

import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../state/player_state.dart';
import '../sheets/video_level_sheet.dart';
import '../widgets/voca_level_badge.dart';
import '../widgets/voca_shimmer.dart';

/// VideoHeader Widget
///
/// Lean, efficient video header displaying:
/// - Title (clamped 2 lines with tooltip)
/// - Channel name (clamped 1 line with tooltip)
/// - Level Badge (`VocaLevelBadge` / clickable pill opening `VideoLevelSheet`,
///   with evaluating shimmer if level is loading)
/// - Shimmer skeleton state when title/channel are empty or loading:
///   `VocaShimmer.line(width: 220, height: 16)` (for title)
///   `VocaShimmer.line(width: 120, height: 12)` (for channel)
class VideoHeader extends StatelessWidget {
  final String? title;
  final String? channel;
  final String? videoId;
  final String? level;
  final String? tier;
  final bool isLevelLoading;
  final VoidCallback? onLevelTap;
  final VoidCallback? onCloseTap;
  final VoidCallback? onVerticalDragDown;
  final VideoPlayerController? controller;
  final YoutubePlayerController? ytController;

  const VideoHeader({
    super.key,
    this.title,
    this.channel,
    this.videoId,
    this.level,
    this.tier,
    this.isLevelLoading = false,
    this.onLevelTap,
    this.onCloseTap,
    this.onVerticalDragDown,
    this.controller,
    this.ytController,
  });

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

    final effectiveIsLevelLoading =
        isLevelLoading || (level == null && (controller?.isLoading.value ?? false));
    final effectiveLevel = level ?? controller?.difficultyLevel.value;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 250) {
          onVerticalDragDown?.call();
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Video Title (clamped 2 lines with tooltip)
          Tooltip(
            message: title!,
            child: Text(
              title!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                letterSpacing: -0.2,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),

          // 2. Level Badge & Channel Row
          Row(
            children: [
              if (effectiveLevel != null && effectiveLevel.isNotEmpty) ...[
                VocaLevelBadge(
                  level: effectiveLevel,
                  size: LevelBadgeSize.small,
                  onTap: () => _handleLevelTap(context),
                ),
                const SizedBox(width: 8),
              ] else if (effectiveIsLevelLoading) ...[
                VocaLevelBadge(
                  isLoading: true,
                  size: LevelBadgeSize.small,
                  customTitle: context.t(
                      'level.evaluating', null, 'Evaluating level...'),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Tooltip(
                  message: channel!,
                  child: Text(
                    channel!,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }
}
