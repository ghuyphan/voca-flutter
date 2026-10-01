// lib/models/voca_models.dart

class Token {
  final String surface;
  final String? reading;
  final String? romanization;
  final String? pinyin;
  final String? baseForm;
  final String? partOfSpeech;
  final bool isPunctuation;

  Token({
    required this.surface,
    this.reading,
    this.romanization,
    this.pinyin,
    this.baseForm,
    this.partOfSpeech,
    this.isPunctuation = false,
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
      levels: (json['levels'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? {},
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

  Map<String, dynamic> toJson() => {
    'sentence': sentence,
    'romanization': romanization,
    'translation': translation,
  };
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
      word: json['word'] as String? ?? '',
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      source: json['source'] as String? ?? 'none',
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) => DictionaryEntry.fromJson(e as Map<String, dynamic>))
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
      word: json['word'] as String?,
      reading: json['reading'] as String?,
      romaji: json['romaji'] as String?,
      partOfSpeech: json['partOfSpeech'] as String?,
      definitions: (json['definitions'] as List<dynamic>?)
              ?.map((d) => d.toString())
              .toList() ??
          [],
      level: json['level'] as String?,
      audio: json['audio'] as String?,
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

class Flashcard {
  final String id;
  final String userId;
  final String word;
  final String? reading;
  final String? romanization;
  final String? pinyin;
  final String meaning;
  final String language;
  final String level; // 'new' | 'learning' | 'known' | 'mastered'
  final int srsInterval;
  final int srsRepetition;
  final double srsEaseFactor;
  final DateTime srsNextReviewAt;
  final DateTime? srsLastReviewedAt;

  Flashcard({
    required this.id,
    required this.userId,
    required this.word,
    this.reading,
    this.romanization,
    this.pinyin,
    required this.meaning,
    required this.language,
    this.level = 'new',
    this.srsInterval = 0,
    this.srsRepetition = 0,
    this.srsEaseFactor = 2.5,
    required this.srsNextReviewAt,
    this.srsLastReviewedAt,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      word: json['word'] as String,
      reading: json['reading'] as String?,
      romanization: json['romanization'] as String?,
      pinyin: json['pinyin'] as String?,
      meaning: json['meaning'] as String? ?? '',
      language: json['language'] as String,
      level: json['level'] as String? ?? 'new',
      srsInterval: json['srs_interval'] as int? ?? 0,
      srsRepetition: json['srs_repetition'] as int? ?? 0,
      srsEaseFactor: (json['srs_ease_factor'] as num?)?.toDouble() ?? 2.5,
      srsNextReviewAt: DateTime.parse(json['srs_next_review_at'] as String),
      srsLastReviewedAt: json['srs_last_reviewed_at'] != null
          ? DateTime.parse(json['srs_last_reviewed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'word': word,
    'reading': reading,
    'romanization': romanization,
    'pinyin': pinyin,
    'meaning': meaning,
    'language': language,
    'level': level,
    'srs_interval': srsInterval,
    'srs_repetition': srsRepetition,
    'srs_ease_factor': srsEaseFactor,
    'srs_next_review_at': srsNextReviewAt.toIso8601String(),
    'srs_last_reviewed_at': srsLastReviewedAt?.toIso8601String(),
  };
}
