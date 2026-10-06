// test/onboarding_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/i18n_service.dart';
import 'package:voca_flutter/state/app_state.dart';
import 'package:voca_flutter/ui/onboarding/models/onboarding_models.dart';
import 'package:voca_flutter/ui/onboarding/onboarding_screen.dart';
import 'package:voca_flutter/ui/onboarding/widgets/onboarding_primitives.dart';
import 'package:voca_flutter/ui/onboarding/widgets/pressable_scale.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});

    // Seed i18n English translations for tests
    I18nService.instance.loadTranslations('en', {
      'settings': {
        'japanese': 'Japanese',
        'korean': 'Korean',
        'chinese': 'Chinese',
        'english': 'English',
        'vietnamese': 'Vietnamese',
      },
      'onboarding': {
        'welcomeTitle': 'Welcome to Voca',
        'welcomeSubtitle': 'Learn languages naturally through YouTube videos',
        'getStarted': 'Get Started',
        'realmTitle': 'Choose Your Language Realm',
        'learningLanguageSubtitle': 'Pick the language you want to study with authentic media',
        'myLanguage': 'My Language',
        'myLanguageHint': 'Interface language & subtitle translations',
        'dualSubtitlesToggle': 'Translate subtitles',
        'dualSubtitlesHint': 'Show translations below video captions',
        'chooseLevel': 'Calibrate Your Rank',
        'levelSubtitle': "We'll suggest videos suited to your pace",
        'dailyGoalLabel': 'Daily Habit Pact',
        'companionTitle': 'Choose Your Companion',
        'companionSubtitle': 'Your companion guide brings unique passive mastery to your journey',
        'starterTitle': "You're All Set!",
        'starterSubtitle': 'Review your learning plan and customize your appearance before starting',
        'claimStarterPack': 'Start Learning',
        'startLearning': 'Start Learning',
        'saveCalibration': 'Save Preferences',
        'planSummary': 'Learning Plan',
        'planReady': 'Ready',
        'appearance': 'Appearance',
        'themeSystem': 'System',
        'themeLight': 'Light',
        'themeDark': 'Dark',
        'skip': 'Skip',
        'back': 'Back',
        'continue': 'Continue',
        'features': {
          'subtitles': 'Bilingual subtitles with audio sync',
          'dict': 'Tap any word to translate instantly',
          'srs': 'Spaced repetition flashcards',
        },
        'demo': {
          'ja': {'text': '日本語を勉強しましょう', 'translation': "Let's study Japanese together!"},
          'ko': {'text': '함께 한국어를 배워요', 'translation': "Let's learn Korean together!"},
        },
        'realmVibes': {
          'ja': 'Anime & Daily Life',
          'ko': 'K-Drama & Slang',
          'zh': 'Hanzi & Podcasts',
          'en': 'Cinema & Idioms',
        },
        'companions': {
          'wizard': 'Scholar Mage',
          'wizardTrait': 'Grammar & Syntax',
          'wizardQuote': "I'll decode every complex sentence and grammar puzzle for you!",
          'knight': 'Guardian Knight',
          'knightTrait': 'Streak Protection',
          'knightQuote': 'Your daily streak will never falter under my unbreakable shield!',
        },
        'ranks': {
          'novice': 'Novice',
          'apprentice': 'Apprentice',
          'adept': 'Adept',
          'veteran': 'Veteran',
          'master': 'Master',
        },
        'levels': {
          'beginnerDesc': 'Simple phrases & clear speech',
          'elementaryDesc': 'Routine everyday vocabulary',
          'intermediateDesc': 'Natural conversations & vlogs',
          'upperIntermediateDesc': 'News clips & deep topics',
          'advancedDesc': 'Documentaries & native lectures',
        },
        'goals': {
          'casual': 'Casual Scout',
          'casualDesc': '5 min/day',
          'regular': 'Immersion Hunter',
          'regularDesc': '10 min/day',
          'serious': 'Dungeon Raider',
          'seriousDesc': '15 min/day',
          'intense': 'Mythic Master',
          'intenseDesc': '25 min/day',
        },
        'starterLoot': {
          'diamonds': 'Full AI Quota (💎)',
          'diamondsDesc': 'Instant AI speech sync ready',
          'xp': '+50 Starter XP',
          'xpDesc': 'Push Level 1 to 66%',
          'hearth': 'Campfire Hearth Ignited',
          'hearthDesc': 'Day 1 streak flame active',
          'freeze': '2 Frost Wards',
          'freezeDesc': 'Streak freeze protection pre-loaded',
        },
      },
      'level': {
        'beginner': 'Beginner',
        'elementary': 'Elementary',
        'intermediate': 'Intermediate',
        'upper_intermediate': 'Upper Intermediate',
        'advanced': 'Advanced',
      },
      'auth': {
        'alreadyHaveAccount': 'I already have an account',
      },
    });
  });

  group('Onboarding Models & Serialization Tests', () {
    test('UserSettings serializes and deserializes onboarding fields correctly', () {
      final settings = UserSettings(
        hasCompletedOnboarding: true,
        preferredLevel: 'intermediate',
        companionClass: 'knight',
        dailyGoalMinutes: 15,
      );

      final json = settings.toJson();
      expect(json['hasCompletedOnboarding'], isTrue);
      expect(json['preferredLevel'], equals('intermediate'));
      expect(json['companionClass'], equals('knight'));
      expect(json['dailyGoalMinutes'], equals(15));

      final deserialized = UserSettings.fromJson(json);
      expect(deserialized.hasCompletedOnboarding, isTrue);
      expect(deserialized.preferredLevel, equals('intermediate'));
      expect(deserialized.companionClass, equals('knight'));
      expect(deserialized.dailyGoalMinutes, equals(15));
    });

    test('Onboarding presets have expected options and data integrity', () {
      expect(LearningLanguageOption.all.length, equals(4));
      expect(NativeLanguageOption.all.length, equals(5));
      expect(LevelOption.all.length, equals(5));
      expect(DailyGoalOption.all.length, equals(4));
      expect(CompanionOption.all.length, equals(8));
    });

    test('Exam badges adapt correctly based on learning language', () {
      final beginner = LevelOption.byId('beginner');
      expect(beginner.examBadge('ja'), equals('JLPT N5'));
      expect(beginner.examBadge('zh'), equals('HSK 1'));
      expect(beginner.examBadge('ko'), equals('TOPIK 1'));
      expect(beginner.examBadge('en'), equals('A1'));

      final advanced = LevelOption.byId('advanced');
      expect(advanced.examBadge('ja'), equals('JLPT N1'));
      expect(advanced.examBadge('zh'), equals('HSK 6'));
      expect(advanced.examBadge('ko'), equals('TOPIK 6'));
      expect(advanced.examBadge('en'), equals('C1-C2'));
    });
  });

  group('Onboarding Primitives & Widgets Tests', () {
    testWidgets('PressableScale fires tap callback and triggers selection', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PressableScale(
              onTap: () => tapped = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      expect(find.text('Tap Me'), findsOneWidget);
      await tester.tap(find.text('Tap Me'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('RadioCheck renders correctly when selected or unselected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RadioCheck(selected: true),
                RadioCheck(selected: false),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });

  group('Onboarding Flow Tests', () {
    testWidgets('OnboardingScreen navigates through streamlined steps to completion', (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool finished = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            onFinish: () {
              finished = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 0: Welcome Step
      expect(find.text('Welcome to'), findsOneWidget);
      expect(find.text('Voca'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Tap "Continue" -> Step 1
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 1: Learning Language Realm & My Language
      expect(find.text('Choose Your Language Realm'), findsOneWidget);
      expect(find.text('Japanese'), findsWidgets);
      expect(find.text('Korean'), findsOneWidget);
      expect(find.text('My Language'), findsOneWidget);
      expect(find.text('Translate subtitles'), findsWidgets);

      // Select Korean
      await tester.tap(find.text('Korean'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap "Continue" -> Step 2: Difficulty Ladder & Habit Pact
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Step 2: Difficulty Ladder & Habit Pact
      expect(find.text('Calibrate Your Rank'), findsOneWidget);
      expect(find.text('DAILY HABIT PACT'), findsOneWidget);

      // Tap "Continue" -> Step 3: Companion Guide & Appearance (Theme) Selection
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Step 3: Companion Guide & Appearance (Theme) Selection
      expect(find.text('Choose Your Companion'), findsOneWidget);
      expect(find.text('Start Learning'), findsOneWidget);

      // Verify Theme Selection cards exist directly on Step 3
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      // Tap "Light" theme to test theme selection
      await tester.ensureVisible(find.text('Light'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      // Tap "Start Learning" to finish onboarding directly on Step 3
      await tester.tap(find.text('Start Learning'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(finished, isTrue);
      expect(AppState.instance.userSettings.value.hasCompletedOnboarding, isTrue);
      expect(AppState.instance.activeLanguage.value, equals('ko'));
      expect(AppState.instance.userSettings.value.themeMode, equals('light'));
    });

    testWidgets('OnboardingScreen Skip button immediately completes onboarding', (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool finished = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            onFinish: () {
              finished = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Skip button exists on step 0
      final skipButton = find.text('Skip');
      expect(skipButton, findsOneWidget);

      await tester.tap(skipButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(finished, isTrue);
      expect(AppState.instance.userSettings.value.hasCompletedOnboarding, isTrue);
    });
  });
}
