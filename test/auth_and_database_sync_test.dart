// test/auth_and_database_sync_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voca_flutter/config/voca_theme.dart';
import 'package:voca_flutter/models/voca_models.dart';
import 'package:voca_flutter/services/auth_service.dart';
import 'package:voca_flutter/services/i18n_service.dart';
import 'package:voca_flutter/services/supabase_service.dart';
import 'package:voca_flutter/state/app_state.dart';
import 'package:voca_flutter/ui/auth/auth_screen.dart';
import 'package:voca_flutter/utils/cyrb53_hasher.dart';

class _FakeGoTrueClient extends GoTrueClient {
  _FakeGoTrueClient() : super();
  @override
  User? get currentUser => null;
}

class _MockSupabaseClient extends Fake implements SupabaseClient {
  @override
  final GoTrueClient auth = _FakeGoTrueClient();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await I18nService.instance.init();
    AppState.instance.activeLanguage.value = 'ja';
    AppState.instance.userSettings.value = UserSettings();
  });

  group('Flashcard Canonical Supabase Serialization Tests', () {
    test('WordLevels.normalize canonical levels and legacy mastered conversion', () {
      expect(WordLevels.normalize('new'), equals('new'));
      expect(WordLevels.normalize('learning'), equals('learning'));
      expect(WordLevels.normalize('known'), equals('known'));
      expect(WordLevels.normalize('ignored'), equals('ignored'));
      expect(WordLevels.normalize('mastered'), equals('known'));
      expect(WordLevels.normalize('MASTERED'), equals('known'));
      expect(WordLevels.normalize('unknown_level'), equals('new'));
      expect(WordLevels.normalize(null), equals('new'));
    });

    test('Flashcard.fromJson parses canonical Supabase columns correctly', () {
      final json = {
        'id': 'test_card_1',
        'user_id': 'user_abc',
        'word': '食べる',
        'reading': 'たべる',
        'romanization': 'taberu',
        'meaning': 'to eat',
        'language': 'ja',
        'level': 'learning',
        'interval': 6,
        'repetitions': 3,
        'ease_factor': 2.6,
        'review_count': 5,
        'next_review_date': '2026-10-10T12:00:00.000Z',
        'last_reviewed_at': '2026-10-04T12:00:00.000Z',
        'source_sentence': '毎朝ご飯を食べる。',
      };

      final card = Flashcard.fromJson(json);

      expect(card.id, equals('test_card_1'));
      expect(card.userId, equals('user_abc'));
      expect(card.word, equals('食べる'));
      expect(card.reading, equals('たべる'));
      expect(card.romanization, equals('taberu'));
      expect(card.meaning, equals('to eat'));
      expect(card.language, equals('ja'));
      expect(card.level, equals('learning'));
      expect(card.srsInterval, equals(6));
      expect(card.srsRepetition, equals(3));
      expect(card.srsEaseFactor, equals(2.6));
      expect(card.reviewCount, equals(5));
      expect(card.srsNextReviewAt, equals(DateTime.parse('2026-10-10T12:00:00.000Z')));
      expect(card.srsLastReviewedAt, equals(DateTime.parse('2026-10-04T12:00:00.000Z')));
      expect(card.contextSentence, equals('毎朝ご飯を食べる。'));
    });

    test('Flashcard.fromJson gracefully parses legacy column aliases', () {
      final legacyJson = {
        'id': 'test_legacy_1',
        'user_id': 'user_xyz',
        'word': '約束',
        'meaning': 'promise',
        'language': 'ja',
        'level': 'mastered', // Legacy mastered
        'srs_interval': 15,
        'srs_repetition': 5,
        'srs_ease_factor': 2.7,
        'srs_next_review_at': '2026-10-20T00:00:00.000Z',
        'srs_last_reviewed_at': '2026-10-05T00:00:00.000Z',
        'context_sentence': '約束を守る。',
      };

      final card = Flashcard.fromJson(legacyJson);

      expect(card.level, equals('known')); // Mapped from 'mastered'
      expect(card.srsInterval, equals(15));
      expect(card.srsRepetition, equals(5));
      expect(card.srsEaseFactor, equals(2.7));
      expect(card.srsNextReviewAt, equals(DateTime.parse('2026-10-20T00:00:00.000Z')));
      expect(card.contextSentence, equals('約束を守る。'));
    });

    test('Flashcard.toBaseJson outputs canonical Supabase columns', () {
      final now = DateTime.now();
      final card = Flashcard(
        id: 'test_card_base',
        userId: 'user_123',
        word: '美しい',
        reading: 'うつくしい',
        meaning: 'beautiful',
        language: 'ja',
        level: 'known',
        srsInterval: 10,
        srsRepetition: 4,
        srsEaseFactor: 2.8,
        reviewCount: 4,
        srsNextReviewAt: now,
        srsLastReviewedAt: now.subtract(const Duration(days: 10)),
      );

      final map = card.toBaseJson();

      expect(map['id'], equals('test_card_base'));
      expect(map['user_id'], equals('user_123'));
      expect(map['word'], equals('美しい'));
      expect(map['reading'], equals('うつくしい'));
      expect(map['level'], equals('known'));
      expect(map['interval'], equals(10));
      expect(map['repetitions'], equals(4));
      expect(map['ease_factor'], equals(2.8));
      expect(map['review_count'], equals(4));
      expect(map['next_review_date'], equals(now.toIso8601String()));
      expect(map['last_reviewed_at'], equals(now.subtract(const Duration(days: 10)).toIso8601String()));
    });

    test('Flashcard.toRemoteJson conforms strictly to public.vocabulary table schema', () {
      final now = DateTime.now();
      final card = Flashcard(
        id: 'test_remote_1',
        userId: 'user_456',
        word: '未来',
        reading: 'みらい',
        meaning: 'future',
        language: 'ja',
        level: 'known',
        srsInterval: 12,
        srsRepetition: 3,
        srsEaseFactor: 2.5,
        reviewCount: 3,
        srsNextReviewAt: now,
        contextSentence: '明るい未来へ。',
      );

      final remote = card.toRemoteJson();

      // Check keys exist
      expect(remote['id'], equals('test_remote_1'));
      expect(remote['user_id'], equals('user_456'));
      expect(remote['word'], equals('未来'));
      expect(remote['interval'], equals(12));
      expect(remote['repetitions'], equals(3));
      expect(remote['ease_factor'], equals(2.5));
      expect(remote['review_count'], equals(3));
      expect(remote['next_review_date'], equals(now.toIso8601String()));
      expect(remote['source_sentence'], equals('明るい未来へ。'));
      expect(remote.containsKey('updated_at'), isTrue);

      // Verify NO non-existent column names that would cause Postgres 400
      expect(remote.containsKey('part_of_speech'), isFalse);
      expect(remote.containsKey('notes'), isFalse);
      expect(remote.containsKey('context_translation'), isFalse);
      expect(remote.containsKey('srs_interval'), isFalse);
      expect(remote.containsKey('srs_next_review_at'), isFalse);
    });
  });

  group('UserProfile & SubscriptionTier Tests', () {
    test('UserProfile fromJson and toJson', () {
      final json = {
        'id': 'profile_1',
        'email': 'learner@voca.study',
        'name': 'Alex',
        'avatar_url': 'https://voca.study/avatar.png',
        'subscription_tier': 'pro',
        'diamonds': 10,
        'country': 'JP',
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.id, equals('profile_1'));
      expect(profile.email, equals('learner@voca.study'));
      expect(profile.name, equals('Alex'));
      expect(profile.avatarUrl, equals('https://voca.study/avatar.png'));
      expect(profile.subscriptionTier, equals('pro'));
      expect(profile.tier, equals(SubscriptionTier.pro));
      expect(profile.tier.displayName, equals('Supporter'));
      expect(profile.diamonds, equals(10));
      expect(profile.country, equals('JP'));

      final out = profile.toJson();
      expect(out['id'], equals('profile_1'));
      expect(out['email'], equals('learner@voca.study'));
      expect(out['subscription_tier'], equals('pro'));
      expect(out['diamonds'], equals(10));
      expect(out['country'], equals('JP'));
    });

    test('SubscriptionTier string mappings', () {
      expect(SubscriptionTier.fromString('free'), equals(SubscriptionTier.free));
      expect(SubscriptionTier.fromString('pro'), equals(SubscriptionTier.pro));
      expect(SubscriptionTier.fromString('premium'), equals(SubscriptionTier.premium));
      expect(SubscriptionTier.fromString('other'), equals(SubscriptionTier.free));
      expect(SubscriptionTier.fromString(null), equals(SubscriptionTier.free));

      expect(SubscriptionTier.free.displayName, equals('Free'));
      expect(SubscriptionTier.pro.displayName, equals('Supporter'));
      expect(SubscriptionTier.premium.displayName, equals('Founder'));
    });
  });

  group('Deterministic Guest Data Migration Tests', () {
    test('guest cards receive deterministic IDs and updated userId', () async {
      final fakeClient = _MockSupabaseClient();
      final supabaseService = SupabaseService(fakeClient);
      final authService = AuthService(supabaseService: supabaseService);

      // Seed local guest cards
      final guestCard1 = Flashcard(
        id: 'sample_ja_1',
        userId: 'guest',
        word: '食べる',
        meaning: 'to eat',
        language: 'ja',
        srsNextReviewAt: DateTime.now(),
      );
      final guestCard2 = Flashcard(
        id: 'sample_ja_2',
        userId: 'guest',
        word: '約束',
        meaning: 'promise',
        language: 'ja',
        srsNextReviewAt: DateTime.now(),
      );

      await supabaseService.replaceLocalCards([guestCard1, guestCard2]);
      expect(supabaseService.getLocalCards().length, equals(2));
      expect(supabaseService.getLocalCards().every((c) => c.userId == 'guest'), isTrue);

      const authedUserId = 'uuid-user-8888';
      await authService.migrateGuestData(authedUserId);

      final migrated = supabaseService.getLocalCards();
      expect(migrated.length, equals(2));

      // Check card 1
      final c1 = migrated.firstWhere((c) => c.word == '食べる');
      expect(c1.userId, equals(authedUserId));
      final expectedId1 = generateDeterministicRecordId([authedUserId, '食べる', 'ja']);
      expect(c1.id, equals(expectedId1));

      // Check card 2
      final c2 = migrated.firstWhere((c) => c.word == '約束');
      expect(c2.userId, equals(authedUserId));
      final expectedId2 = generateDeterministicRecordId([authedUserId, '約束', 'ja']);
      expect(c2.id, equals(expectedId2));
    });
  });

  group('AuthScreen UI Rendering Tests', () {
    testWidgets('renders all essential elements and landing CTAs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const AuthScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Brand Title & Subtitle
      expect(find.text('VOCA'), findsOneWidget);
      expect(find.text('Learn languages through authentic videos'), findsOneWidget);

      // Social Sign-in Button
      expect(find.text('Continue with Google'), findsOneWidget);

      // Continue with email button
      expect(find.text('Continue with email'), findsOneWidget);

      // Guest link
      expect(find.text('Continue as Guest'), findsOneWidget);

      // Policy & terms consent
      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('opening email form sheet and toggling between Sign In and Register', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VocaTheme.darkTheme,
          home: const AuthScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Open email sheet
      final continueEmailBtn = find.text('Continue with email');
      await tester.tap(continueEmailBtn);
      await tester.pumpAndSettle();

      // In Sign In mode:
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Need an account? Create one'), findsOneWidget);
      expect(find.text('Name (optional)'), findsNothing);

      // Tap switch to register
      final switchRegisterBtn = find.text('Need an account? Create one');
      await tester.tap(switchRegisterBtn);
      await tester.pumpAndSettle();

      // In Register mode: Name and Confirm password appear
      expect(find.text('Name (optional)'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('Already have an account? Sign in'), findsOneWidget);
    });
  });
}
