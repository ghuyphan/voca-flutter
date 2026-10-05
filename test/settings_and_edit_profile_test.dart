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
    testWidgets('renders all 6 Inset Grouped sections cleanly', (tester) async {
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

      // Section 1: Account
      expect(find.text('ACCOUNT & PROFILE'), findsOneWidget);
      expect(find.text('Sign In to Voca'), findsOneWidget);
      expect(find.text('Sign In / Register'), findsOneWidget);

      // Section 2: Learning & Reading Guides
      expect(find.text('LEARNING & READING GUIDES'), findsOneWidget);
      expect(find.text('Learning Language'), findsOneWidget);
      expect(find.text('Furigana & Ruby'), findsOneWidget);
      expect(find.text('Translation Language'), findsOneWidget);
      expect(find.text('Recalibrate Learning Goals'), findsOneWidget);

      // Section 3: Video Player & Subtitles
      expect(find.text('VIDEO PLAYER & SUBTITLES'), findsOneWidget);
      expect(find.text('Dual Subtitles'), findsOneWidget);
      expect(find.text('Subtitle Font Size'), findsOneWidget);
      expect(find.text('Auto-pause on Lookup'), findsOneWidget);

      // Section 4: Appearance & Interface
      expect(find.text('APPEARANCE & INTERFACE'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.text('App Interface Language'), findsOneWidget);

      // Scroll to bottom for remaining sections
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // Section 5: Data & Storage
      expect(find.text('DATA & STORAGE'), findsOneWidget);
      expect(find.text('Clear Subtitle & Dict Cache'), findsOneWidget);

      // Section 6: About & Support
      expect(find.text('ABOUT & SUPPORT'), findsOneWidget);
      expect(find.text('Version'), findsOneWidget);
      expect(find.text('1.0.0+1 (Voca Mobile)'), findsOneWidget);
      expect(find.text("What's New"), findsOneWidget);
      expect(find.text('Discord Community & Feedback'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
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
      expect(find.text('Version 1.0.0+1 (Voca Mobile)'), findsOneWidget);
      expect(find.text('Buttery-Smooth Playback'), findsOneWidget);
      expect(find.text('Rock-Solid Cloud Sync'), findsOneWidget);
      expect(find.text('Native Inset Preferences & Avatars'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);

      // Tap Done to dismiss
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Done'), findsNothing);
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
    testWidgets('renders Kikyou branding, benefits, and Google CTA', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const AuthScreen()));
      await tester.pumpAndSettle();

      // App Title & Tagline
      expect(find.text('VOCA'), findsOneWidget);

      // Value Propositions
      expect(find.text('Seamless Cloud Sync'), findsOneWidget);
      expect(find.text('Streak & Progress Guard'), findsOneWidget);
      expect(find.text('Global Learner Ranks'), findsOneWidget);

      // Buttons
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);
    });
  });
}
