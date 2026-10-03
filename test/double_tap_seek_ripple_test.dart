// test/double_tap_seek_ripple_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/ui/video/double_tap_seek_ripple.dart';

void main() {
  group('DoubleTapSeekRipple Widget Tests', () {
    testWidgets('renders left rewind seek ripple with accumulator text and chevrons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 200,
              child: DoubleTapSeekRipple(
                isLeft: true,
                seconds: 10,
              ),
            ),
          ),
        ),
      );

      // Verify accumulator label
      expect(find.text('10s'), findsOneWidget);

      // Verify chevrons group
      expect(find.byIcon(Icons.play_arrow_rounded), findsNWidgets(3));

      // Pump 100ms for scale animation
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('10s'), findsOneWidget);
    });

    testWidgets('renders right forward seek ripple and updates accumulator on rebuild', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 200,
              child: DoubleTapSeekRipple(
                isLeft: false,
                seconds: 10,
              ),
            ),
          ),
        ),
      );

      expect(find.text('10s'), findsOneWidget);

      // Rebuild with updated seconds (consecutive double-tap)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 200,
              child: DoubleTapSeekRipple(
                isLeft: false,
                seconds: 20,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('20s'), findsOneWidget);
    });
  });
}
