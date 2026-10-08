// lib/models/voca_models.dart
export '../services/auth_service.dart' show UserProfile, SubscriptionTier;

class RubyPart {
  final String text;
  final String? reading;
  const RubyPart({required this.text, this.reading});
  factory RubyPart.fromJson(Map<String, dynamic> json) => RubyPart(
    text: json['text'] as String? ?? '',
    reading: json['reading'] as String?,
  );
  Map<String, dynamic> toJson() => {'text': text, if (reading != null) 'reading': reading};
}

class Token {
  final String surface;
  final String? reading;
  final String? romanization;
  final String? pinyin;
  final String? baseForm;
  final String? partOfSpeech;
  final bool isPunctuation;
  final List<RubyPart>? rubyParts;
  final bool hasKanji;
  final String? level; // 'new' | 'learning' | 'known' | 'ignored'
  final bool isSaved;

  Token({
    required this.surface,
    this.reading,
    this.romanization,
    this.pinyin,
    this.baseForm,
    this.partOfSpeech,
    this.isPunctuation = false,
    this.rubyParts,
    this.hasKanji = false,
    this.level,
    this.isSaved = false,
  });

  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
      surface: json['surface'] as String? ?? '',
      reading: json['reading'] as String?,
      romanization: json['romanization'] as String?,
      pinyin: json['pinyin'] as String?,
      baseForm: json['baseForm'] as String?,
      partOfSpeech: json['partOfSpeech'] as String?,
      isPunctuation: json['isPunctuation'] as bool? ?? false,
      rubyParts: (json['rubyParts'] as List<dynamic>?)
          ?.map((e) => RubyPart.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasKanji: json['hasKanji'] as bool? ?? false,
      level: json['level'] as String?,
      isSaved: json['isSaved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'surface': surface,
    'reading': reading,
    'romanization': romanization,
    'pinyin': pinyin,
    'baseForm': baseForm,
    'partOfSpeech': partOfSpeech,
    'isPunctuation': isPunctuation,
    if (rubyParts != null) 'rubyParts': rubyParts!.map((e) => e.toJson()).toList(),
    'hasKanji': hasKanji,
    if (level != null) 'level': level,
    if (isSaved) 'isSaved': isSaved,
  };
}

class SubtitleCue {
  final double start;
  final double duration;
  final String text;
  String? translation;
  List<Token> tokens;

  SubtitleCue({
    required this.start,
    required this.duration,
    required this.text,
    this.translation,
    this.tokens = const [],
  });

  factory SubtitleCue.fromJson(Map<String, dynamic> json) {
    return SubtitleCue(
      start: (json['start'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      text: json['text'] as String? ?? '',
      translation: json['translation'] as String?,
      tokens: (json['tokens'] as List<dynamic>?)
              ?.map((t) => Token.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'start': start,
    'duration': duration,
    'text': text,
    'translation': translation,
    'tokens': tokens.map((t) => t.toJson()).toList(),
  };
}

class AvailableLanguages {
  final List<String> native;
  final List<String> ai;

  AvailableLanguages({
    this.native = const [],
    this.ai = const [],
  });

  factory AvailableLanguages.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AvailableLanguages();
    return AvailableLanguages(
      native: (json['native'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      ai: (json['ai'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {'native': native, 'ai': ai};
}

class TranscriptResponse {
  final bool success;
  final String videoId;
  final String? language;
  final String? requestedLanguage;
  final String? status; // 'processing' during Gladia ASR
  final String? resultUrl;
  final String? source; // 'cache' | 'native' | 'ai' | 'none'
  final String? sourceDetail;
  final bool languageMismatch;
  final List<SubtitleCue> segments;
  final AvailableLanguages availableLanguages;
  final List<String> subLanguages;
  final Map<String, String> levels;
  final bool whisperAvailable;
  final int diamonds;
  final int maxDiamonds;
  final int? nextRegenAt;
  final String? errorCode;
  final String? error;

  TranscriptResponse({
    required this.success,
    required this.videoId,
    this.language,
    this.requestedLanguage,
    this.status,
    this.resultUrl,
    this.source,
    this.sourceDetail,
    this.languageMismatch = false,
    this.segments = const [],
    required this.availableLanguages,
    this.subLanguages = const [],
    this.levels = const {},
    this.whisperAvailable = false,
    this.diamonds = 0,
    this.maxDiamonds = 5,
    this.nextRegenAt,
    this.errorCode,
    this.error,
  });

  bool get isProcessing => status == 'processing' && resultUrl != null;

  factory TranscriptResponse.fromJson(Map<String, dynamic> json) {
    return TranscriptResponse(
      success: json['success'] as bool? ?? false,
      videoId: json['videoId'] as String? ?? '',
      language: json['language'] as String?,
      requestedLanguage: json['requestedLanguage'] as String?,
      status: json['status'] as String?,
      resultUrl: json['resultUrl'] as String?,
      source: json['source'] as String?,
      sourceDetail: json['sourceDetail'] as String?,
      languageMismatch: json['languageMismatch'] as bool? ?? false,
      segments: (json['segments'] as List<dynamic>?)
              ?.map((s) => SubtitleCue.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      availableLanguages: AvailableLanguages.fromJson(json['availableLanguages'] as Map<String, dynamic>?),
      subLanguages: (json['subLanguages'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      levels: (json['levels'] as Map<String, dynamic>?)?.map((k, v) {
            if (v is Map) {
              final levelStr = v['level'] ?? v['tier'] ?? v['label'];
              return MapEntry(k, (levelStr ?? '').toString());
            }
            return MapEntry(k, v.toString());
          }) ?? {},
      whisperAvailable: json['whisperAvailable'] as bool? ?? false,
      diamonds: json['diamonds'] as int? ?? 0,
      maxDiamonds: json['maxDiamonds'] as int? ?? 5,
      nextRegenAt: json['nextRegenAt'] as int?,
      errorCode: json['errorCode'] as String?,
      error: json['error'] as String?,
    );
  }
}

class GrammarPattern {
  final String id;
  final String language;
  final String pattern;
  final String title;
  final String shortExplanation;
  final String longExplanation;
  final String formation;
  final String level;
  final List<GrammarExample> examples;

  GrammarPattern({
    required this.id,
    required this.language,
    required this.pattern,
    required this.title,
    required this.shortExplanation,
    required this.longExplanation,
    required this.formation,
    required this.level,
    required this.examples,
  });

  factory GrammarPattern.fromJson(Map<String, dynamic> json) {
    return GrammarPattern(
      id: json['id'] as String? ?? '',
      language: json['language'] as String? ?? 'ja',
      pattern: json['pattern'] as String? ?? '',
      title: json['title'] as String? ?? '',
      shortExplanation: json['shortExplanation'] as String? ?? '',
      longExplanation: json['longExplanation'] as String? ?? '',
      formation: json['formation'] as String? ?? '',
      level: json['level'] as String? ?? '',
      examples: (json['examples'] as List<dynamic>?)
              ?.map((e) => GrammarExample.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String get meaning => shortExplanation.isNotEmpty ? shortExplanation : title;
  String get explanation => longExplanation.isNotEmpty ? longExplanation : shortExplanation;

  GrammarPattern copyWith({
    String? id,
    String? language,
    String? pattern,
    String? title,
    String? shortExplanation,
    String? longExplanation,
    String? formation,
    String? level,
    List<GrammarExample>? examples,
  }) {
    return GrammarPattern(
      id: id ?? this.id,
      language: language ?? this.language,
      pattern: pattern ?? this.pattern,
      title: title ?? this.title,
      shortExplanation: shortExplanation ?? this.shortExplanation,
      longExplanation: longExplanation ?? this.longExplanation,
      formation: formation ?? this.formation,
      level: level ?? this.level,
      examples: examples ?? this.examples,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'language': language,
    'pattern': pattern,
    'title': title,
    'shortExplanation': shortExplanation,
    'longExplanation': longExplanation,
    'formation': formation,
    'level': level,
    'examples': examples.map((e) => e.toJson()).toList(),
  };
}

class GrammarExample {
  final String sentence;
  final String? romanization;
  final String translation;

  String? get reading => romanization;

  GrammarExample({
    required this.sentence,
    this.romanization,
    required this.translation,
  });

  factory GrammarExample.fromJson(Map<String, dynamic> json) {
    return GrammarExample(
      sentence: json['sentence'] as String? ?? '',
      romanization: json['romanization'] as String?,
      translation: json['translation'] as String? ?? '',
    );
  }

  GrammarExample copyWith({
    String? sentence,
    String? romanization,
    String? translation,
  }) {
    return GrammarExample(
      sentence: sentence ?? this.sentence,
      romanization: romanization ?? this.romanization,
      translation: translation ?? this.translation,
    );
  }

  Map<String, dynamic> toJson() => {
    'sentence': sentence,
    'romanization': romanization,
    'translation': translation,
  };
}

class GrammarTranslation {
  final String? title;
  final String? shortExplanation;
  final String? longExplanation;
  final String? formation;
  final List<GrammarExampleTranslation>? examples;

  GrammarTranslation({
    this.title,
    this.shortExplanation,
    this.longExplanation,
    this.formation,
    this.examples,
  });

  factory GrammarTranslation.fromJson(Map<String, dynamic> json) {
    return GrammarTranslation(
      title: json['title'] as String?,
      shortExplanation: json['shortExplanation'] as String?,
      longExplanation: json['longExplanation'] as String?,
      formation: json['formation'] as String?,
      examples: (json['examples'] as List<dynamic>?)
          ?.map((e) => GrammarExampleTranslation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GrammarExampleTranslation {
  final String? sentence;
  final String translation;

  GrammarExampleTranslation({
    this.sentence,
    required this.translation,
  });

  factory GrammarExampleTranslation.fromJson(Map<String, dynamic> json) {
    return GrammarExampleTranslation(
      sentence: json['sentence'] as String?,
      translation: json['translation'] as String? ?? '',
    );
  }
}

class GrammarMatch {
  final GrammarPattern pattern;
  final List<int> tokenIndices;
  final int startIndex;
  final int endIndex;

  GrammarMatch({
    required this.pattern,
    required this.tokenIndices,
    required this.startIndex,
    required this.endIndex,
  });
}

class DictionaryResult {
  final String word;
  final String from;
  final String to;
  final String source;
  final List<DictionaryEntry> entries;

  DictionaryResult({
    required this.word,
    required this.from,
    required this.to,
    required this.source,
    required this.entries,
  });

  factory DictionaryResult.fromJson(Map<String, dynamic> json) {
    return DictionaryResult(
      word: json['word']?.toString() ?? '',
      from: json['from']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      source: json['source']?.toString() ?? 'none',
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) => DictionaryEntry.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
    );
  }
}

class DictionaryEntry {
  final String? word;
  final String? reading;
  final String? romaji;
  final String? partOfSpeech;
  final List<String> definitions;
  final String? level;
  final String? audio;
  final List<Map<String, dynamic>> examples;

  DictionaryEntry({
    this.word,
    this.reading,
    this.romaji,
    this.partOfSpeech,
    required this.definitions,
    this.level,
    this.audio,
    this.examples = const [],
  });

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    return DictionaryEntry(
      word: json['word']?.toString(),
      reading: json['reading']?.toString(),
      romaji: json['romaji']?.toString(),
      partOfSpeech: json['partOfSpeech']?.toString(),
      definitions: (json['definitions'] as List<dynamic>?)
              ?.map((d) => d.toString())
              .toList() ??
          [],
      level: json['level']?.toString(),
      audio: json['audio']?.toString(),
      examples: (json['examples'] as List<dynamic>?)?.map((e) {
            if (e is Map) {
              return Map<String, dynamic>.from(e);
            } else if (e is String) {
              return <String, dynamic>{'sentence': e, 'translation': ''};
            }
            return <String, dynamic>{'sentence': e.toString(), 'translation': ''};
          }).toList() ??
          [],
    );
  }
}

class KanjiData {
  final String literal;
  final List<String> meanings;
  final int strokeCount;
  final int? grade;
  final int? jlpt;
  final int? frequency;
  final List<String> onyomi;
  final List<String> kunyomi;
  final List<String> chinese;
  final List<String> koreanR;
  final List<String> koreanH;
  final String? radical;
  final List<String> parts;

  KanjiData({
    required this.literal,
    required this.meanings,
    required this.strokeCount,
    this.grade,
    this.jlpt,
    this.frequency,
    this.onyomi = const [],
    this.kunyomi = const [],
    this.chinese = const [],
    this.koreanR = const [],
    this.koreanH = const [],
    this.radical,
    this.parts = const [],
  });

  String get animationSvgUrl => 'https://jotoba.de/resource/kanji/animation/$literal';
  String get framesSvgUrl => 'https://jotoba.de/resource/kanji/frames/$literal';

  factory KanjiData.fromJson(Map<String, dynamic> json) {
    return KanjiData(
      literal: json['literal']?.toString() ?? '',
      meanings: (json['meanings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      strokeCount: (json['stroke_count'] as num?)?.toInt() ?? 0,
      grade: (json['grade'] as num?)?.toInt(),
      jlpt: (json['jlpt'] as num?)?.toInt(),
      frequency: (json['frequency'] as num?)?.toInt(),
      onyomi: (json['onyomi'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      kunyomi: (json['kunyomi'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      chinese: (json['chinese'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      koreanR: (json['korean_r'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      koreanH: (json['korean_h'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      radical: json['radical']?.toString(),
      parts: (json['parts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'literal': literal,
    'meanings': meanings,
    'stroke_count': strokeCount,
    if (grade != null) 'grade': grade,
    if (jlpt != null) 'jlpt': jlpt,
    if (frequency != null) 'frequency': frequency,
    'onyomi': onyomi,
    'kunyomi': kunyomi,
    'chinese': chinese,
    'korean_r': koreanR,
    'korean_h': koreanH,
    if (radical != null) 'radical': radical,
    'parts': parts,
  };
}

typedef WordLevel = String;

class WordLevels {
  static const String isNew = 'new';
  static const String learning = 'learning';
  static const String known = 'known';
  static const String ignored = 'ignored';

  static const List<String> all = [isNew, learning, known, ignored];

  static String normalize(dynamic val) {
    if (val == null) return isNew;
    final s = val.toString().toLowerCase().trim();
    if (s == 'mastered') return known;
    if (s == learning || s == known || s == ignored) return s;
    return isNew;
  }
}

class Flashcard {
  final String id;
  final String userId;
  final String word;
  final String? reading;
  final String? romanization;
  final String? pinyin;
  final String meaning;
  final String language;
  final String level; // 'new' | 'learning' | 'known' | 'ignored'
  final int srsInterval;
  final int srsRepetition;
  final double srsEaseFactor;
  final int reviewCount;
  final DateTime srsNextReviewAt;
  final DateTime? srsLastReviewedAt;

  final String? partOfSpeech;
  final String? contextSentence;
  final String? contextTranslation;
  final String? audio;
  final String? notes;
  final DateTime? createdAt;
  final String? sourceVideoId;
  final double? sourceTimestamp;

  Flashcard({
    required this.id,
    required this.userId,
    required this.word,
    this.reading,
    this.romanization,
    this.pinyin,
    required this.meaning,
    required this.language,
    String level = 'new',
    this.srsInterval = 0,
    this.srsRepetition = 0,
    this.srsEaseFactor = 2.5,
    this.reviewCount = 0,
    required this.srsNextReviewAt,
    this.srsLastReviewedAt,
    this.partOfSpeech,
    this.contextSentence,
    this.contextTranslation,
    this.audio,
    this.notes,
    this.createdAt,
    this.sourceVideoId,
    this.sourceTimestamp,
  }) : level = WordLevels.normalize(level);

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val == null) return fallback;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? fallback;
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    return Flashcard(
      id: json['id'] as String? ?? '',
      userId: (json['user_id'] ?? json['userId']) as String? ?? 'guest',
      word: json['word'] as String? ?? '',
      reading: json['reading'] as String?,
      romanization: json['romanization'] as String?,
      pinyin: json['pinyin'] as String?,
      meaning: json['meaning'] as String? ?? '',
      language: json['language'] as String? ?? 'ja',
      level: WordLevels.normalize(json['level']),
      srsInterval: ((json['interval'] ?? json['srs_interval']) as num?)?.toInt() ?? 0,
      srsRepetition: ((json['repetitions'] ?? json['srs_repetition']) as num?)?.toInt() ?? 0,
      srsEaseFactor: ((json['ease_factor'] ?? json['srs_ease_factor']) as num?)?.toDouble() ?? 2.5,
      reviewCount: ((json['review_count'] ?? json['reviewCount']) as num?)?.toInt() ?? 0,
      srsNextReviewAt: parseDate(
        json['next_review_date'] ?? json['srs_next_review_at'] ?? json['nextReviewDate'],
        WordLevels.normalize(json['level']) == WordLevels.known
            ? DateTime.now().add(Duration(
                days: (((json['interval'] ?? json['srs_interval']) as num?)?.toInt() ?? 0) > 0
                    ? (((json['interval'] ?? json['srs_interval']) as num?)?.toInt() ?? 21)
                    : 21))
            : DateTime.now(),
      ),
      srsLastReviewedAt: parseNullableDate(
        json['last_reviewed_at'] ?? json['srs_last_reviewed_at'] ?? json['lastReviewedAt'],
      ),
      partOfSpeech: json['part_of_speech'] as String?,
      contextSentence: (json['source_sentence'] ?? json['context_sentence'] ?? json['sourceSentence']) as String?,
      contextTranslation: (json['context_translation'] ?? json['contextTranslation']) as String?,
      audio: json['audio'] as String?,
      notes: json['notes'] as String?,
      createdAt: parseNullableDate(json['created_at'] ?? json['createdAt']),
      sourceVideoId: (json['source_video_id'] ?? json['sourceVideoId'] ?? json['video_id'] ?? json['videoId']) as String?,
      sourceTimestamp: ((json['source_timestamp'] ?? json['sourceTimestamp'] ?? json['timestamp']) as num?)?.toDouble(),
    );
  }

  Flashcard copyWith({
    String? id,
    String? userId,
    String? word,
    String? reading,
    String? romanization,
    String? pinyin,
    String? meaning,
    String? language,
    String? level,
    int? srsInterval,
    int? srsRepetition,
    double? srsEaseFactor,
    int? reviewCount,
    DateTime? srsNextReviewAt,
    DateTime? srsLastReviewedAt,
    String? partOfSpeech,
    String? contextSentence,
    String? contextTranslation,
    String? audio,
    String? notes,
    DateTime? createdAt,
    String? sourceVideoId,
    double? sourceTimestamp,
  }) {
    return Flashcard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      word: word ?? this.word,
      reading: reading ?? this.reading,
      romanization: romanization ?? this.romanization,
      pinyin: pinyin ?? this.pinyin,
      meaning: meaning ?? this.meaning,
      language: language ?? this.language,
      level: level != null ? WordLevels.normalize(level) : this.level,
      srsInterval: srsInterval ?? this.srsInterval,
      srsRepetition: srsRepetition ?? this.srsRepetition,
      srsEaseFactor: srsEaseFactor ?? this.srsEaseFactor,
      reviewCount: reviewCount ?? this.reviewCount,
      srsNextReviewAt: srsNextReviewAt ?? this.srsNextReviewAt,
      srsLastReviewedAt: srsLastReviewedAt ?? this.srsLastReviewedAt,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      contextSentence: contextSentence ?? this.contextSentence,
      contextTranslation: contextTranslation ?? this.contextTranslation,
      audio: audio ?? this.audio,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      sourceVideoId: sourceVideoId ?? this.sourceVideoId,
      sourceTimestamp: sourceTimestamp ?? this.sourceTimestamp,
    );
  }

  /// Canonical Supabase column representation matching `public.vocabulary` table schema.
  Map<String, dynamic> toBaseJson() => {
    'id': id,
    'user_id': userId,
    'word': word,
    if (reading != null) 'reading': reading,
    if (romanization != null) 'romanization': romanization,
    if (pinyin != null) 'pinyin': pinyin,
    'meaning': meaning,
    'language': language,
    'level': WordLevels.normalize(level),
    'interval': srsInterval,
    'repetitions': srsRepetition,
    'ease_factor': srsEaseFactor,
    'review_count': reviewCount,
    'next_review_date': srsNextReviewAt.toIso8601String(),
    if (srsLastReviewedAt != null) 'last_reviewed_at': srsLastReviewedAt!.toIso8601String(),
    if (sourceVideoId != null) 'source_video_id': sourceVideoId,
    if (sourceTimestamp != null) 'source_timestamp': sourceTimestamp,
  };

  /// Strict Supabase payload containing only existing columns in `public.vocabulary`.
  Map<String, dynamic> toRemoteJson() {
    final map = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'word': word,
      'reading': reading ?? '',
      'pinyin': pinyin ?? '',
      'romanization': romanization ?? '',
      'meaning': meaning,
      'language': language,
      'level': WordLevels.normalize(level),
      'ease_factor': srsEaseFactor,
      'interval': srsInterval,
      'repetitions': srsRepetition,
      'review_count': reviewCount,
      'next_review_date': srsNextReviewAt.toIso8601String(),
      'last_reviewed_at': srsLastReviewedAt?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (contextSentence != null && contextSentence!.isNotEmpty) {
      map['source_sentence'] = contextSentence;
    }
    if (audio != null && audio!.isNotEmpty) {
      map['audio'] = audio;
    }
    if (createdAt != null) {
      map['created_at'] = createdAt!.toIso8601String();
    }
    if (sourceVideoId != null && sourceVideoId!.isNotEmpty) {
      map['source_video_id'] = sourceVideoId;
    }
    if (sourceTimestamp != null) {
      map['source_timestamp'] = sourceTimestamp;
    }
    return map;
  }

  /// Full JSON representation supporting both canonical and legacy keys for local persistence.
  Map<String, dynamic> toJson() {
    final map = toBaseJson();
    if (contextSentence != null) {
      map['source_sentence'] = contextSentence;
      map['context_sentence'] = contextSentence;
    }
    if (contextTranslation != null) map['context_translation'] = contextTranslation;
    if (partOfSpeech != null) map['part_of_speech'] = partOfSpeech;
    if (audio != null) map['audio'] = audio;
    if (notes != null) map['notes'] = notes;
    if (createdAt != null) map['created_at'] = createdAt!.toIso8601String();
    if (sourceVideoId != null) map['source_video_id'] = sourceVideoId;
    if (sourceTimestamp != null) map['source_timestamp'] = sourceTimestamp;
    map['updated_at'] = DateTime.now().toIso8601String();

    // Legacy column aliases for local caches / backwards compatibility:
    map['srs_interval'] = srsInterval;
    map['srs_repetition'] = srsRepetition;
    map['srs_ease_factor'] = srsEaseFactor;
    map['srs_next_review_at'] = srsNextReviewAt.toIso8601String();
    if (srsLastReviewedAt != null) {
      map['srs_last_reviewed_at'] = srsLastReviewedAt!.toIso8601String();
    }
    return map;
  }
}

class WatchHistoryItem {
  final String id;
  final String userId;
  final String videoId;
  final String title;
  final String thumbnail;
  final String channel;
  final int duration;
  final String language;
  final double progress;
  final DateTime watchedAt;

  WatchHistoryItem({
    required this.id,
    required this.userId,
    required this.videoId,
    required this.title,
    required this.thumbnail,
    required this.channel,
    required this.duration,
    required this.language,
    required this.progress,
    required this.watchedAt,
  });

  factory WatchHistoryItem.fromJson(Map<String, dynamic> json) {
    return WatchHistoryItem(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      videoId: json['video_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      thumbnail: json['thumbnail'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      language: json['language'] as String? ?? 'ja',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      watchedAt: json['watched_at'] != null
          ? DateTime.tryParse(json['watched_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'video_id': videoId,
    'title': title,
    'thumbnail': thumbnail,
    'channel': channel,
    'duration': duration,
    'language': language,
    'progress': progress,
    'watched_at': watchedAt.toIso8601String(),
  };
}

class PlaylistItem {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String visibility;
  final String language;
  final int videoCount;
  final String? level;
  final List<String> tags;
  final String? thumbnail;
  final List<String> videoIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlaylistItem({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.visibility = 'private',
    required this.language,
    this.videoCount = 0,
    this.level,
    this.tags = const [],
    this.thumbnail,
    this.videoIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    return PlaylistItem(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      visibility: json['visibility'] as String? ?? 'private',
      language: json['language'] as String? ?? 'ja',
      videoCount: (json['video_count'] as num?)?.toInt() ?? 0,
      level: json['level'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      thumbnail: json['thumbnail'] as String?,
      videoIds: (json['video_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'description': description,
    'visibility': visibility,
    'language': language,
    'video_count': videoCount,
    'level': level,
    'tags': tags,
    'thumbnail': thumbnail,
    'video_ids': videoIds,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

class PlaylistVideo {
  final String videoId;
  final String title;
  final String thumbnail;
  final String? channel;
  final double? duration;
  final int position;
  final String? level;

  const PlaylistVideo({
    required this.videoId,
    required this.title,
    required this.thumbnail,
    this.channel,
    this.duration,
    this.position = 0,
    this.level,
  });

  factory PlaylistVideo.fromJson(Map<String, dynamic> json, {int index = 0}) {
    final vId = (json['video_id'] ?? json['videoId'] ?? json['id'] ?? '').toString();
    return PlaylistVideo(
      videoId: vId,
      title: (json['title'] ?? 'YouTube Video').toString(),
      thumbnail: (json['thumbnail'] ??
              'https://img.youtube.com/vi/$vId/hqdefault.jpg')
          .toString(),
      channel: json['channel'] as String? ?? json['author'] as String?,
      duration: (json['duration'] as num?)?.toDouble(),
      position: (json['position'] as num?)?.toInt() ?? index,
      level: json['level'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'video_id': videoId,
    'title': title,
    'thumbnail': thumbnail,
    'channel': channel,
    'duration': duration,
    'position': position,
    'level': level,
  };
}

enum ProficiencyLevelTier {
  beginner,
  elementary,
  intermediate,
  upperIntermediate,
  advanced;

  String get apiTier => this == ProficiencyLevelTier.upperIntermediate ? 'upper_intermediate' : name;

  static ProficiencyLevelTier fromString(String? val) {
    if (val == null) return ProficiencyLevelTier.intermediate;
    final lower = val.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    if (lower == 'upper_intermediate' || lower == 'upperintermediate') {
      return ProficiencyLevelTier.upperIntermediate;
    }
    for (final t in ProficiencyLevelTier.values) {
      if (t.name.toLowerCase() == lower) return t;
    }
    return ProficiencyLevelTier.intermediate;
  }
}

class VideoLevelInfo {
  final String level;
  final ProficiencyLevelTier tier;
  final double score;
  final double confidence;
  final int grammarCount;
  final double? speechRateCpm;
  final String detectedFrom; // 'title' | 'linguistics' | 'server'
  final Map<String, int>? breakdown;

  VideoLevelInfo({
    required this.level,
    required this.tier,
    this.score = 3.0,
    this.confidence = 0.85,
    this.grammarCount = 0,
    this.speechRateCpm,
    this.detectedFrom = 'server',
    this.breakdown,
  });

  factory VideoLevelInfo.fromJson(Map<String, dynamic> json) {
    return VideoLevelInfo(
      level: json['level'] as String? ?? 'Intermediate',
      tier: ProficiencyLevelTier.fromString(json['tier'] as String?),
      score: (json['score'] as num?)?.toDouble() ?? 3.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.85,
      grammarCount: (json['grammarCount'] as num?)?.toInt() ?? 0,
      speechRateCpm: (json['speechRateCpm'] as num?)?.toDouble(),
      detectedFrom: json['detectedFrom'] as String? ?? 'server',
      breakdown: (json['breakdown'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'level': level,
    'tier': tier.name,
    'score': score,
    'confidence': confidence,
    'grammarCount': grammarCount,
    'speechRateCpm': speechRateCpm,
    'detectedFrom': detectedFrom,
    if (breakdown != null) 'breakdown': breakdown,
  };
}

enum RubyDisplayMode { always, tap, never }
enum SubtitleSize { small, medium, large }

class UserSettings {
  final RubyDisplayMode rubyMode;
  final SubtitleSize subtitleSize;
  final String nativeLanguage;
  final bool autoPauseOnLookup;
  final double playbackRate;
  final String themeMode; // 'system' | 'light' | 'dark'
  final String uiLanguage; // 'en' | 'vi' | 'ja' | 'ko' | 'zh'
  final String readingDisplayMode; // 'annotated' | 'native' | 'reading' | 'annotatedRomanized' | 'romanized'
  final bool showDualSubtitles;
  final String dualSubtitleTargetLang;
  final bool hasSeenSubtitleCoachmark;
  final bool hasCompletedOnboarding;
  final String preferredLevel; // 'beginner' | 'elementary' | 'intermediate' | 'upper_intermediate' | 'advanced'
  final String companionClass; // 'wizard' | 'knight' | 'shinobi' | 'ranger' | 'miner' | 'alchemist' | 'bard' | 'sovereign'
  final int dailyGoalMinutes; // 5 | 10 | 15 | 25

  UserSettings({
    this.rubyMode = RubyDisplayMode.always,
    this.subtitleSize = SubtitleSize.medium,
    this.nativeLanguage = 'en',
    this.autoPauseOnLookup = true,
    this.playbackRate = 1.0,
    this.themeMode = 'system',
    this.uiLanguage = 'en',
    this.readingDisplayMode = 'annotated',
    this.showDualSubtitles = true,
    this.dualSubtitleTargetLang = 'en',
    this.hasSeenSubtitleCoachmark = false,
    this.hasCompletedOnboarding = false,
    this.preferredLevel = 'beginner',
    this.companionClass = 'wizard',
    this.dailyGoalMinutes = 10,
  });

  UserSettings copyWith({
    RubyDisplayMode? rubyMode,
    SubtitleSize? subtitleSize,
    String? nativeLanguage,
    bool? autoPauseOnLookup,
    double? playbackRate,
    String? themeMode,
    String? uiLanguage,
    String? readingDisplayMode,
    bool? showDualSubtitles,
    String? dualSubtitleTargetLang,
    bool? hasSeenSubtitleCoachmark,
    bool? hasCompletedOnboarding,
    String? preferredLevel,
    String? companionClass,
    int? dailyGoalMinutes,
  }) {
    return UserSettings(
      rubyMode: rubyMode ?? this.rubyMode,
      subtitleSize: subtitleSize ?? this.subtitleSize,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      autoPauseOnLookup: autoPauseOnLookup ?? this.autoPauseOnLookup,
      playbackRate: playbackRate ?? this.playbackRate,
      themeMode: themeMode ?? this.themeMode,
      uiLanguage: uiLanguage ?? this.uiLanguage,
      readingDisplayMode: readingDisplayMode ?? this.readingDisplayMode,
      showDualSubtitles: showDualSubtitles ?? this.showDualSubtitles,
      dualSubtitleTargetLang: dualSubtitleTargetLang ?? this.dualSubtitleTargetLang,
      hasSeenSubtitleCoachmark: hasSeenSubtitleCoachmark ?? this.hasSeenSubtitleCoachmark,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      preferredLevel: preferredLevel ?? this.preferredLevel,
      companionClass: companionClass ?? this.companionClass,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
    'rubyMode': rubyMode.name,
    'subtitleSize': subtitleSize.name,
    'nativeLanguage': nativeLanguage,
    'autoPauseOnLookup': autoPauseOnLookup,
    'playbackRate': playbackRate,
    'themeMode': themeMode,
    'uiLanguage': uiLanguage,
    'readingDisplayMode': readingDisplayMode,
    'showDualSubtitles': showDualSubtitles,
    'dualSubtitleTargetLang': dualSubtitleTargetLang,
    'hasSeenSubtitleCoachmark': hasSeenSubtitleCoachmark,
    'hasCompletedOnboarding': hasCompletedOnboarding,
    'preferredLevel': preferredLevel,
    'companionClass': companionClass,
    'dailyGoalMinutes': dailyGoalMinutes,
  };

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      rubyMode: RubyDisplayMode.values.firstWhere(
        (e) => e.name == json['rubyMode'],
        orElse: () => RubyDisplayMode.always,
      ),
      subtitleSize: SubtitleSize.values.firstWhere(
        (e) => e.name == json['subtitleSize'],
        orElse: () => SubtitleSize.medium,
      ),
      nativeLanguage: json['nativeLanguage'] as String? ?? 'en',
      autoPauseOnLookup: json['autoPauseOnLookup'] as bool? ?? true,
      playbackRate: (json['playbackRate'] as num?)?.toDouble() ?? 1.0,
      themeMode: json['themeMode'] as String? ?? 'system',
      uiLanguage: json['uiLanguage'] as String? ?? 'en',
      readingDisplayMode: json['readingDisplayMode'] as String? ?? 'annotated',
      showDualSubtitles: json['showDualSubtitles'] as bool? ?? true,
      dualSubtitleTargetLang: json['dualSubtitleTargetLang'] as String? ?? 'en',
      hasSeenSubtitleCoachmark: json['hasSeenSubtitleCoachmark'] as bool? ?? false,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      preferredLevel: json['preferredLevel'] as String? ?? 'beginner',
      companionClass: json['companionClass'] as String? ?? 'wizard',
      dailyGoalMinutes: json['dailyGoalMinutes'] as int? ?? 10,
    );
  }
}

