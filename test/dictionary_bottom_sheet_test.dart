// test/dictionary_bottom_sheet_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/voca_api_client.dart';
import 'package:voca_flutter/state/app_state.dart';
import 'package:voca_flutter/ui/sheets/dictionary_bottom_sheet.dart';

class FakeDictionaryApiClient extends VocaApiClient {
  @override
  Future<DictionaryResult> lookupDictionary({
    required String word,
    required String from,
    required String to,
  }) async {
    return DictionaryResult(
      word: word,
      from: from,
      to: to,
      source: 'test',
      entries: [
        DictionaryEntry(
          word: '食べる',
          reading: 'たべる',
          romaji: 'taberu',
          partOfSpeech: 'v1, vt',
          definitions: [
            'to eat',
            'to live on; to survive',
          ],
          level: 'N5',
          examples: [
            {
              'sentence': '朝ご飯を食べる。',
              'translation': 'Eat breakfast.',
            },
          ],
        ),
      ],
    );
  }
}

void main() {
  setUpAll(() {
    AppState.instance.apiClient = FakeDictionaryApiClient();
  });

  testWidgets('DictionaryBottomSheet renders centered word, reading, audio button, and save footer', (tester) async {
    final token = Token(
      surface: '食べた',
      baseForm: '食べる',
      reading: 'たべた',
      romanization: 'tabeta',
      partOfSpeech: 'v1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => DictionaryBottomSheet.show(
                ctx,
                token: token,
                sourceLang: 'ja',
              ),
              child: const Text('Open Dict'),
            ),
          ),
        ),
      ),
    );

    // Open sheet
    await tester.tap(find.text('Open Dict'));
    await tester.pumpAndSettle();

    // 1. Centered Word & Base Form
    expect(find.text('食べた'), findsOneWidget);
    expect(find.text('(食べる)'), findsOneWidget);

    // 2. Reading
    expect(find.text('たべた'), findsOneWidget);

    // 3. Audio Button (speaker icon)
    expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget);

    // 4. Badges (POS & JLPT)
    expect(find.text('N5'), findsOneWidget);

    // 5. Definitions
    expect(find.text('to eat'), findsOneWidget);
    expect(find.text('to live on; to survive'), findsOneWidget);

    // 6. Examples
    expect(find.text('• 朝ご飯を食べる。'), findsOneWidget);
    expect(find.text('Eat breakfast.'), findsOneWidget);

    // 7. Full-width Footer Save Button
    expect(find.text('Save Word'), findsOneWidget);
  });
}
