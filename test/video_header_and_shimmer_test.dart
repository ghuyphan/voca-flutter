// test/video_header_and_shimmer_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/ui/video/video_header.dart';
import 'package:voca_flutter/ui/widgets/voca_level_badge.dart';
import 'package:voca_flutter/ui/widgets/voca_shimmer.dart';

void main() {
  group('VocaShimmer Tests', () {
    testWidgets('VocaShimmer.box renders container with custom width, height, and borderRadius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VocaShimmer.box(
              width: 100,
              height: 40,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );

      expect(find.byType(VocaShimmer), findsOneWidget);
      final containerFinder = find.descendant(
        of: find.byType(VocaShimmer),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsOneWidget);
      final container = tester.widget<Container>(containerFinder);
      final boxDec = container.decoration as BoxDecoration;
      expect(boxDec.borderRadius, equals(BorderRadius.circular(8)));
    });

    testWidgets('VocaShimmer.line renders with default height 12 and custom width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VocaShimmer.line(width: 220),
          ),
        ),
      );

      expect(find.byType(VocaShimmer), findsOneWidget);
      final container = tester.widget<Container>(find.descendant(
        of: find.byType(VocaShimmer),
        matching: find.byType(Container),
      ));
      expect(container.constraints?.maxHeight ?? 12.0, equals(12.0));
    });

    testWidgets('VocaShimmer.circle renders circle shape container', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VocaShimmer.circle(size: 32),
          ),
        ),
      );

      final container = tester.widget<Container>(find.descendant(
        of: find.byType(VocaShimmer),
        matching: find.byType(Container),
      ));
      final boxDec = container.decoration as BoxDecoration;
      expect(boxDec.shape, equals(BoxShape.circle));
    });
  });

  group('VideoHeader Tests', () {
    testWidgets('renders skeleton loading when title and channel are empty or null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoHeader(
              title: null,
              channel: null,
            ),
          ),
        ),
      );

      // Finds two shimmer lines: 220x16 for title, 120x12 for channel
      final shimmers = find.byType(VocaShimmer);
      expect(shimmers, findsNWidgets(2));
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('renders full header with title, channel, level badge, and action buttons', (tester) async {
      bool shareTapped = false;
      bool closeTapped = false;
      bool subtitleTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoHeader(
              title: 'Learn Japanese with Anime',
              channel: 'Nihongo Channel',
              videoId: 'test_123',
              level: 'JLPT N3',
              onShareTap: () => shareTapped = true,
              onCloseTap: () => closeTapped = true,
              onSubtitleTap: () => subtitleTapped = true,
            ),
          ),
        ),
      );

      // Verify title & channel
      expect(find.text('Learn Japanese with Anime'), findsOneWidget);
      expect(find.text('Nihongo Channel'), findsOneWidget);

      // Verify level badge
      expect(find.byType(VocaLevelBadge), findsOneWidget);
      expect(find.text('JLPT N3'), findsOneWidget);

      // Verify action buttons
      expect(find.byIcon(Icons.subtitles_rounded), findsOneWidget);
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap subtitle button
      await tester.tap(find.byIcon(Icons.subtitles_rounded));
      expect(subtitleTapped, isTrue);

      // Tap share button
      await tester.tap(find.byIcon(Icons.share_rounded));
      expect(shareTapped, isTrue);

      // Tap close button
      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(closeTapped, isTrue);
    });

    testWidgets('renders evaluating shimmer level badge when isLevelLoading is true and level is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoHeader(
              title: 'Video Title',
              channel: 'Channel Name',
              isLevelLoading: true,
            ),
          ),
        ),
      );

      expect(find.text('Video Title'), findsOneWidget);
      expect(find.text('Channel Name'), findsOneWidget);

      // Level badge with loading state is rendered
      final levelBadgeFinder = find.byType(VocaLevelBadge);
      expect(levelBadgeFinder, findsOneWidget);
      final levelBadge = tester.widget<VocaLevelBadge>(levelBadgeFinder);
      expect(levelBadge.isLoading, isTrue);
    });

    testWidgets('renders AI badge indicator on subtitle button when isAIGenerated is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoHeader(
              title: 'Video Title',
              channel: 'Channel Name',
              isAIGenerated: true,
            ),
          ),
        ),
      );

      // Has AI text badge inside the subtitle action button
      expect(find.text('AI'), findsOneWidget);
      expect(find.byIcon(Icons.subtitles_rounded), findsOneWidget);
    });
  });
}
