// lib/ui/video/transcript_view.dart

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../models/voca_models.dart';
import '../../state/app_state.dart';
import '../../state/player_state.dart';

class TranscriptView extends StatefulWidget {
  final VideoPlayerController controller;
  final void Function(double seconds) onSeek;
  final void Function(Token token) onTokenTap;
  final void Function(GrammarPattern pattern)? onGrammarTap;

  const TranscriptView({
    super.key,
    required this.controller,
    required this.onSeek,
    required this.onTokenTap,
    this.onGrammarTap,
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

  @override
  void initState() {
    super.initState();

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

  void _scrollToActiveCue(SubtitleCue active) {
    if (!mounted || !widget.controller.autoScrollTranscript.value) return;
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

      return Column(
        children: [
          // Transcript Header Bar: Search + Auto-Scroll Toggle + Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
            ),
            child: Row(
              children: [
                // Search Input Field
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      cursorColor: const Color(0xFF38BDF8),
                      decoration: InputDecoration(
                        hintText: 'Search transcript...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 12.5,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Colors.white38,
                          size: 18,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white54,
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
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isAutoScroll
                          ? const Color(0xFF0284C7).withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isAutoScroll
                            ? const Color(0xFF38BDF8).withOpacity(0.5)
                            : Colors.white10,
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
                              ? const Color(0xFF38BDF8)
                              : Colors.white38,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isAutoScroll ? 'Auto-scroll' : 'Manual',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isAutoScroll
                                ? const Color(0xFF38BDF8)
                                : Colors.white60,
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
                          color: Colors.white24,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No matching cues found'
                              : 'No transcript available',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
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
                      );
                    },
                  ),
          ),
        ],
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
            AppState.instance.activeLanguage.value,
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
            ? const Color(0xFF1E293B)
            : const Color(0xFF131D31).withOpacity(0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? const Color(0xFF38BDF8).withOpacity(0.4)
              : Colors.white.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF38BDF8).withOpacity(0.12),
                  blurRadius: 8,
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
          borderRadius: BorderRadius.circular(10),
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
                    color: isActive ? const Color(0xFF38BDF8) : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Timestamp Chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF38BDF8).withOpacity(0.15)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF38BDF8).withOpacity(0.4)
                          : Colors.white10,
                    ),
                  ),
                  child: Text(
                    _formatTimestamp(cue.start),
                    style: TextStyle(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: isActive
                          ? const Color(0xFF38BDF8)
                          : Colors.white60,
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
                                      ? Colors.white
                                      : Colors.white70,
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
                                      ? const Border(
                                          bottom: BorderSide(
                                            color: Colors.amberAccent,
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
                                            color: Colors.white60,
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
                                            ? Colors.amberAccent
                                            : (isActive
                                                ? Colors.white
                                                : Colors.white.withOpacity(0.85)),
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
                                ? Colors.white
                                : Colors.white.withOpacity(0.85),
                            fontSize: surfaceFontSize,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),

                      // Translation
                      if (showTranslation &&
                          cue.translation != null &&
                          cue.translation!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          cue.translation!,
                          style: TextStyle(
                            color: const Color(0xFF94A3B8),
                            fontSize: translationFontSize,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
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
                      ? const Color(0xFFF59E0B)
                      : (isActive ? Colors.white70 : Colors.white30),
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
