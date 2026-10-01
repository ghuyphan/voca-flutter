// lib/services/voca_api_client.dart

import 'dart:async';
import 'package:dio/dio.dart';
import '../models/voca_models.dart';

class VocaApiClient {
  static const String baseUrl = 'https://voca.study';
  late final Dio _dio;

  VocaApiClient({String? authToken}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        // Mandatory User-Agent to bypass Cloudflare Bot Defense
        'User-Agent': 'VocaMobile/1.0.0 (Flutter; Android/iOS)',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException err, handler) {
        if (err.response?.statusCode == 429) {
          final retryAfter = err.response?.headers.value('retry-after') ?? '60';
          // Rate limited, log and propagate
          print('[VocaApiClient] Rate limited. Retry after $retryAfter seconds');
        }
        return handler.next(err);
      },
    ));
  }

  /// 1. Fetch transcript with Gladia ASR auto-polling & background auto-resumption support
  Future<TranscriptResponse> getTranscript({
    required String videoId,
    required String lang,
    bool preferAI = false,
    bool forceRefresh = false,
    String? turnstileToken,
    String? jobId,
    int? duration,
    Function(String status)? onProgress,
  }) async {
    final response = await _dio.post('/api/transcript', data: {
      'videoId': videoId,
      'lang': lang,
      'preferAI': preferAI,
      'forceRefresh': forceRefresh,
      if (jobId != null) 'jobId': jobId,
      if (turnstileToken != null) 'turnstileToken': turnstileToken,
      if (duration != null) 'duration': duration,
    });

    final res = TranscriptResponse.fromJson(response.data as Map<String, dynamic>);

    // Handle Gladia AI queued polling
    if (res.isProcessing && res.resultUrl != null) {
      onProgress?.call('Transcribing audio with Gladia AI...');
      return _pollGladiaResult(videoId, lang, res.resultUrl!, onProgress);
    }

    return res;
  }

  Future<TranscriptResponse> _pollGladiaResult(
    String videoId,
    String lang,
    String resultUrl,
    Function(String status)? onProgress,
  ) async {
    const int maxRetries = 25; // ~75 seconds
    for (int i = 0; i < maxRetries; i++) {
      await Future.delayed(const Duration(milliseconds: 3000));
      onProgress?.call('AI transcription in progress (${(i + 1) * 3}s)...');

      final pollRes = await _dio.post('/api/transcript', data: {
        'videoId': videoId,
        'lang': lang,
        'resultUrl': resultUrl,
      });

      final parsed = TranscriptResponse.fromJson(pollRes.data as Map<String, dynamic>);
      if (parsed.success) {
        return parsed;
      }
      if (parsed.errorCode != null && parsed.errorCode != 'AI_PROCESSING') {
        throw Exception(parsed.error ?? 'AI transcription failed');
      }
    }
    throw Exception('Gladia transcription timed out after 75s');
  }

  /// 2. Batch tokenize subtitle cues (videoId and texts are REQUIRED)
  Future<List<List<Token>>> tokenizeBatch({
    required String videoId,
    required String lang,
    required List<String> texts,
  }) async {
    if (texts.isEmpty) return [];

    final response = await _dio.post(
      '/api/tokenize-batch/$lang',
      data: {
        'videoId': videoId,
        'texts': texts,
      },
    );

    final rawTokens = response.data['tokens'] as List<dynamic>?;
    if (rawTokens == null) return [];

    return rawTokens.map((line) {
      return (line as List<dynamic>)
          .map((t) => Token.fromJson(t as Map<String, dynamic>))
          .toList();
    }).toList();
  }

  /// 3. Multi-source dictionary search
  Future<DictionaryResult> lookupDictionary({
    required String word,
    required String from,
    required String to,
  }) async {
    final response = await _dio.get(
      '/api/dict',
      queryParameters: {'word': word, 'from': from, 'to': to},
    );
    return DictionaryResult.fromJson(response.data as Map<String, dynamic>);
  }

  /// 4. Urgent seek micro-batch (< 200ms) for immediate bilingual cue display
  Future<void> translateUrgentSeek({
    required List<SubtitleCue> cues,
    required int activeIndex,
    required String sourceLang,
    required String targetLang,
  }) async {
    if (activeIndex < 0 || activeIndex >= cues.length) return;
    final end = (activeIndex + 3).clamp(0, cues.length);
    final slice = cues.sublist(activeIndex, end);
    final missing = slice.where((c) => c.translation == null || c.translation!.isEmpty).toList();
    if (missing.isEmpty) return;

    final translations = await translateBatch(
      texts: missing.map((c) => c.text).toList(),
      sourceLang: sourceLang,
      targetLang: targetLang,
    );

    for (int i = 0; i < missing.length && i < translations.length; i++) {
      missing[i].translation = translations[i];
    }
  }

  /// 5. Low-latency batch translation (Edge LRU in-memory + KV cache)
  Future<List<String>> translateBatch({
    required List<String> texts,
    required String sourceLang,
    required String targetLang,
  }) async {
    if (texts.isEmpty) return [];
    final response = await _dio.post(
      '/api/translate/batch',
      data: {
        'texts': texts,
        'source': sourceLang,
        'target': targetLang,
      },
    );

    final list = response.data['translations'] as List<dynamic>?;
    return list?.map((e) => e.toString()).toList() ?? [];
  }

  /// 6. Synchronized whole-video dual subtitles (Cloudflare R2 cached)
  Future<List<SubtitleCue>> getDualSubtitles({
    required String videoId,
    required String sourceLang,
    required String targetLang,
    required List<SubtitleCue> segments,
  }) async {
    final response = await _dio.post('/api/dual-subtitles', data: {
      'videoId': videoId,
      'sourceLang': sourceLang,
      'targetLang': targetLang,
      'segments': segments.map((s) => {'start': s.start, 'duration': s.duration, 'text': s.text}).toList(),
    });

    if (response.data['segments'] != null) {
      return (response.data['segments'] as List)
          .map((s) => SubtitleCue.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    return segments;
  }

  /// 7. Recommended videos list with pre-cached transcripts
  Future<List<Map<String, dynamic>>> getRecommendedVideos({
    String lang = 'ja',
    String? tier,
    int limit = 12,
    int offset = 0,
    bool refresh = false,
  }) async {
    final response = await _dio.get('/api/recommended-videos', queryParameters: {
      'lang': lang,
      if (tier != null) 'tier': tier,
      'limit': limit,
      'offset': offset,
      if (refresh) 'refresh': 'true',
    });

    final videos = response.data['videos'] as List<dynamic>?;
    return videos?.map((v) => Map<String, dynamic>.from(v as Map)).toList() ?? [];
  }

  /// 8. Two-tier video metadata check
  Future<Map<String, dynamic>> getVideoInfo({required String videoId}) async {
    final response = await _dio.get('/api/video-info', queryParameters: {
      'videoId': videoId,
    });
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// 9. Diamond credits balance and regen timer
  Future<Map<String, dynamic>> getDiamonds() async {
    final response = await _dio.get('/api/diamonds');
    return Map<String, dynamic>.from(response.data as Map);
  }
}
