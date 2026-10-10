// lib/ui/explore/widgets/video_feed_card.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/video_level_service.dart';
import '../../../utils/video_format_utils.dart';
import '../../widgets/voca_level_badge.dart';
import '../../widgets/pressable_scale.dart';

/// Official Material 3 Video Feed Card with outlined border, 16:9 thumbnail, and structured metadata.
class VideoFeedCard extends StatelessWidget {
  final Map<String, dynamic> video;
  final String currentLang;
  final VoidCallback onTap;

  const VideoFeedCard({
    super.key,
    required this.video,
    required this.currentLang,
    required this.onTap,
  });

  static String resolveVideoLevel(Map<String, dynamic> item, String lang) {
    final directLevel = item['level'] as String?;
    if (directLevel != null && directLevel.isNotEmpty) {
      return directLevel;
    }

    final levels = item['levels'] as Map<String, dynamic>?;
    if (levels != null && levels[lang] != null) {
      return levels[lang].toString();
    }

    final tierStr = item['tier'] as String?;
    if (tierStr != null && tierStr.isNotEmpty) {
      final tier = VideoLevelService.deriveLevelTier(tierStr);
      return VideoLevelService.instance.tierToLabel(tier, lang);
    }

    // Heuristics: detect from title / channel metadata
    final videoId = item['videoId'] as String?;
    final title = item['title'] as String? ?? '';
    final channel = item['channel'] as String? ?? '';
    if (title.isNotEmpty || channel.isNotEmpty) {
      final detected = VideoLevelService.instance.resolveLevel(
        videoId: videoId,
        lang: lang,
        title: title,
        channel: channel,
      );
      if (detected != null && detected.level.isNotEmpty) {
        return detected.level;
      }
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final videoId = video['videoId'] as String? ?? '';
    final rawTitle = (video['title'] as String?)?.trim();
    final title = (rawTitle != null && rawTitle.isNotEmpty) ? rawTitle : 'YouTube Video';
    final rawChannel = (video['channel'] as String?)?.trim();
    final channel = (rawChannel != null && rawChannel.isNotEmpty) ? rawChannel : 'YouTube Creator';
    final channelAvatar = video['channelAvatar'] as String?;
    final duration = (video['duration'] as num?)?.toInt() ?? 0;
    final durationStr = duration > 0 ? formatVideoTime(duration) : '';
    final levelTag = VideoFeedCard.resolveVideoLevel(video, currentLang);
    final double? resumeProgress = (video['resumeProgress'] as num?)?.toDouble() ??
        (video['progress'] as num?)?.toDouble();

    final thumbnailUrl = (video['thumbnail'] as String?)?.isNotEmpty == true
        ? video['thumbnail'] as String
        : 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

    Widget thumbnailWidget = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              thumbnailUrl,
              fit: BoxFit.cover,
              cacheWidth: 480,
              cacheHeight: 270,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  child: child,
                );
              },
              errorBuilder: (_, __, ___) => Container(
                color: colors.bgSecondary,
                child: Center(
                  child: Icon(
                    Icons.play_circle_outline_rounded,
                    color: colors.textTertiary,
                    size: 48,
                  ),
                ),
              ),
            ),

            // Level Badge (Bottom-Left)
            if (levelTag.isNotEmpty)
              Positioned(
                bottom: 8,
                left: 8,
                child: VocaLevelBadge(
                  level: levelTag,
                  size: LevelBadgeSize.small,
                  isSolid: true,
                ),
              ),

            // Duration Badge (Bottom-Right)
            if (durationStr.isNotEmpty)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xCC000000),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    durationStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),

            // Resume progress bar at bottom of thumbnail
            if (resumeProgress != null && resumeProgress > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: resumeProgress.clamp(0.0, 1.0),
                  backgroundColor: Colors.black.withValues(alpha: 0.38),
                  valueColor: AlwaysStoppedAnimation<Color>(colors.accentPrimary),
                  minHeight: 3.5,
                ),
              ),
          ],
        ),
      ),
    );

    return RepaintBoundary(
      child: PressableScale(
        pressedScale: 0.985,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              thumbnailWidget,

              // Title, Channel, and Level Info
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 2, right: 2, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (channelAvatar != null && channelAvatar.isNotEmpty)
                      ClipOval(
                        child: Image.network(
                          channelAvatar,
                          width: 38,
                          height: 38,
                          cacheWidth: 76,
                          cacheHeight: 76,
                          fit: BoxFit.cover,
                          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded) return child;
                            return AnimatedOpacity(
                              opacity: frame == null ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: child,
                            );
                          },
                          errorBuilder: (_, __, ___) => CircleAvatar(
                            radius: 19,
                            backgroundColor: colors.bgSurface,
                            child: Icon(Icons.person, size: 18, color: colors.textSecondary),
                          ),
                        ),
                      )
                    else
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: colors.bgSurface,
                        child: Icon(Icons.smart_display_rounded, size: 18, color: colors.textSecondary),
                      ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            channel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
