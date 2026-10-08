// test/kanji_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/kanji_service.dart';

void main() {
  group('KanjiService & KanjiData Tests', () {
    test('extractUniqueKanji extracts all kanji ideographs in order without duplicates', () {
      final service = KanjiService.instance;

      expect(service.extractUniqueKanji('食べる'), equals(['食']));
      expect(service.extractUniqueKanji('時間'), equals(['時', '間']));
      expect(service.extractUniqueKanji('日本語能力試験'), equals(['日', '本', '語', '能', '力', '試', '験']));
      expect(service.extractUniqueKanji('日日是好日'), equals(['日', '是', '好']));
      expect(service.extractUniqueKanji('こんにちは'), isEmpty);
      expect(service.extractUniqueKanji('Hello World 123!'), isEmpty);
    });

    test('hasKanji accurately detects presence of CJK kanji characters', () {
      final service = KanjiService.instance;

      expect(service.hasKanji('食べる'), isTrue);
      expect(service.hasKanji('映画館'), isTrue);
      expect(service.hasKanji('ひらがな'), isFalse);
      expect(service.hasKanji('カタカナ'), isFalse);
      expect(service.hasKanji('English'), isFalse);
    });

    test('KanjiData deserializes from JSON with correct fields and SVG URLs', () {
      final json = {
        'literal': '食',
        'meanings': ['eat', 'food'],
        'stroke_count': 9,
        'grade': 2,
        'jlpt': 5,
        'frequency': 328,
        'onyomi': ['ショク', 'ジキ'],
        'kunyomi': ['く.う', 'た.べる'],
        'chinese': ['shi2'],
        'korean_r': ['sig'],
        'korean_h': ['식'],
        'radical': '食',
        'parts': ['食'],
      };

      final kanji = KanjiData.fromJson(json);

      expect(kanji.literal, equals('食'));
      expect(kanji.meanings, equals(['eat', 'food']));
      expect(kanji.strokeCount, equals(9));
      expect(kanji.grade, equals(2));
      expect(kanji.jlpt, equals(5));
      expect(kanji.frequency, equals(328));
      expect(kanji.onyomi, equals(['ショク', 'ジキ']));
      expect(kanji.kunyomi, equals(['く.う', 'た.べる']));
      expect(kanji.chinese, equals(['shi2']));
      expect(kanji.koreanH, equals(['식']));
      expect(kanji.radical, equals('食'));
      expect(kanji.parts, equals(['食']));

      expect(kanji.animationSvgUrl, equals('https://jotoba.de/resource/kanji/animation/食'));
      expect(kanji.framesSvgUrl, equals('https://jotoba.de/resource/kanji/frames/食'));

      final serialized = kanji.toJson();
      expect(serialized['literal'], equals('食'));
      expect(serialized['stroke_count'], equals(9));
      expect(serialized['jlpt'], equals(5));
    });

    test('KanjiData handles missing and null values safely', () {
      final json = <String, dynamic>{
        'literal': '漢',
      };

      final kanji = KanjiData.fromJson(json);

      expect(kanji.literal, equals('漢'));
      expect(kanji.strokeCount, equals(0));
      expect(kanji.meanings, isEmpty);
      expect(kanji.onyomi, isEmpty);
      expect(kanji.kunyomi, isEmpty);
      expect(kanji.grade, isNull);
      expect(kanji.jlpt, isNull);
      expect(kanji.radical, isNull);
    });
  });
}
