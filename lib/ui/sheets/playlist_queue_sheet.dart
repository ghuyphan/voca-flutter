// lib/ui/sheets/playlist_queue_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import '../widgets/voca_shimmer.dart';
import 'voca_bottom_sheet.dart';

class PlaylistQueueSheet extends StatefulWidget {
  final String playlistTitle;
  final String currentVideoId;
  final String? authorName;
  final int currentIndex;
  final int totalCount;
  final bool isPlaying;
  final List<Map<String, dynamic>>? initialVideos;
  final void Function(String videoId, String title, int index) onSelectVideo;
  final VoidCallback? onToggleShuffle;
  final VoidCallback? onToggleLoop;
  final bool isShuffled;
  final bool isLooping;

  const PlaylistQueueSheet({
    super.key,
    required this.playlistTitle,
    required this.currentVideoId,
    this.authorName,
    this.currentIndex = 0,
    this.totalCount = 1,
    this.isPlaying = true,
    this.initialVideos,
    required this.onSelectVideo,
    this.onToggleShuffle,
    this.onToggleLoop,
    this.isShuffled = false,
    this.isLooping = false,
  });

  static Future<void> show(
    BuildContext context, {
    required String playlistTitle,
    required String currentVideoId,
    String? authorName,
    int currentIndex = 0,
    int totalCount = 1,
    bool isPlaying = true,
    List<Map<String, dynamic>>? initialVideos,
    required void Function(String videoId, String title, int index) onSelectVideo,
    VoidCallback? onToggleShuffle,
    VoidCallback? onToggleLoop,
    bool isShuffled = false,
    bool isLooping = false,
  }) {
    final author = authorName ?? context.t('playlist.curated', null, 'Curated');
    final countText = '${currentIndex + 1} / $totalCount';

    return showVocaBottomSheet(
      context: context,
      title: playlistTitle,
      subtitle: '$author • $countText',
      showCloseButton: true,
      showDragHandle: true,
      maxHeightFactor: 0.72,
      contentPadding: EdgeInsets.zero,
      builder: (_) => PlaylistQueueSheet(
        playlistTitle: playlistTitle,
        currentVideoId: currentVideoId,
        authorName: authorName,
        currentIndex: currentIndex,
        totalCount: totalCount,
        isPlaying: isPlaying,
        initialVideos: initialVideos,
        onSelectVideo: onSelectVideo,
        onToggleShuffle: onToggleShuffle,
        onToggleLoop: onToggleLoop,
        isShuffled: isShuffled,
        isLooping: isLooping,
      ),
    );
  }

  @override
  State<PlaylistQueueSheet> createState() => _PlaylistQueueSheetState();
}

class _PlaylistQueueSheetState extends State<PlaylistQueueSheet>
    with SingleTickerProviderStateMixin {
  late bool _isShuffled;
  late bool _isLooping;
  bool _isCopied = false;
  late final AnimationController _eqController;

  @override
  void initState() {
    super.initState();
    _isShuffled = widget.isShuffled;
    _isLooping = widget.isLooping;
    _eqController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _eqController.dispose();
    super.dispose();
  }

  void _handleShare(BuildContext context) {
    final url = 'https://voca.study/video/${widget.currentVideoId}';
    Clipboard.setData(ClipboardData(text: url));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final lang = AppState.instance.activeLanguage.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Mobile Playlist Action Toolbar (Shuffle, Repeat, Share)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              _buildToolbarButton(
                icon: Icons.shuffle_rounded,
                isActive: _isShuffled,
                tooltip: _isShuffled
                    ? context.t('playlist.shuffleOn', null, 'Shuffle on')
                    : context.t('playlist.shufflePlaylist', null, 'Shuffle playlist'),
                onTap: () {
                  setState(() => _isShuffled = !_isShuffled);
                  widget.onToggleShuffle?.call();
                },
              ),
              const SizedBox(width: 8),
              _buildToolbarButton(
                icon: Icons.repeat_rounded,
                isActive: _isLooping,
                tooltip: _isLooping
                    ? context.t('playlist.loopOn', null, 'Looping on')
                    : context.t('playlist.loopPlaylist', null, 'Loop playlist'),
                onTap: () {
                  setState(() => _isLooping = !_isLooping);
                  widget.onToggleLoop?.call();
                },
              ),
              const SizedBox(width: 8),
              _buildToolbarButton(
                icon: _isCopied ? Icons.check_rounded : Icons.share_rounded,
                isActive: _isCopied,
                isSuccess: _isCopied,
                tooltip: _isCopied
                    ? context.t('playlist.linkCopied', null, 'Link copied!')
                    : context.t('playlist.sharePlaylist', null, 'Share playlist'),
                onTap: () => _handleShare(context),
              ),
            ],
          ),
        ),

        // 3. Playlist Items List
        Flexible(
          child: widget.initialVideos != null && widget.initialVideos!.isNotEmpty
              ? _buildVideoList(widget.initialVideos!, colors)
              : FutureBuilder<List<Map<String, dynamic>>>(
                  future: AppState.instance.apiClient.getRecommendedVideos(
                    lang: lang,
                    query: widget.playlistTitle != 'Anime' &&
                            widget.playlistTitle != 'Tuyển chọn'
                        ? widget.playlistTitle.toLowerCase()
                        : null,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildSkeletonList(colors);
                    }

                    final videos = snapshot.data ?? [];
                    if (videos.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            context.t('playlist.empty.noVideosTitle', null, 'No videos yet'),
                            style: TextStyle(color: colors.textMuted, fontSize: 13),
                          ),
                        ),
                      );
                    }

                    return _buildVideoList(videos, colors);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required bool isActive,
    bool isSuccess = false,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final colors = context.vocaColors;
    final bg = isSuccess
        ? colors.success.withOpacity(0.15)
        : isActive
            ? colors.accentPrimarySoft
            : colors.bgSurface;
    final border = isSuccess
        ? colors.success.withOpacity(0.35)
        : isActive
            ? colors.accentPrimary.withOpacity(0.3)
            : colors.borderColor;
    final iconColor = isSuccess
        ? colors.success
        : isActive
            ? colors.accentPrimary
            : colors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: iconColor),
        ),
      ),
    );
  }

  Widget _buildVideoList(List<Map<String, dynamic>> videos, VocaColorPalette colors) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final item = videos[index];
        final vId = item['videoId'] as String? ?? item['id'] as String? ?? '';
        final title = item['title'] as String? ?? 'Video';
        final channel = item['channel'] as String? ?? 'YouTube';
        final isCurrent = vId == widget.currentVideoId;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              if (!isCurrent) {
                widget.onSelectVideo(vId, title, index);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
              decoration: BoxDecoration(
                color: isCurrent ? colors.bgSurface : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrent ? colors.borderColor : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  // Slot 1: item-left index or playing indicator (20px width)
                  Container(
                    width: 20,
                    alignment: Alignment.center,
                    child: isCurrent
                        ? (widget.isPlaying
                            ? _buildEqualizer(colors.accentPrimary)
                            : Icon(Icons.play_arrow_rounded,
                                size: 14, color: colors.accentPrimary))
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),

                  // Slot 2: 16:9 Thumbnail (84px width x ~47px height)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 84,
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              'https://i.ytimg.com/vi/$vId/hqdefault.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: colors.bgSurface,
                                child: Icon(Icons.play_circle_outline,
                                    color: colors.textMuted, size: 20),
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                color: Colors.black.withOpacity(0.35),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Slot 3: Video info (title + channel)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isCurrent ? colors.accentPrimary : colors.textPrimary,
                            fontSize: 13,
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          channel,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEqualizer(Color color) {
    return AnimatedBuilder(
      animation: _eqController,
      builder: (_, __) {
        final t = _eqController.value;
        return SizedBox(
          width: 14,
          height: 14,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBar(color, 4 + 7 * t),
              const SizedBox(width: 1.5),
              _buildBar(color, 12 - 7 * t),
              const SizedBox(width: 1.5),
              _buildBar(color, 6 + 6 * (1.0 - t)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBar(Color color, double height) {
    return Container(
      width: 2.5,
      height: height.clamp(3.0, 14.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildSkeletonList(VocaColorPalette colors) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5,
      itemBuilder: (_, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '${index + 1}',
                style: TextStyle(color: colors.textMuted.withOpacity(0.5), fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
            VocaShimmer.box(
              width: 84,
              height: 47,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VocaShimmer.line(
                    height: 12,
                    width: double.infinity,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 6),
                  VocaShimmer.line(
                    height: 10,
                    width: 100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
