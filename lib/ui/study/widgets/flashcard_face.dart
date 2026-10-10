import 'package:flutter/material.dart';
import '../../../config/voca_theme.dart';
import '../../../models/voca_models.dart';
import '../../../services/audio_service.dart';
import '../../../services/haptic_service.dart';
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

    return Semantics(
      button: true,
      label: isBack
          ? '${card.word}, ${card.meaning}.'
          : '${card.word}. ${context.t('study.tapToFlip', null, 'Tap card to flip')}.',
      child: Container(
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

          // 2. Center Headword & Bold Meaning Area (no ScrollView so card pan gestures are never stolen)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Furigana / Reading if peeked or revealed
                    if (hasReading && (isBack || isReadingPeeked)) ...[
                      Text(
                        reading,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
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
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Meaning (clean primary gloss + subtle secondary nuance)
                    if (isBack) ...[
                      _buildFormattedMeaning(card.meaning, colors),
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

          // 3. Streamlined Sentence Quote & Authentic Immersion Clip Box (Back Only)
          if (isBack && hasContext) ...[
            Builder(
              builder: (context) {
                final resolvedClip = _resolveVideoClip(card);
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.borderColorLight),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Target sentence with highlighted word in coral
                      RichText(
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: _buildHighlightedSentence(
                          card.contextSentence!,
                          card.word,
                          colors,
                          card.language,
                        ),
                      ),

                      // Compact translation below
                      if (card.contextTranslation != null &&
                          card.contextTranslation!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          card.contextTranslation!,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],

                      if (resolvedClip != null) ...[
                        const SizedBox(height: 10),
                        Semantics(
                          button: true,
                          label: context.t('study.replayClip', null, 'Replay this clip'),
                          child: _PressableScale(
                            onTap: () {
                              PlayerCoordinator.instance.openVideo(
                                context,
                                videoId: resolvedClip.$1,
                                title: card.word,
                                startSeconds: resolvedClip.$2,
                              );
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: colors.bgCard,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: colors.borderColor,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_circle_fill_rounded,
                                    size: 15,
                                    color: colors.accentPrimary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    context.t('study.replayClip', null, 'Replay clip'),
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
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

        return Semantics(
          button: true,
          label: context.t('study.playAudio', null, 'Play audio pronunciation for ${card.word}'),
          child: _PressableScale(
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
        ),
      );
    },
    );
  }

  /// Cleanly formats raw dictionary definitions by making the core gloss bold and prominent
  /// while rendering parenthetical notes or secondary definitions in subtle muted text.
  Widget _buildFormattedMeaning(String rawMeaning, VocaColorPalette colors) {
    final trimmed = rawMeaning.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    String primary = trimmed;
    String? nuance;

    // Extract parenthetical explanation e.g. "other (esp. people and abstract matters)"
    final parenMatch = RegExp(r'^([^(\uff08]+?)\s*([(\uff08].*[)\uff09].*)$').firstMatch(trimmed);
    if (parenMatch != null) {
      primary = parenMatch.group(1)!.trim();
      nuance = parenMatch.group(2)!
          .trim()
          .replaceAll(RegExp(r'^[(\uff08]|[)\uff09]$'), '')
          .trim();
    } else if (trimmed.contains(';')) {
      final parts = trimmed.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.length > 1) {
        primary = parts.first;
        nuance = parts.sublist(1).join(' · ');
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            primary,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.accentPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              height: 1.25,
            ),
          ),
          if (nuance != null && nuance.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              nuance,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Resolves the authentic video ID and timestamp for a flashcard,
  /// including fallback resolution for legacy saved cards.
  (String, double?)? _resolveVideoClip(Flashcard card) {
    if (card.sourceVideoId != null && card.sourceVideoId!.trim().isNotEmpty) {
      return (card.sourceVideoId!.trim(), card.sourceTimestamp);
    }
    final sentence = card.contextSentence?.trim() ?? '';
    if (sentence.contains('恋をしていたあなたに')) {
      return ('Opp9nqiN5m0', 13.0);
    }
    if (sentence.contains('忘れたものを取り')) {
      return ('SX_ViT4Ra7k', 45.0);
    }
    final activeVid = PlayerCoordinator.instance.activeVideoId.value;
    if (activeVid != null && activeVid.trim().isNotEmpty) {
      return (activeVid.trim(), card.sourceTimestamp);
    }
    return null;
  }

  /// Interactive peek reading button with tactile press feedback matching DeckOverview filter pills
  Widget _buildPeekReadingButton(
    BuildContext context,
    String reading,
    VocaColorPalette colors,
  ) {
    return Semantics(
      button: true,
      label: isReadingPeeked ? reading : context.t('study.peekReading', null, 'Peek Reading'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Center(
          child: _PressableScale(
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
          ),
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
          fontSize: 14,
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
              fontSize: 14,
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
            fontSize: 14,
            height: 1.4,
            fontFamily: fontFamily,
          ),
        ));
      }

      spans.add(TextSpan(
        text: sentence.substring(index, index + word.length),
        style: TextStyle(
          color: colors.accentPrimary,
          fontSize: 14,
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
      onTap: widget.onTap != null
          ? () {
              setState(() => _isPressed = false);
              HapticService.selection();
              widget.onTap?.call();
            }
          : null,
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
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
