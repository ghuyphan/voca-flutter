// lib/ui/widgets/interactive_subtitle_view.dart

import 'package:flutter/material.dart';
import '../../models/voca_models.dart';

class InteractiveSubtitleView extends StatelessWidget {
  final SubtitleCue cue;
  final List<GrammarMatch> grammarMatches;
  final Function(Token token) onTokenTap;
  final Function(GrammarPattern pattern)? onGrammarTap;
  final bool showFurigana;
  final bool showTranslation;
  final SubtitleSize subtitleSize;

  const InteractiveSubtitleView({
    super.key,
    required this.cue,
    this.grammarMatches = const [],
    required this.onTokenTap,
    this.onGrammarTap,
    this.showFurigana = true,
    this.showTranslation = true,
    this.subtitleSize = SubtitleSize.medium,
  });

  double get _surfaceFontSize {
    switch (subtitleSize) {
      case SubtitleSize.small:
        return 16.0;
      case SubtitleSize.medium:
        return 20.0;
      case SubtitleSize.large:
        return 24.0;
    }
  }

  double get _rubyFontSize {
    switch (subtitleSize) {
      case SubtitleSize.small:
        return 9.5;
      case SubtitleSize.medium:
        return 11.0;
      case SubtitleSize.large:
        return 13.0;
    }
  }

  double get _translationFontSize {
    switch (subtitleSize) {
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
    // Map token index -> GrammarPattern for quick lookups
    final grammarTokenMap = <int, GrammarPattern>{};
    for (final m in grammarMatches) {
      for (final idx in m.tokenIndices) {
        grammarTokenMap[idx] = m.pattern;
      }
    }

    final hasTokens = cue.tokens.isNotEmpty;

    return Container(
      // Zero-CLS: Enforce consistent minimum height and padding
      constraints: const BoxConstraints(minHeight: 76),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Primary Subtitle
          if (hasTokens)
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 2,
              runSpacing: 4,
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
                        color: Colors.white,
                        fontSize: _surfaceFontSize,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                }

                final rubyText = token.reading ?? token.pinyin ?? token.romanization;

                return InkWell(
                  onTap: () {
                    if (grammarPattern != null && onGrammarTap != null) {
                      onGrammarTap!(grammarPattern);
                    } else {
                      onTokenTap(token);
                    }
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      border: grammarPattern != null
                          ? const Border(
                              bottom: BorderSide(
                                color: Colors.amberAccent,
                                width: 2.5,
                              ),
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Furigana reading or Chinese Pinyin ruby text (if enabled)
                        if (showFurigana) ...[
                          if (rubyText != null)
                            Text(
                              rubyText,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: _rubyFontSize,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.2,
                              ),
                            )
                          else
                            SizedBox(height: _rubyFontSize + 2), // Baseline alignment
                        ],
                        // Surface word
                        Text(
                          token.surface,
                          style: TextStyle(
                            color: grammarPattern != null
                                ? Colors.amberAccent
                                : Colors.white,
                            fontSize: _surfaceFontSize,
                            fontWeight: FontWeight.w600,
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
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: _surfaceFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),

          // Secondary translated subtitle
          if (showTranslation && cue.translation != null && cue.translation!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              cue.translation!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFE2E8F0),
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
}
