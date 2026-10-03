// test/voca_empty_state_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/config/voca_theme.dart';
import 'package:voca_flutter/ui/widgets/voca_empty_state.dart';

void main() {
  testWidgets('VocaEmptyState renders title, description, and primary pill button', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: VocaTheme.darkTheme,
        home: Scaffold(
          body: VocaEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No videos found',
            description: 'Try searching with different keywords.',
            actionLabel: 'Reset Filters',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    expect(find.text('No videos found'), findsOneWidget);
    expect(find.text('Try searching with different keywords.'), findsOneWidget);
    expect(find.text('Reset Filters'), findsOneWidget);

    await tester.tap(find.text('Reset Filters'));
    expect(tapped, isTrue);
  });

  testWidgets('VocaEmptyState renders semantic icon variants: neutral, error, and accent', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: VocaTheme.darkTheme,
        home: const Scaffold(
          body: Column(
            children: [
              VocaEmptyState(
                icon: Icons.search_off_rounded,
                variant: EmptyStateIconVariant.neutral,
                title: 'Neutral State',
              ),
              VocaEmptyState(
                icon: Icons.cloud_off_rounded,
                variant: EmptyStateIconVariant.error,
                title: 'Error State',
              ),
              VocaEmptyState(
                icon: Icons.star_rounded,
                variant: EmptyStateIconVariant.accent,
                title: 'Accent State',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Neutral State'), findsOneWidget);
    expect(find.text('Error State'), findsOneWidget);
    expect(find.text('Accent State'), findsOneWidget);
  });

  testWidgets('VocaEmptyState renders compact mode and secondary button', (tester) async {
    bool primaryTapped = false;
    bool secondaryTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: VocaTheme.darkTheme,
        home: Scaffold(
          body: VocaEmptyState(
            icon: Icons.info_outline_rounded,
            compact: true,
            title: 'Compact Title',
            description: 'Compact description',
            secondaryActionLabel: 'Cancel',
            onSecondaryAction: () => secondaryTapped = true,
            actionLabel: 'Confirm',
            onAction: () => primaryTapped = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Compact Title'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    expect(secondaryTapped, isTrue);

    await tester.tap(find.text('Confirm'));
    expect(primaryTapped, isTrue);
  });
}
