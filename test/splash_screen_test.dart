// test/splash_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/config/voca_theme.dart';
import 'package:voca_flutter/ui/splash/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplashScreen Widget Tests', () {
    testWidgets('SplashScreen renders with VOCA brand color, logo, and title',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(
            autoNavigate: false,
          ),
        ),
      );

      // Verify scaffold has authentic VOCA obsidian background color
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(VocaTokens.bgPrimary));

      // Verify "Voca" title and tagline exist
      expect(find.text('Voca'), findsOneWidget);
      expect(find.text('Learn Languages with YouTube'), findsOneWidget);

      // Verify logo image is displayed
      expect(find.byType(Image), findsOneWidget);
      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(
        (imageWidget.image as AssetImage).assetName,
        equals('assets/images/app_logo.png'),
      );
    });

    testWidgets('SplashScreen calls onFinish callback when tapped',
        (tester) async {
      bool finished = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            duration: const Duration(seconds: 10),
            autoNavigate: true,
            onFinish: () {
              finished = true;
            },
          ),
        ),
      );

      expect(finished, isFalse);

      // Tap on the splash screen
      await tester.tap(find.byType(SplashScreen));
      await tester.pump();

      expect(finished, isTrue);
    });

    testWidgets('SplashScreen auto-navigates after specified duration',
        (tester) async {
      bool finished = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            duration: const Duration(milliseconds: 300),
            autoNavigate: true,
            onFinish: () {
              finished = true;
            },
          ),
        ),
      );

      expect(finished, isFalse);

      // Advance time by 350ms
      await tester.pump(const Duration(milliseconds: 100));
      expect(finished, isFalse);

      await tester.pump(const Duration(milliseconds: 250));
      expect(finished, isTrue);
    });
  });
}
