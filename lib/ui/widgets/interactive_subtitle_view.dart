// lib/ui/widgets/interactive_subtitle_view.dart

import 'package:flutter/material.dart';
import '../../models/voca_models.dart';

class InteractiveSubtitleView extends StatelessWidget {
  final SubtitleCue cue;
  final List<GrammarMatch> grammarMatches;
  final Function(Token token) onTokenTap;
  final Function(GrammarPattern pattern)? onGrammarTap;

  const InteractiveSubtitleView({
    super.key,
    required this.cue,
    this.grammarMatches = const [],
    required this.onTokenTap,
    this.onGrammarTap,
  });

  @override
  Widget build(BuildContext context) {
    // Map token index -> GrammarPattern for quick lookups
    final grammarTokenMap = <int, GrammarPattern>{};
    for (final m in grammarMatches) {
      for (final idx in m.tokenIndices) {
        grammarTokenMap[idx] = m.pattern;
      }
    }

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
          // Primary Subtitle with Furigana / Pinyin ruby stack
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              }

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
                      // Furigana reading or Chinese Pinyin ruby text
                      if (token.reading != null || token.pinyin != null)
                        Text(
                          token.reading ?? token.pinyin!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
                          ),
                        )
                      else
                        const SizedBox(height: 12), // Placeholder to align baseline
                      // Surface word
                      Text(
                        token.surface,
                        style: TextStyle(
                          color: grammarPattern != null
                              ? Colors.amberAccent
                              : Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Secondary translated subtitle
          if (cue.translation != null && cue.translation!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              cue.translation!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 14.5,
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
