// test/settings_and_edit_profile_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voca_flutter/config/voca_theme.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/auth_service.dart';
import 'package:voca_flutter/services/i18n_service.dart';
import 'package:voca_flutter/services/supabase_service.dart';
import 'package:voca_flutter/state/app_state.dart';
import 'package:voca_flutter/ui/auth/auth_screen.dart';
import 'package:voca_flutter/ui/onboarding/onboarding_screen.dart';
import 'package:voca_flutter/ui/profile/edit_profile_screen.dart';
import 'package:voca_flutter/ui/settings/settings_screen.dart';

class FakeSupabaseService extends Fake implements SupabaseService {
  @override
  User? get currentUser => null;
  @override
  bool get isAuthenticated => false;
}

class FakeAuthService extends Fake implements AuthService {
  @override
  final userProfile = signal<UserProfile?>(null);
  @override
  late final isLoggedIn = computed<bool>(() => userProfile.value != null);
  @override
  final isLoggingIn = signal<bool>(false);
  @override
  final authError = signal<String?>(null);
  @override
  late final subscriptionTier = computed<SubscriptionTier>(
    () => userProfile.value?.tier ?? SubscriptionTier.free,
  );
  @override
  Future<void> init() async {}
  @override
  Future<bool> updateUserProfile({String? name, String? avatarUrl, String? country}) async {
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await I18nService.instance.init();
    AppState.instance.activeLanguage.value = 'ja';
    AppState.instance.userSettings.value = UserSettings();
    AppState.instance.supabaseService = FakeSupabaseService();
    AppState.instance.authService = FakeAuthService();
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: VocaTheme.darkTheme,
      home: child,
    );
  }

  group('SettingsScreen Tests', () {
    testWidgets('renders all settings sections cleanly like a real app', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const SettingsScreen()));
      await tester.pumpAndSettle();

      // AppBar title
      expect(find.text('Settings'), findsOneWidget);

      // Account Hero Card (Guest Mode)
      expect(find.text('Sync vocabulary across devices'), findsOneWidget);
      expect(find.text('Log in or Sign up'), findsOneWidget);

      // Section 1: Learning & Display (Learning & UI languages next to each other)
      expect(find.text('LEARNING & DISPLAY'), findsOneWidget);
      expect(find.text('Learning Language'), findsOneWidget);
      expect(find.text('Interface Language'), findsOneWidget);
      expect(find.text('Furigana & Ruby'), findsOneWidget);
      expect(find.text('On-Device Translation'), findsOneWidget);

      // Section 2: Appearance
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Haptic Feedback'), findsOneWidget);

      // Section 3: About & Updates
      expect(find.text('ABOUT & UPDATES'), findsOneWidget);
      expect(find.text('Version'), findsOneWidget);
      expect(find.text("What's New"), findsOneWidget);
      expect(find.text('Check for Updates'), findsOneWidget);
      expect(find.text('Discord Community'), findsOneWidget);

      // Simplified clean footer
      expect(find.text('VOCA MOBILE • v1.2.4'), findsOneWidget);
    });

    testWidgets('navigates to HapticSettingsScreen and toggles haptic feedback on/off', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(AppState.instance.userSettings.value.hapticFeedbackEnabled, isTrue);
      expect(find.text('Haptic Feedback'), findsOneWidget);
      expect(find.text('On'), findsOneWidget);

      // Tap Haptic Feedback tile to open sub-screen
      await tester.tap(find.text('Haptic Feedback'));
      await tester.pumpAndSettle();

      expect(find.text('Tactile Touch Feedback'), findsOneWidget);
      expect(find.text('Enable Haptic Feedback'), findsOneWidget);

      // Toggle off
      await tester.tap(find.text('Enable Haptic Feedback'));
      await tester.pumpAndSettle();
      expect(AppState.instance.userSettings.value.hapticFeedbackEnabled, isFalse);

      // Pop back and verify subtitle updated to Off
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Off'), findsWidgets);
    });

    testWidgets('navigates to unified sub-screens for Learning Language and Theme', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestableWidget(const SettingsScreen()));
      await tester.pumpAndSettle();

      // Open Learning Language sub-screen
      await tester.tap(find.text('Learning Language'));
      await tester.pumpAndSettle();

      expect(find.text('Target Immersion Language'), findsOneWidget);
      expect(find.text('中文'), findsOneWidget);

      // Select Chinese
      await tester.tap(find.text('中文'));
      await tester.pumpAndSettle();
      expect(AppState.instance.activeLanguage.value, equals('zh'));

      // Pop back to SettingsScreen
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // Open Theme sub-screen
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      expect(find.text('Visual Appearance'), findsOneWidget);
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(AppState.instance.userSettings.value.themeMode, equals('light'));
    });

    testWidgets('strictly removes raw emoji stat rows, library items, and bulky segmented buttons', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const SettingsScreen()));
      await tester.pumpAndSettle();

      // Verify NO raw Unicode emoji stat rows ('🔥', '🛡️', '💎')
      expect(find.text('🔥'), findsNothing);
      expect(find.text('🛡️'), findsNothing);
      expect(find.text('💎'), findsNothing);

      // Verify NO embedded Library navigation items (Playlists, History)
      expect(find.text('Playlists'), findsNothing);
      expect(find.text('Recently watched lessons'), findsNothing);
      expect(find.text('Organized study collections'), findsNothing);

      // Verify NO bulky Material 3 segmented button controls
      expect(find.byType(SegmentedButton<dynamic>), findsNothing);
    });

    testWidgets('dynamic reading guide adapts to target language', (tester) async {
      // 1. Japanese -> Furigana & Ruby
      AppState.instance.setLanguage('ja');
      await tester.pumpWidget(buildTestableWidget(const SettingsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Furigana & Ruby'), findsOneWidget);

      // 2. Chinese -> Pinyin Guides
      AppState.instance.setLanguage('zh');
      await tester.pumpWidget(buildTestableWidget(const SettingsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Pinyin Guides'), findsOneWidget);

      // 3. Korean -> Romaji Guides
      AppState.instance.setLanguage('ko');
      await tester.pumpWidget(buildTestableWidget(const SettingsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Romaji Guides'), findsOneWidget);
    });

    testWidgets('tapping What\'s New opens release notes sheet', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const SettingsScreen()));
      await tester.pumpAndSettle();

      // Scroll to What's New tile
      await tester.scrollUntilVisible(
        find.text("What's New"),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      // Tap What's New
      await tester.tap(find.text("What's New"));
      await tester.pumpAndSettle();

      // Bottom sheet is displayed
      expect(find.text('Version 1.2.4 • 2026-09-30'), findsOneWidget);
      expect(find.text('Buttery-Smooth Playback'), findsOneWidget);
      expect(find.text('Rock-Solid Cloud Sync'), findsOneWidget);
      expect(find.text('Rock-Steady Screens'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Tap Done to dismiss
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Done'), findsNothing);
    });

    testWidgets('tapping Replay Onboarding opens OnboardingScreen without clearing app state', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Replay Onboarding'), findsOneWidget);
      await tester.ensureVisible(find.text('Replay Onboarding'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Replay Onboarding'));
      await tester.pumpAndSettle();

      // OnboardingScreen is opened at Welcome step (step 0)
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('Welcome to Voca'), findsOneWidget);

      // Back button is visible and pops back to SettingsScreen
      final backButton = find.byIcon(Icons.arrow_back_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('EditProfileScreen Tests', () {
    testWidgets('renders hero avatar preview, 16 presets grid, and inputs', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const EditProfileScreen()));
      await tester.pumpAndSettle();

      // Title & Save action
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Hero Avatar label
      expect(find.text('Or choose a preset'), findsOneWidget);

      // 16 Archetype Presets block
      expect(find.text('COMPANION ARCHETYPES'), findsOneWidget);
      expect(kPresetAvatars.length, equals(16));

      // Display Name & Country inputs
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Country / Region'), findsOneWidget);
      expect(find.text('Appears next to your name on the global leaderboard'), findsOneWidget);

      // Save Changes CTA button
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('selecting a preset avatar updates hero preview selection', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const EditProfileScreen()));
      await tester.pumpAndSettle();

      // Find 'Shinobi' preset
      final shinobiText = find.text('Shinobi');
      expect(shinobiText, findsOneWidget);

      // Tap Shinobi
      await tester.tap(shinobiText);
      await tester.pumpAndSettle();

      // Checkmark icon appears on selected avatar
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });
  });

  group('AuthScreen Tests', () {
    testWidgets('renders VOCA branding and ACTE landing CTAs', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const AuthScreen()));
      await tester.pumpAndSettle();

      // App Title & Tagline
      expect(find.text('VOCA'), findsOneWidget);
      expect(find.text('Learn languages through authentic videos'), findsOneWidget);

      // Buttons
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with email'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);
    });
  });
}
