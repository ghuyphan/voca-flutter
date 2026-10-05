// lib/services/voca_api_client.dart

import 'dart:async';
import 'dart:typed_data';
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
  /// First checks GET /api/dual-subtitles for R2 pre-cached whole-video translation.
  Future<List<SubtitleCue>?> getCachedDualSubtitles({
    required String videoId,
    required String sourceLang,
    required String targetLang,
  }) async {
    try {
      final response = await _dio.get('/api/dual-subtitles', queryParameters: {
        'videoId': videoId,
        'sourceLang': sourceLang,
        'targetLang': targetLang,
      });

      if (response.data != null &&
          response.data['cached'] == true &&
          response.data['segments'] != null) {
        return (response.data['segments'] as List)
            .map((s) => SubtitleCue.fromJson(s as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // 404 or cache miss: normal flow
    }
    return null;
  }

  /// Synchronized whole-video dual subtitles (Cloudflare R2 cached or generated)
  Future<List<SubtitleCue>> getDualSubtitles({
    required String videoId,
    required String sourceLang,
    required String targetLang,
    required List<SubtitleCue> segments,
  }) async {
    // 1. Try fast GET R2 cache first
    final cached = await getCachedDualSubtitles(
      videoId: videoId,
      sourceLang: sourceLang,
      targetLang: targetLang,
    );
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    // 2. If <= 40 segments, request Cloudflare Worker batch
    if (segments.length <= 40) {
      try {
        final response = await _dio.post('/api/dual-subtitles', data: {
          'videoId': videoId,
          'sourceLang': sourceLang,
          'targetLang': targetLang,
          'segments': segments
              .map((s) => {'start': s.start, 'duration': s.duration, 'text': s.text})
              .toList(),
        });

        if (response.data != null && response.data['segments'] != null) {
          return (response.data['segments'] as List)
              .map((s) => SubtitleCue.fromJson(s as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }

    return segments;
  }

  /// Persist completed dual subtitle segments to Cloudflare R2 / Edge cache
  Future<bool> saveDualSubtitles({
    required String videoId,
    required String sourceLang,
    required String targetLang,
    required List<Map<String, dynamic>> segments,
  }) async {
    try {
      final response = await _dio.post('/api/dual-subtitles', data: {
        'videoId': videoId,
        'sourceLang': sourceLang,
        'targetLang': targetLang,
        'segments': segments,
        'saveOnly': true,
      });
      return response.data != null &&
          (response.data['success'] == true ||
              response.data['saved'] == true ||
              response.data['cached'] == true);
    } catch (e) {
      return false;
    }
  }

  /// 7. Recommended videos list with pre-cached transcripts
  Future<List<Map<String, dynamic>>> getRecommendedVideos({
    String lang = 'ja',
    String? tier,
    String? query,
    int limit = 20,
    int offset = 0,
    bool refresh = false,
  }) async {
    final response = await _dio.get('/api/recommended-videos', queryParameters: {
      'lang': lang,
      if (tier != null && tier != 'all') 'tier': tier,
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
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

  /// 10. Fetch Edge Neural TTS audio bytes with mandatory User-Agent
  Future<Uint8List?> fetchTtsAudio({
    required String text,
    required String lang,
  }) async {
    if (text.trim().isEmpty) return null;
    try {
      final response = await _dio.get<List<int>>(
        '/api/tts',
        queryParameters: {
          'lang': lang,
          'text': text.trim(),
        },
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'audio/mpeg'},
        ),
      );
      if (response.data != null && response.data!.isNotEmpty) {
        return Uint8List.fromList(response.data!);
      }
      return null;
    } catch (e) {
      print('[VocaApiClient] TTS fetch error: $e');
      return null;
    }
  }

  /// 11. Fetch current server version metadata and changelog
  Future<Map<String, dynamic>?> fetchVersionInfo() async {
    try {
      final response = await _dio.get('/api/version');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return null;
    } catch (e) {
      print('[VocaApiClient] Version fetch error: $e');
      return null;
    }
  }
}
