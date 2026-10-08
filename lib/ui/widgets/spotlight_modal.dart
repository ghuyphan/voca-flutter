// lib/ui/widgets/spotlight_modal.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/voca_theme.dart';
import '../../state/app_state.dart';
import '../../utils/youtube_url_parser.dart';
import '../../services/i18n_service.dart';
import '../settings/settings_screen.dart';
import '../../state/player_coordinator.dart';
import '../../utils/video_format_utils.dart';

/// Authentic Spotlight / Command Palette matching lingua-tube's command-palette component.
class SpotlightModal extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;
  final void Function(String videoId)? onVideoSelected;

  const SpotlightModal({
    super.key,
    this.onNavigateTab,
    this.onVideoSelected,
  });

  /// Displays the SpotlightModal dialog with blur backdrop.
  static Future<T?> show<T>(
    BuildContext context, {
    void Function(int tabIndex)? onNavigateTab,
    void Function(String videoId)? onVideoSelected,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Spotlight',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SpotlightModal(
          onNavigateTab: onNavigateTab,
          onVideoSelected: onVideoSelected,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = Curves.easeOutCubic.transform(animation.value);
        return Transform.scale(
          scale: 0.96 + 0.04 * curved,
          alignment: Alignment.topCenter,
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<SpotlightModal> createState() => _SpotlightModalState();
}

class _SpotlightModalState extends State<SpotlightModal>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  Timer? _debounceTimer;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _hasError = false;
  String? _detectedVideoId;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() => _hasError = false);
        }
      }
    });

    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    setState(() => _hasError = true);
    _shakeController.forward(from: 0.0);
  }

  void _onInputChanged(String val) {
    final trimmed = val.trim();
    final videoId = YouTubeUrlParser.extractVideoId(trimmed);

    setState(() {
      _detectedVideoId = videoId;
      if (_hasError) _hasError = false;
    });

    _debounceTimer?.cancel();

    if (trimmed.isEmpty || videoId != null) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounceTimer = Timer(const Duration(milliseconds: 280), () {
      _performCatalogSearch(trimmed);
    });
  }

  Future<void> _performCatalogSearch(String query) async {
    try {
      final lang = AppState.instance.activeLanguage.value;
      final results = await AppState.instance.apiClient.getRecommendedVideos(
        lang: lang,
        query: query,
        limit: 8,
      );

      if (mounted && _controller.text.trim() == query) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.isEmpty) return;

      _controller.text = text;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );
      _onInputChanged(text);

      final videoId = YouTubeUrlParser.extractVideoId(text);
      if (videoId != null) {
        _navigateToPlayer(videoId, 'YouTube Video');
      }
    } catch (_) {
      _focusNode.requestFocus();
    }
  }

  void _clearInput() {
    _controller.clear();
    _debounceTimer?.cancel();
    setState(() {
      _detectedVideoId = null;
      _searchResults = [];
      _isSearching = false;
      _hasError = false;
    });
    _focusNode.requestFocus();
  }

  void _handleSubmit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return;

    final videoId = YouTubeUrlParser.extractVideoId(trimmed);
    if (videoId != null) {
      _navigateToPlayer(videoId, 'YouTube Video');
      return;
    }

    if (_searchResults.isNotEmpty) {
      final first = _searchResults.first;
      final id = first['videoId'] as String?;
      final title = first['title'] as String? ?? 'YouTube Video';
      if (id != null) {
        _navigateToPlayer(id, title);
        return;
      }
    }

    // No valid video or results
    _triggerShake();
  }

  void _navigateToPlayer(String videoId, String title, {int? duration}) {
    Navigator.of(context).pop();
    if (widget.onVideoSelected != null) {
      widget.onVideoSelected!(videoId);
    } else {
      PlayerCoordinator.instance.openVideo(
        context,
        videoId: videoId,
        title: title,
        initialDuration: duration,
      );
    }
  }

  void _handleQuickNav(int tabIndex) {
    Navigator.of(context).pop();
    widget.onNavigateTab?.call(tabIndex);
  }

  void _openSettings() {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }


  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < VocaTokens.tabletBreakpoint;
    final topPadding = isMobile
        ? (mediaQuery.padding.top + 16.0)
        : (mediaQuery.size.height * 0.08).clamp(32.0, 100.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blur backdrop that captures taps to close
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Centered spotlight modal container
          Positioned(
            top: topPadding,
            left: 16,
            right: 16,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: GestureDetector(
                  onTap: () {}, // Prevent backdrop tap inside
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Spotlight Bar Row (Bar + Cancel Button)
                      _buildSpotlightBarRow(isMobile),

                      const SizedBox(height: 10),

                      // Results & Navigation List Container
                      _buildResultsContainer(context, isMobile),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotlightBarRow(bool isMobile) {
    final colors = context.vocaColors;
    return Row(
      children: [
        // The Spotlight Bar
        Expanded(
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: child,
              );
            },
            child: Container(
              height: isMobile ? 50 : 56,
              decoration: BoxDecoration(
                color: colors.bgCard,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _hasError
                      ? colors.error
                      : (_detectedVideoId != null || _focusNode.hasFocus)
                          ? colors.accentPrimary
                          : colors.borderColor,
                  width: (_hasError || _detectedVideoId != null || _focusNode.hasFocus)
                      ? 1.5
                      : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.isDarkMode
                        ? Colors.black.withValues(alpha: 0.40)
                        : Colors.black.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                  if (_hasError)
                    BoxShadow(
                      color: colors.error.withValues(alpha: 0.25),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  else if (_focusNode.hasFocus || _detectedVideoId != null)
                    BoxShadow(
                      color: colors.accentPrimary.withValues(alpha: 0.18),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  // Left Icon (Link if URL detected, search otherwise)
                  Icon(
                    _detectedVideoId != null
                        ? Icons.link_rounded
                        : Icons.search_rounded,
                    color: (_detectedVideoId != null || _focusNode.hasFocus)
                        ? colors.accentPrimary
                        : colors.textMuted,
                    size: 21,
                  ),
                  const SizedBox(width: 12),

                  // Input Field
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: colors.accentPrimary,
                      textInputAction: TextInputAction.go,
                      onChanged: _onInputChanged,
                      onSubmitted: (_) => _handleSubmit(),
                      decoration: InputDecoration(
                        hintText: context.t('spotlight.hint', null, 'Paste YouTube link or search...'),
                        hintStyle: TextStyle(
                          color: colors.textMuted,
                          fontSize: 14.5,
                          fontWeight: FontWeight.normal,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),

                  // Trailing Actions (Clear + Submit OR Paste)
                  if (_controller.text.isNotEmpty) ...[
                    // Clear Button
                    IconButton(
                      key: const Key('spotlight-clear-btn'),
                      icon: Icon(
                        Icons.close_rounded,
                        color: colors.textMuted,
                        size: 19,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: context.t('common.clear', null, 'Clear'),
                      onPressed: _clearInput,
                    ),
                    const SizedBox(width: 4),

                    // Submit Button in Signature Coral
                    Material(
                      key: const Key('spotlight-submit-btn'),
                      color: colors.accentPrimary,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _handleSubmit,
                        child: const SizedBox(
                          width: 32,
                          height: 32,
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ] else ...[
                    // Clipboard Paste Button
                    IconButton(
                      key: const Key('spotlight-paste-btn'),
                      icon: Icon(
                        Icons.assignment_outlined,
                        color: colors.textSecondary,
                        size: 20,
                      ),
                      tooltip: context.t('common.paste', null, 'Paste from clipboard'),
                      onPressed: _pasteFromClipboard,
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Cancel Button
        TextButton(
          key: const Key('spotlight-cancel-btn'),
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          ),
          child: Text(
            context.t('common.cancel', null, 'Cancel'),
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsContainer(BuildContext context, bool isMobile) {
    final colors = context.vocaColors;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxResultsHeight = (screenHeight * 0.65).clamp(360.0, 480.0);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: maxResultsHeight),
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderColor),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withValues(alpha: 0.40)
                : Colors.black.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Label
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              _detectedVideoId != null
                  ? context.t('spotlight.youtubeVideo', null, 'YOUTUBE VIDEO')
                  : _controller.text.trim().isNotEmpty
                      ? context.t('spotlight.searchResults', null, 'SEARCH RESULTS')
                      : context.t('spotlight.quickNavigation', null, 'QUICK NAVIGATION'),
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),

          // Scrollable Content
          Flexible(
            child: _buildScrollableContent(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableContent(VocaColorPalette colors) {
    // 1. YouTube Video Detected (High Priority Card)
    if (_detectedVideoId != null) {
      final videoId = _detectedVideoId!;
      return ListView(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
        shrinkWrap: true,
        children: [
          Material(
            key: const Key('spotlight-youtube-card'),
            color: colors.accentPrimarySoft,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _navigateToPlayer(videoId, 'YouTube Video'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.accentPrimary.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.accentPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '▶ ${context.t('spotlight.loadVideo', {'id': videoId}, 'Load YouTube Video: $videoId')}',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.t('spotlight.bilingualImmersion', null, 'Tap to start bilingual immersion & transcription'),
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.accentPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.t('spotlight.startLearning', null, 'Start Learning'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 2. User has typed text -> API search results
    if (_controller.text.trim().isNotEmpty) {
      if (_isSearching) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colors.accentPrimary,
              ),
            ),
          ),
        );
      }

      if (_searchResults.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                color: colors.textMuted,
                size: 32,
              ),
              const SizedBox(height: 10),
              Text(
                context.t('search.noResults', null, 'No results found'),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.t('search.noResultsHint', null, 'Try a different command or paste a YouTube link'),
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shrinkWrap: true,
        itemCount: _searchResults.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final item = _searchResults[index];
          final videoId = item['videoId'] as String? ?? '';
          final title = item['title'] as String? ?? 'YouTube Video';
          final channel = item['channel'] as String? ?? '';
          final duration = (item['duration'] as num?)?.toInt() ?? 0;
          final durationStr = duration > 0 ? formatVideoTime(duration) : '';
          final level = item['level'] as String? ?? item['tier'] as String? ?? '';

          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _navigateToPlayer(videoId, title, duration: duration > 0 ? duration : null),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.bgSecondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: colors.accentPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (channel.isNotEmpty) channel,
                              if (durationStr.isNotEmpty) durationStr,
                            ].join(' • '),
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 11.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (level.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.bgSecondary,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: Text(
                          level.toUpperCase(),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // 3. Empty input: Quick Navigation matching requirements
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shrinkWrap: true,
      children: [
        _buildNavTile(
          icon: Icons.play_circle_outline,
          title: context.t('sidebar.watch', null, 'Watch & Learn'),
          subtitle: context.t('spotlight.watchSubtitle', null, 'Explore video catalog & lessons'),
          onTap: () => _handleQuickNav(0),
          colors: colors,
        ),
        _buildNavTile(
          icon: Icons.school_outlined,
          title: context.t('sidebar.review', null, 'Review Flashcards'),
          subtitle: context.t('spotlight.reviewSubtitle', null, 'Spaced Repetition System (SRS)'),
          onTap: () => _handleQuickNav(1),
          colors: colors,
        ),
        _buildNavTile(
          icon: Icons.menu_book_outlined,
          title: context.t('sidebar.vocab', null, 'Vocabulary Notebook'),
          subtitle: context.t('spotlight.vocabSubtitle', null, 'Saved words & grammar expressions'),
          onTap: () => _handleQuickNav(2),
          colors: colors,
        ),
        _buildNavTile(
          icon: Icons.playlist_play,
          title: context.t('sidebar.playlists', null, 'Playlists'),
          subtitle: context.t('spotlight.playlistsSubtitle', null, 'Curated playlists & saved videos'),
          onTap: () => _handleQuickNav(3),
          colors: colors,
        ),
        _buildNavTile(
          icon: Icons.history,
          title: context.t('sidebar.history', null, 'Watch History'),
          subtitle: context.t('spotlight.historySubtitle', null, 'Resume recently watched videos'),
          onTap: () => _handleQuickNav(4),
          colors: colors,
        ),
        _buildNavTile(
          icon: Icons.settings_outlined,
          title: context.t('sidebar.settings', null, 'Settings'),
          subtitle: context.t('spotlight.settingsSubtitle', null, 'Furigana, font size & preferences'),
          onTap: _openSettings,
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required VocaColorPalette colors,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.bgSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: colors.textSecondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.textTertiary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
