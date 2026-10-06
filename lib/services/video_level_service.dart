import 'package:signals_flutter/signals_flutter.dart';
import '../models/voca_models.dart';

/// Service responsible for assessing and resolving proficiency levels for videos and playlists.
/// Ported from lingua-tube's VideoLevelService with multi-stage resolution:
/// 1. Explicit level
/// 2. Memory / persistent cache
/// 3. Metadata regex heuristics (title & channel)
/// 4. Subtitle linguistic analysis (grammar patterns & speech rate)
class VideoLevelService {
  static final VideoLevelService instance = VideoLevelService._internal();

  VideoLevelService._internal();

  // Reactive state matching Angular signal
  final Signal<VideoLevelInfo?> currentLevel = signal<VideoLevelInfo?>(null);
  final Signal<bool> isAnalyzing = signal<bool>(false);

  // In-memory cache: 'videoId_lang' -> VideoLevelInfo
  final Map<String, VideoLevelInfo> _levelCache = {};

  void reset() {
    currentLevel.value = null;
    isAnalyzing.value = false;
  }

  void clearCache() {
    _levelCache.clear();
  }

  VideoLevelInfo? getCachedLevel(String videoId, String lang) {
    return _levelCache['${videoId}_$lang'];
  }

  void setCache(String videoId, String lang, VideoLevelInfo info) {
    _levelCache['${videoId}_$lang'] = info;
  }

  /// Maps any arbitrary level string to standard ProficiencyLevelTier
  ProficiencyLevelTier labelToTier(String? label) {
    return deriveLevelTier(label);
  }

  /// Derives ProficiencyLevelTier from label
  static ProficiencyLevelTier deriveLevelTier(String? label) {
    if (label == null || label.trim().isEmpty) {
      return ProficiencyLevelTier.intermediate;
    }
    final clean = label.trim();
    final lower = clean.toLowerCase();

    for (final t in ProficiencyLevelTier.values) {
      if (t.name.toLowerCase() == lower ||
          t.name.toLowerCase() == lower.replaceAll('-', '').replaceAll('_', '') ||
          (t == ProficiencyLevelTier.upperIntermediate && (lower == 'upper_intermediate' || lower == 'upper-intermediate'))) {
        return t;
      }
    }

    final upper = clean.toUpperCase();

    // 1. Beginner
    if (RegExp(r'\b(?:JLPT\s*)?N5\b', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'\bHSK\s*1\b', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'\bTOPIK\s*(?:1|I)\b', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'\bCEFR\s*A1\b', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'\bA1\b', caseSensitive: false).hasMatch(clean) ||
        upper.contains('BEGINNER') ||
        upper.contains('NOVICE') ||
        upper.contains('SƠ CẤP') ||
        upper.contains('NHẬP MÔN') ||
        RegExp(r'入門|初級|초급\s*1|입문').hasMatch(clean)) {
      return ProficiencyLevelTier.beginner;
    }

    // 2. Elementary
    if (RegExp(r'\b(?:JLPT\s*)?N4\b', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'\bHSK\s*2\b', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'\bTOPIK\s*2\b', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'\bCEFR\s*A2\b', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'\bA2\b', caseSensitive: false).hasMatch(clean) ||
        upper.contains('ELEMENTARY') ||
        RegExp(r'초급\s*2|초급').hasMatch(clean)) {
      return ProficiencyLevelTier.elementary;
    }

    // 3. Intermediate
    if (RegExp(r'\b(?:JLPT\s*)?N3\b', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'\bHSK\s*(?:[34]|3-4|3\s*-\s*4)\b', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'\bTOPIK\s*(?:[34]|3-4|3\s*-\s*4)\b', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'\bCEFR\s*B1\b', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'\bB1\b', caseSensitive: false).hasMatch(clean) ||
        upper.contains('INTERMEDIATE') ||
        upper.contains('TRUNG CẤP') ||
        RegExp(r'中級|중급').hasMatch(clean)) {
      return ProficiencyLevelTier.intermediate;
    }

    // 4. Upper-Intermediate
    if (RegExp(r'\b(?:JLPT\s*)?N2\b', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'\bHSK\s*5\b', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'\bTOPIK\s*5\b', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'\bCEFR\s*B2\b', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'\bB2\b', caseSensitive: false).hasMatch(clean) ||
        upper.contains('UPPER') ||
        upper.contains('UPPER-INTERMEDIATE')) {
      return ProficiencyLevelTier.upperIntermediate;
    }

    // 5. Advanced
    if (RegExp(r'\b(?:JLPT\s*)?N1\b', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'\bHSK\s*6\b', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'\bTOPIK\s*6\b', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'\bCEFR\s*(?:C[12]|C1-C2|C1\s*-\s*C2)\b', caseSensitive: false).hasMatch(clean) ||
        RegExp(r'\b(?:C[12]|C1-C2|C1\s*-\s*C2)\b', caseSensitive: false).hasMatch(clean) ||
        upper.contains('ADVANCED') ||
        upper.contains('CAO CẤP') ||
        RegExp(r'上級|고급').hasMatch(clean)) {
      return ProficiencyLevelTier.advanced;
    }

    return ProficiencyLevelTier.intermediate;
  }

  /// Maps a tier to official label for language (e.g. intermediate -> JLPT N3)
  String tierToLabel(ProficiencyLevelTier tier, String lang) {
    const map = {
      'ja': {
        ProficiencyLevelTier.beginner: 'JLPT N5',
        ProficiencyLevelTier.elementary: 'JLPT N4',
        ProficiencyLevelTier.intermediate: 'JLPT N3',
        ProficiencyLevelTier.upperIntermediate: 'JLPT N2',
        ProficiencyLevelTier.advanced: 'JLPT N1',
      },
      'zh': {
        ProficiencyLevelTier.beginner: 'HSK 1',
        ProficiencyLevelTier.elementary: 'HSK 2',
        ProficiencyLevelTier.intermediate: 'HSK 3-4',
        ProficiencyLevelTier.upperIntermediate: 'HSK 5',
        ProficiencyLevelTier.advanced: 'HSK 6',
      },
      'ko': {
        ProficiencyLevelTier.beginner: 'TOPIK 1',
        ProficiencyLevelTier.elementary: 'TOPIK 2',
        ProficiencyLevelTier.intermediate: 'TOPIK 3-4',
        ProficiencyLevelTier.upperIntermediate: 'TOPIK 5',
        ProficiencyLevelTier.advanced: 'TOPIK 6',
      },
      'en': {
        ProficiencyLevelTier.beginner: 'CEFR A1',
        ProficiencyLevelTier.elementary: 'CEFR A2',
        ProficiencyLevelTier.intermediate: 'CEFR B1',
        ProficiencyLevelTier.upperIntermediate: 'CEFR B2',
        ProficiencyLevelTier.advanced: 'CEFR C1-C2',
      },
    };

    return map[lang]?[tier] ?? tier.name.toUpperCase();
  }

  /// Returns standard selectable level filter badges for a language
  static List<String> getAvailableLevelFilters(String lang) {
    switch (lang.toLowerCase()) {
      case 'ja':
        return const ['All', 'N5', 'N4', 'N3', 'N2', 'N1'];
      case 'zh':
        return const ['All', 'HSK 1', 'HSK 2', 'HSK 3', 'HSK 4', 'HSK 5', 'HSK 6'];
      case 'ko':
        return const ['All', 'TOPIK 1', 'TOPIK 2', 'TOPIK 3', 'TOPIK 4', 'TOPIK 5', 'TOPIK 6'];
      case 'en':
        return const ['All', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
      default:
        return const ['All', 'Beginner', 'Elementary', 'Intermediate', 'Upper', 'Advanced'];
    }
  }

  /// Detects difficulty level from video title, channel, or metadata
  String? detectFromMetadata(String title, String channel, String lang) {
    final combined = '$title $channel'.trim();
    if (combined.isEmpty) return null;

    final tier = deriveLevelTier(combined);
    return tierToLabel(tier, lang);
  }

  /// Synchronously resolves best known level for a video
  VideoLevelInfo? resolveLevel({
    String? videoId,
    String? lang,
    String title = '',
    String channel = '',
    String? explicitLevel,
  }) {
    final l = lang ?? 'ja';

    if (explicitLevel != null && explicitLevel.isNotEmpty) {
      final tier = labelToTier(explicitLevel);
      return VideoLevelInfo(
        level: explicitLevel,
        tier: tier,
        detectedFrom: 'title',
      );
    }

    if (videoId != null && lang != null) {
      final cached = getCachedLevel(videoId, lang);
      if (cached != null) return cached;
    }

    if (title.isNotEmpty || channel.isNotEmpty) {
      final meta = detectFromMetadata(title, channel, l);
      if (meta != null) {
        return VideoLevelInfo(
          level: meta,
          tier: labelToTier(meta),
          detectedFrom: 'title',
        );
      }
    }

    return null;
  }

  /// Resolves difficulty level for a playlist
  VideoLevelInfo? resolvePlaylistLevel(PlaylistItem? playlist) {
    if (playlist == null) return null;

    // 1. Explicit level or title heuristics
    final direct = resolveLevel(
      lang: playlist.language,
      title: playlist.title,
      channel: playlist.description ?? '',
      explicitLevel: playlist.level,
    );
    if (direct != null) return direct;

    // 2. Check tags
    if (playlist.tags.isNotEmpty) {
      for (final tag in playlist.tags) {
        final match = resolveLevel(
          lang: playlist.language,
          title: tag,
          explicitLevel: tag,
        );
        if (match != null) return match;
      }
    }

    // 3. Fallback default for language
    const defaultTier = ProficiencyLevelTier.beginner;
    final defaultLabel = tierToLabel(defaultTier, playlist.language);
    return VideoLevelInfo(
      level: defaultLabel,
      tier: defaultTier,
      detectedFrom: 'server',
    );
  }

  /// Full assessment of video level (server, heuristics, or linguistic cues)
  VideoLevelInfo assessLevel({
    required String videoId,
    required String lang,
    String title = '',
    String channel = '',
    List<SubtitleCue> cues = const [],
    List<GrammarMatch> grammarMatches = const [],
    Map<String, dynamic>? serverLevels,
  }) {
    final cacheKey = '${videoId}_$lang';
    if (_levelCache.containsKey(cacheKey)) {
      final cached = _levelCache[cacheKey]!;
      currentLevel.value = cached;
      return cached;
    }

    // 1. Server levels from API response
    if (serverLevels != null && serverLevels[lang] != null) {
      final s = serverLevels[lang];
      String label = '';
      if (s is Map) {
        label = (s['level'] ?? s['label'] ?? s['tier'] ?? '').toString();
      } else {
        label = s.toString();
      }
      if (label.isNotEmpty) {
        final tier = labelToTier(label);
        final info = VideoLevelInfo(
          level: label,
          tier: tier,
          detectedFrom: 'server',
        );
        setCache(videoId, lang, info);
        currentLevel.value = info;
        return info;
      }
    }

    // 2. Linguistic heuristics from grammar matches
    if (grammarMatches.isNotEmpty) {
      // Calculate level breakdown
      final breakdown = <String, int>{};
      for (final m in grammarMatches) {
        final lvl = m.pattern.level;
        if (lvl.isNotEmpty) {
          breakdown[lvl] = (breakdown[lvl] ?? 0) + 1;
        }
      }

      // Find predominant level
      String topLevel = '';
      int maxCount = 0;
      breakdown.forEach((lvl, count) {
        if (count > maxCount) {
          maxCount = count;
          topLevel = lvl;
        }
      });

      if (topLevel.isNotEmpty) {
        final tier = labelToTier(topLevel);
        final info = VideoLevelInfo(
          level: topLevel,
          tier: tier,
          confidence: 0.9,
          grammarCount: grammarMatches.length,
          detectedFrom: 'linguistics',
          breakdown: breakdown,
        );
        setCache(videoId, lang, info);
        currentLevel.value = info;
        return info;
      }
    }

    // 3. Metadata regex heuristics
    final resolved = resolveLevel(
      videoId: videoId,
      lang: lang,
      title: title,
      channel: channel,
    );
    if (resolved != null) {
      setCache(videoId, lang, resolved);
      currentLevel.value = resolved;
      return resolved;
    }

    // 4. Default fallback
    final defaultInfo = VideoLevelInfo(
      level: tierToLabel(ProficiencyLevelTier.intermediate, lang),
      tier: ProficiencyLevelTier.intermediate,
      detectedFrom: 'server',
    );
    setCache(videoId, lang, defaultInfo);
    currentLevel.value = defaultInfo;
    return defaultInfo;
  }
}
