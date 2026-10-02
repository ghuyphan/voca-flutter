import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/i18n_service.dart';
import '../../state/app_state.dart';
import '../../state/player_state.dart';
import '../../utils/video_format_utils.dart';
import '../sheets/dictionary_bottom_sheet.dart';
import '../sheets/grammar_bottom_sheet.dart';
import '../sheets/practice_sheet.dart';
import '../sheets/saved_words_sheet.dart';
import '../sheets/subtitle_options_sheet.dart';

/// SubtitlePanel Widget
///
/// Exact 1:1 pixel-perfect port of lingua-tube's `.subtitle-panel`:
/// Unified container comprising:
/// 1. `.current-subtitle`: Fixed-height display of active cue with interactive
///    Ruby Furigana/Pinyin tokens, grammar pattern highlights, SRS level badges,
///    secondary translated subtitle line, and loading/waiting states.
/// 2. `.subtitle-list`: Scrollable list of cues with clean timestamps, text,
///    active accent indicator bar, past dimmed cues, auto-scrolling,
///    and "Jump to current" floating sync button.
/// 3. `.subtitle-controls`: 4-pill bottom toolbar ([Loop 1/3], [Added (count)], [Quiz], [Options]).
class SubtitlePanel extends StatefulWidget {
  final VideoPlayerController controller;
  final YoutubePlayerController ytController;
  final void Function(double seconds) onSeek;

  const SubtitlePanel({
    super.key,
    required this.controller,
    required this.ytController,
    required this.onSeek,
  });

  @override
  State<SubtitlePanel> createState() => _SubtitlePanelState();
}

class _SubtitlePanelState extends State<SubtitlePanel>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _cueKeys = {};
  late final EffectCleanup _activeCueCleanup;
  late final AnimationController _dotsAnimController;
  bool _isScrolledAway = false;

  @override
  void initState() {
    super.initState();

    _dotsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _scrollController.addListener(_onListScroll);

    _activeCueCleanup = effect(() {
      final active = widget.controller.activeCue.value;
      final autoScroll = widget.controller.autoScrollTranscript.value;
      if (active != null && autoScroll && !_isScrolledAway) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToActiveCue(active);
        });
      }
    });

    // Load saved words count for this video session
    _loadSavedWordsCount();
  }

  Future<void> _loadSavedWordsCount() async {
    try {
      final cards = await AppState.instance.supabaseService
          .getVocabularyCards(language: AppState.instance.activeLanguage.value);
      if (mounted) {
        widget.controller.savedWordCount.value = cards.length;
      }
    } catch (_) {}
  }

  void _onListScroll() {
    if (!_scrollController.hasClients) return;
    final active = widget.controller.activeCue.value;
    if (active == null) {
      if (_isScrolledAway) setState(() => _isScrolledAway = false);
      return;
    }
    final allCues = widget.controller.cues.value;
    final index = allCues.indexOf(active);
    if (index == -1) return;

    // Approximate row height ~48px
    final estimatedTarget = (index * 48.0)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    final diff = (_scrollController.offset - estimatedTarget).abs();
    final isAway = diff > 140.0;
    if (isAway != _isScrolledAway) {
      setState(() {
        _isScrolledAway = isAway;
      });
    }
  }

  void _scrollToActiveCue(SubtitleCue active, {bool force = false}) {
    if (!mounted) return;
    if (force) {
      setState(() => _isScrolledAway = false);
    }
    if (!force && !widget.controller.autoScrollTranscript.value) return;
    if (!_scrollController.hasClients) return;

    final allCues = widget.controller.cues.value;
    final index = allCues.indexOf(active);
    if (index == -1) return;

    final key = _cueKeys[index];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        alignment: 0.35,
      );
    } else {
      final maxExtent = _scrollController.position.maxScrollExtent;
      final target = (index * 48.0).clamp(0.0, maxExtent);
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _activeCueCleanup();
    _dotsAnimController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // SECTION 1: CURRENT SUBTITLE (Top of panel)
  // ===========================================================================
  Widget _buildCurrentSubtitle({
    required SubtitleCue? activeCue,
    required List<GrammarMatch> grammarMatches,
    required bool showFurigana,
    required bool showTranslation,
    required SubtitleSize subtitleSize,
    required bool isTranslating,
    required VocaColorPalette colors,
    required bool isDark,
  }) {
    // Height matching lingua-tube: 8.5rem (136px) or 10.5rem (168px) with dual subs
    final containerHeight = showTranslation ? 148.0 : 124.0;

    return Container(
      height: containerHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border(
          bottom: BorderSide(color: colors.borderColor, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Center(
        child: activeCue != null
            ? _buildActiveCueBody(
                cue: activeCue,
                grammarMatches: grammarMatches,
                showFurigana: showFurigana,
                showTranslation: showTranslation,
                subtitleSize: subtitleSize,
                isTranslating: isTranslating,
                colors: colors,
                isDark: isDark,
              )
            : _buildWaitingOrLoadingState(colors),
      ),
    );
  }

  Widget _buildActiveCueBody({
    required SubtitleCue cue,
    required List<GrammarMatch> grammarMatches,
    required bool showFurigana,
    required bool showTranslation,
    required SubtitleSize subtitleSize,
    required bool isTranslating,
    required VocaColorPalette colors,
    required bool isDark,
  }) {
    // Dynamic font sizing
    double surfaceFontSize;
    double rubyFontSize;
    double translationFontSize;
    switch (subtitleSize) {
      case SubtitleSize.small:
        surfaceFontSize = 16.0;
        rubyFontSize = 10.0;
        translationFontSize = 13.0;
        break;
      case SubtitleSize.medium:
        surfaceFontSize = 19.5;
        rubyFontSize = 11.5;
        translationFontSize = 14.5;
        break;
      case SubtitleSize.large:
        surfaceFontSize = 23.0;
        rubyFontSize = 13.0;
        translationFontSize = 16.5;
        break;
    }

    final grammarTokenMap = <int, GrammarPattern>{};
    for (final m in grammarMatches) {
      for (final idx in m.tokenIndices) {
        grammarTokenMap[idx] = m.pattern;
      }
    }

    final hasTokens = cue.tokens.isNotEmpty;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Primary Line: Interactive Word Tokens with Ruby/Pinyin
          if (hasTokens)
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 3.5,
              runSpacing: 4.0,
              children: cue.tokens.asMap().entries.map((entry) {
                final idx = entry.key;
                final token = entry.value;
                final grammarPattern = grammarTokenMap[idx];

                if (token.isPunctuation) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      token.surface,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: surfaceFontSize,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                }

                return InkWell(
                  onTap: () {
                    widget.ytController.pauseVideo();
                    if (grammarPattern != null) {
                      GrammarBottomSheet.show(context, grammarPattern);
                    } else {
                      DictionaryBottomSheet.show(
                        context,
                        token: token,
                        sourceLang: AppState.instance.activeLanguage.value,
                        contextSentence: cue.text,
                        contextTranslation: cue.translation,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: _buildTokenChip(
                    token: token,
                    grammarPattern: grammarPattern,
                    surfaceFontSize: surfaceFontSize,
                    rubyFontSize: rubyFontSize,
                    showFurigana: showFurigana,
                    colors: colors,
                  ),
                );
              }).toList(),
            )
          else
            Text(
              cue.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: surfaceFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),

          // 2. Secondary Line: Dual Subtitle Translation (Pic 3: 14.5px, regular font, centered)
          if (showTranslation) ...[
            const SizedBox(height: 6),
            if (isTranslating && (cue.translation == null || cue.translation!.isEmpty))
              _buildAnimatedWaitingDots(colors.textMuted)
            else if (cue.translation != null && cue.translation!.isNotEmpty)
              Text(
                cue.translation!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: translationFontSize,
                  fontWeight: FontWeight.w400,
                  height: 1.35,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTokenChip({
    required Token token,
    required GrammarPattern? grammarPattern,
    required double surfaceFontSize,
    required double rubyFontSize,
    required bool showFurigana,
    required VocaColorPalette colors,
  }) {
    final isGrammar = grammarPattern != null;
    Color textColor = colors.textPrimary;
    Color? chipBgColor;
    Border? chipBorder;
    TextDecoration? textDecoration;
    Color? decorationColor;

    if (isGrammar) {
      textColor = colors.textPrimary;
      chipBgColor = const Color(0xFF2DD4BF).withOpacity(0.18);
      chipBorder = Border.all(
        color: const Color(0xFF2DD4BF).withOpacity(0.55),
        width: 1.0,
      );
      textDecoration = TextDecoration.underline;
      decorationColor = const Color(0xFF2DD4BF);
    } else if (token.level == 'new') {
      textColor = colors.wordNewText;
      chipBgColor = colors.wordNewBg;
      chipBorder = Border.all(color: colors.wordNewText.withOpacity(0.35));
    } else if (token.level == 'learning') {
      textColor = colors.wordLearningText;
      chipBgColor = colors.wordLearningBg;
      chipBorder = Border.all(color: colors.wordLearningText.withOpacity(0.35));
    } else if (token.level == 'known') {
      textColor = colors.wordKnownText;
      chipBgColor = colors.wordKnownBg;
      chipBorder = Border.all(color: colors.wordKnownText.withOpacity(0.35));
    } else if (token.isSaved) {
      textColor = colors.accentPrimary;
      textDecoration = TextDecoration.underline;
      decorationColor = colors.accentPrimary;
    }

    // Granular rubyParts rendering (Chinese Pinyin / Japanese Furigana)
    final tokenReading = token.reading ?? token.pinyin ?? token.romanization;
    final hasRuby = showFurigana && token.rubyParts != null && token.rubyParts!.isNotEmpty;
    final hasReading = showFurigana && tokenReading != null && tokenReading.isNotEmpty;

    Widget content;
    if (hasRuby) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: token.rubyParts!.map((part) {
          final hasPartReading = part.reading != null && part.reading!.isNotEmpty;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (hasPartReading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    part.reading!,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: rubyFontSize,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                      height: 1.15,
                    ),
                  ),
                )
              else if (showFurigana)
                SizedBox(
                  height: rubyFontSize * 1.15 + 1,
                ),
              Text(
                part.text,
                style: TextStyle(
                  color: textColor,
                  fontSize: surfaceFontSize,
                  fontWeight: isGrammar ? FontWeight.w600 : FontWeight.w500,
                  decoration: textDecoration,
                  decorationColor: decorationColor,
                  decorationThickness: 1.5,
                  height: 1.2,
                ),
              ),
            ],
          );
        }).toList(),
      );
    } else if (hasReading) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Text(
              tokenReading,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: rubyFontSize,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
                height: 1.15,
              ),
            ),
          ),
          Text(
            token.surface,
            style: TextStyle(
              color: textColor,
              fontSize: surfaceFontSize,
              fontWeight: isGrammar ? FontWeight.w600 : FontWeight.w500,
              decoration: textDecoration,
              decorationColor: decorationColor,
              decorationThickness: 1.5,
              height: 1.2,
            ),
          ),
        ],
      );
    } else {
      content = Text(
        token.surface,
        style: TextStyle(
          color: textColor,
          fontSize: surfaceFontSize,
          fontWeight: isGrammar ? FontWeight.w600 : FontWeight.w500,
          decoration: textDecoration,
          decorationColor: decorationColor,
          decorationThickness: 1.5,
          height: 1.2,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (chipBorder != null || chipBgColor != null) ? 4.0 : 2.0,
        vertical: (chipBorder != null || chipBgColor != null) ? 2.0 : 1.0,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 1.0),
      decoration: BoxDecoration(
        color: chipBgColor,
        borderRadius: BorderRadius.circular(4),
        border: chipBorder,
      ),
      child: content,
    );
  }

  Widget _buildWaitingOrLoadingState(VocaColorPalette colors) {
    if (widget.controller.isLoading.value) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.accentPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            context.t('subtitle.fetchingCaptions', null, 'Fetching captions...'),
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ],
      );
    }

    if (widget.controller.isAIGenerated.value && widget.controller.cues.value.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.colorDiamond,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            context.t('subtitle.generatingTranscript', null, 'Generating transcript...'),
            style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    // Default waiting state: 3 pulsing dots (exact match with Pic 2!)
    return _buildAnimatedWaitingDots(colors.textMuted);
  }

  Widget _buildAnimatedWaitingDots(Color color) {
    return AnimatedBuilder(
      animation: _dotsAnimController,
      builder: (context, _) {
        final val = _dotsAnimController.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = ((val + i * 0.25) % 1.0);
            final opacity = 0.25 + 0.75 * (0.5 - (phase - 0.5).abs()) * 2.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color.withOpacity(opacity.clamp(0.2, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  // ===========================================================================
  // SECTION 2: SUBTITLE LIST (Middle of panel)
  // ===========================================================================
  Widget _buildSubtitleList({
    required List<SubtitleCue> cues,
    required SubtitleCue? activeCue,
    required bool showTranslation,
    required VocaColorPalette colors,
    required bool isDark,
  }) {
    if (cues.isEmpty) {
      return Center(
        child: Text(
          context.t('subtitle.noSubtitlesLoaded', null, 'No subtitles loaded'),
          style: TextStyle(color: colors.textMuted, fontSize: 13),
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: cues.length,
          itemBuilder: (context, index) {
            final cue = cues[index];
            final isActive = activeCue == cue;
            final isPast = activeCue != null && cue.start < activeCue.start;

            _cueKeys[index] ??= GlobalKey();

            return _buildCueRow(
              key: _cueKeys[index]!,
              cue: cue,
              isActive: isActive,
              isPast: isPast,
              showTranslation: showTranslation,
              colors: colors,
              isDark: isDark,
            );
          },
        ),

        // Floating "Jump to current" pill when user scrolls away
        if (_isScrolledAway && activeCue != null)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: InkWell(
                onTap: () => _scrollToActiveCue(activeCue, force: true),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: colors.accentPrimary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${context.t('subtitle.jumpToCurrent', null, 'Jump to current')} (${formatVideoTime(activeCue.start)})',
                        style: TextStyle(
                          color: colors.accentPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCueRow({
    required Key key,
    required SubtitleCue cue,
    required bool isActive,
    required bool isPast,
    required bool showTranslation,
    required VocaColorPalette colors,
    required bool isDark,
  }) {
    final activeBg = isDark
        ? colors.accentPrimary.withOpacity(0.12)
        : colors.accentPrimary.withOpacity(0.07);

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? activeBg : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            widget.onSeek(cue.start);
            widget.controller.currentTime.value = cue.start;
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Indicator Accent Bar (Pic 3: 3px wide, 18px tall rounded bar)
                if (isActive)
                  Container(
                    width: 3,
                    height: 18,
                    decoration: BoxDecoration(
                      color: colors.accentPrimary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  )
                else
                  const SizedBox(width: 3),

                const SizedBox(width: 8),

                // Timestamp: 0:18, 0:20, 0:23 (monospace tabular figures)
                SizedBox(
                  width: 38,
                  child: Text(
                    formatVideoTime(cue.start),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? colors.accentPrimary
                          : colors.textMuted.withOpacity(isPast ? 0.55 : 0.85),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Cue Text & Translation Body
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cue.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive
                              ? colors.textPrimary
                              : colors.textSecondary.withOpacity(isPast ? 0.45 : 0.9),
                        ),
                      ),
                      if (showTranslation && cue.translation != null && cue.translation!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          cue.translation!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: isActive
                                ? colors.textSecondary
                                : colors.textMuted.withOpacity(isPast ? 0.45 : 0.8),
                          ),
                        ),
                      ],
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

  // ===========================================================================
  // SECTION 3: SUBTITLE CONTROLS TOOLBAR (Bottom of panel)
  // ===========================================================================
  Widget _buildSubtitleControlsToolbar({
    required bool isLooping,
    required bool isQuizActive,
    required int savedCount,
    required bool hasCues,
    required VocaColorPalette colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgCard,
        border: Border(
          top: BorderSide(color: colors.borderColor, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // 1. Loop Button: [🔁 Lặp câu]
          Expanded(
            child: _buildPillBtn(
              icon: isLooping ? Icons.repeat_one_rounded : Icons.repeat_rounded,
              label: context.t('subtitle.loop', null, 'Lặp câu'),
              isActive: isLooping,
              badgeText: isLooping ? '1' : null,
              onTap: hasCues ? () => widget.controller.toggleLoopCurrentCue() : null,
              colors: colors,
            ),
          ),
          const SizedBox(width: 6),

          // 2. Added Words Button: [🔖 2] (Label hidden on mobile when count > 0)
          Expanded(
            child: _buildPillBtn(
              icon: Icons.bookmark_border_rounded,
              label: savedCount > 0 ? '' : context.t('nav.added', null, 'Đã lưu'),
              badgeText: savedCount > 0 ? '$savedCount' : null,
              isActive: false,
              onTap: () {
                SavedWordsSheet.show(
                  context,
                  videoId: widget.controller.videoId,
                  language: AppState.instance.activeLanguage.value,
                );
              },
              colors: colors,
            ),
          ),
          const SizedBox(width: 6),

          // 3. Quiz Button: [⚔️ Luyện tập]
          Expanded(
            child: _buildPillBtn(
              icon: Icons.sports_kabaddi_rounded,
              label: context.t('quiz.short', null, 'Luyện tập'),
              isActive: isQuizActive,
              onTap: () {
                PracticeSheet.show(
                  context,
                  controller: widget.controller,
                  ytController: widget.ytController,
                );
              },
              colors: colors,
            ),
          ),
          const SizedBox(width: 6),

          // 4. Options Button: [⚙️ Tùy chọn]
          Expanded(
            child: _buildPillBtn(
              icon: Icons.settings_outlined,
              label: context.t('vocab.options', null, 'Tùy chọn'),
              isActive: false,
              onTap: () {
                SubtitleOptionsSheet.show(
                  context,
                  controller: widget.controller,
                  ytController: widget.ytController,
                );
              },
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillBtn({
    required IconData icon,
    required String label,
    required bool isActive,
    String? badgeText,
    VoidCallback? onTap,
    required VocaColorPalette colors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isActive ? colors.accentPrimary : colors.bgSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isActive ? colors.accentPrimary : colors.borderColor,
              width: 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: colors.accentPrimary.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isActive ? Colors.white : colors.textSecondary,
              ),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : colors.textSecondary,
                    ),
                  ),
                ),
              ],
              if (badgeText != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withOpacity(0.25)
                        : colors.bgHover,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isActive
                          ? Colors.white.withOpacity(0.4)
                          : colors.borderColor,
                    ),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MAIN BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final isDark = context.isDarkMode;

    return Watch((context) {
      final activeCue = widget.controller.activeCue.value;
      final allCues = widget.controller.cues.value;
      final grammarMatches = widget.controller.activeGrammarMatches.value;
      final showFurigana = widget.controller.showFurigana.value;
      final showTranslation = widget.controller.showTranslation.value;
      final subtitleSize = widget.controller.subtitleSize.value;
      final isDualTranslating = widget.controller.isDualSubLoading.value;
      final isLooping = widget.controller.isLoopingCue.value;
      final isQuizActive = widget.controller.isQuizActive.value;
      final savedCount = widget.controller.savedWordCount.value;

      return Container(
        margin: const EdgeInsets.fromLTRB(14, 2, 14, 10),
        decoration: BoxDecoration(
          color: colors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.borderColor, width: 1.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // 1. Current Subtitle (Top section)
            _buildCurrentSubtitle(
              activeCue: activeCue,
              grammarMatches: grammarMatches,
              showFurigana: showFurigana,
              showTranslation: showTranslation,
              subtitleSize: subtitleSize,
              isTranslating: isDualTranslating,
              colors: colors,
              isDark: isDark,
            ),

            // 2. Subtitle List (Flexible scroll area)
            Expanded(
              child: _buildSubtitleList(
                cues: allCues,
                activeCue: activeCue,
                showTranslation: showTranslation,
                colors: colors,
                isDark: isDark,
              ),
            ),

            // 3. Subtitle Controls Toolbar (Bottom section)
            _buildSubtitleControlsToolbar(
              isLooping: isLooping,
              isQuizActive: isQuizActive,
              savedCount: savedCount,
              hasCues: allCues.isNotEmpty,
              colors: colors,
            ),
          ],
        ),
      );
    });
  }
}
