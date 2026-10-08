// lib/services/kanji_service.dart

import 'dart:async';
import 'package:dio/dio.dart';
import '../models/voca_models.dart';
import 'voca_api_client.dart';

class KanjiService {
  KanjiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: VocaApiClient.baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        // Mandatory Anti-Bot User-Agent Header (Rule 2)
        'User-Agent': 'VocaMobile/1.0.0 (Android; Mobile)',
      },
    ));

    _jotobaDio = Dio(BaseOptions(
      baseUrl: 'https://jotoba.de',
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        'Referer': 'https://jotoba.de/',
      },
    ));
  }

  static final KanjiService instance = KanjiService._();

  late final Dio _dio;
  late final Dio _jotobaDio;
  final Map<String, KanjiData> _cache = {};

  /// CJK Unified Ideographs range (\u4E00 - \u9FAF)
  static final RegExp _kanjiRegex = RegExp(r'[\u4E00-\u9FAF]');

  /// Check whether text contains any Kanji characters
  bool hasKanji(String text) {
    return _kanjiRegex.hasMatch(text);
  }

  /// Extract unique Kanji characters from a text in appearance order
  List<String> extractUniqueKanji(String text) {
    if (text.isEmpty) return const [];
    final seen = <String>{};
    final result = <String>[];
    for (final match in _kanjiRegex.allMatches(text)) {
      final char = match.group(0)!;
      if (seen.add(char)) {
        result.add(char);
      }
    }
    return result;
  }

  /// Check if a character is cached in memory
  KanjiData? getCached(String kanji) => _cache[kanji];

  /// Lookup all Kanji characters for a word or phrase via Edge backend /api/kanji
  /// with automatic fallback directly to Jotoba upstream API.
  Future<List<KanjiData>> lookupWordKanji(String word) async {
    final trimmed = word.trim();
    if (trimmed.isEmpty) return const [];

    final kanjisInWord = extractUniqueKanji(trimmed);
    if (kanjisInWord.isEmpty) return const [];

    // Check if all characters are already cached
    final allCached = kanjisInWord.every((k) => _cache.containsKey(k));
    if (allCached) {
      return kanjisInWord.map((k) => _cache[k]!).toList();
    }

    // 1. Try our Edge backend /api/kanji
    try {
      final response = await _dio.get(
        '/api/kanji',
        queryParameters: {'query': trimmed},
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final list = (response.data['kanji'] as List<dynamic>?) ?? [];
        final results = <KanjiData>[];
        for (final item in list) {
          if (item is Map) {
            final data = KanjiData.fromJson(Map<String, dynamic>.from(item));
            if (data.literal.isNotEmpty) {
              _cache[data.literal] = data;
              results.add(data);
            }
          }
        }
        if (results.isNotEmpty) {
          return results;
        }
      }
    } catch (_) {
      // Backend /api/kanji not deployed or returned error; proceed to upstream fallback
    }

    // 2. Direct Fallback to Jotoba API (same upstream source used by Edge function)
    try {
      final jotobaResponse = await _jotobaDio.post(
        '/api/search/kanji',
        data: {'query': trimmed, 'language': 'English'},
      );

      if (jotobaResponse.statusCode == 200 &&
          jotobaResponse.data is Map<String, dynamic>) {
        final list = (jotobaResponse.data['kanji'] as List<dynamic>?) ?? [];
        final results = <KanjiData>[];
        for (final item in list) {
          if (item is Map) {
            final data = KanjiData.fromJson(Map<String, dynamic>.from(item));
            if (data.literal.isNotEmpty) {
              _cache[data.literal] = data;
              results.add(data);
            }
          }
        }
        if (results.isNotEmpty) {
          return results;
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('[KanjiService] Upstream Jotoba kanji lookup failed for "$trimmed": $e');
    }

    // 3. Fallback: Return any cached entries we have
    return kanjisInWord.map((k) => _cache[k]).whereType<KanjiData>().toList();
  }

  /// Lookup a single Kanji from cache, Edge backend, or upstream Jotoba
  Future<KanjiData?> lookupKanji(String kanji) async {
    final trimmed = kanji.trim();
    if (trimmed.isEmpty) return null;

    final cached = _cache[trimmed];
    if (cached != null) return cached;

    final list = await lookupWordKanji(trimmed);
    if (list.isEmpty) return null;

    return list.firstWhere(
      (k) => k.literal == trimmed,
      orElse: () => list.first,
    );
  }
}
