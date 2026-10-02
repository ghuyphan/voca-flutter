// lib/ui/widgets/interactive_subtitle_view.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';

class InteractiveSubtitleView extends StatefulWidget {
  final SubtitleCue? cue;
  final List<GrammarMatch> grammarMatches;
  final Function(Token token) onTokenTap;
  final Function(GrammarPattern pattern)? onGrammarTap;
  final bool showFurigana;
  final bool showTranslation;
  final SubtitleSize subtitleSize;

  // Visual state flags
  final bool isTranslating;
  final bool isAIGenerating;
  final bool isLoading;
  final String? statusMessage;
  final String? errorCode;
  final String? errorMessage;
  final int diamonds;
  final VoidCallback? onTriggerAI;
  final String? switchLanguageName;
  final VoidCallback? onSwitchLanguage;
  final bool subtitlesEnabled;
  final bool hasSubtitles;
  final bool showCoachmark;
  final VoidCallback? onDismissCoachmark;
  final bool isLooping;

  const InteractiveSubtitleView({
    super.key,
    this.cue,
    this.grammarMatches = const [],
    required this.onTokenTap,
    this.onGrammarTap,
    this.showFurigana = true,
    this.showTranslation = true,
    this.subtitleSize = SubtitleSize.medium,
    this.isTranslating = false,
    this.isAIGenerating = false,
    this.isLoading = false,
    this.statusMessage,
    this.errorCode,
    this.errorMessage,
    this.diamonds = 0,
    this.onTriggerAI,
    this.switchLanguageName,
    this.onSwitchLanguage,
    this.subtitlesEnabled = true,
    this.hasSubtitles = false,
    this.showCoachmark = false,
    this.onDismissCoachmark,
    this.isLooping = false,
  });

  @override
  State<InteractiveSubtitleView> createState() => _InteractiveSubtitleViewState();
}

class _InteractiveSubtitleViewState extends State<InteractiveSubtitleView> {
  bool _dismissedCoachmark = false;

  double get _surfaceFontSize {
    switch (widget.subtitleSize) {
      case SubtitleSize.small:
        return 16.0;
      case SubtitleSize.medium:
        return 20.0;
      case SubtitleSize.large:
        return 24.0;
    }
  }

  double get _rubyFontSize {
    switch (widget.subtitleSize) {
      case SubtitleSize.small:
        return 9.5;
      case SubtitleSize.medium:
        return 11.0;
      case SubtitleSize.large:
        return 13.0;
    }
  }

  double get _translationFontSize {
    switch (widget.subtitleSize) {
      case SubtitleSize.small:
        return 12.5;
      case SubtitleSize.medium:
        return 14.5;
      case SubtitleSize.large:
        return 16.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final isDark = context.isDarkMode;
    final double targetHeight = widget.showTranslation ? 154.0 : 138.0;

    return Container(
      height: targetHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard.withOpacity(isDark ? 0.95 : 0.98),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Coachmark (if enabled and not locally dismissed)
          if (widget.showCoachmark && !_dismissedCoachmark) _buildCoachmark(colors),

          // 2. Main Content based on state
          Expanded(
            child: Center(
              child: _buildStateContent(context, colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachmark(VocaColorPalette colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.accentPrimarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.accentPrimary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lightbulb_rounded,
            size: 14,
            color: colors.accentPrimary,
          ),
          const SizedBox(width: 6),
          Text(
            'Tap any word to translate & save',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () {
              setState(() {
                _dismissedCoachmark = true;
              });
              widget.onDismissCoachmark?.call();
            },
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateContent(BuildContext context, VocaColorPalette colors) {
    // A. Subtitles turned off
    if (!widget.subtitlesEnabled) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.subtitles_off_rounded, size: 24, color: colors.textMuted),
          const SizedBox(height: 6),
          Text(
            'Subtitles turned off',
            style: TextStyle(color: colors.textMuted, fontSize: 13),
          ),
        ],
      );
    }

    // B. AI Generating state
    if (widget.isAIGenerating) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: colors.accentPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Generating transcript...',
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Using Whisper AI',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ],
      );
    }

    // C. Loading captions state
    if (widget.isLoading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: colors.accentPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            widget.statusMessage ?? 'Fetching captions...',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ],
      );
    }

    // D. Error state: NO_NATIVE
    if (widget.errorCode == 'NO_NATIVE') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No captions available',
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            'AI transcription available',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: widget.onTriggerAI,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.accentPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: Text(
              widget.diamonds > 0 ? 'Use AI Transcription (${widget.diamonds})' : 'Use AI Transcription',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    // E. Error state: UNSUPPORTED_LANGUAGE
    if (widget.errorCode == 'UNSUPPORTED_LANGUAGE') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Language not supported',
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          if (widget.switchLanguageName != null)
            ElevatedButton(
              onPressed: widget.onSwitchLanguage,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: Text(
                'Switch to ${widget.switchLanguageName}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      );
    }

    // F. Waiting state (between cues)
    if (widget.cue == null) {
      return widget.hasSubtitles
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WaitingDot(delayMs: 0, color: colors.textMuted),
                const SizedBox(width: 6),
                _WaitingDot(delayMs: 200, color: colors.textMuted),
                const SizedBox(width: 6),
                _WaitingDot(delayMs: 400, color: colors.textMuted),
              ],
            )
          : Text(
              'Listening...',
              style: TextStyle(color: colors.textMuted, fontSize: 14),
            );
    }

    // G. Active Cue Subtitles display
    return _buildCueContent(widget.cue!, colors);
  }

  Widget _buildCueContent(SubtitleCue activeCue, VocaColorPalette colors) {
    final grammarTokenMap = <int, GrammarPattern>{};
    for (final m in widget.grammarMatches) {
      for (final idx in m.tokenIndices) {
        grammarTokenMap[idx] = m.pattern;
      }
    }

    final hasTokens = activeCue.tokens.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Primary Subtitle (Tokens or raw text)
        if (hasTokens)
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 3,
            runSpacing: 4,
            children: activeCue.tokens.asMap().entries.map((entry) {
              final idx = entry.key;
              final token = entry.value;
              final grammarPattern = grammarTokenMap[idx];

              if (token.isPunctuation) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    token.surface,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: _surfaceFontSize,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              }

              return InkWell(
                onTap: () {
                  if (grammarPattern != null && widget.onGrammarTap != null) {
                    widget.onGrammarTap!(grammarPattern);
                  } else {
                    widget.onTokenTap(token);
                  }
                },
                borderRadius: BorderRadius.circular(4),
                child: _buildTokenWidget(token, grammarPattern, colors),
              );
            }).toList(),
          )
        else
          Text(
            activeCue.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: _surfaceFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),

        // Secondary translated subtitle
        if (widget.showTranslation) ...[
          const SizedBox(height: 6),
          if (widget.isTranslating && (activeCue.translation == null || activeCue.translation!.isEmpty))
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WaitingDot(delayMs: 0, color: colors.textMuted),
                const SizedBox(width: 4),
                _WaitingDot(delayMs: 200, color: colors.textMuted),
                const SizedBox(width: 4),
                _WaitingDot(delayMs: 400, color: colors.textMuted),
              ],
            )
          else if (activeCue.translation != null && activeCue.translation!.isNotEmpty)
            Text(
              activeCue.translation!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: _translationFontSize,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildTokenWidget(Token token, GrammarPattern? grammarPattern, VocaColorPalette colors) {
    // Style hierarchy: Grammar > SRS levels > Saved words
    Color textColor = colors.textPrimary;
    Color? bgColor;
    Border? border;

    if (grammarPattern != null) {
      textColor = colors.colorGrammar;
      border = Border(
        bottom: BorderSide(
          color: colors.colorGrammar,
          width: 2.5,
        ),
      );
    } else if (token.level == 'new') {
      textColor = colors.wordNewText;
      bgColor = colors.wordNewBg;
    } else if (token.level == 'learning') {
      textColor = colors.wordLearningText;
      bgColor = colors.wordLearningBg;
    } else if (token.level == 'known') {
      textColor = colors.wordKnownText;
      bgColor = colors.wordKnownBg;
    } else if (token.isSaved) {
      border = Border(
        bottom: BorderSide(
          color: colors.accentPrimary.withOpacity(0.8),
          width: 1.5,
        ),
      );
    }

    // Granular rubyParts rendering if available
    if (widget.showFurigana && token.rubyParts != null && token.rubyParts!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
          border: border,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: token.rubyParts!.map((part) {
            final hasReading = part.reading != null && part.reading!.isNotEmpty;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasReading)
                  Text(
                    part.reading!,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: _rubyFontSize,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  )
                else
                  SizedBox(height: _rubyFontSize + 2),
                Text(
                  part.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: _surfaceFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      );
    }

    // Fallback standard ruby text
    final rubyText = token.reading ?? token.pinyin ?? token.romanization;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: border,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showFurigana) ...[
            if (rubyText != null)
              Text(
                rubyText,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: _rubyFontSize,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              )
            else
              SizedBox(height: _rubyFontSize + 2),
          ],
          Text(
            token.surface,
            style: TextStyle(
              color: textColor,
              fontSize: _surfaceFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingDot extends StatelessWidget {
  final int delayMs;
  final Color color;
  const _WaitingDot({required this.delayMs, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
