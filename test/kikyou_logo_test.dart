import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/ui/widgets/kikyou_logo.dart';

void main() {
  group('KikyouLogo Widget Tests', () {
    testWidgets('renders properly with default size and custom color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: KikyouLogo(
                size: 28,
                color: Color(0xFFFF6B82),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(KikyouLogo), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(KikyouLogo),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(KikyouLogo),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox.width, 28);
      expect(sizedBox.height, 28);
    });

    testWidgets('renders cleanly at micro (16px) and large (60px) dimensions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                KikyouLogo(size: 16),
                KikyouLogo(size: 60),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(KikyouLogo), findsNWidgets(2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
