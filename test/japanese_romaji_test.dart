import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/utils/japanese_romaji.dart';

void main() {
  group('Japanese Romaji & Kana Utilities', () {
    test('converts simple hiragana to romaji', () {
      expect(toJapaneseRomaji('と'), 'to');
      expect(toJapaneseRomaji('たび'), 'tabi');
      expect(toJapaneseRomaji('あふれ'), 'afure');
      expect(toJapaneseRomaji('であう'), 'deau');
    });

    test('converts katakana to hiragana', () {
      expect(katakanaToHiragana('デアウ'), 'であう');
      expect(katakanaToHiragana('タビ'), 'たび');
      expect(katakanaToHiragana('ト'), 'と');
    });

    test('converts katakana to romaji', () {
      expect(toJapaneseRomaji('デアウ'), 'deau');
      expect(toJapaneseRomaji('ラーメン'), 'rāmen');
    });

    test('handles small tsu sokuon (gemination)', () {
      expect(toJapaneseRomaji('もっと'), 'motto');
      expect(toJapaneseRomaji('やっぱり'), 'yappari');
      expect(toJapaneseRomaji('きって'), 'kitte');
    });

    test('handles digraphs (youon)', () {
      expect(toJapaneseRomaji('きょう'), 'kyou');
      expect(toJapaneseRomaji('しょくどう'), 'shokudou');
      expect(toJapaneseRomaji('ちょっと'), 'chotto');
    });

    test('handles choonpu long vowels', () {
      expect(toJapaneseRomaji('コーヒー'), 'kōhī');
    });

    test('detects pure kana text', () {
      expect(isJapaneseKanaText('であう'), isTrue);
      expect(isJapaneseKanaText('出会う'), isFalse);
      expect(isJapaneseKanaText('と'), isTrue);
    });

    test('getJapaneseRomaji resolves Kana or falls back correctly', () {
      expect(getJapaneseRomaji('であう', '出会う'), 'deau');
      expect(getJapaneseRomaji(null, 'と'), 'to');
      expect(getJapaneseRomaji(null, 'たび'), 'tabi');
      expect(getJapaneseRomaji(null, '出会う'), isNull);
    });
  });
}
