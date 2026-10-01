// test/study_and_vocabulary_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/srs_service.dart';

void main() {
  group('Flashcard Model & Serialization Tests', () {
    test('Flashcard serializes and deserializes optional rich fields', () {
      final now = DateTime(2026, 10, 1, 12, 0, 0);
      final card = Flashcard(
        id: 'test_card_1',
        userId: 'user_1',
        word: '食べる',
        reading: 'たべる',
        romanization: 'taberu',
        meaning: 'to eat',
        language: 'ja',
        level: 'learning',
        partOfSpeech: 'verb',
        contextSentence: '毎日美味しいご飯を食べる。',
        contextTranslation: 'Eat delicious food every day.',
        audio: 'https://example.com/taberu.mp3',
        notes: 'Frequent JLPT N5 verb',
        srsInterval: 2,
        srsRepetition: 1,
        srsEaseFactor: 2.5,
        srsNextReviewAt: now.add(const Duration(days: 2)),
        srsLastReviewedAt: now,
        createdAt: now.subtract(const Duration(days: 1)),
      );

      final json = card.toJson();
      expect(json['word'], equals('食べる'));
      expect(json['part_of_speech'], equals('verb'));
      expect(json['context_sentence'], equals('毎日美味しいご飯を食べる。'));
      expect(json['context_translation'], equals('Eat delicious food every day.'));
      expect(json['notes'], equals('Frequent JLPT N5 verb'));

      final baseJson = card.toBaseJson();
      expect(baseJson.containsKey('part_of_speech'), isFalse);
      expect(baseJson.containsKey('context_sentence'), isFalse);
      expect(baseJson['word'], equals('食べる'));

      final restored = Flashcard.fromJson(json);
      expect(restored.word, equals('食べる'));
      expect(restored.partOfSpeech, equals('verb'));
      expect(restored.contextSentence, equals('毎日美味しいご飯を食べる。'));
      expect(restored.contextTranslation, equals('Eat delicious food every day.'));
    });

    test('Flashcard.copyWith updates fields correctly', () {
      final now = DateTime.now();
      final card = Flashcard(
        id: 'c1',
        userId: 'u1',
        word: '約束',
        meaning: 'promise',
        language: 'ja',
        srsNextReviewAt: now,
      );

      final updated = card.copyWith(
        level: 'mastered',
        srsInterval: 15,
        partOfSpeech: 'noun',
      );

      expect(updated.id, equals('c1'));
      expect(updated.word, equals('約束'));
      expect(updated.level, equals('mastered'));
      expect(updated.srsInterval, equals(15));
      expect(updated.partOfSpeech, equals('noun'));
    });
  });

  group('SM-2 Spaced Repetition Interval Badge Calculations', () {
    test('Calculates expected intervals for Again, Hard, Good, Easy', () {
      // Starting from a learning card with repetition=1, interval=1, ease=2.5
      const currentRep = 1;
      const currentInt = 1;
      const currentEase = 2.5;

      // Again
      final againRes = SpacedRepetitionService.calculateNextReview(
        rating: SRSReviewRating.again,
        currentRepetitions: currentRep,
        currentInterval: currentInt,
        currentEaseFactor: currentEase,
      );
      expect(againRes.interval, equals(0));
      expect(againRes.repetition, equals(0));

      // Hard
      final hardRes = SpacedRepetitionService.calculateNextReview(
        rating: SRSReviewRating.hard,
        currentRepetitions: currentRep,
        currentInterval: currentInt,
        currentEaseFactor: currentEase,
      );
      expect(hardRes.interval, equals(1));
      expect(hardRes.repetition, equals(2));

      // Good
      final goodRes = SpacedRepetitionService.calculateNextReview(
        rating: SRSReviewRating.good,
        currentRepetitions: currentRep,
        currentInterval: currentInt,
        currentEaseFactor: currentEase,
      );
      expect(goodRes.interval, equals(6));
      expect(goodRes.repetition, equals(2));

      // Easy
      final easyRes = SpacedRepetitionService.calculateNextReview(
        rating: SRSReviewRating.easy,
        currentRepetitions: currentRep,
        currentInterval: currentInt,
        currentEaseFactor: currentEase,
      );
      expect(easyRes.interval, equals(8));
      expect(easyRes.repetition, equals(2));
      expect(easyRes.easeFactor, greaterThan(currentEase));
    });
  });

  group('Vocabulary Filtering and Sorting Logic', () {
    final now = DateTime(2026, 10, 1, 10, 0, 0);
    final cards = [
      Flashcard(
        id: '1',
        userId: 'u1',
        word: '食べる',
        meaning: 'to eat',
        language: 'ja',
        level: 'learning',
        srsInterval: 2,
        srsNextReviewAt: now,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Flashcard(
        id: '2',
        userId: 'u1',
        word: '約束',
        meaning: 'promise',
        language: 'ja',
        level: 'mastered',
        srsInterval: 14,
        srsNextReviewAt: now,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Flashcard(
        id: '3',
        userId: 'u1',
        word: '美しい',
        meaning: 'beautiful',
        language: 'ja',
        level: 'new',
        srsInterval: 0,
        srsNextReviewAt: now,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    test('Filters by status tab', () {
      final newCards = cards.where((c) => c.level == 'new').toList();
      expect(newCards.length, equals(1));
      expect(newCards.first.word, equals('美しい'));

      final learningCards = cards.where((c) => c.level == 'learning').toList();
      expect(learningCards.length, equals(1));
      expect(learningCards.first.word, equals('食べる'));

      final masteredCards = cards.where((c) => c.level == 'mastered').toList();
      expect(masteredCards.length, equals(1));
      expect(masteredCards.first.word, equals('約束'));
    });

    test('Searches by word and meaning', () {
      const queryWord = '約';
      final matchWord = cards.where((c) => c.word.contains(queryWord)).toList();
      expect(matchWord.length, equals(1));
      expect(matchWord.first.word, equals('約束'));

      const queryMeaning = 'eat';
      final matchMeaning = cards.where((c) => c.meaning.contains(queryMeaning)).toList();
      expect(matchMeaning.length, equals(1));
      expect(matchMeaning.first.word, equals('食べる'));
    });

    test('Sorts by date added and interval', () {
      final sortedByDate = List<Flashcard>.from(cards)
        ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
      expect(sortedByDate.first.word, equals('美しい')); // 1 day ago (most recent)
      expect(sortedByDate.last.word, equals('約束')); // 5 days ago

      final sortedByInterval = List<Flashcard>.from(cards)
        ..sort((a, b) => b.srsInterval.compareTo(a.srsInterval));
      expect(sortedByInterval.first.word, equals('約束')); // 14 days
      expect(sortedByInterval.last.word, equals('美しい')); // 0 days
    });
  });
}
