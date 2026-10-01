// lib/services/grammar_engine.dart

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/voca_models.dart';

class GrammarEngine {
  final Map<String, List<GrammarPattern>> _patternsByLang = {};
  final Map<String, Map<String, List<GrammarPattern>>> _indicesByLang = {};

  static const List<String> _jaEndingPatterns = [
    'ている', 'ていた', 'ています', 'ていました',
    'たい', 'たかった', 'たくない',
    'ない', 'なかった', 'ません',
    'れる', 'られる', 'させる',
    'たら', 'たり', 'ても', 'ば', 'なければ',
    'てもいい', 'てはいけない',
    'てしまう', 'ちゃう', 'ておく', 'とく',
    'かもしれない', 'はずだ', 'ようだ', 'そうだ',
  ];

  static const List<String> _koEndingPatterns = [
    '은', '는', '이', '가', '을', '를', '에', '에서', '도', '만',
    '과', '와', '로', '으로', '보다', '부터', '까지',
    '고', '고 있다', '고 싶다', '지 않다', '지 못하다',
    '아서', '어서', '면', '으면', '려고 하다',
    'ㄹ 수 있다', '을 수 있다', '수 있다',
    '아야 하다', '어야 하다', '아/어 보다',
  ];

  static const List<Map<String, String>> _zhSplitRules = [
    {'start': '虽然', 'end': '但是', 'key': '虽然但是'},
    {'start': '因为', 'end': '所以', 'key': '因为所以'},
    {'start': '如果', 'end': '就', 'key': '如果就'},
    {'start': '不但', 'end': '而且', 'key': '不但而且'},
    {'start': '越', 'end': '越', 'key': '越越'},
    {'start': '一边', 'end': '一边', 'key': '一边一边'},
    {'start': '除了', 'end': '以外', 'key': '除了以外'},
    {'start': '是', 'end': '的', 'key': '是的'},
    {'start': '既然', 'end': '就', 'key': '既然就'},
    {'start': '只要', 'end': '就', 'key': '只要就'},
    {'start': '只有', 'end': '才', 'key': '只有才'},
  ];

  /// Initialize and load grammar patterns for target language from assets
  Future<void> loadLanguage(String lang) async {
    if (_patternsByLang.containsKey(lang)) return;

    try {
      final jsonStr = await rootBundle.loadString('assets/grammar/grammar_$lang.json');
      final list = jsonDecode(jsonStr) as List<dynamic>;
      final patterns = list.map((p) => GrammarPattern.fromJson(p as Map<String, dynamic>)).toList();

      _patternsByLang[lang] = patterns;
      _indicesByLang[lang] = _buildIndex(patterns, lang);
    } catch (e) {
      print('[GrammarEngine] Warning: Could not load assets/grammar/grammar_$lang.json: $e');
    }
  }

  Map<String, List<GrammarPattern>> _buildIndex(List<GrammarPattern> patterns, String lang) {
    final index = <String, List<GrammarPattern>>{};

    void add(String raw, GrammarPattern pattern) {
      final key = _normalize(raw);
      if (key.isEmpty) return;
      index.putIfAbsent(key, () => []).add(pattern);
    }

    for (final p in patterns) {
      add(p.id, p);
      add(p.pattern, p);

      if (p.pattern.contains('(') || p.pattern.contains(')')) {
        add(p.pattern.replaceAll(RegExp(r'[()（）]'), ''), p);
      }
      if (p.pattern.contains('/')) {
        for (final part in p.pattern.split('/')) {
          add(part, p);
        }
      }
    }
    return index;
  }

  String _normalize(String text) {
    return text
        .replaceAll(RegExp(r'[~～〜。、・….\s?？！!,，:：;；"“”‘’()（）\[\]【】]'), '')
        .toLowerCase();
  }

  /// Detect grammar patterns in a sequence of subtitle tokens
  List<GrammarMatch> detectPatterns(List<Token> tokens, String lang) {
    final index = _indicesByLang[lang];
    if (index == null || tokens.isEmpty) return [];

    final matches = <GrammarMatch>[];

    // Strategy 1: Multi-token sequence matching (window size 1 to 5)
    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i].isPunctuation || tokens[i].surface.trim().isEmpty) continue;

      for (int len = 1; len <= 5 && (i + len) <= tokens.length; len++) {
        final seq = tokens.sublist(i, i + len);
        if (seq.last.isPunctuation) continue;

        final seqText = seq.map((t) => t.surface).join();
        final norm = _normalize(seqText);

        final hits = index[norm];
        if (hits != null && hits.isNotEmpty) {
          matches.add(GrammarMatch(
            pattern: hits.first,
            tokenIndices: List.generate(len, (idx) => i + idx),
            startIndex: i,
            endIndex: i + len - 1,
          ));
        }
      }
    }

    // Strategy 2: Japanese verb ending & baseForm detection
    if (lang == 'ja') {
      for (int i = 0; i < tokens.length; i++) {
        final t = tokens[i];
        if (t.isPunctuation) continue;

        for (final ending in _jaEndingPatterns) {
          if (t.surface.endsWith(ending)) {
            final hits = index[_normalize(ending)];
            if (hits != null && hits.isNotEmpty) {
              matches.add(GrammarMatch(
                pattern: hits.first,
                tokenIndices: [i],
                startIndex: i,
                endIndex: i,
              ));
              break;
            }
          }
        }

        if (t.baseForm != null && t.baseForm != t.surface) {
          final hits = index[_normalize(t.baseForm!)];
          if (hits != null && hits.isNotEmpty) {
            matches.add(GrammarMatch(
              pattern: hits.first,
              tokenIndices: [i],
              startIndex: i,
              endIndex: i,
            ));
          }
        }
      }
    }

    // Strategy 3: Korean verb endings & postpositions
    if (lang == 'ko') {
      for (int i = 0; i < tokens.length; i++) {
        final t = tokens[i];
        if (t.isPunctuation) continue;

        for (final ending in _koEndingPatterns) {
          if (t.surface.endsWith(ending)) {
            final hits = index[_normalize(ending)];
            if (hits != null && hits.isNotEmpty) {
              matches.add(GrammarMatch(
                pattern: hits.first,
                tokenIndices: [i],
                startIndex: i,
                endIndex: i,
              ));
              break;
            }
          }
        }
      }
    }

    // Strategy 4: Chinese split correlatives (虽然...但是)
    if (lang == 'zh') {
      for (final rule in _zhSplitRules) {
        final startIdx = tokens.indexWhere((t) => _normalize(t.surface) == _normalize(rule['start']!));
        if (startIdx != -1) {
          final endIdx = tokens.indexWhere(
            (t) => _normalize(t.surface) == _normalize(rule['end']!),
            startIdx + 1,
          );
          if (endIdx != -1) {
            final hits = index[_normalize(rule['key']!)];
            if (hits != null && hits.isNotEmpty) {
              matches.add(GrammarMatch(
                pattern: hits.first,
                tokenIndices: [startIdx, endIdx],
                startIndex: startIdx,
                endIndex: endIdx,
              ));
            }
          }
        }
      }
    }

    // Deduplicate matches on overlapping spans
    final seen = <String>{};
    return matches.where((m) {
      final key = '${m.pattern.id}_${m.tokenIndices.join(",")}';
      return seen.add(key);
    }).toList();
  }
}
