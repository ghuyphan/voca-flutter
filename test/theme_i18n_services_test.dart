// test/theme_i18n_services_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:voca_flutter/config/voca_theme.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/i18n_service.dart';
import 'package:voca_flutter/services/video_level_service.dart';
import 'package:voca_flutter/state/app_state.dart';
import 'package:voca_flutter/ui/sheets/voca_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await I18nService.instance.init();
  });

  group('I18nService Unit Tests', () {
    test('Translates nested keys with dot-notation and fallback to English', () {
      final i18n = I18nService.instance;
      i18n.currentLanguage.value = 'en';

      expect(i18n.t('nav.watch'), 'Watch');
      expect(i18n.t('nav.review'), 'Review');
      expect(i18n.t('nav.vocab'), 'Vocab');
      expect(i18n.t('nav.more'), 'More');
      expect(i18n.t('common.cancel'), 'Cancel');

      // Non-existent key returns fallback or key itself
      expect(i18n.t('non.existent.key', null, 'My Fallback'), 'My Fallback');
    });

    test('Interpolates params properly ({{param}} and {param})', () {
      final i18n = I18nService.instance;
      i18n.currentLanguage.value = 'en';

      final interpolated = i18n.t(
        'playlist.addedSuccess',
        {'title': 'Japanese J-Pop'},
        'Added to {title}',
      );
      expect(interpolated.contains('Japanese J-Pop'), isTrue);
    });

    test('Switches between supported languages cleanly', () {
      final i18n = I18nService.instance;

      i18n.currentLanguage.value = 'vi';
      expect(i18n.currentLanguage.value, 'vi');

      i18n.currentLanguage.value = 'ja';
      expect(i18n.currentLanguage.value, 'ja');

      i18n.currentLanguage.value = 'ko';
      expect(i18n.currentLanguage.value, 'ko');

      i18n.currentLanguage.value = 'zh';
      expect(i18n.currentLanguage.value, 'zh');
    });
  });

  group('VocaTheme & ColorPalette Unit Tests', () {
    test('Dark and Light palettes have distinct background and text contrast', () {
      const dark = VocaColorPalette.dark;
      const light = VocaColorPalette.light;

      expect(dark.isDark, isTrue);
      expect(light.isDark, isFalse);

      expect(dark.bgPrimary, const Color(0xFF0D0F14)); // Obsidian
      expect(light.bgPrimary, const Color(0xFFF3F4F7)); // Porcelain

      expect(dark.textPrimary, const Color(0xFFF1F3F7)); // Light text for dark bg
      expect(light.textPrimary, const Color(0xFF181D27)); // Dark text for light bg

      // Signature Coral accents (WCAG AA tuned for light bg)
      expect(dark.accentPrimary, const Color(0xFFFF6B82));
      expect(light.accentPrimary, const Color(0xFFE84562));
    });

    test('LevelColorInfo returns high-contrast colors in both dark and light mode', () {
      final n5Dark = LevelColorInfo.forLevel('JLPT N5', isDark: true);
      final n5Light = LevelColorInfo.forLevel('JLPT N5', isDark: false);

      expect(n5Dark.text, isNot(equals(n5Light.text)));
      expect(n5Dark.bg, isNot(equals(n5Light.bg)));

      final n1Dark = LevelColorInfo.forLevel('JLPT N1', isDark: true);
      final n1Light = LevelColorInfo.forLevel('JLPT N1', isDark: false);

      expect(n1Dark.text, isNot(equals(n1Light.text)));
    });

    test('ThemeData builds for dark and light without assertion errors', () {
      final darkTheme = VocaTheme.darkTheme;
      final lightTheme = VocaTheme.lightTheme;

      expect(darkTheme.brightness, Brightness.dark);
      expect(lightTheme.brightness, Brightness.light);
      expect(darkTheme.useMaterial3, isTrue);
      expect(lightTheme.useMaterial3, isTrue);
    });
  });

  group('VideoLevelService Unit Tests', () {
    test('Derives correct ProficiencyLevelTier from arbitrary level labels', () {
      expect(VideoLevelService.deriveLevelTier('JLPT N5'), ProficiencyLevelTier.beginner);
      expect(VideoLevelService.deriveLevelTier('HSK 1'), ProficiencyLevelTier.beginner);
      expect(VideoLevelService.deriveLevelTier('TOPIK 1'), ProficiencyLevelTier.beginner);
      expect(VideoLevelService.deriveLevelTier('CEFR A1'), ProficiencyLevelTier.beginner);
      expect(VideoLevelService.deriveLevelTier('Sơ cấp 1'), ProficiencyLevelTier.beginner);

      expect(VideoLevelService.deriveLevelTier('JLPT N4'), ProficiencyLevelTier.elementary);
      expect(VideoLevelService.deriveLevelTier('HSK 2'), ProficiencyLevelTier.elementary);
      expect(VideoLevelService.deriveLevelTier('TOPIK 2'), ProficiencyLevelTier.elementary);
      expect(VideoLevelService.deriveLevelTier('CEFR A2'), ProficiencyLevelTier.elementary);

      expect(VideoLevelService.deriveLevelTier('JLPT N3'), ProficiencyLevelTier.intermediate);
      expect(VideoLevelService.deriveLevelTier('HSK 3'), ProficiencyLevelTier.intermediate);
      expect(VideoLevelService.deriveLevelTier('TOPIK 3'), ProficiencyLevelTier.intermediate);
      expect(VideoLevelService.deriveLevelTier('CEFR B1'), ProficiencyLevelTier.intermediate);

      expect(VideoLevelService.deriveLevelTier('JLPT N2'), ProficiencyLevelTier.upperIntermediate);
      expect(VideoLevelService.deriveLevelTier('HSK 5'), ProficiencyLevelTier.upperIntermediate);

      expect(VideoLevelService.deriveLevelTier('JLPT N1'), ProficiencyLevelTier.advanced);
      expect(VideoLevelService.deriveLevelTier('HSK 6'), ProficiencyLevelTier.advanced);
      expect(VideoLevelService.deriveLevelTier('CEFR C1'), ProficiencyLevelTier.advanced);
    });

    test('Maps tiers to canonical exam labels for language', () {
      final s = VideoLevelService.instance;
      expect(s.tierToLabel(ProficiencyLevelTier.beginner, 'ja'), 'JLPT N5');
      expect(s.tierToLabel(ProficiencyLevelTier.intermediate, 'ja'), 'JLPT N3');
      expect(s.tierToLabel(ProficiencyLevelTier.advanced, 'ja'), 'JLPT N1');

      expect(s.tierToLabel(ProficiencyLevelTier.beginner, 'zh'), 'HSK 1');
      expect(s.tierToLabel(ProficiencyLevelTier.advanced, 'zh'), 'HSK 6');

      expect(s.tierToLabel(ProficiencyLevelTier.beginner, 'ko'), 'TOPIK 1');
      expect(s.tierToLabel(ProficiencyLevelTier.beginner, 'en'), 'CEFR A1');
    });

    test('Detects level from video title or channel heuristics', () {
      final s = VideoLevelService.instance;

      final detectedJa = s.detectFromMetadata('Learn Japanese for Beginners - N5 Grammar', 'Nihongo 101', 'ja');
      expect(detectedJa, 'JLPT N5');

      final detectedZh = s.detectFromMetadata('HSK 2 Vocabulary and Speaking Practice', 'Chinese Zero to Hero', 'zh');
      expect(detectedZh, 'HSK 2');
    });

    test('Assesses level with server fast-path and caching', () {
      final s = VideoLevelService.instance;
      s.reset();

      final res = s.assessLevel(
        videoId: 'v123',
        lang: 'ja',
        serverLevels: {'ja': 'JLPT N3'},
      );

      expect(res.level, 'JLPT N3');
      expect(res.tier, ProficiencyLevelTier.intermediate);
      expect(res.detectedFrom, 'server');

      // Verify cached
      final cached = s.getCachedLevel('v123', 'ja');
      expect(cached, isNotNull);
      expect(cached!.level, 'JLPT N3');
    });
  });

  group('Theme, Locale, and Native Bottom Sheet Widget Tests', () {
    testWidgets('UI dynamically adapts between dark and light themes via context.vocaColors', (tester) async {
      await tester.pumpWidget(
        Watch((context) {
          final isDark = AppState.instance.isDarkMode;
          return MaterialApp(
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            theme: VocaTheme.lightTheme,
            darkTheme: VocaTheme.darkTheme,
            home: Builder(
              builder: (ctx) {
                final colors = ctx.vocaColors;
                return Scaffold(
                  backgroundColor: colors.bgPrimary,
                  body: Text(
                    isDark ? 'Dark Mode Active' : 'Light Mode Active',
                    style: TextStyle(color: colors.textPrimary),
                  ),
                );
              },
            ),
          );
        }),
      );
      await tester.pumpAndSettle();

      // Set to dark mode
      AppState.instance.setThemeMode('dark');
      await tester.pumpAndSettle();
      expect(find.text('Dark Mode Active'), findsOneWidget);

      // Switch to light mode
      AppState.instance.setThemeMode('light');
      await tester.pumpAndSettle();
      expect(find.text('Light Mode Active'), findsOneWidget);

      // Switch back to dark mode
      AppState.instance.setThemeMode('dark');
      await tester.pumpAndSettle();
      expect(find.text('Dark Mode Active'), findsOneWidget);
    });

    testWidgets('UI dynamically adapts to runtime locale changes via context.t(...)', (tester) async {
      await tester.pumpWidget(
        Watch((context) {
          final uiLang = I18nService.instance.currentLanguage.value;
          return MaterialApp(
            key: ValueKey('app_test_$uiLang'),
            home: Builder(
              builder: (ctx) {
                return Scaffold(
                  body: Text(
                    ctx.t('nav.watch', null, 'Watch'),
                  ),
                );
              },
            ),
          );
        }),
      );
      await tester.pumpAndSettle();

      // In English
      await I18nService.instance.setLanguage('en');
      await tester.pumpAndSettle();
      expect(find.text('Watch'), findsOneWidget);

      // Switch to Vietnamese
      await I18nService.instance.setLanguage('vi');
      await tester.pumpAndSettle();
      expect(find.text('Xem'), findsOneWidget);

      // Switch to Japanese
      await I18nService.instance.setLanguage('ja');
      await tester.pumpAndSettle();
      expect(find.text('動画'), findsOneWidget);

      // Switch back to English
      await I18nService.instance.setLanguage('en');
      await tester.pumpAndSettle();
      expect(find.text('Watch'), findsOneWidget);
    });

    testWidgets('showVocaBottomSheet renders native sheet with header, drag handle, and dismisses', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                return ElevatedButton(
                  onPressed: () {
                    showVocaBottomSheet(
                      context: ctx,
                      title: 'Practice Immersion',
                      subtitle: 'Choose your challenge',
                      builder: (sheetCtx) => const Text('Sheet Content Area'),
                    );
                  },
                  child: const Text('Open Sheet'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap button to open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify sheet title, subtitle, content, and close button
      expect(find.text('Practice Immersion'), findsOneWidget);
      expect(find.text('Choose your challenge'), findsOneWidget);
      expect(find.text('Sheet Content Area'), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);

      // Tap close button
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      // Sheet should be dismissed
      expect(find.text('Practice Immersion'), findsNothing);
      expect(find.text('Sheet Content Area'), findsNothing);
    });
  });
}
