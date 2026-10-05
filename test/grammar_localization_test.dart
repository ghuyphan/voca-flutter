// test/grammar_localization_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voca_flutter/config/voca_theme.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/grammar_engine.dart';
import 'package:voca_flutter/services/i18n_service.dart';
import 'package:voca_flutter/state/app_state.dart';
import 'package:voca_flutter/ui/sheets/grammar_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GrammarEngine Localization Tests', () {
    late GrammarEngine grammarEngine;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      grammarEngine = GrammarEngine();
    });

    test('loadTranslation lazy-loads Vietnamese grammar translations for Japanese', () async {
      final trans = await grammarEngine.loadTranslation('ja', 'vi');
      expect(trans.isNotEmpty, isTrue);
      expect(trans.containsKey('ja_n5_A_0'), isTrue);

      final n5A0 = trans['ja_n5_A_0']!;
      expect(n5A0.title, contains('A が いちばん'));
      expect(n5A0.shortExplanation, contains('so sánh nhất'));
      expect(n5A0.formation, contains('Danh từ + が + いちばん'));
      expect(n5A0.examples, isNotNull);
      expect(n5A0.examples!.first.translation, contains('sushi'));

      // Verify synchronous getter returns cached pack
      final cached = grammarEngine.getLoadedTranslation('ja', 'vi');
      expect(cached, isNotNull);
      expect(cached!['ja_n5_A_0']?.shortExplanation, n5A0.shortExplanation);
    });

    test('getLocalizedPattern overlays Vietnamese translation onto Japanese GrammarPattern', () async {
      await grammarEngine.loadLanguage('ja');
      await grammarEngine.loadTranslation('ja', 'vi');

      final basePattern = GrammarPattern(
        id: 'ja_n5_A_0',
        language: 'ja',
        pattern: 'A が いちばん～',
        title: 'A is the most (A ga ichiban～)',
        shortExplanation: 'Expresses the superlative degree / highest degree.',
        longExplanation: 'Used to express superlative comparison in English.',
        formation: 'Noun + ga + ichiban + Adj/Verb',
        level: 'N5',
        examples: [
          GrammarExample(
            sentence: 'この中で、寿司が一番好きです。',
            translation: 'Among these, I like sushi the most.',
          ),
        ],
      );

      // Localize with 'vi'
      final localizedVi = grammarEngine.getLocalizedPattern(basePattern, 'vi');
      expect(localizedVi.shortExplanation, contains('so sánh nhất'));
      expect(localizedVi.formation, contains('Danh từ + が + いちばん'));
      expect(localizedVi.examples.first.translation, contains('sushi'));

      // Localize with 'en' retains English
      final localizedEn = grammarEngine.getLocalizedPattern(basePattern, 'en');
      expect(localizedEn.shortExplanation, 'Expresses the superlative degree / highest degree.');
      expect(localizedEn.examples.first.translation, 'Among these, I like sushi the most.');
    });

    test('detectPatterns automatically localizes pattern when uiLang is Vietnamese', () async {
      await grammarEngine.loadLanguage('ja');
      await grammarEngine.loadTranslation('ja', 'vi');

      // Tokens representing: 食べてもいい (verb ending with てもいい)
      final tokens = [
        Token(surface: '食べてもいい', baseForm: '食べる', partOfSpeech: 'verb'),
      ];

      final matches = grammarEngine.detectPatterns(tokens, 'ja', uiLang: 'vi');
      expect(matches.isNotEmpty, isTrue);

      final match = matches.firstWhere((m) => m.pattern.id == 'ja_n4_てもいい_95');
      expect(match.pattern.shortExplanation, contains('cho phép'));
      expect(match.pattern.formation, contains('thể て + もいい'));
    });

    test('All 4 learning languages have valid translations in assets', () async {
      final pairs = [
        ('en', 'vi'),
        ('ja', 'vi'),
        ('ko', 'vi'),
        ('zh', 'vi'),
        ('ja', 'zh'),
        ('ko', 'ja'),
      ];

      for (final (learning, ui) in pairs) {
        final trans = await grammarEngine.loadTranslation(learning, ui);
        expect(trans.isNotEmpty, isTrue, reason: 'Failed loading $learning -> $ui');
      }
    });

    testWidgets('GrammarBottomSheet renders Vietnamese translations when UI language is Vietnamese', (tester) async {
      I18nService.instance.loadTranslations('vi', {
        'grammar': {
          'formation': 'Cấu trúc',
          'explanation': 'Giải thích',
          'examples': 'Ví dụ',
          'saved': 'Đã lưu',
          'savePattern': 'Lưu ngữ pháp',
        },
      });
      I18nService.instance.currentLanguage.value = 'vi';
      AppState.instance.grammarEngine = grammarEngine;
      await tester.runAsync(() async {
        await grammarEngine.loadLanguage('ja');
        await grammarEngine.loadTranslation('ja', 'vi');
      });

      final basePattern = GrammarPattern(
        id: 'ja_n4_てもいい_95',
        language: 'ja',
        pattern: '～てもいい',
        title: '～てもいい (〜temo ii)',
        shortExplanation: 'May / can; indicates permission.',
        longExplanation: 'English long explanation.',
        formation: 'Verb te + mo ii',
        level: 'N4',
        examples: [
          GrammarExample(
            sentence: 'ここで写真を撮ってもいいですか。',
            translation: 'Can I take pictures here?',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: GrammarBottomSheet(pattern: basePattern),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify Vietnamese texts appear
      expect(find.textContaining('cho phép'), findsOneWidget);
      expect(find.textContaining('thể て + もいい'), findsOneWidget);
      expect(find.textContaining('Tôi có thể chụp ảnh ở đây được không?'), findsOneWidget);
    });
  });
}
