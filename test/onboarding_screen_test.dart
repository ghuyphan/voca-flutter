// test/onboarding_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/i18n_service.dart';
import 'package:voca_flutter/state/app_state.dart';
import 'package:voca_flutter/ui/onboarding/models/onboarding_models.dart';
import 'package:voca_flutter/ui/onboarding/onboarding_screen.dart';
import 'package:voca_flutter/ui/onboarding/widgets/onboarding_selection_tile.dart';
import 'package:voca_flutter/ui/onboarding/widgets/companion_speech_bubble.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});

    // Seed i18n English translations for tests
    I18nService.instance.loadTranslations('en', {
      'onboarding': {
        'welcomeTitle': 'Welcome to Voca',
        'welcomeSubtitle': 'Learn languages naturally through YouTube videos',
        'getStarted': 'Get Started',
        'realmTitle': 'Choose Your Language Realm',
        'learningLanguageSubtitle': 'Pick the language you want to study',
        'myLanguage': 'My Language',
        'myLanguageHint': 'Interface & subtitles',
        'dualSubtitlesToggle': 'Translate subtitles',
        'dualSubtitlesHint': 'Show translations below video captions',
        'chooseLevel': 'Calibrate Your Rank & Habit',
        'levelSubtitle': 'We’ll suggest videos suited to your pace',
        'dailyGoalLabel': 'Daily Habit Pact',
        'pactSubtitle': 'Habits build legends',
        'companionTitle': 'Choose Your Companion Spirit',
        'companionSubtitle': 'Pick a companion guide for your journey',
        'starterTitle': 'Adventurer License Activated!',
        'starterSubtitle': 'The Guild welcomes you with your initial supply cache',
        'startLearning': 'Start Learning',
        'guildCharter': 'Voca Guild Charter',
        'skip': 'Skip',
        'back': 'Back',
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
      'common': {
        'continue': 'Continue',
      },
      'levels': {
        'beginner': 'Beginner',
        'beginnerDesc': 'Just getting started',
        'elementary': 'Elementary',
        'elementaryDesc': 'Basic everyday words',
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
      expect(LearningRealmOption.all.length, equals(4));
      expect(NativeLanguageOption.all.length, equals(5));
      expect(RankLevelOption.all.length, equals(5));
      expect(DailyGoalOption.all.length, equals(4));
      expect(CompanionSpiritOption.all.length, equals(8));
      expect(StarterLootItem.all.length, equals(4));
    });
  });

  group('Onboarding Widgets & Flow Tests', () {
    testWidgets('OnboardingSelectionTile renders title, tagChip, and handles tap callback',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnboardingSelectionTile(
              title: 'Japanese',
              tagChip: '日本語',
              subtitle: 'Anime & Daily Life',
              isSelected: true,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Japanese'), findsOneWidget);
      expect(find.text('日本語'), findsOneWidget);
      expect(find.text('Anime & Daily Life'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await tester.tap(find.byType(OnboardingSelectionTile));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('CompanionSpeechBubble renders dynamic voice line quote', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompanionSpeechBubble(
              quote: "I'll decode every complex sentence!",
              accentColor: Colors.purple,
            ),
          ),
        ),
      );

      expect(find.text('“I\'ll decode every complex sentence!”'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    });

    testWidgets('OnboardingScreen starts at Step 0 and navigates through steps to completion',
        (tester) async {
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
      expect(find.text('Welcome to Voca'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      // Tap "Get Started" -> Step 1
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Step 1: Language Realm
      expect(find.text('Choose Your Language Realm'), findsOneWidget);
      expect(find.text('Japanese'), findsWidgets);
      expect(find.text('Korean'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Select Korean
      await tester.tap(find.text('Korean'));
      await tester.pumpAndSettle();

      // Tap "Continue" -> Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: Pace & Level Ladder
      expect(find.text('Calibrate Your Rank & Habit'), findsOneWidget);
      expect(find.text('Daily Habit Pact'), findsOneWidget);

      // Tap "Continue" -> Step 3
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: Companion Spirit Guide
      expect(find.text('Choose Your Companion Spirit'), findsOneWidget);
      expect(find.text('Scholar Mage'), findsOneWidget);

      // Select Guardian Knight
      await tester.tap(find.text('Guardian Knight'));
      await tester.pumpAndSettle();

      // Tap "Continue" -> Step 4
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 4: Adventurer License Activated
      expect(find.text('Adventurer License Activated!'), findsOneWidget);
      expect(find.text('VOCA GUILD CHARTER'), findsOneWidget);
      expect(find.text('Start Learning'), findsOneWidget);

      // Tap "Start Learning"
      await tester.tap(find.text('Start Learning'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(finished, isTrue);
      expect(AppState.instance.userSettings.value.hasCompletedOnboarding, isTrue);
      expect(AppState.instance.userSettings.value.companionClass, equals('knight'));
      expect(AppState.instance.activeLanguage.value, equals('ko'));
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
