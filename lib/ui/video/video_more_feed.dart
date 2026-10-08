// lib/ui/video/video_more_feed.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import '../explore/widgets/feed_skeleton_card.dart';
import '../explore/widgets/video_feed_card.dart';

/// Context-aware feed of similar and recommended videos to watch next,
/// intelligently prioritizing the same artist/creator, topic keywords,
/// and proficiency level, while strictly excluding the current video.
class VideoMoreFeed extends StatefulWidget {
  final String currentVideoId;
  final String? currentTitle;
  final String? currentChannel;
  final String language;
  final String? tier;
  final void Function(String videoId, String title, String? channel, String? level) onVideoTap;
  final ScrollController? scrollController;

  const VideoMoreFeed({
    super.key,
    required this.currentVideoId,
    this.currentTitle,
    this.currentChannel,
    required this.language,
    this.tier,
    required this.onVideoTap,
    this.scrollController,
  });

  @override
  State<VideoMoreFeed> createState() => VideoMoreFeedState();
}

class VideoMoreFeedState extends State<VideoMoreFeed> {
  final _videos = signal<List<Map<String, dynamic>>>([]);
  final _isLoading = signal<bool>(true);
  final _isLoadingMore = signal<bool>(false);
  final _hasMore = signal<bool>(true);
  final _errorMessage = signal<String?>(null);

  static const int _pageSize = 16;
  int _currentOffset = 0;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void didUpdateWidget(covariant VideoMoreFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only refresh if the video ID or target language actually changed.
    // If only title or tier resolved later for the current video, preserve loaded feed.
    if (oldWidget.currentVideoId != widget.currentVideoId ||
        oldWidget.language != widget.language) {
      _loadVideos(refresh: true);
    } else if (_videos.value.isEmpty && !_isLoading.value &&
        (oldWidget.currentTitle != widget.currentTitle || oldWidget.tier != widget.tier)) {
      _loadVideos(refresh: false);
    }
  }

  Future<void> _loadVideos({bool refresh = false}) async {
    final seq = ++_requestId;
    _currentOffset = 0;
    _hasMore.value = true;
    _isLoading.value = true;
    _errorMessage.value = null;

    try {
      final list = await _fetchSmartRecommendations(
        currentVideoId: widget.currentVideoId,
        title: widget.currentTitle,
        channel: widget.currentChannel,
        language: widget.language,
        tier: widget.tier,
        limit: _pageSize,
        offset: 0,
        refresh: refresh,
      );

      if (seq != _requestId) return;

      _videos.value = list;
      _hasMore.value = list.length >= _pageSize;
      _isLoading.value = false;
    } catch (e) {
      if (seq != _requestId) return;
      _errorMessage.value = e.toString();
      _isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (_isLoading.value || _isLoadingMore.value || !_hasMore.value) return;

    final seq = _requestId;
    _isLoadingMore.value = true;
    _currentOffset += _pageSize;

    try {
      final existingIds = _videos.value.map((v) => v['videoId'] as String? ?? '').toSet();
      existingIds.add(widget.currentVideoId);

      final list = await _fetchSmartRecommendations(
        currentVideoId: widget.currentVideoId,
        title: widget.currentTitle,
        channel: widget.currentChannel,
        language: widget.language,
        tier: widget.tier,
        limit: _pageSize,
        offset: _currentOffset,
        refresh: false,
        excludedIds: existingIds,
      );

      if (seq != _requestId) return;

      if (list.isEmpty) {
        _hasMore.value = false;
      } else {
        _videos.value = [..._videos.value, ...list];
        _hasMore.value = list.length >= _pageSize;
      }
    } catch (_) {
      // Ignore load more errors silently
    } finally {
      if (seq == _requestId) {
        _isLoadingMore.value = false;
      }
    }
  }

  /// Multi-tier smart candidate retrieval and relevance scoring
  Future<List<Map<String, dynamic>>> _fetchSmartRecommendations({
    required String currentVideoId,
    String? title,
    String? channel,
    required String language,
    String? tier,
    required int limit,
    required int offset,
    bool refresh = false,
    Set<String>? excludedIds,
  }) async {
    final apiClient = AppState.instance.apiClient;
    final cleanKeywords = _extractSearchKeywords(title);
    final cleanChannel = _cleanChannelName(channel);

    List<Map<String, dynamic>> channelCandidates = [];
    List<Map<String, dynamic>> keywordCandidates = [];
    List<Map<String, dynamic>> tierCandidates = [];

    // Query 1: Targeted query for same channel/artist (highest relevance)
    if (cleanChannel != null && cleanChannel.isNotEmpty) {
      try {
        channelCandidates = await apiClient.getRecommendedVideos(
          lang: language,
          query: cleanChannel,
          limit: limit,
          offset: offset,
          refresh: refresh,
        );
      } catch (_) {}
    }

    // Query 2: Targeted query for core title keywords (song/topic match)
    if (cleanKeywords.isNotEmpty && channelCandidates.length < limit) {
      try {
        keywordCandidates = await apiClient.getRecommendedVideos(
          lang: language,
          query: cleanKeywords,
          tier: tier,
          limit: limit,
          offset: offset,
          refresh: refresh,
        );
      } catch (_) {}
    }

    // Query 3: Same level/tier immersion videos (backfill / language context)
    try {
      tierCandidates = await apiClient.getRecommendedVideos(
        lang: language,
        tier: tier,
        limit: limit,
        offset: offset,
        refresh: refresh,
      );
    } catch (_) {}

    // Pool & deduplicate, strictly excluding currentVideoId and already-shown videos
    final Map<String, Map<String, dynamic>> pool = {};
    final excludeSet = Set<String>.from(excludedIds ?? {});
    excludeSet.add(currentVideoId);

    for (final v in [...channelCandidates, ...keywordCandidates, ...tierCandidates]) {
      final vid = v['videoId'] as String? ?? '';
      if (vid.isNotEmpty && !excludeSet.contains(vid)) {
        pool.putIfAbsent(vid, () => v);
      }
    }

    // Relevance Scoring & Ranking
    final candidateList = pool.values.toList();
    final scored = candidateList.map((video) {
      final score = _calculateRelevanceScore(
        candidate: video,
        currentChannel: cleanChannel,
        currentKeywords: cleanKeywords,
        currentTier: tier,
      );
      return MapEntry(video, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).take(limit).toList();
  }

  /// Extracts core song/topic keywords from title by removing boilerplate buzzwords
  static String _extractSearchKeywords(String? title) {
    if (title == null || title.trim().isEmpty) return '';
    var clean = title;
    // Remove brackets and parentheticals: [Official MV], (Lyrics), etc.
    clean = clean.replaceAll(RegExp(r'\[.*?\]'), ' ');
    clean = clean.replaceAll(RegExp(r'\(.*?\)'), ' ');
    clean = clean.replaceAll(RegExp(r'【.*?】'), ' ');
    clean = clean.replaceAll(RegExp(r'（.*?）'), ' ');
    clean = clean.replaceAll(RegExp(r'「.*?」'), ' ');
    // Remove boilerplate video buzzwords
    clean = clean.replaceAll(
      RegExp(
        r'\b(official|music|video|mv|hd|4k|1080p|audio|lyrics|vietsub|engsub|sub|español|live|ver|version|full|album)\b',
        caseSensitive: false,
      ),
      ' ',
    );
    // Remove punctuation
    clean = clean.replaceAll(RegExp(r'[/\\|#_~*•–—\-]'), ' ');
    // Keep top meaningful keyword tokens
    final tokens = clean.split(RegExp(r'\s+')).where((s) => s.trim().length >= 2).take(4);
    return tokens.join(' ').trim();
  }

  /// Cleans creator/channel name to isolate primary artist name
  static String? _cleanChannelName(String? channel) {
    if (channel == null || channel.trim().isEmpty) return null;
    final ch = channel.trim();
    if (ch.toLowerCase() == 'youtube' || ch.toLowerCase() == 'youtube creator') return null;
    return ch
        .replaceAll(RegExp(r'\s*-\s*Topic$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+Official$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+VEVO$', caseSensitive: false), '')
        .trim();
  }

  /// Calculates content similarity score between current video and candidate
  static double _calculateRelevanceScore({
    required Map<String, dynamic> candidate,
    String? currentChannel,
    required String currentKeywords,
    String? currentTier,
  }) {
    double score = 0.0;
    final candidateChannel = (candidate['channel'] as String? ?? '').toLowerCase();
    final candidateTitle = (candidate['title'] as String? ?? '').toLowerCase();
    final candidateTier = (candidate['tier'] as String? ?? '').toLowerCase();

    // 1. Same artist/channel boost (+50)
    if (currentChannel != null && currentChannel.isNotEmpty) {
      final ch = currentChannel.toLowerCase();
      if (candidateChannel.contains(ch) || ch.contains(candidateChannel)) {
        score += 50.0;
      }
    }

    // 2. Title keyword overlap boost (+25 per keyword)
    if (currentKeywords.isNotEmpty) {
      final words = currentKeywords.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length >= 2);
      for (final w in words) {
        if (candidateTitle.contains(w)) {
          score += 25.0;
        }
      }
    }

    // 3. Same proficiency tier boost (+15)
    if (currentTier != null && currentTier.isNotEmpty) {
      if (candidateTier == currentTier.toLowerCase()) {
        score += 15.0;
      }
    }

    return score;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;

    return Watch((context) {
      final isLoading = _isLoading.value;
      final isLoadingMore = _isLoadingMore.value;
      final errorMessage = _errorMessage.value;
      final videos = _videos.value;

      Widget content;

      if (isLoading) {
        content = Padding(
          key: const ValueKey('more_skeleton'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            children: List.generate(
              3,
              (i) => const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: FeedSkeletonCard(),
              ),
            ),
          ),
        );
      } else if (errorMessage != null) {
        content = Padding(
          key: const ValueKey('more_error'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded, color: colors.textMuted, size: 36),
                const SizedBox(height: 8),
                Text(
                  context.t('explore.networkError', null, 'Could not load more videos'),
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _loadVideos(refresh: true),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(context.t('common.retry', null, 'Retry')),
                ),
              ],
            ),
          ),
        );
      } else if (videos.isEmpty) {
        content = Padding(
          key: const ValueKey('more_empty'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: Text(
              context.t('explore.noVideos', null, 'No recommended videos available'),
              style: TextStyle(color: colors.textMuted, fontSize: 13),
            ),
          ),
        );
      } else {
        content = ListView.separated(
          key: const ValueKey('more_list'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 32),
          itemCount: videos.length + (isLoadingMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 18),
          itemBuilder: (context, index) {
            if (index >= videos.length) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.accentPrimary,
                    ),
                  ),
                ),
              );
            }

            final item = videos[index];
            final vidId = item['videoId'] as String? ?? '';
            final title = item['title'] as String? ?? 'YouTube Video';
            final channel = item['channel'] as String? ?? 'YouTube Creator';
            final levelTag = VideoFeedCard.resolveVideoLevel(item, widget.language);

            return RepaintBoundary(
              child: VideoFeedCard(
                video: item,
                currentLang: widget.language,
                onTap: () => widget.onVideoTap(vidId, title, channel, levelTag),
              ),
            );
          },
        );
      }

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: content,
      );
    });
  }
}
