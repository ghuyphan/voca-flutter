import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/srs_service.dart';
import 'package:voca_flutter/utils/cyrb53_hasher.dart';

void main() {
  group('Deterministic Cyrb53 Hasher Tests', () {
    test('generates 15-character base36 deterministic hash', () {
      final hash1 = generateDeterministicRecordId(['user_123', '食べる', 'ja']);
      final hash2 = generateDeterministicRecordId(['user_123', '食べる', 'ja']);
      final hash3 = generateDeterministicRecordId(['user_456', '食べる', 'ja']);

      expect(hash1, equals(hash2));
      expect(hash1.length, equals(15));
      expect(hash1, isNot(equals(hash3)));
    });
  });

  group('SM-2 Spaced Repetition Tests', () {
    test('Again resets repetitions and interval to 0', () {
      final res = SpacedRepetitionService.calculateNextReview(
        rating: SRSReviewRating.again,
        currentRepetitions: 4,
        currentInterval: 12,
        currentEaseFactor: 2.5,
      );

      expect(res.repetition, equals(0));
      expect(res.interval, equals(0));
      expect(res.level, equals('learning'));
      expect(res.easeFactor, lessThan(2.5));
    });

    test('Good advances repetition: 1 day -> 6 days', () {
      final res1 = SpacedRepetitionService.calculateNextReview(
        rating: SRSReviewRating.good,
        currentRepetitions: 0,
        currentInterval: 0,
        currentEaseFactor: 2.5,
      );
      expect(res1.repetition, equals(1));
      expect(res1.interval, equals(1));

      final res2 = SpacedRepetitionService.calculateNextReview(
        rating: SRSReviewRating.good,
        currentRepetitions: 1,
        currentInterval: 1,
        currentEaseFactor: 2.5,
      );
      expect(res2.repetition, equals(2));
      expect(res2.interval, equals(6));
    });
  });

  group('Model Deserialization Tests', () {
    test('Token parses correctly from API payload', () {
      final json = {
        'surface': '日本語',
        'reading': 'にほんご',
        'romanization': 'nihongo',
        'baseForm': '日本語',
        'partOfSpeech': '名詞',
        'isPunctuation': false,
      };

      final token = Token.fromJson(json);
      expect(token.surface, equals('日本語'));
      expect(token.reading, equals('にほんご'));
      expect(token.romanization, equals('nihongo'));
      expect(token.isPunctuation, isFalse);
    });
  });
}
