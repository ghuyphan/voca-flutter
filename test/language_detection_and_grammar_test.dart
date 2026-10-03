// test/language_detection_and_grammar_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/grammar_engine.dart';
import 'package:voca_flutter/services/voca_api_client.dart';
import 'package:voca_flutter/state/app_state.dart';
import 'package:voca_flutter/state/player_state.dart';
import 'package:voca_flutter/utils/language_utils.dart';

class _FakeApiClient extends Fake implements VocaApiClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Language Utilities Tests (1:1 port of lingua-tube language.utils.ts)', () {
    test('normalizeLanguageCode standardizes various alias formats', () {
      expect(normalizeLanguageCode('ja'), 'ja');
      expect(normalizeLanguageCode('japanese'), 'ja');
      expect(normalizeLanguageCode('jpn'), 'ja');
      expect(normalizeLanguageCode('ja-JP'), 'ja');

      expect(normalizeLanguageCode('ko'), 'ko');
      expect(normalizeLanguageCode('korean'), 'ko');
      expect(normalizeLanguageCode('kor'), 'ko');
      expect(normalizeLanguageCode('ko-KR'), 'ko');

      expect(normalizeLanguageCode('zh'), 'zh');
      expect(normalizeLanguageCode('chinese'), 'zh');
      expect(normalizeLanguageCode('cmn'), 'zh');
      expect(normalizeLanguageCode('mandarin'), 'zh');
      expect(normalizeLanguageCode('zh-CN'), 'zh');
      expect(normalizeLanguageCode('yue'), 'zh');

      expect(normalizeLanguageCode('en'), 'en');
      expect(normalizeLanguageCode('english'), 'en');
      expect(normalizeLanguageCode('eng'), 'en');
      expect(normalizeLanguageCode('en-US'), 'en');

      expect(normalizeLanguageCode(null), '');
      expect(normalizeLanguageCode(''), '');
    });

    test('detectLanguage correctly identifies Korean, Japanese, Chinese, English', () {
      // Korean (Hangul)
      expect(detectLanguage('안녕하세요 반갑습니다'), 'ko');
      expect(detectLanguage('한국어를 공부하고 있어요'), 'ko');

      // Japanese (Hiragana / Katakana)
      expect(detectLanguage('こんにちは、元気ですか'), 'ja');
      expect(detectLanguage('ラーメンが食べたい'), 'ja');

      // Chinese (Hanzi)
      expect(detectLanguage('你好，这是一个测试'), 'zh');
      expect(detectLanguage('我们一起学中文'), 'zh');

      // Context-aware Kanji/Hanzi disambiguation
      expect(detectLanguage('日本', 'ja'), 'ja');
      expect(detectLanguage('日本', 'zh'), 'zh');

      // English
      expect(detectLanguage('Hello, how are you today?'), 'en');
      expect(detectLanguage('Spaced repetition system'), 'en');
    });

    test('detectSubtitleLanguage samples cue list and detects authentic language', () {
      final koCues = [
        SubtitleCue(start: 0.0, duration: 2.0, text: '안녕하세요 여러분'),
        SubtitleCue(start: 2.0, duration: 2.5, text: '오늘 영상에서는 한국어를 배워봅시다'),
      ];
      expect(detectSubtitleLanguage(koCues), 'ko');

      final jaCues = [
        SubtitleCue(start: 0.0, duration: 1.5, text: '皆さん、こんにちは！'),
        SubtitleCue(start: 1.5, duration: 2.0, text: '今日は日本語の文法を学びます'),
      ];
      expect(detectSubtitleLanguage(jaCues), 'ja');

      final zhCues = [
        SubtitleCue(start: 0.0, duration: 1.8, text: '大家今天过得怎么样？'),
        SubtitleCue(start: 1.8, duration: 2.2, text: '现在我们来看一下例句'),
      ];
      expect(detectSubtitleLanguage(zhCues), 'zh');

      final enCues = [
        SubtitleCue(start: 0.0, duration: 2.0, text: 'Welcome back to the channel!'),
        SubtitleCue(start: 2.0, duration: 2.0, text: 'In this video we cover advanced grammar.'),
      ];
      expect(detectSubtitleLanguage(enCues), 'en');

      // Fallback for empty cues list
      expect(detectSubtitleLanguage([], 'ko'), 'ko');
      expect(detectSubtitleLanguage([], 'ja'), 'ja');
    });
  });

  group('GrammarEngine Multi-Language Pattern Detection Tests', () {
    late GrammarEngine grammarEngine;

    setUp(() {
      grammarEngine = GrammarEngine();
    });

    test('loadLanguage updates loadedLanguages reactive signal', () async {
      expect(grammarEngine.loadedLanguages.value.contains('ja'), isFalse);
      await grammarEngine.loadLanguage('ja');
      expect(grammarEngine.loadedLanguages.value.contains('ja'), isTrue);
    });

    test('detectPatterns detects Japanese verb endings and grammar', () async {
      await grammarEngine.loadLanguage('ja');

      final List<Token> tokens = [
        Token(surface: '本', reading: 'ほん', partOfSpeech: 'Noun'),
        Token(surface: 'を', reading: 'を', partOfSpeech: 'Particle'),
        Token(surface: '食べてもいい', reading: 'たべてもいい', partOfSpeech: 'Verb'),
      ];

      final matches = grammarEngine.detectPatterns(tokens, 'ja');
      expect(matches, isNotEmpty);
      expect(matches.any((m) => m.pattern.pattern.contains('てもいい')), isTrue);
    });

    test('detectPatterns detects Korean verb endings and grammar', () async {
      await grammarEngine.loadLanguage('ko');

      final List<Token> tokens = [
        Token(surface: '나', partOfSpeech: 'Pronoun'),
        Token(surface: '는', partOfSpeech: 'Particle'),
        Token(surface: '한국어를', partOfSpeech: 'Noun'),
        Token(surface: '공부하고 있다', partOfSpeech: 'Verb'),
      ];

      final matches = grammarEngine.detectPatterns(tokens, 'ko');
      expect(matches, isNotEmpty);
      expect(matches.any((m) => m.pattern.pattern.contains('고 있다')), isTrue);
    });

    test('detectPatterns detects Chinese correlative patterns', () async {
      await grammarEngine.loadLanguage('zh');

      final List<Token> tokens = [
        Token(surface: '虽然', partOfSpeech: 'Conjunction'),
        Token(surface: '天气', partOfSpeech: 'Noun'),
        Token(surface: '不好', partOfSpeech: 'Adjective'),
        Token(surface: '但是', partOfSpeech: 'Conjunction'),
        Token(surface: '我们', partOfSpeech: 'Pronoun'),
        Token(surface: '去', partOfSpeech: 'Verb'),
      ];

      final matches = grammarEngine.detectPatterns(tokens, 'zh');
      expect(matches, isNotEmpty);
      expect(matches.any((m) => m.pattern.pattern.contains('虽然') && m.pattern.pattern.contains('但是')), isTrue);
    });
  });

  group('VideoPlayerController Authentic Language Resolution Tests', () {
    late GrammarEngine grammarEngine;
    late VideoPlayerController controller;

    setUp(() {
      grammarEngine = GrammarEngine();
      controller = VideoPlayerController(
        apiClient: _FakeApiClient(),
        grammarEngine: grammarEngine,
      );
    });

    test('activeLanguage defaults to AppState when cues are empty', () {
      AppState.instance.activeLanguage.value = 'ja';
      expect(controller.activeLanguage.value, 'ja');

      controller.loadedLanguage.value = 'ko';
      expect(controller.activeLanguage.value, 'ko');
    });

    test('activeLanguage automatically evaluates authentic language from cues', () async {
      await grammarEngine.loadLanguage('ko');

      // User default is Japanese
      AppState.instance.activeLanguage.value = 'ja';
      expect(controller.activeLanguage.value, 'ja');

      // Video cues arrive with authentic Korean text
      final koCues = [
        SubtitleCue(
          start: 1.0,
          duration: 3.0,
          text: '밥을 먹고 있다',
          tokens: [
            Token(surface: '밥', partOfSpeech: 'Noun'),
            Token(surface: '을', partOfSpeech: 'Particle'),
            Token(surface: '먹고 있다', partOfSpeech: 'Verb'),
          ],
        ),
      ];

      controller.cues.value = koCues;
      controller.currentTime.value = 1.5;

      // activeLanguage MUST dynamically detect 'ko'
      expect(controller.activeLanguage.value, 'ko');

      // activeGrammarMatches MUST detect Korean grammar pattern, NOT Japanese
      final matches = controller.activeGrammarMatches.value;
      expect(matches, isNotEmpty);
      expect(matches.first.pattern.language, 'ko');
      expect(matches.first.pattern.pattern.contains('고 있다'), isTrue);
    });
  });
}
