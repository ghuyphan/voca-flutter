import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../state/player_state.dart';
import '../sheets/dictionary_bottom_sheet.dart';
import '../sheets/grammar_bottom_sheet.dart';

/// FullscreenSubtitle Widget
///
/// Exact 1:1 pixel-perfect port of lingua-tube's `fullscreen-subtitle.component`:
/// - Frosted glass card with 12px backdrop blur and 10px rounded corners.
/// - Card sizes to FIT ITS CONTENT (`fit-content`), never expanding unnecessarily to full screen.
/// - Centered horizontal drag handle pill (`fs-drag-handle-bar`):
///   - Tap: Smoothly animates between bottom dock and top dock.
///   - Drag up/down: 120fps physics-driven gesture tracking using AnimationController
///     with inertia and auto-snapping on release.
/// - Adaptive controls clearance: Lifts cleanly above scrub bar and bottom controls
///   when [areControlsVisible] is true, rests closer to the bottom when hidden.
/// - Interactive word tokens:
///   - Ruby Furigana (Japanese) & Pinyin (Chinese) annotations above kanji/hanzi.
///   - Punctuation rendered non-interactive.
///   - 5-tier word status badges (new, learning, known, saved, grammar).
///   - Tapping any word pauses the video and opens [DictionaryBottomSheet] or [GrammarBottomSheet].
/// - Dual subtitles translation: Secondary translated line with animated pulsing dots loader.
class FullscreenSubtitle extends StatefulWidget {
  final VideoPlayerController controller;
  final YoutubePlayerController ytController;
  final bool areControlsVisible;

  const FullscreenSubtitle({
    super.key,
    required this.controller,
    required this.ytController,
    required this.areControlsVisible,
  });

  @override
  State<FullscreenSubtitle> createState() => _FullscreenSubtitleState();
}

class _FullscreenSubtitleState extends State<FullscreenSubtitle>
    with TickerProviderStateMixin {
  /// Position controller: 0.0 = Top dock, 1.0 = Bottom dock. Defaults to Bottom dock (1.0).
  late final AnimationController _positionAnim;
  late final AnimationController _dotsAnimController;
  final ValueNotifier<bool> _isDragging = ValueNotifier<bool>(false);

  SubtitleCue? _lastActiveCue;
  double _availableHeight = 360.0;

  @override
  void initState() {
    super.initState();
    _positionAnim = AnimationController(
      vsync: this,
      value: 1.0,
      duration: const Duration(milliseconds: 300),
    );

    _dotsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _positionAnim.dispose();
    _dotsAnimController.dispose();
    _isDragging.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    _positionAnim.stop();
    _isDragging.value = true;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_availableHeight <= 0) return;
    // Map vertical pixel delta to change in normalized position (0.0 top to 1.0 bottom)
    final travelDistance = math.max(120.0, _availableHeight * 0.55);
    final deltaNormalized = details.delta.dy / travelDistance;
    _positionAnim.value = (_positionAnim.value + deltaNormalized).clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails details) {
    _isDragging.value = false;
    final velocity = details.primaryVelocity ?? 0.0;

    double target;
    if (velocity < -250) {
      // Flinging up -> Top dock
      target = 0.0;
    } else if (velocity > 250) {
      // Flinging down -> Bottom dock
      target = 1.0;
    } else {
      // Released without strong fling -> Snap to closest dock
      target = _positionAnim.value < 0.5 ? 0.0 : 1.0;
    }

    _positionAnim.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleDock() {
    final target = _positionAnim.value < 0.5 ? 1.0 : 0.0;
    _positionAnim.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final subtitlesVisible = widget.controller.subtitlesVisible.value;
      final activeCue = widget.controller.activeCue.value;

      if (activeCue != null) {
        _lastActiveCue = activeCue;
      }

      // Preserve last active cue during drag so silence between cues never causes card to unmount mid-drag
      final displayCue = activeCue ?? (_isDragging.value ? _lastActiveCue : null);

      if (!subtitlesVisible || displayCue == null) {
        return const SizedBox.shrink();
      }

      final colors = context.vocaColors;
      final showFurigana = widget.controller.showFurigana.value;
      final showTranslation = widget.controller.showTranslation.value;
      final subtitleSize = widget.controller.subtitleSize.value;
      final isDualSubLoading = widget.controller.isDualSubLoading.value;
      final grammarMatches = widget.controller.activeGrammarMatches.value;

      // Font sizing scale (1:1 with CSS tokens)
      double surfaceFontSize;
      double rubyFontSize;
      double translationFontSize;
      switch (subtitleSize) {
        case SubtitleSize.small:
          surfaceFontSize = 15.0;
          rubyFontSize = 9.5;
          translationFontSize = 12.5;
          break;
        case SubtitleSize.medium:
          surfaceFontSize = 18.0;
          rubyFontSize = 11.0;
          translationFontSize = 14.5;
          break;
        case SubtitleSize.large:
          surfaceFontSize = 22.0;
          rubyFontSize = 12.5;
          translationFontSize = 17.0;
          break;
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          _availableHeight = constraints.maxHeight;
          final availableWidth = constraints.maxWidth;

          // Resting dock clearance paddings
          final topPadding = widget.areControlsVisible ? 54.0 : 18.0;
          final bottomPadding = widget.areControlsVisible ? 82.0 : 20.0;

          return AnimatedPadding(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.only(
              top: topPadding,
              bottom: bottomPadding,
              left: 16.0,
              right: 16.0,
            ),
            child: AnimatedBuilder(
              animation: _positionAnim,
              builder: (context, child) {
                // Lerp alignment from -1.0 (top) to 1.0 (bottom)
                final alignY = -1.0 + (_positionAnim.value * 2.0);

                return Align(
                  key: const Key('fullscreen_subtitle_align'),
                  alignment: Alignment(0.0, alignY),
                  child: child,
                );
              },
              child: IntrinsicWidth(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 80.0,
                    maxWidth: math.min(availableWidth * 0.90, 840.0),
                    maxHeight: math.min(constraints.maxHeight * 0.45, 220.0),
                  ),
                  child: _buildSubtitleCard(
                    context: context,
                    cue: displayCue,
                    colors: colors,
                    showFurigana: showFurigana,
                    showTranslation: showTranslation,
                    isDualSubLoading: isDualSubLoading,
                    grammarMatches: grammarMatches,
                    surfaceFontSize: surfaceFontSize,
                    rubyFontSize: rubyFontSize,
                    translationFontSize: translationFontSize,
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildSubtitleCard({
    required BuildContext context,
    required SubtitleCue cue,
    required VocaColorPalette colors,
    required bool showFurigana,
    required bool showTranslation,
    required bool isDualSubLoading,
    required List<GrammarMatch> grammarMatches,
    required double surfaceFontSize,
    required double rubyFontSize,
    required double translationFontSize,
  }) {
    final grammarTokenMap = <int, GrammarPattern>{};
    for (final m in grammarMatches) {
      for (final idx in m.tokenIndices) {
        grammarTokenMap[idx] = m.pattern;
      }
    }

    final hasTokens = cue.tokens.isNotEmpty;

    return ValueListenableBuilder<bool>(
      valueListenable: _isDragging,
      builder: (context, isDragging, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(10, 12, 18, 0.58),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDragging
                      ? colors.accentPrimary.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.08),
                  width: 1.0,
                ),
                boxShadow: [
                  if (isDragging) ...[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 48,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: colors.accentPrimary.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ] else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Centered Horizontal Drag Handle Bar
                  _buildDragHandle(colors, isDragging),

                  // 2. Subtitle Content (Word tokens with ruby + secondary translation)
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 9),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Primary Line: Interactive Word Tokens
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 1.0,
                                      vertical: 2.0,
                                    ),
                                    child: Text(
                                      token.surface,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: surfaceFontSize,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  );
                                }

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _handleWordTap(
                                      context: context,
                                      token: token,
                                      grammarPattern: grammarPattern,
                                      cue: cue,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                    splashColor: Colors.white.withValues(alpha: 0.2),
                                    highlightColor: Colors.white.withValues(alpha: 0.12),
                                    child: _buildTokenChip(
                                      token: token,
                                      grammarPattern: grammarPattern,
                                      surfaceFontSize: surfaceFontSize,
                                      rubyFontSize: rubyFontSize,
                                      showFurigana: showFurigana,
                                      colors: colors,
                                    ),
                                  ),
                                );
                              }).toList(),
                            )
                          else
                            Text(
                              cue.text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: surfaceFontSize,
                                fontWeight: FontWeight.w600,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),

                          // Secondary Line: Dual Subtitle Translation with subtle animation
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            child: showTranslation
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: AnimatedOpacity(
                                      duration: const Duration(milliseconds: 180),
                                      opacity: showTranslation ? 1.0 : 0.0,
                                      curve: Curves.easeOut,
                                      child: (isDualSubLoading &&
                                              (cue.translation == null || cue.translation!.isEmpty))
                                          ? Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                                              child: _buildAnimatedDots(Colors.white.withValues(alpha: 0.7)),
                                            )
                                          : (cue.translation != null &&
                                                  cue.translation!.trim().isNotEmpty &&
                                                  cue.translation!.trim() != cue.text.trim())
                                              ? Text(
                                                  cue.translation!,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.85),
                                                    fontSize: translationFontSize,
                                                    fontWeight: FontWeight.w400,
                                                    height: 1.35,
                                                    shadows: const [
                                                      Shadow(
                                                        color: Colors.black,
                                                        blurRadius: 4,
                                                        offset: Offset(0, 1),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
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

  Widget _buildDragHandle(VocaColorPalette colors, bool isDragging) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleDock,
      onVerticalDragStart: _onDragStart,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 5),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: isDragging ? 44.0 : 32.0,
            height: 3.5,
            decoration: BoxDecoration(
              color: isDragging
                  ? colors.accentPrimary
                  : Colors.white.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                if (isDragging)
                  BoxShadow(
                    color: colors.accentPrimary.withValues(alpha: 0.6),
                    blurRadius: 8,
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
              ],
            ),
          ),
        ),
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
    Color textColor = Colors.white;
    Color? chipBgColor;
    Border? chipBorder;
    TextDecoration? textDecoration;
    Color? decorationColor;

    if (isGrammar) {
      textColor = Colors.white;
      chipBgColor = colors.colorGrammar.withValues(alpha: 0.18);
      chipBorder = Border.all(
        color: colors.colorGrammar.withValues(alpha: 0.55),
        width: 1.0,
      );
      textDecoration = TextDecoration.underline;
      decorationColor = colors.colorGrammar;
    } else if (token.level == 'new') {
      textColor = colors.wordNewText;
      chipBgColor = colors.wordNewBg;
      chipBorder = Border.all(
        color: colors.wordNewText.withValues(alpha: 0.35),
        width: 1.0,
      );
    } else if (token.level == 'learning') {
      textColor = colors.wordLearningText;
      chipBgColor = colors.wordLearningBg;
      chipBorder = Border.all(
        color: colors.wordLearningText.withValues(alpha: 0.35),
        width: 1.0,
      );
    } else if (token.level == 'known') {
      textColor = colors.wordKnownText;
      chipBgColor = colors.wordKnownBg;
      chipBorder = Border.all(
        color: colors.wordKnownText.withValues(alpha: 0.35),
        width: 1.0,
      );
    } else if (token.isSaved) {
      textColor = colors.accentPrimary;
      chipBgColor = colors.accentPrimary.withValues(alpha: 0.22);
      chipBorder = Border.all(
        color: colors.accentPrimary.withValues(alpha: 0.4),
        width: 1.0,
      );
      textDecoration = TextDecoration.underline;
      decorationColor = colors.accentPrimary;
    }

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
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: rubyFontSize,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                      height: 1.15,
                      shadows: const [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
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
                  shadows: const [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
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
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: rubyFontSize,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
                height: 1.15,
                shadows: const [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
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
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
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
          shadows: const [
            Shadow(
              color: Colors.black,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (chipBorder != null || chipBgColor != null) ? 4.0 : 2.5,
        vertical: (chipBorder != null || chipBgColor != null) ? 2.0 : 1.0,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 1.0),
      decoration: BoxDecoration(
        color: chipBgColor,
        borderRadius: BorderRadius.circular(5),
        border: chipBorder,
      ),
      child: content,
    );
  }

  Future<void> _handleWordTap({
    required BuildContext context,
    required Token token,
    required GrammarPattern? grammarPattern,
    required SubtitleCue cue,
  }) async {
    widget.controller.acquirePauseLock(
      'dictionary',
      onPause: () => widget.ytController.pauseVideo(),
    );

    try {
      if (grammarPattern != null) {
        await GrammarBottomSheet.show(context, grammarPattern);
      } else {
        await DictionaryBottomSheet.show(
          context,
          token: token,
          sourceLang: widget.controller.activeLanguage.value,
          contextSentence: cue.text,
          contextTranslation: cue.translation,
        );
      }
    } finally {
      widget.controller.releasePauseLock(
        'dictionary',
        onResume: () => widget.ytController.playVideo(),
      );
    }
  }

  Widget _buildAnimatedDots(Color color) {
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
              width: 5.5,
              height: 5.5,
              decoration: BoxDecoration(
                color: color.withValues(alpha: opacity.clamp(0.2, 1.0)),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
