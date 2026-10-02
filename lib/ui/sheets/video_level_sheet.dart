// lib/ui/sheets/video_level_sheet.dart

import 'package:flutter/material.dart';
import '../../config/voca_theme.dart';
import '../../models/voca_models.dart';
import '../../services/i18n_service.dart';
import '../../services/video_level_service.dart';
import 'voca_bottom_sheet.dart';

class VideoLevelSheet extends StatelessWidget {
  final String level;
  final String? tier;
  final int grammarCount;
  final double? speechRateCpm;
  final String? detectedFrom;
  final List<GrammarMatch> grammarMatches;

  const VideoLevelSheet({
    super.key,
    required this.level,
    this.tier,
    this.grammarCount = 0,
    this.speechRateCpm,
    this.detectedFrom,
    this.grammarMatches = const [],
  });

  static Future<void> show(
    BuildContext context, {
    required String level,
    String? tier,
    int grammarCount = 0,
    double? speechRateCpm,
    String? detectedFrom,
    List<GrammarMatch> grammarMatches = const [],
  }) {
    return showVocaBottomSheet(
      context: context,
      title: context.t('level.immersionLevel', null, 'Video Difficulty Level'),
      showCloseButton: true,
      maxHeightFactor: 0.85,
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      builder: (_) => VideoLevelSheet(
        level: level,
        tier: tier,
        grammarCount: grammarCount,
        speechRateCpm: speechRateCpm,
        detectedFrom: detectedFrom,
        grammarMatches: grammarMatches,
      ),
    );
  }

  String get _cleanLevel => LevelColorInfo.cleanLevel(level);

  String get _effectiveTier {
    if (tier != null && tier!.isNotEmpty) return tier!;
    return VideoLevelService.deriveLevelTier(_cleanLevel).name;
  }

  String _getTierTitle(BuildContext context) {
    switch (_effectiveTier) {
      case 'beginner':
        return context.t('level.beginner', null, 'Beginner Level');
      case 'elementary':
        return context.t('level.elementary', null, 'Elementary Level');
      case 'intermediate':
        return context.t('level.intermediate', null, 'Intermediate Level');
      case 'upper_intermediate':
        return context.t('level.upperIntermediate', null, 'Upper-Intermediate Level');
      case 'advanced':
        return context.t('level.advanced', null, 'Advanced Level');
      default:
        return 'Language Immersion Level';
    }
  }

  bool get _isLinguistic => detectedFrom == 'linguistics' || grammarCount > 0 || grammarMatches.isNotEmpty;

  String _getEvaluationSummary(BuildContext context) {
    if (_isLinguistic) {
      return context.t(
        'level.evaluatedLinguistic',
        null,
        'Level estimated from subtitle grammar patterns, vocabulary difficulty, and speech cadence.',
      );
    }
    return context.t(
      'level.evaluatedCurriculum',
      null,
      'Level matched from video title, channel, and curated curriculum data.',
    );
  }

  Map<String, String> get _speechPaceInfo {
    final rawCpm = speechRateCpm ?? 165.0;
    final isSlow = rawCpm < 140;
    final isFast = rawCpm > 240;

    String tag = 'Natural Pace';

    if (isSlow) {
      tag = 'Clear & Measured';
    } else if (isFast) {
      tag = 'Fast Native';
    } else {
      tag = 'Natural Flow';
    }

    return {
      'cpm': rawCpm.round().toString(),
      'tag': tag,
      'unit': 'chars/min',
    };
  }

  String _immersionTip(BuildContext context) {
    final rawCpm = speechRateCpm ?? 165.0;
    if (rawCpm > 240) {
      return context.t('level.immersionTipFast', null, 'Fast native speech. Try 0.75x or loop tricky sentences.');
    }
    if (_effectiveTier == 'advanced' || _effectiveTier == 'upper_intermediate') {
      return context.t('level.immersionTipAdvanced', null, 'Advanced content. Tap any word to look up its meaning in the dictionary.');
    }
    if (_effectiveTier == 'beginner' || _effectiveTier == 'elementary') {
      return context.t('level.immersionTipBeginner', null, 'Clear speech cadence. Great for listening comprehension and shadowing practice.');
    }
    return context.t('level.immersionTipDefault', null, 'Too fast? Slow to 0.75x or turn on dual subtitles in options.');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vocaColors;
    final colorInfo = LevelColorInfo.forLevel(_cleanLevel, isDark: context.isDarkMode);
    final pace = _speechPaceInfo;
    final effectiveGrammarCount = grammarCount > 0 ? grammarCount : grammarMatches.length;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),

          // Hero Level Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: colorInfo.bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colorInfo.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: colorInfo.bg.withOpacity(0.5),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              _cleanLevel,
              style: TextStyle(
                color: colorInfo.text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Tier Title
          Text(
            _getTierTitle(context),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),

          // Source Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isLinguistic
                  ? colors.accentSecondarySoft
                  : colors.bgSurface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _isLinguistic
                    ? colors.accentSecondary.withOpacity(0.3)
                    : colors.borderColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isLinguistic ? Icons.auto_awesome_rounded : Icons.menu_book_rounded,
                  size: 13,
                  color: _isLinguistic ? colors.accentSecondary : colors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  _isLinguistic ? context.t('level.analyzedFromSubtitles', null, 'Analyzed from Subtitles') : context.t('level.curriculumMatch', null, 'Curriculum Match'),
                  style: TextStyle(
                    color: _isLinguistic ? colors.accentSecondary : colors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Diagnostics Grid
          Row(
            children: [
              // Grammar Patterns Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0x266366F1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFF6366F1),
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.t('level.grammar', null, 'GRAMMAR'),
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        effectiveGrammarCount > 0 ? '$effectiveGrammarCount ${context.t('level.patterns', null, 'patterns')}' : context.t('level.detected', null, 'Detected'),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Spoken Cadence / Pace Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0x26F59E0B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.speed_rounded,
                              color: Color(0xFFF59E0B),
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.t('level.spokenPace', null, 'SPOKEN PACE'),
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pace['tag']!,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Evaluation Summary Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: colors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getEvaluationSummary(context),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Immersion Tip Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x1AF59E0B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x4DF59E0B)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 18, color: Color(0xFFF59E0B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('level.immersionTip', null, 'Immersion Tip'),
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _immersionTip(context),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Got It Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accentPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.t('common.gotIt', null, 'Got it'),
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
