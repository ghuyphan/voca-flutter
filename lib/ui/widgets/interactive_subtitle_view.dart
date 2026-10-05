// lib/ui/widgets/interactive_subtitle_view.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/i18n_service.dart';

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
  final int maxDiamonds;
  final VoidCallback? onTriggerAI;
  final String? switchLanguageName;
  final VoidCallback? onSwitchLanguage;
  final VoidCallback? onRetry;
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
    this.maxDiamonds = 5,
    this.onTriggerAI,
    this.switchLanguageName,
    this.onSwitchLanguage,
    this.onRetry,
    this.subtitlesEnabled = true,
    this.hasSubtitles = false,
    this.showCoachmark = false,
    this.onDismissCoachmark,
    this.isLooping = false,
  });

  @override
  State<InteractiveSubtitleView> createState() => _InteractiveSubtitleViewState();
}

class _InteractiveSubtitleViewState extends State<InteractiveSubtitleView>
    with SingleTickerProviderStateMixin {
  bool _dismissedCoachmark = false;
  late final AnimationController _dotsAnimController;

  @override
  void initState() {
    super.initState();
    _dotsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _dotsAnimController.dispose();
    super.dispose();
  }

  double get _surfaceFontSize {
    switch (widget.subtitleSize) {
      case SubtitleSize.small:
        return 16.0;
      case SubtitleSize.medium:
        return 19.5;
      case SubtitleSize.large:
        return 23.5;
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
        return 14.0;
      case SubtitleSize.large:
        return 16.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final isDark = context.isDarkMode;

    return Container(
      constraints: BoxConstraints(
        minHeight: widget.showTranslation ? 148.0 : 130.0,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgCard.withOpacity(isDark ? 0.95 : 0.98),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isLooping ? colors.accentPrimary.withOpacity(0.6) : colors.borderColor,
          width: widget.isLooping ? 1.5 : 1.0,
        ),
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
          if (widget.showCoachmark && !_dismissedCoachmark) _buildCoachmark(context, colors),

          // 2. Main Content based on state
          _buildStateContent(context, colors),
        ],
      ),
    );
  }

  Widget _buildCoachmark(BuildContext context, VocaColorPalette colors) {
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
            context.t('onboarding.subtitleCoachmark', null, 'Tap any word to translate & save'),
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.subtitles_off_rounded, size: 24, color: colors.textMuted),
            const SizedBox(height: 6),
            Text(
              context.t('subtitle.subtitlesOff', null, 'Subtitles turned off'),
              style: TextStyle(color: colors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // B. AI Generating state
    if (widget.isAIGenerating) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: colors.accentPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              context.t('subtitle.generatingTranscript', null, 'Generating transcript...'),
              style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              context.t('subtitle.usingWhisperAI', null, 'Using Whisper AI'),
              style: TextStyle(color: colors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // C. Loading captions state
    if (widget.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: colors.accentPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              widget.statusMessage ?? context.t('subtitle.fetchingCaptions', null, 'Fetching captions...'),
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // D. Error states
    if (widget.errorCode != null && widget.errorCode!.isNotEmpty) {
      return _buildErrorState(context, colors);
    }

    // E. Waiting state (between cues)
    if (widget.cue == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: widget.hasSubtitles
            ? _buildAnimatedWaitingDots(colors.textMuted)
            : Text(
                context.t('subtitle.noSubtitlesLoaded', null, 'No subtitles loaded'),
                style: TextStyle(color: colors.textMuted, fontSize: 14),
              ),
      );
    }

    // F. Active Cue Subtitles display
    return _buildCueContent(widget.cue!, colors);
  }

  Widget _buildErrorState(BuildContext context, VocaColorPalette colors) {
    final code = widget.errorCode;

    if (code == 'VIDEO_TOO_LONG') {
      return _buildErrorCard(
        context: context,
        colors: colors,
        icon: Icons.timer_off_rounded,
        title: context.t('subtitle.videoTooLongTitle', null, 'Video is too long'),
        hint: context.t('subtitle.videoTooLongHint', null, 'Videos longer than 30 minutes are not currently supported for AI captions.'),
      );
    }

    if (code == 'UNSUPPORTED_LANGUAGE' || code == 'UNSUPPORTED_VIDEO_LANGUAGE') {
      return _buildErrorCard(
        context: context,
        colors: colors,
        icon: Icons.language_rounded,
        title: context.t('subtitle.unsupportedLanguageTitle', null, 'Language not supported'),
        hint: context.t('subtitle.unsupportedLanguageHint', null, 'Captions are not available in this language.'),
        action: widget.switchLanguageName != null && widget.onSwitchLanguage != null
            ? ElevatedButton.icon(
                onPressed: widget.onSwitchLanguage,
                icon: const Icon(Icons.language_rounded, size: 14),
                label: Text(
                  context.t(
                    'subtitle.switchLanguage',
                    {'language': widget.switchLanguageName!},
                    'Switch to ${widget.switchLanguageName}',
                  ),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              )
            : null,
      );
    }

    if (code == 'RATE_LIMITED') {
      return _buildErrorCard(
        context: context,
        colors: colors,
        icon: Icons.speed_rounded,
        title: context.t('subtitle.rateLimitedTitle', null, 'Rate limited'),
        hint: context.t('subtitle.rateLimitedHint', null, 'Too many requests. Please wait a few moments before trying again.'),
        action: _buildRetryButton(context, colors),
      );
    }

    if (code == 'NO_DIAMONDS' || code == 'INSUFFICIENT_DIAMONDS') {
      return _buildErrorCard(
        context: context,
        colors: colors,
        icon: Icons.diamond_outlined,
        title: context.t('subtitle.noCaptionsAvailable', null, 'No captions available'),
        hint: context.t('subtitle.noDiamondsLeft', null, 'No AI credits remaining. Credits regenerate over time.'),
      );
    }

    if (code == 'NO_NATIVE' || code == 'NO_SUBTITLES') {
      final hasDiamonds = widget.diamonds > 0;
      return _buildErrorCard(
        context: context,
        colors: colors,
        icon: hasDiamonds ? Icons.auto_awesome_rounded : Icons.subtitles_off_rounded,
        title: context.t('subtitle.noCaptionsAvailable', null, 'No captions available'),
        hint: hasDiamonds
            ? context.t('subtitle.fallbackAvailable', null, 'AI transcription available')
            : context.t('subtitle.aiUnavailable', null, 'AI transcription is currently unavailable'),
        action: hasDiamonds && widget.onTriggerAI != null
            ? ElevatedButton.icon(
                onPressed: widget.onTriggerAI,
                icon: const Icon(Icons.diamond_rounded, size: 15),
                label: Text(
                  '${context.t('subtitle.useAITranscription', null, 'Use AI Transcription')}${widget.diamonds > 0 ? ' (${widget.diamonds})' : ''}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              )
            : null,
      );
    }

    // Default error (Network or server)
    return _buildErrorCard(
      context: context,
      colors: colors,
      icon: Icons.error_outline_rounded,
      title: context.t('subtitle.networkErrorTitle', null, 'Connection Error'),
      hint: widget.errorMessage ?? context.t('subtitle.networkErrorHint', null, 'Failed to fetch subtitles. Please retry.'),
      action: _buildRetryButton(context, colors),
    );
  }

  Widget _buildErrorCard({
    required BuildContext context,
    required VocaColorPalette colors,
    required IconData icon,
    required String title,
    required String hint,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: colors.accentTertiary),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: 10),
            action,
          ],
        ],
      ),
    );
  }

  Widget _buildRetryButton(BuildContext context, VocaColorPalette colors) {
    if (widget.onRetry == null) return const SizedBox.shrink();
    return OutlinedButton.icon(
      onPressed: widget.onRetry,
      icon: const Icon(Icons.refresh_rounded, size: 14),
      label: Text(
        context.t('common.retry', null, 'Retry'),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textPrimary,
        side: BorderSide(color: colors.borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
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
            final opacity = 0.3 + 0.7 * (0.5 - (phase - 0.5).abs()) * 2.0;
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

  Widget _buildCueContent(SubtitleCue activeCue, VocaColorPalette colors) {
    final grammarTokenMap = <int, GrammarPattern>{};
    for (final m in widget.grammarMatches) {
      for (final idx in m.tokenIndices) {
        grammarTokenMap[idx] = m.pattern;
      }
    }

    final hasTokens = activeCue.tokens.isNotEmpty;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Primary Subtitle (Tokens or raw text)
          if (hasTokens)
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 4,
              runSpacing: 6,
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
                        color: colors.textSecondary,
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
            const SizedBox(height: 8),
            if (widget.isTranslating && (activeCue.translation == null || activeCue.translation!.isEmpty))
              _buildAnimatedWaitingDots(colors.textMuted)
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
      ),
    );
  }

  Widget _buildTokenWidget(Token token, GrammarPattern? grammarPattern, VocaColorPalette colors) {
    // Style hierarchy: Grammar > SRS levels > Saved words
    final isGrammar = grammarPattern != null;
    Color textColor = colors.textPrimary;
    Color? chipBgColor;
    Border? chipBorder;
    TextDecoration? textDecoration;
    Color? decorationColor;

    if (isGrammar) {
      textColor = colors.textPrimary;
      chipBgColor = colors.colorGrammar.withOpacity(0.18);
      chipBorder = Border.all(
        color: colors.colorGrammar.withOpacity(0.55),
        width: 1.0,
      );
      textDecoration = TextDecoration.underline;
      decorationColor = colors.colorGrammar;
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

    // Granular rubyParts rendering if available
    if (widget.showFurigana && token.rubyParts != null && token.rubyParts!.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: token.rubyParts!.map((part) {
          final hasReading = part.reading != null && part.reading!.isNotEmpty;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasReading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    part.reading!,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: _rubyFontSize,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: (chipBorder != null || chipBgColor != null) ? 4.5 : 2.0,
                  vertical: (chipBorder != null || chipBgColor != null) ? 1.0 : 0.0,
                ),
                decoration: BoxDecoration(
                  color: chipBgColor,
                  borderRadius: BorderRadius.circular(4),
                  border: chipBorder,
                ),
                child: Text(
                  part.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: _surfaceFontSize,
                    fontWeight: isGrammar ? FontWeight.w600 : FontWeight.w500,
                    decoration: textDecoration,
                    decorationColor: decorationColor,
                    decorationThickness: 1.5,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      );
    }

    // Fallback standard ruby text
    final rubyText = token.reading ?? token.pinyin ?? token.romanization;
    final hasRuby = widget.showFurigana && rubyText != null && rubyText.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasRuby)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              rubyText,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: _rubyFontSize,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: (chipBorder != null || chipBgColor != null) ? 4.5 : 2.0,
            vertical: (chipBorder != null || chipBgColor != null) ? 1.0 : 0.0,
          ),
          decoration: BoxDecoration(
            color: chipBgColor,
            borderRadius: BorderRadius.circular(4),
            border: chipBorder,
          ),
          child: Text(
            token.surface,
            style: TextStyle(
              color: textColor,
              fontSize: _surfaceFontSize,
              fontWeight: isGrammar ? FontWeight.w600 : FontWeight.w500,
              decoration: textDecoration,
              decorationColor: decorationColor,
              decorationThickness: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
