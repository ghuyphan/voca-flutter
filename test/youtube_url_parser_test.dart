// test/youtube_url_parser_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/utils/youtube_url_parser.dart';

void main() {
  group('YouTubeUrlParser Tests', () {
    const expectedId = 'dQw4w9WgXcQ';

    test('validates standard 11-char video ID', () {
      expect(YouTubeUrlParser.isValidVideoId(expectedId), isTrue);
      expect(YouTubeUrlParser.isValidVideoId('clU8c2fpk2s'), isTrue);
      expect(YouTubeUrlParser.isValidVideoId('a-b_c12345Z'), isTrue);
      expect(YouTubeUrlParser.isValidVideoId('short'), isFalse);
      expect(YouTubeUrlParser.isValidVideoId('toolongvideoidentifier'), isFalse);
      expect(YouTubeUrlParser.isValidVideoId('invalid@char'), isFalse);
    });

    test('extracts bare 11-char video ID', () {
      expect(YouTubeUrlParser.extractVideoId('dQw4w9WgXcQ'), equals('dQw4w9WgXcQ'));
      expect(YouTubeUrlParser.extractVideoId('  dQw4w9WgXcQ  '), equals('dQw4w9WgXcQ'));
    });

    test('extracts from standard watch URL', () {
      expect(
        YouTubeUrlParser.extractVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        equals('dQw4w9WgXcQ'),
      );
      expect(
        YouTubeUrlParser.extractVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42s&feature=share'),
        equals('dQw4w9WgXcQ'),
      );
    });

    test('extracts from short URL (youtu.be)', () {
      expect(
        YouTubeUrlParser.extractVideoId('https://youtu.be/dQw4w9WgXcQ'),
        equals('dQw4w9WgXcQ'),
      );
      expect(
        YouTubeUrlParser.extractVideoId('https://youtu.be/dQw4w9WgXcQ?si=abcdef12345'),
        equals('dQw4w9WgXcQ'),
      );
    });

    test('extracts from mobile URL (m.youtube.com)', () {
      expect(
        YouTubeUrlParser.extractVideoId('https://m.youtube.com/watch?v=dQw4w9WgXcQ'),
        equals('dQw4w9WgXcQ'),
      );
      expect(
        YouTubeUrlParser.extractVideoId('https://m.youtube.com/watch?v=dQw4w9WgXcQ&feature=youtu.be'),
        equals('dQw4w9WgXcQ'),
      );
    });

    test('extracts from shorts URL', () {
      expect(
        YouTubeUrlParser.extractVideoId('https://www.youtube.com/shorts/dQw4w9WgXcQ'),
        equals('dQw4w9WgXcQ'),
      );
      expect(
        YouTubeUrlParser.extractVideoId('https://youtube.com/shorts/dQw4w9WgXcQ?feature=share'),
        equals('dQw4w9WgXcQ'),
      );
    });

    test('extracts from embed / v / live URLs', () {
      expect(
        YouTubeUrlParser.extractVideoId('https://www.youtube.com/embed/dQw4w9WgXcQ'),
        equals('dQw4w9WgXcQ'),
      );
      expect(
        YouTubeUrlParser.extractVideoId('https://www.youtube.com/v/dQw4w9WgXcQ'),
        equals('dQw4w9WgXcQ'),
      );
      expect(
        YouTubeUrlParser.extractVideoId('https://www.youtube.com/live/dQw4w9WgXcQ'),
        equals('dQw4w9WgXcQ'),
      );
    });

    test('handles URLs without scheme', () {
      expect(
        YouTubeUrlParser.extractVideoId('youtube.com/watch?v=dQw4w9WgXcQ'),
        equals('dQw4w9WgXcQ'),
      );
      expect(
        YouTubeUrlParser.extractVideoId('youtu.be/dQw4w9WgXcQ'),
        equals('dQw4w9WgXcQ'),
      );
    });

    test('returns null on invalid input', () {
      expect(YouTubeUrlParser.extractVideoId(''), isNull);
      expect(YouTubeUrlParser.extractVideoId('   '), isNull);
      expect(YouTubeUrlParser.extractVideoId('https://google.com'), isNull);
      expect(YouTubeUrlParser.extractVideoId('not a youtube link'), isNull);
    });
  });
}
