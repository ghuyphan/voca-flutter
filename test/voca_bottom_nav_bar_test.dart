import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voca_flutter/config/voca_theme.dart';
import 'package:voca_flutter/services/i18n_service.dart';
import 'package:voca_flutter/ui/widgets/voca_bottom_nav_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    I18nService.instance.loadTranslations('en', {
      'nav': {
        'watch': 'Watch',
        'review': 'Review',
        'vocab': 'Vocab',
        'more': 'More',
      }
    });
    I18nService.instance.loadTranslations('vi', {
      'nav': {
        'watch': 'Xem',
        'review': 'Ôn tập',
        'vocab': 'Từ vựng',
        'more': 'Thêm',
      }
    });
    I18nService.instance.currentLanguage.value = 'en';
  });

  setUp(() {
    I18nService.instance.currentLanguage.value = 'en';
  });

  tearDownAll(() {
    I18nService.instance.currentLanguage.value = 'en';
  });

  group('VocaBottomNavBar Widget Tests', () {
    testWidgets('Renders 4 native destinations cleanly in Dark Mode', (tester) async {
      int selectedTab = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: Scaffold(
            bottomNavigationBar: VocaBottomNavBar(
              currentIndex: selectedTab,
              onTabSelected: (idx) => selectedTab = idx,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Watch'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Vocab'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);

      // Tap Review
      await tester.tap(find.text('Review'));
      expect(selectedTab, 1);

      // Tap Vocab
      await tester.tap(find.text('Vocab'));
      expect(selectedTab, 2);

      // Tap More
      await tester.tap(find.text('More'));
      expect(selectedTab, 3);
    });

    testWidgets('Renders cleanly in Light Mode without errors or dark hardcoded tokens', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: VocaBottomNavBar(
              currentIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Watch'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Vocab'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('Dynamically updates labels when UI locale changes reactively', (tester) async {
      I18nService.instance.currentLanguage.value = 'en';

      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: Scaffold(
            bottomNavigationBar: VocaBottomNavBar(
              currentIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Watch'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Vocab'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);

      // Switch language to Vietnamese reactively
      I18nService.instance.currentLanguage.value = 'vi';
      await tester.pumpAndSettle();

      expect(find.text('Xem'), findsOneWidget);
      expect(find.text('Ôn tập'), findsOneWidget);
      expect(find.text('Từ vựng'), findsOneWidget);
      expect(find.text('Thêm'), findsOneWidget);

      I18nService.instance.currentLanguage.value = 'en';
    });

    testWidgets('Applies correct theme colors in Dark Mode vs Light Mode', (tester) async {
      // 1. Dark Mode
      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: Scaffold(
            bottomNavigationBar: VocaBottomNavBar(
              currentIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final darkWatchText = tester.widget<AnimatedDefaultTextStyle>(
        find.ancestor(
          of: find.text('Watch'),
          matching: find.byType(AnimatedDefaultTextStyle),
        ).first,
      );
      expect(darkWatchText.style.color, VocaColorPalette.dark.accentPrimary);

      // 2. Light Mode
      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.lightTheme,
          home: Scaffold(
            bottomNavigationBar: VocaBottomNavBar(
              currentIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final lightWatchText = tester.widget<AnimatedDefaultTextStyle>(
        find.ancestor(
          of: find.text('Watch'),
          matching: find.byType(AnimatedDefaultTextStyle),
        ).first,
      );
      expect(lightWatchText.style.color, VocaColorPalette.light.accentPrimary);
    });

    testWidgets('Respects safe area bottom inset on devices with home indicator', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(bottom: 34),
          ),
          child: MaterialApp(
            theme: VocaTheme.darkTheme,
            home: Scaffold(
              bottomNavigationBar: VocaBottomNavBar(
                currentIndex: 0,
                onTabSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(VocaBottomNavBar),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.padding, const EdgeInsets.only(bottom: 34));
    });
  });
}
