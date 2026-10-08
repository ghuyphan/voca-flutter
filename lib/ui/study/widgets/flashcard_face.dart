import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/voca_theme.dart';
import '../../../models/voca_models.dart';
import '../../../services/audio_service.dart';
import '../../../services/i18n_service.dart';
import '../../../state/player_coordinator.dart';

/// Single unified, high-performance Flashcard Face widget for SRS immersion study.
/// Matches Voca's obsidian dark theme tokens, canonical lingua-tube layout,
/// authentic video subtitle context, and responsive typography without vertical clipping.
class FlashcardFace extends StatelessWidget {
  final Flashcard card;
  final bool isBack;
  final bool isReadingPeeked;
  final VoidCallback? onTogglePeekReading;
  final String againInterval;
  final String goodInterval;

  const FlashcardFace({
    super.key,
    required this.card,
    required this.isBack,
    this.isReadingPeeked = false,
    this.onTogglePeekReading,
    this.againInterval = '<1 min',
    this.goodInterval = '1 d',
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final reading = card.reading ?? card.pinyin ?? card.romanization;
    final hasReading = reading != null &&
        reading.trim().isNotEmpty &&
        reading.trim() != card.word.trim();
    final hasContext = card.contextSentence != null &&
        card.contextSentence!.trim().isNotEmpty;
    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Row: Stage Dots (Left) and Audio Speaker Button (Right) matching reference UI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(child: _buildStageDots(context, card, colors)),
              _buildAudioButton(card, colors),
            ],
          ),

          // 2. Center Headword & Bold Meaning Area
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Furigana / Reading if peeked or revealed
                    if (hasReading && (isBack || isReadingPeeked)) ...[
                      Text(
                        reading,
                        style: TextStyle(
                          color: colors.accentPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Headword (large, bold, CJK typography)
                    Text(
                      card.word,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.2,
                        fontFamily: switch (card.language.toLowerCase()) {
                          'ja' || 'japanese' => 'Kosugi Maru',
                          'zh' || 'chinese' => 'Noto Sans SC',
                          'ko' || 'korean' => 'Noto Sans KR',
                          _ => null,
                        },
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Meaning (prominent bold coral text, exactly like the screenshot!)
                    if (isBack) ...[
                      Text(
                        card.meaning,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.accentPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          height: 1.3,
                        ),
                      ),
                    ] else ...[
                      if (hasReading && !isReadingPeeked) ...[
                        _buildPeekReadingButton(context, reading, colors),
                      ] else ...[
                        Text(
                          context.t('study.tapToFlip', null, 'Tap card to flip'),
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 3. Sentence Quote & Authentic Immersion Clip Box
          if (hasContext) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderColorLight),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Japanese sentence with highlighted word in coral
                  RichText(
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    text: _buildHighlightedSentence(
                      card.contextSentence!,
                      card.word,
                      colors,
                      card.language,
                    ),
                  ),

                  // Translation below
                  if (card.contextTranslation != null &&
                      card.contextTranslation!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      card.contextTranslation!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // '▶ Replay this clip' Button
                  _PressableScale(
                    onTap: () {
                      if (card.sourceVideoId != null &&
                          card.sourceVideoId!.isNotEmpty) {
                        PlayerCoordinator.instance.openVideo(
                          context,
                          videoId: card.sourceVideoId!,
                          title: card.word,
                          startSeconds: card.sourceTimestamp,
                        );
                      } else {
                        AudioService.instance.playWord(
                          card.word,
                          language: card.language,
                          fallbackAudioUrl: card.audio,
                        );
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_fill_rounded,
                          size: 16,
                          color: colors.accentPrimary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          context.t('study.replayClip', null, 'Replay this clip'),
                          style: TextStyle(
                            color: colors.accentPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 4. Memory SRS Progress Section
          _buildMemoryProgressSection(context, card, colors),
        ],
      ),
    );
  }

  /// 4 Stage Dots + Stage Label matching the top left of the screenshot
  Widget _buildStageDots(
    BuildContext context,
    Flashcard card,
    VocaColorPalette colors,
  ) {
    final normLevel = card.level.toLowerCase().trim();
    final (dotsFilled, label, activeColor) = switch (normLevel) {
      'mastered' => (4, context.t('study.mastered', null, 'Mastered'), colors.wordMasteredText),
      'known' => (3, context.t('study.known', null, 'Known'), colors.wordKnownText),
      'learning' => (2, context.t('study.learning', null, 'Learning'), colors.wordLearningText),
      _ => (1, context.t('study.new', null, 'New'), colors.wordNewText),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (int i = 0; i < 4; i++) ...[
          Container(
            width: 6.0,
            height: 6.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < dotsFilled ? activeColor : colors.borderColorLight,
            ),
          ),
          if (i < 3) const SizedBox(width: 3.0),
        ],
        const SizedBox(width: 6.0),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: activeColor,
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  /// Circular speaker button matching the top right of the screenshot
  Widget _buildAudioButton(Flashcard card, VocaColorPalette colors) {
    return ValueListenableBuilder<String?>(
      valueListenable: AudioService.instance.currentPlaying,
      builder: (context, currentlyPlaying, _) {
        final isPlaying = currentlyPlaying == card.word.trim();

        return _PressableScale(
          onTap: () {
            AudioService.instance.playWord(
              card.word,
              language: card.language,
              fallbackAudioUrl: card.audio,
            );
          },
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.bgSurface,
                  border: Border.all(
                    color: isPlaying ? colors.accentPrimary : colors.borderColorLight,
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: isPlaying
                      ? _AudioWaveIndicator(color: colors.accentPrimary)
                      : Icon(
                          Icons.volume_up_rounded,
                          size: 19,
                          color: colors.accentPrimary,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Memory SRS Progress Section matching the bottom of the screenshot card
  Widget _buildMemoryProgressSection(
    BuildContext context,
    Flashcard card,
    VocaColorPalette colors,
  ) {
    final normLevel = card.level.toLowerCase().trim();
    final stageIndex = switch (normLevel) {
      'mastered' => 3,
      'known' => 2,
      'learning' => 1,
      _ => 0,
    };

    final stages = [
      context.t('study.new', null, 'New'),
      context.t('study.learning', null, 'Learning'),
      context.t('study.known', null, 'Known'),
      context.t('study.mastered', null, 'Mastered'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header: 'Memory' on left, '< 1 min → 1 d' on right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.t('study.memory', null, 'Memory'),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$againInterval → $goodInterval',
              style: TextStyle(
                color: colors.accentPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 4-Segment Progress Bar Track
        Row(
          children: List.generate(4, (i) {
            final isFilled = i <= stageIndex;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: i < 3 ? 3 : 0,
                  left: i > 0 ? 3 : 0,
                ),
                height: 7,
                decoration: BoxDecoration(
                  color: isFilled
                      ? colors.colorFire
                      : colors.borderColorLight,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 6),

        // Stage labels below each segment
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Text(
                stages[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: i == stageIndex ? colors.textSecondary : colors.textMuted,
                  fontSize: 10,
                  fontWeight: i == stageIndex ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Interactive peek reading button with tactile press feedback matching DeckOverview filter pills
  Widget _buildPeekReadingButton(
    BuildContext context,
    String reading,
    VocaColorPalette colors,
  ) {
    return _PressableScale(
      onTap: onTogglePeekReading,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isReadingPeeked
              ? colors.accentPrimary.withValues(alpha: 0.12)
              : colors.bgSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isReadingPeeked
                ? colors.accentPrimary.withValues(alpha: 0.45)
                : colors.borderColorLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isReadingPeeked
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 15,
              color: isReadingPeeked ? colors.accentPrimary : colors.textMuted,
            ),
            const SizedBox(width: 7),
            Text(
              isReadingPeeked
                  ? reading
                  : context.t('study.peekReading', null, 'Peek Reading'),
              style: TextStyle(
                color: isReadingPeeked ? colors.accentPrimary : colors.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextSpan _buildHighlightedSentence(
      String sentence, String word, VocaColorPalette colors, String language) {
    final spans = <TextSpan>[];
    final cleanWord = word.trim();
    final fontFamily = switch (language.toLowerCase()) {
      'ja' || 'japanese' => 'Kosugi Maru',
      'zh' || 'chinese' => 'Noto Sans SC',
      'ko' || 'korean' => 'Noto Sans KR',
      _ => null,
    };

    if (cleanWord.isEmpty || sentence.trim().isEmpty) {
      return TextSpan(
        text: sentence,
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 13,
          height: 1.4,
          fontFamily: fontFamily,
        ),
      );
    }
    final lowerSentence = sentence.toLowerCase();
    final lowerWord = cleanWord.toLowerCase();

    int start = 0;
    while (true) {
      final index = lowerSentence.indexOf(lowerWord, start);
      if (index == -1) {
        if (start < sentence.length) {
          spans.add(TextSpan(
            text: sentence.substring(start),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.4,
              fontFamily: fontFamily,
            ),
          ));
        }
        break;
      }

      if (index > start) {
        spans.add(TextSpan(
          text: sentence.substring(start, index),
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 13,
            height: 1.4,
            fontFamily: fontFamily,
          ),
        ));
      }

      spans.add(TextSpan(
        text: sentence.substring(index, index + word.length),
        style: TextStyle(
          color: colors.accentPrimary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          height: 1.4,
          fontFamily: fontFamily,
        ),
      ));

      start = index + word.length;
    }

    return TextSpan(children: spans);
  }
}

/// Lightweight pressable wrapper providing subtle tactile spring scale-down feedback on tap
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _PressableScale({required this.child, this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _isPressed = false);
              HapticFeedback.selectionClick();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _AudioWaveIndicator extends StatefulWidget {
  final Color color;
  const _AudioWaveIndicator({required this.color});

  @override
  State<_AudioWaveIndicator> createState() => _AudioWaveIndicatorState();
}

class _AudioWaveIndicatorState extends State<_AudioWaveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final t = _anim.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _bar(4.0 + (t * 7.0)),
            const SizedBox(width: 2),
            _bar(11.0 - (t * 6.0)),
            const SizedBox(width: 2),
            _bar(5.0 + (t * 8.0)),
          ],
        );
      },
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 2.2,
      height: height.clamp(3.0, 14.0),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
