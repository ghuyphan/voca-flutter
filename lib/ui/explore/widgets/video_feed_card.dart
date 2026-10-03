// lib/ui/explore/widgets/video_feed_card.dart

import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../services/video_level_service.dart';
import '../../../utils/video_format_utils.dart';
import '../../widgets/voca_level_badge.dart';

/// 1:1 Video Card matching lingua-tube's yt-video-card & AGENTS.md.
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

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final videoId = video['videoId'] as String? ?? '';
    final title = video['title'] as String? ?? 'YouTube Video';
    final channel = video['channel'] as String? ?? 'YouTube Creator';
    final channelAvatar = video['channelAvatar'] as String?;
    final duration = video['duration'] as int? ?? 0;
    final durationStr = duration > 0 ? formatVideoTime(duration) : '';
    final levelTag = resolveVideoLevel(video, currentLang);
    final double? resumeProgress = (video['resumeProgress'] as num?)?.toDouble() ??
        (video['progress'] as num?)?.toDouble();

    final thumbnailUrl = (video['thumbnail'] as String?)?.isNotEmpty == true
        ? video['thumbnail'] as String
        : 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

    return Container(
      color: Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 16:9 Thumbnail with Duration & Resume Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        cacheWidth: 480,
                        cacheHeight: 270,
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
                          backgroundColor: Colors.black38,
                          valueColor: AlwaysStoppedAnimation<Color>(colors.accentPrimary),
                          minHeight: 3.5,
                        ),
                      ),
                  ],
                ),
              ),

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
                          width: 36,
                          height: 36,
                          cacheWidth: 72,
                          cacheHeight: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => CircleAvatar(
                            radius: 18,
                            backgroundColor: colors.bgSurface,
                            child: Icon(Icons.person, size: 18, color: colors.textSecondary),
                          ),
                        ),
                      )
                    else
                      CircleAvatar(
                        radius: 18,
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
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            channel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (levelTag.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            VocaLevelBadge(
                              level: levelTag,
                              size: LevelBadgeSize.small,
                            ),
                          ],
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
    );
  }
}
