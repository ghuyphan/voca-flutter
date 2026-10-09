// test/vocabulary_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voca_flutter/config/voca_theme.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/grammar_engine.dart';
import 'package:voca_flutter/services/supabase_service.dart';
import 'package:voca_flutter/services/vocabulary_service.dart';
import 'package:voca_flutter/state/app_state.dart';
import 'package:voca_flutter/ui/vocabulary/vocabulary_screen.dart';

class MockSupabaseService extends SupabaseService {
  MockSupabaseService() : super(SupabaseClient('https://mock.supabase.co', 'mock_anon_key')) {
    vocabularyCardsSignal.value = List.from(mockCards);
  }

  final List<Flashcard> mockCards = [
    Flashcard(
      id: 'mock_1',
      userId: 'u1',
      word: '食べる',
      reading: 'たべる',
      meaning: 'to eat',
      language: 'ja',
      level: 'learning',
      partOfSpeech: 'verb',
      contextSentence: '毎日美味しいご飯を食べる。',
      contextTranslation: 'Eat delicious meals every day.',
      srsInterval: 1,
      srsRepetition: 1,
      srsEaseFactor: 2.5,
      srsNextReviewAt: DateTime.now().subtract(const Duration(hours: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Flashcard(
      id: 'mock_2',
      userId: 'u1',
      word: '約束',
      reading: 'やくそく',
      meaning: 'promise',
      language: 'ja',
      level: 'known',
      partOfSpeech: 'noun',
      contextSentence: '友達との約束を守る。',
      contextTranslation: 'Keep promise with friend.',
      srsInterval: 14,
      srsRepetition: 4,
      srsEaseFactor: 2.6,
      srsNextReviewAt: DateTime.now().subtract(const Duration(hours: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  @override
  User? get currentUser => null;

  @override
  Future<List<Flashcard>> getVocabularyCards({String? language}) async {
    return List.from(mockCards);
  }

  @override
  Future<void> upsertVocabularyCard(Flashcard card) async {
    final idx = mockCards.indexWhere((c) => c.id == card.id);
    if (idx >= 0) {
      mockCards[idx] = card;
    } else {
      mockCards.add(card);
    }
    vocabularyCardsSignal.value = List.from(mockCards);
  }

  @override
  Future<void> deleteVocabularyCard(String id) async {
    mockCards.removeWhere((c) => c.id == id);
    vocabularyCardsSignal.value = List.from(mockCards);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSupabaseService mockSupabase;

  setUp(() {
    mockSupabase = MockSupabaseService();
    AppState.instance.grammarEngine = GrammarEngine();
    AppState.instance.supabaseService = mockSupabase;
  });

  group('VocabularyScreen Sleek UI & Layout Tests', () {
    testWidgets('Renders clean panel header, spotlight search bar, and filter strip', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const VocabularyScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Sleek top header (No generic AppBar)
      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Words'), findsOneWidget);
      expect(find.text('Dictionary'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

      // 2. Spotlight search bar
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

      // 3. Level filter strip
      expect(find.text('All'), findsWidgets);
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Learning'), findsOneWidget);
      expect(find.text('Known'), findsOneWidget);

      // 4. Word List
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(GridView), findsNothing);

      // 5. Cards Content
      expect(find.text('食べる'), findsOneWidget);
      expect(find.text('たべる'), findsOneWidget);
      expect(find.text('to eat'), findsOneWidget);
      expect(find.text('“毎日美味しいご飯を食べる。”'), findsOneWidget);
      expect(find.text('約束'), findsOneWidget);
      expect(find.text('やくそく'), findsOneWidget);
    });

    testWidgets('Renders 2-column responsive GridView on tablet (width >= 720)', (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const VocabularyScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Words'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('Typing query into spotlight search bar filters cards or shows empty state', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const VocabularyScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final searchFinder = find.byType(TextField);
      expect(searchFinder, findsOneWidget);

      // Enter an impossible search query
      await tester.enterText(searchFinder, 'xyzNonExistentWord123');
      await tester.pump(const Duration(milliseconds: 100));

      // Expect helpful empty state with Show All action
      expect(find.text('No matches found'), findsOneWidget);
      expect(find.text('Show All'), findsOneWidget);

      // Clear search button appears
      final clearButton = find.byIcon(Icons.close_rounded);
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pump(const Duration(milliseconds: 100));

      // Restored list view
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('Filtering by level tabs isolates matching words', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const VocabularyScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap 'Learning' tab
      final learningChip = find.widgetWithText(InkWell, 'Learning').first;
      await tester.tap(learningChip);
      await tester.pump(const Duration(milliseconds: 100));

      // '食べる' has level 'learning', '約束' has level 'known'
      expect(find.text('食べる'), findsOneWidget);
      expect(find.text('約束'), findsNothing);

      // Tap 'Known' tab
      final knownChip = find.widgetWithText(InkWell, 'Known').first;
      await tester.ensureVisible(knownChip);
      await tester.pumpAndSettle();
      await tester.tap(knownChip);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('食べる'), findsNothing);
      expect(find.text('約束'), findsOneWidget);
    });

    testWidgets('Tapping delete button removes card and triggers undo toast', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const VocabularyScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('食べる'), findsOneWidget);

      // Find delete button on first card
      final deleteButtons = find.byIcon(Icons.delete_outline_rounded);
      expect(deleteButtons, findsWidgets);

      await tester.tap(deleteButtons.first);
      await tester.pump(const Duration(milliseconds: 100));

      // '食べる' was removed
      expect(find.text('食べる'), findsNothing);
      // Undo action is visible in toast
      expect(find.text('Undo'), findsOneWidget);

      // Verify undo restores the card
      await VocabularyService.instance.undoLastDelete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('食べる'), findsOneWidget);
    });

    testWidgets('Tapping options icon opens bottom sheet with Export JSON and Export Anki', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const VocabularyScreen(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final optionsBtn = find.byIcon(Icons.more_vert_rounded);
      await tester.tap(optionsBtn);
      await tester.pumpAndSettle();

      expect(find.text('Vocabulary Options'), findsOneWidget);
      expect(find.text('Export as JSON'), findsOneWidget);
      expect(find.text('Export to Anki'), findsOneWidget);
    });
  });
}
