// lib/ui/sheets/grammar_bottom_sheet.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import 'voca_bottom_sheet.dart';

class GrammarBottomSheet extends StatelessWidget {
  final GrammarPattern pattern;

  const GrammarBottomSheet({super.key, required this.pattern});

  static Future<void> show(BuildContext context, GrammarPattern pattern) {
    return showVocaBottomSheet(
      context: context,
      title: pattern.title,
      subtitle: pattern.level.isNotEmpty ? 'Grammar • ${pattern.level}' : 'Grammar Pattern',
      showCloseButton: true,
      maxHeightFactor: 0.85,
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      builder: (ctx) => GrammarBottomSheet(pattern: pattern),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final levelColor = LevelColorInfo.forLevel(pattern.level, isDark: context.isDarkMode);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level badge chip
          if (pattern.level.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: levelColor.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: levelColor.border, width: 1),
              ),
              child: Text(
                pattern.level,
                style: TextStyle(
                  color: levelColor.text,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Formation formula
          if (pattern.formation.isNotEmpty) ...[
            Text(
              'FORMATION',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.borderColor),
              ),
              child: Text(
                pattern.formation,
                style: TextStyle(
                  color: colors.colorDiamond,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Explanation
          Text(
            'EXPLANATION',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pattern.longExplanation.isNotEmpty
                ? pattern.longExplanation
                : pattern.shortExplanation,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Authentic Examples
          if (pattern.examples.isNotEmpty) ...[
            Text(
              'EXAMPLES',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            ...pattern.examples.map((ex) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.sentence,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (ex.romanization != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        ex.romanization!,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      ex.translation,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
