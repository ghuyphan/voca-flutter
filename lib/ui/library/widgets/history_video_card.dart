// lib/ui/library/widgets/history_video_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/voca_theme.dart';
import '../../../state/player_coordinator.dart';
import '../../../utils/video_format_utils.dart';
import '../../widgets/voca_level_badge.dart';
import '../../widgets/voca_favorite_button.dart';
import '../../widgets/pressable_scale.dart';

/// Sleek 16:9 History Video Card matching lingua-tube's yt-video-card.
class HistoryVideoCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onRemove;

  const HistoryVideoCard({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onRemove,
  });

  static String formatRelativeTime(dynamic dateVal) {
    if (dateVal == null) return '';
    DateTime? dt;
    if (dateVal is DateTime) {
      dt = dateVal;
    } else {
      dt = DateTime.tryParse(dateVal.toString());
    }
    if (dt == null) return '';

    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dt);
    }
  }

  static String formatDuration(int seconds) => formatVideoTime(seconds);

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final videoId = item['video_id'] as String? ?? item['videoId'] as String? ?? '';
    final title = item['title'] as String? ?? 'Untitled Video';
    final channel = item['channel'] as String? ?? 'YouTube';
    final duration = (item['duration'] as num?)?.toInt() ?? 0;
    final rawProgress = (item['progress'] as num?)?.toDouble() ?? 0.0;
    final progress = rawProgress > 1.0 ? rawProgress / 100.0 : rawProgress;
    final progressPercent = (progress * 100).clamp(0, 100).toInt();
    final watchedAt = item['watched_at'] ?? item['updated_at'] ?? item['created_at'];
    final language = (item['language'] as String? ?? '').trim();
    final level = (item['level'] as String? ?? '').trim();

    final thumbnailUrl = (item['thumbnail'] as String?)?.isNotEmpty == true
        ? item['thumbnail'] as String
        : 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

    return Dismissible(
      key: ValueKey('history_${item['id'] ?? videoId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.error.withValues(alpha: 0.35)),
        ),
        child: Icon(Icons.delete_outline_rounded, color: colors.error, size: 22),
      ),
      onDismissed: (_) => onRemove(),
      child: PressableScale(
        pressedScale: 0.985,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: colors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderColor),
          ),
          clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              PlayerCoordinator.instance.openVideo(
                context,
                videoId: videoId,
                title: title,
                channel: channel,
                level: level.isNotEmpty ? level : null,
                initialDuration: duration > 0 ? duration : null,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 16:9 Thumbnail with Duration Badge & Hairline Progress Bar
                  SizedBox(
                    width: 122,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: colors.bgSecondary,
                                child: Icon(
                                  Icons.play_circle_outline_rounded,
                                  color: colors.textMuted,
                                  size: 32,
                                ),
                              ),
                            ),

                            // Duration Badge (bottom-right)
                            if (duration > 0)
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xD9000000),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    formatDuration(duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),

                            // Progress Hairline Bar along bottom edge
                            if (progressPercent > 0)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 3,
                                  color: Colors.black45,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: (progressPercent / 100.0).clamp(0.0, 1.0),
                                      child: Container(
                                        color: colors.accentPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Metadata Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title (14px, 2 lines max)
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 3),

                        // Channel & Relative Time Row
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                channel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            if (watchedAt != null) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  '•',
                                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                                ),
                              ),
                              Text(
                                formatRelativeTime(watchedAt),
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Sub-row: Language / Level badges & Progress percent
                        Row(
                          children: [
                            if (language.isNotEmpty && language != 'all') ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: colors.bgSurface,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: colors.borderColor),
                                ),
                                child: Text(
                                  language.toUpperCase(),
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (level.isNotEmpty && level != 'all') ...[
                              VocaLevelBadge(
                                level: level,
                                size: LevelBadgeSize.small,
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (progressPercent > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: colors.accentPrimarySoft,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$progressPercent%',
                                  style: TextStyle(
                                    color: colors.accentPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions: Favorite and Delete
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VocaFavoriteButton(
                        isFavorite: isFavorite,
                        onToggle: onToggleFavorite,
                        iconSize: 20,
                      ),
                      IconButton(
                        onPressed: onRemove,
                        tooltip: 'Remove',
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: colors.textMuted,
                        ),
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          foregroundColor: colors.textMuted,
                          minimumSize: const Size(48, 48),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
