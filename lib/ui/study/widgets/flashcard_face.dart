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
  final VoidCallback? onMarkAsKnown;
  final bool isInteractive;

  const FlashcardFace({
    super.key,
    required this.card,
    required this.isBack,
    this.isReadingPeeked = false,
    this.onTogglePeekReading,
    this.onMarkAsKnown,
    this.isInteractive = true,
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Badges & Actions Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: POS tag & Stage badge
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (card.partOfSpeech != null &&
                        card.partOfSpeech!.trim().isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: colors.borderColorLight),
                        ),
                        child: Text(
                          _formatPartOfSpeech(card.partOfSpeech!),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(child: _buildStageBadge(context, card, colors)),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Right Actions: Watch Scene, Mark Known, Audio Speaker
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Video Scene Clip Button (Canonical lingua-tube top-action parity)
                  if (card.sourceVideoId != null &&
                      card.sourceVideoId!.isNotEmpty) ...[
                    _buildWatchSceneButton(context, card, colors),
                    const SizedBox(width: 5),
                  ],

                  // Mark Known Action (Quick graduation on both front and back)
                  if (onMarkAsKnown != null) ...[
                    _buildMarkKnownButton(context, card, colors),
                    const SizedBox(width: 5),
                  ],

                  // Audio Pronunciation Button with reactive soundwave animation
                  _buildAudioButton(card, colors),
                ],
              ),
            ],
          ),

          // 2. Center Headword & Meaning Section (Generous breathing room)
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- FRONT FACE: Active Recall ---
                    if (!isBack) ...[
                      // Headword (large, bold, CJK typography)
                      Text(
                        card.word,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          height: 1.2,
                          fontFamily: card.language == 'ja' ? 'Kosugi Maru' : null,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Peek Reading Button
                      if (hasReading) ...[
                        _buildPeekReadingButton(context, reading, colors),
                      ],
                    ],

                    // --- BACK FACE: Revealed Answer & Pronunciation ---
                    if (isBack) ...[
                      if (hasReading) ...[
                        Text(
                          reading,
                          style: TextStyle(
                            color: colors.accentPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        card.word,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          height: 1.2,
                          fontFamily: card.language == 'ja' ? 'Kosugi Maru' : null,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Clean Meaning Container
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.borderColorLight),
                        ),
                        child: Text(
                          card.meaning,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.accentPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.35,
                          ),
                        ),
                      ),
                      if (card.notes != null &&
                          card.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          card.notes!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 3. Sentence Quote at bottom (Authentic YouTube Subtitle Context)
          if (hasContext) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderColorLight),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isBack)
                    Text(
                      _buildMaskedSentence(card.contextSentence!, card.word),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    )
                  else ...[
                    RichText(
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      text: _buildHighlightedSentence(
                        card.contextSentence!,
                        card.word,
                        colors,
                      ),
                    ),
                    if (card.contextTranslation != null &&
                        card.contextTranslation!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        card.contextTranslation!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // 4. Subtle Bottom Gestures Hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isBack ? Icons.swipe_rounded : Icons.touch_app_outlined,
                size: 13,
                color: colors.textMuted,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  isBack
                      ? context.t('study.swipeHintShort', null,
                          'Swipe right: Good · left: Again')
                      : context.t('study.tapToFlip', null, 'Tap card to flip'),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Interactive peek reading button with tactile press feedback
  Widget _buildPeekReadingButton(
    BuildContext context,
    String reading,
    VocaColorPalette colors,
  ) {
    return _PressableScale(
      onTap: onTogglePeekReading,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isReadingPeeked
                ? colors.accentPrimary.withValues(alpha: 0.4)
                : colors.borderColorLight,
          ),
        ),
        child: isReadingPeeked
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    reading,
                    style: TextStyle(
                      color: colors.accentPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.visibility_off_outlined,
                      size: 14, color: colors.textMuted),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_outlined,
                      size: 13, color: colors.textMuted),
                  const SizedBox(width: 5),
                  Text(
                    context.t('study.peekReading', null, 'Xem cách đọc'),
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildWatchSceneButton(
    BuildContext context,
    Flashcard card,
    VocaColorPalette colors,
  ) {
    return _PressableScale(
      onTap: () {
        PlayerCoordinator.instance.openVideo(
          context,
          videoId: card.sourceVideoId!,
          title: card.word,
          startSeconds: card.sourceTimestamp,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: colors.accentPrimary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: colors.accentPrimary.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_fill_rounded,
                size: 12, color: colors.accentPrimary),
            const SizedBox(width: 3.5),
            Text(
              context.t('study.watchScene', null, 'Scene'),
              style: TextStyle(
                color: colors.accentPrimary,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkKnownButton(
    BuildContext context,
    Flashcard card,
    VocaColorPalette colors,
  ) {
    return _PressableScale(
      onTap: onMarkAsKnown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: colors.bgSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.borderColorLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 12, color: colors.wordKnownText),
            const SizedBox(width: 3),
            Text(
              context.t('study.markKnownShort', null, 'Known'),
              style: TextStyle(
                color: colors.wordKnownText,
                fontSize: 9.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isPlaying
                  ? colors.accentPrimary.withValues(alpha: 0.18)
                  : colors.bgSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isPlaying
                    ? colors.accentPrimary
                    : colors.borderColorLight,
                width: isPlaying ? 1.5 : 1.0,
              ),
              boxShadow: [
                if (isPlaying)
                  BoxShadow(
                    color: colors.accentPrimary.withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
              size: 15,
              color: colors.accentPrimary,
            ),
          ),
        );
      },
    );
  }

  String _buildMaskedSentence(String sentence, String word) {
    if (sentence.contains(word)) {
      return sentence.replaceAll(word, '[ _____ ]');
    }
    return sentence;
  }

  Widget _buildStageBadge(
    BuildContext context,
    Flashcard card,
    VocaColorPalette colors,
  ) {
    final normLevel = card.level.toLowerCase().trim();
    if (normLevel == 'known' || normLevel == 'mastered') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(
          color: colors.wordKnownBg,
          borderRadius: BorderRadius.circular(999),
          border:
              Border.all(color: colors.wordKnownText.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded,
                size: 10.5, color: colors.wordKnownText),
            const SizedBox(width: 3.5),
            Flexible(
              child: Text(
                context.t('study.known', null, 'Known'),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.wordKnownText,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (normLevel == 'learning') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
        decoration: BoxDecoration(
          color: colors.wordLearningBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: colors.wordLearningText.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_rounded,
                size: 10.5, color: colors.wordLearningText),
            const SizedBox(width: 3.5),
            Flexible(
              child: Text(
                context.t('study.learning', null, 'Learning'),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.wordLearningText,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: colors.wordNewBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.wordNewText.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_rounded, size: 10.5, color: colors.wordNewText),
          const SizedBox(width: 3.5),
          Flexible(
            child: Text(
              context.t('study.new', null, 'New'),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.wordNewText,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _buildHighlightedSentence(
      String sentence, String word, VocaColorPalette colors) {
    final spans = <TextSpan>[];
    final lowerSentence = sentence.toLowerCase();
    final lowerWord = word.toLowerCase();

    int start = 0;
    while (true) {
      final index = lowerSentence.indexOf(lowerWord, start);
      if (index == -1) {
        if (start < sentence.length) {
          spans.add(TextSpan(
            text: sentence.substring(start),
            style: TextStyle(
                color: colors.textSecondary, fontSize: 13, height: 1.4),
          ));
        }
        break;
      }

      if (index > start) {
        spans.add(TextSpan(
          text: sentence.substring(start, index),
          style: TextStyle(
              color: colors.textSecondary, fontSize: 13, height: 1.4),
        ));
      }

      spans.add(TextSpan(
        text: sentence.substring(index, index + word.length),
        style: TextStyle(
          color: colors.accentPrimary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          height: 1.4,
        ),
      ));

      start = index + word.length;
    }

    return TextSpan(children: spans);
  }

  String _formatPartOfSpeech(String pos) {
    final clean = pos.replaceAll(RegExp(r'[\[\]]'), '').trim();
    if (clean.length > 12) {
      return clean.substring(0, 12).toUpperCase();
    }
    return clean.toUpperCase();
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
