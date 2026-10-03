// lib/ui/video/transcript_view.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../state/app_state.dart';
import '../../state/player_state.dart';
import '../../utils/video_format_utils.dart';
import '../widgets/voca_shimmer.dart';

class TranscriptView extends StatefulWidget {
  final VideoPlayerController controller;
  final void Function(double seconds) onSeek;
  final void Function(Token token) onTokenTap;
  final void Function(GrammarPattern pattern)? onGrammarTap;
  final bool isQuizMode;

  const TranscriptView({
    super.key,
    required this.controller,
    required this.onSeek,
    required this.onTokenTap,
    this.onGrammarTap,
    this.isQuizMode = false,
  });

  @override
  State<TranscriptView> createState() => _TranscriptViewState();
}

class _TranscriptViewState extends State<TranscriptView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final Map<int, GlobalKey> _cueKeys = {};
  late final EffectCleanup _activeCueCleanup;
  String _searchQuery = '';
  bool _isScrolledAway = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final active = widget.controller.activeCue.value;
      if (active == null) {
        if (_isScrolledAway) setState(() => _isScrolledAway = false);
        return;
      }
      final visibleCues = _getFilteredCues(widget.controller.cues.value);
      final index = visibleCues.indexOf(active);
      if (index == -1) return;
      final target = (index * 84.0).clamp(0.0, _scrollController.position.maxScrollExtent);
      final isAway = (_scrollController.offset - target).abs() > 180.0;
      if (isAway != _isScrolledAway) {
        setState(() {
          _isScrolledAway = isAway;
        });
      }
    });

    _activeCueCleanup = effect(() {
      final active = widget.controller.activeCue.value;
      final autoScroll = widget.controller.autoScrollTranscript.value;
      if (active != null && autoScroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToActiveCue(active);
        });
      }
    });

    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      if (q != _searchQuery) {
        setState(() {
          _searchQuery = q;
        });
      }
    });
  }

  @override
  void dispose() {
    _activeCueCleanup();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<SubtitleCue> _getFilteredCues(List<SubtitleCue> cues) {
    if (_searchQuery.isEmpty) return cues;
    return cues.where((c) {
      final inText = c.text.toLowerCase().contains(_searchQuery);
      final inTrans = c.translation?.toLowerCase().contains(_searchQuery) ?? false;
      return inText || inTrans;
    }).toList();
  }

  void _scrollToActiveCue(SubtitleCue active, {bool force = false}) {
    if (!mounted) return;
    if (_isScrolledAway) {
      setState(() => _isScrolledAway = false);
    }
    if (!force && !widget.controller.autoScrollTranscript.value) return;
    if (!_scrollController.hasClients) return;

    final visibleCues = _getFilteredCues(widget.controller.cues.value);
    final index = visibleCues.indexOf(active);
    if (index == -1) return;

    final key = _cueKeys[index];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignment: 0.25,
      );
    } else {
      final maxExtent = _scrollController.position.maxScrollExtent;
      final target = (index * 84.0).clamp(0.0, maxExtent);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  String _formatTimestamp(double seconds) {
    final totalSecs = seconds.floor();
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final allCues = widget.controller.cues.value;
      final activeCue = widget.controller.activeCue.value;
      final isLoopingCue = widget.controller.isLoopingCue.value;
      final loopingCue = widget.controller.loopingCue.value;
      final showFurigana = widget.controller.showFurigana.value;
      final showTranslation = widget.controller.showTranslation.value;
      final isAutoScroll = widget.controller.autoScrollTranscript.value;
      final subtitleSize = widget.controller.subtitleSize.value;

      final filteredCues = _getFilteredCues(allCues);
      final colors = context.vocaColors;

      return Container(
        color: colors.bgPrimary,
        child: Column(
          children: [
            // Transcript Header Bar: Search + Auto-Scroll Toggle + Count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.bgSecondary,
                border: Border(
                  bottom: BorderSide(color: colors.borderColor),
                ),
              ),
              child: Row(
                children: [
                  // Search Input Field
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.borderColor),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                        ),
                        cursorColor: colors.accentPrimary,
                        decoration: InputDecoration(
                          hintText: 'Search transcript...',
                          hintStyle: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12.5,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: colors.textMuted,
                            size: 18,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: colors.textMuted,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Auto-Scroll Toggle Chip
                  InkWell(
                    onTap: widget.controller.toggleAutoScroll,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isAutoScroll
                            ? colors.accentPrimarySoft
                            : colors.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isAutoScroll
                              ? colors.accentPrimary
                              : colors.borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAutoScroll
                                ? Icons.vertical_align_center_rounded
                                : Icons.vertical_align_bottom_rounded,
                            size: 16,
                            color: isAutoScroll
                                ? colors.accentPrimary
                                : colors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isAutoScroll ? 'Auto-scroll' : 'Manual',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isAutoScroll
                                  ? colors.accentPrimary
                                  : colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Transcript List or Empty State
            Expanded(
              child: filteredCues.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty
                                ? Icons.search_off_rounded
                                : Icons.subtitles_off_rounded,
                            color: colors.textMuted.withOpacity(0.5),
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No matching cues found'
                                : 'No transcript available',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          itemCount: filteredCues.length,
                          itemBuilder: (context, index) {
                            final cue = filteredCues[index];
                            final isActive = activeCue == cue;
                            final isLoopingThis = isLoopingCue && loopingCue == cue;

                            _cueKeys[index] ??= GlobalKey();

                            return _buildCueCard(
                              key: _cueKeys[index]!,
                              cue: cue,
                              isActive: isActive,
                              isLoopingThis: isLoopingThis,
                              showFurigana: showFurigana,
                              showTranslation: showTranslation,
                              subtitleSize: subtitleSize,
                              colors: colors,
                            );
                          },
                        ),
                        if (_isScrolledAway && activeCue != null)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.accentPrimary,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                                label: Text(
                                  'Jump to current (${formatVideoTime(activeCue.start)})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() => _isScrolledAway = false);
                                  _scrollToActiveCue(activeCue, force: true);
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCueCard({
    required Key key,
    required SubtitleCue cue,
    required bool isActive,
    required bool isLoopingThis,
    required bool showFurigana,
    required bool showTranslation,
    required SubtitleSize subtitleSize,
    required VocaColorPalette colors,
  }) {
    // Dynamic font sizing
    double surfaceFontSize;
    double rubyFontSize;
    double translationFontSize;
    switch (subtitleSize) {
      case SubtitleSize.small:
        surfaceFontSize = 14.5;
        rubyFontSize = 9.0;
        translationFontSize = 11.5;
        break;
      case SubtitleSize.medium:
        surfaceFontSize = 16.0;
        rubyFontSize = 10.0;
        translationFontSize = 13.0;
        break;
      case SubtitleSize.large:
        surfaceFontSize = 18.0;
        rubyFontSize = 11.5;
        translationFontSize = 14.5;
        break;
    }

    final grammarMatches = (cue.tokens.isNotEmpty)
        ? AppState.instance.grammarEngine.detectPatterns(
            cue.tokens,
            widget.controller.activeLanguage.value,
          )
        : const <GrammarMatch>[];

    final grammarTokenMap = <int, GrammarPattern>{};
    for (final m in grammarMatches) {
      for (final idx in m.tokenIndices) {
        grammarTokenMap[idx] = m.pattern;
      }
    }

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? colors.bgSurface
            : colors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? colors.accentPrimary.withOpacity(0.6)
              : colors.borderColor,
          width: 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: colors.accentPrimary.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            widget.onSeek(cue.start);
            widget.controller.currentTime.value = cue.start;
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active Accent Indicator Bar
                Container(
                  width: 3.5,
                  height: 36,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isActive ? colors.accentPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Timestamp Chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? colors.accentPrimarySoft
                        : colors.bgCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive
                          ? colors.accentPrimary.withOpacity(0.5)
                          : colors.borderColor,
                    ),
                  ),
                  child: Text(
                    _formatTimestamp(cue.start),
                    style: TextStyle(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: isActive
                          ? colors.accentPrimary
                          : colors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Main Cue Text & Secondary Translation
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.isQuizMode) ...[
                        Container(
                          width: 160,
                          height: 18,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.bgSecondary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        if (showTranslation) ...[
                          const SizedBox(height: 4),
                          Container(
                            width: 110,
                            height: 12,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.bgSecondary.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ] else ...[
                        // Tokens with Ruby furigana / Pinyin
                        if (cue.tokens.isNotEmpty)
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.end,
                            spacing: 2,
                            runSpacing: 2,
                            children: cue.tokens.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final token = entry.value;
                              final grammarPattern = grammarTokenMap[idx];

                              if (token.isPunctuation) {
                                return Text(
                                  token.surface,
                                  style: TextStyle(
                                    color: isActive
                                        ? colors.textPrimary
                                        : colors.textSecondary,
                                    fontSize: surfaceFontSize,
                                  ),
                                );
                              }

                              final ruby = token.reading ??
                                  token.pinyin ??
                                  token.romanization;

                              return InkWell(
                                onTap: () {
                                  if (grammarPattern != null &&
                                      widget.onGrammarTap != null) {
                                    widget.onGrammarTap!(grammarPattern);
                                  } else {
                                    widget.onTokenTap(token);
                                  }
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                                  decoration: BoxDecoration(
                                    border: grammarPattern != null
                                        ? Border(
                                            bottom: BorderSide(
                                              color: colors.colorGrammar,
                                              width: 2,
                                            ),
                                          )
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (showFurigana) ...[
                                        if (ruby != null)
                                          Text(
                                            ruby,
                                            style: TextStyle(
                                              color: colors.textMuted,
                                              fontSize: rubyFontSize,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: -0.2,
                                            ),
                                          )
                                        else
                                          SizedBox(height: rubyFontSize + 1),
                                      ],
                                      Text(
                                        token.surface,
                                        style: TextStyle(
                                          color: grammarPattern != null
                                              ? colors.colorGrammar
                                              : (isActive
                                                  ? colors.textPrimary
                                                  : colors.textPrimary.withOpacity(0.85)),
                                          fontSize: surfaceFontSize,
                                          fontWeight: isActive
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                        else
                          Text(
                            cue.text,
                            style: TextStyle(
                              color: isActive
                                  ? colors.textPrimary
                                  : colors.textPrimary.withOpacity(0.85),
                              fontSize: surfaceFontSize,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),

                        // Translation
                        if (showTranslation) ...[
                          if (cue.translation != null &&
                              cue.translation!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              cue.translation!,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: translationFontSize,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ] else if (widget.controller.isDualSubLoading.value) ...[
                            const SizedBox(height: 6),
                            VocaShimmer.line(width: 140, height: 12),
                          ],
                        ],
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Repeat / Loop Cue Button
                IconButton(
                  icon: Icon(
                    isLoopingThis
                        ? Icons.repeat_one_rounded
                        : Icons.replay_rounded,
                    size: 20,
                  ),
                  color: isLoopingThis
                      ? colors.accentPrimary
                      : (isActive ? colors.textPrimary : colors.textMuted),
                  tooltip: isLoopingThis
                      ? 'Stop looping this sentence'
                      : 'Loop this sentence',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: () {
                    if (isLoopingThis) {
                      widget.controller.setLoopCue(null);
                    } else {
                      widget.onSeek(cue.start);
                      widget.controller.currentTime.value = cue.start;
                      widget.controller.setLoopCue(cue);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
