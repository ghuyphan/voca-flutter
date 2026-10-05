// lib/services/grammar_engine.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:signals_flutter/signals_flutter.dart';
import '../models/voca_models.dart';
import 'i18n_service.dart';

class GrammarEngine {
  final Map<String, List<GrammarPattern>> _patternsByLang = {};
  final Map<String, Map<String, List<GrammarPattern>>> _indicesByLang = {};
  final Map<String, Map<String, GrammarTranslation>> _translationsByKey = {};

  /// Reactive signal of loaded languages to trigger UI auto-recompute when pattern lazy loading finishes
  final loadedLanguages = signal<Set<String>>({});

  /// Reactive signal of loaded translations to trigger UI auto-recompute when translation lazy loading finishes
  final loadedTranslations = signal<Set<String>>({});

  final Map<String, Future<void>> _patternPromises = {};
  final Map<String, Future<Map<String, GrammarTranslation>>> _translationPromises = {};

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
    if (_patternsByLang.containsKey(lang)) {
      if (!loadedLanguages.value.contains(lang)) {
        loadedLanguages.value = {...loadedLanguages.value, lang};
      }
      return;
    }

    if (_patternPromises.containsKey(lang)) {
      return _patternPromises[lang]!;
    }

    final future = () async {
      try {
        final jsonStr = await rootBundle.loadString('assets/grammar/grammar_$lang.json');
        final list = jsonDecode(jsonStr) as List<dynamic>;
        final patterns = list.map((p) => GrammarPattern.fromJson(p as Map<String, dynamic>)).toList();

        _patternsByLang[lang] = patterns;
        _indicesByLang[lang] = _buildIndex(patterns, lang);
        loadedLanguages.value = {...loadedLanguages.value, lang};
      } catch (e) {
        debugPrint('[GrammarEngine] Warning: Could not load assets/grammar/grammar_$lang.json: $e');
      } finally {
        _patternPromises.remove(lang);
      }
    }();

    _patternPromises[lang] = future;
    return future;
  }

  /// Lazy-load translation pack for a learning language and UI language
  Future<Map<String, GrammarTranslation>> loadTranslation(String learningLang, String uiLang) async {
    if (uiLang == 'en' || learningLang.isEmpty || uiLang.isEmpty) {
      return {};
    }

    final key = '${learningLang}_$uiLang';
    if (_translationsByKey.containsKey(key)) {
      return _translationsByKey[key]!;
    }

    if (_translationPromises.containsKey(key)) {
      return _translationPromises[key]!;
    }

    final future = () async {
      try {
        final jsonStr = await rootBundle.loadString('assets/grammar/translations/${learningLang}_$uiLang.json');
        final rawMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        final translations = rawMap.map(
          (k, v) => MapEntry(k, GrammarTranslation.fromJson(v as Map<String, dynamic>)),
        );
        _translationsByKey[key] = translations;
        loadedTranslations.value = {...loadedTranslations.value, key};
        return translations;
      } catch (e) {
        debugPrint('[GrammarEngine] Warning: Could not load assets/grammar/translations/${learningLang}_$uiLang.json: $e');
        return <String, GrammarTranslation>{};
      } finally {
        _translationPromises.remove(key);
      }
    }();

    _translationPromises[key] = future;
    return future;
  }

  /// Get already loaded translation pack synchronously
  Map<String, GrammarTranslation>? getLoadedTranslation(String learningLang, String uiLang) {
    return _translationsByKey['${learningLang}_$uiLang'];
  }

  /// Get a localized copy of the grammar pattern for the given UI language
  GrammarPattern getLocalizedPattern(GrammarPattern pattern, String uiLang) {
    if (uiLang == 'en' || uiLang.isEmpty) {
      return pattern;
    }

    final key = '${pattern.language}_$uiLang';
    final translations = _translationsByKey[key];
    if (translations == null) {
      loadTranslation(pattern.language, uiLang);
      return pattern;
    }

    final trans = translations[pattern.id];
    if (trans == null) {
      return pattern;
    }

    return pattern.copyWith(
      title: (trans.title != null && trans.title!.isNotEmpty) ? trans.title : pattern.title,
      shortExplanation: (trans.shortExplanation != null && trans.shortExplanation!.isNotEmpty)
          ? trans.shortExplanation
          : pattern.shortExplanation,
      longExplanation: (trans.longExplanation != null && trans.longExplanation!.isNotEmpty)
          ? trans.longExplanation
          : pattern.longExplanation,
      formation: (trans.formation != null && trans.formation!.isNotEmpty)
          ? trans.formation
          : pattern.formation,
      examples: pattern.examples.asMap().entries.map((entry) {
        final idx = entry.key;
        final ex = entry.value;
        final transEx = (trans.examples != null && idx < trans.examples!.length)
            ? trans.examples![idx]
            : null;
        return ex.copyWith(
          translation: (transEx != null && transEx.translation.isNotEmpty)
              ? transEx.translation
              : ex.translation,
        );
      }).toList(),
    );
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
  List<GrammarMatch> detectPatterns(List<Token> tokens, String lang, {String? uiLang}) {
    final effectiveUiLang = uiLang ?? (I18nService.instance.isInitialized ? I18nService.instance.currentLanguage.value : 'en');
    final index = _indicesByLang[lang];
    if (index == null) {
      // Proactively load patterns in background matching lingua-tube behavior
      loadLanguage(lang);
      if (effectiveUiLang != 'en') {
        loadTranslation(lang, effectiveUiLang);
      }
      return [];
    }
    if (effectiveUiLang != 'en') {
      final transKey = '${lang}_$effectiveUiLang';
      if (!_translationsByKey.containsKey(transKey)) {
        loadTranslation(lang, effectiveUiLang);
      }
    }
    if (tokens.isEmpty) return [];

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
        } else if (lang == 'ko' && norm.length >= 3) {
          // Korean sub-sequence suffix checking (1:1 with lingua-tube)
          for (int sLen = norm.length - 1; sLen >= 2; sLen--) {
            final suffix = norm.substring(norm.length - sLen);
            final suffixHits = index[suffix];
            if (suffixHits != null && suffixHits.isNotEmpty) {
              matches.add(GrammarMatch(
                pattern: suffixHits.first,
                tokenIndices: List.generate(len, (idx) => i + idx),
                startIndex: i,
                endIndex: i + len - 1,
              ));
              break;
            }
          }
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
    final uniqueMatches = matches.where((m) {
      final key = '${m.pattern.id}_${m.tokenIndices.join(",")}';
      return seen.add(key);
    }).toList();

    if (effectiveUiLang != 'en') {
      return uniqueMatches.map((m) => GrammarMatch(
        pattern: getLocalizedPattern(m.pattern, effectiveUiLang),
        tokenIndices: m.tokenIndices,
        startIndex: m.startIndex,
        endIndex: m.endIndex,
      )).toList();
    }

    return uniqueMatches;
  }
}
