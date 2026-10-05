// lib/services/auth_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/voca_models.dart' hide UserProfile;
import '../utils/cyrb53_hasher.dart';
import 'supabase_service.dart';

enum SubscriptionTier {
  free,
  pro,
  premium;

  static SubscriptionTier fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'pro':
        return SubscriptionTier.pro;
      case 'premium':
        return SubscriptionTier.premium;
      default:
        return SubscriptionTier.free;
    }
  }

  String get nameString {
    switch (this) {
      case SubscriptionTier.pro:
        return 'pro';
      case SubscriptionTier.premium:
        return 'premium';
      case SubscriptionTier.free:
        return 'free';
    }
  }

  String get displayName {
    switch (this) {
      case SubscriptionTier.premium:
        return 'Founder';
      case SubscriptionTier.pro:
        return 'Supporter';
      case SubscriptionTier.free:
        return 'Free';
    }
  }
}

class UserProfile {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final String subscriptionTier; // 'free' | 'pro' | 'premium'
  final DateTime? subscriptionExpires;
  final int diamonds;
  final String? country;
  final String? targetLang;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.subscriptionTier = 'free',
    this.subscriptionExpires,
    this.diamonds = 5,
    this.country,
    this.targetLang,
  });

  String get displayName => (name.trim().isNotEmpty)
      ? name.trim()
      : (email.contains('@') ? email.split('@').first : 'Learner');

  SubscriptionTier get tier => SubscriptionTier.fromString(subscriptionTier);

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? (json['email'] as String? ?? 'Learner').split('@').first,
      avatarUrl: json['avatar_url'] as String?,
      subscriptionTier: (json['subscription_tier'] as String?)?.toLowerCase() ?? 'free',
      subscriptionExpires: json['subscription_expires'] != null
          ? DateTime.tryParse(json['subscription_expires'] as String)
          : null,
      diamonds: (json['diamonds'] as num?)?.toInt() ?? 5,
      country: json['country'] as String?,
      targetLang: json['target_lang'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'avatar_url': avatarUrl,
    'subscription_tier': subscriptionTier,
    if (subscriptionExpires != null) 'subscription_expires': subscriptionExpires!.toIso8601String(),
    'diamonds': diamonds,
    if (country != null) 'country': country,
    if (targetLang != null) 'target_lang': targetLang,
  };

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    String? subscriptionTier,
    DateTime? subscriptionExpires,
    int? diamonds,
    String? country,
    String? targetLang,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpires: subscriptionExpires ?? this.subscriptionExpires,
      diamonds: diamonds ?? this.diamonds,
      country: country ?? this.country,
      targetLang: targetLang ?? this.targetLang,
    );
  }
}

class AuthService {
  static const String _profileCacheKey = 'voca_user_profile';

  final SupabaseService supabaseService;
  StreamSubscription<AuthState>? _authSubscription;

  // Signals
  final userProfile = signal<UserProfile?>(null);
  late final isLoggedIn = computed<bool>(() => userProfile.value != null);
  final isLoggingIn = signal<bool>(false);
  late final subscriptionTier = computed<SubscriptionTier>(
    () => userProfile.value?.tier ?? SubscriptionTier.free,
  );
  final authError = signal<String?>(null);

  AuthService({required this.supabaseService});

  SupabaseClient get _client => supabaseService.client;
  User? get currentUser => _client.auth.currentUser;

  /// Initialize auth listeners and load cached profile
  Future<void> init() async {
    // 1. Synchronously load profile cache from SharedPreferences
    await _loadCachedProfile();

    // 2. If session already exists, fetch freshest profile row
    final session = _client.auth.currentSession;
    if (session?.user != null) {
      await _syncProfile(session!.user);
    }

    // 3. Reactively listen for auth state changes
    _authSubscription?.cancel();
    _authSubscription = _client.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      if (user != null) {
        await _syncProfile(user);
        await migrateGuestData(user.id);
      } else {
        userProfile.value = null;
        await _clearCachedProfile();
      }
    });
  }

  void dispose() {
    _authSubscription?.cancel();
  }

  /// Sign In with Google OAuth using standard redirect to `voca://login-callback`
  Future<bool> signInWithGoogle() async {
    isLoggingIn.value = true;
    authError.value = null;
    try {
      final res = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'voca://login-callback',
      );
      return res;
    } on AuthException catch (e) {
      authError.value = e.message;
      return false;
    } catch (e) {
      authError.value = e.toString();
      return false;
    } finally {
      isLoggingIn.value = false;
    }
  }

  /// Sign In with Apple (universal / iOS)
  Future<bool> signInWithApple() async {
    isLoggingIn.value = true;
    authError.value = null;
    try {
      final res = await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'voca://login-callback',
      );
      return res;
    } on AuthException catch (e) {
      authError.value = e.message;
      return false;
    } catch (e) {
      authError.value = e.toString();
      return false;
    } finally {
      isLoggingIn.value = false;
    }
  }

  /// Sign In with Email & Password
  Future<bool> signInWithEmail(String email, String password) async {
    isLoggingIn.value = true;
    authError.value = null;
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.user != null) {
        await _syncProfile(response.user!);
        await migrateGuestData(response.user!.id);
        return true;
      }
      return false;
    } on AuthException catch (e) {
      authError.value = e.message;
      return false;
    } catch (e) {
      authError.value = e.toString();
      return false;
    } finally {
      isLoggingIn.value = false;
    }
  }

  /// Sign Up with Email, Password and optional Name
  Future<bool> signUpWithEmail(
    String email,
    String password, {
    String? name,
  }) async {
    isLoggingIn.value = true;
    authError.value = null;
    try {
      final trimmedName = name?.trim();
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: trimmedName != null && trimmedName.isNotEmpty
            ? {'full_name': trimmedName, 'name': trimmedName}
            : null,
        emailRedirectTo: 'voca://login-callback',
      );
      if (response.user != null) {
        await _syncProfile(response.user!);
        await migrateGuestData(response.user!.id);
        return true;
      }
      return false;
    } on AuthException catch (e) {
      authError.value = e.message;
      return false;
    } catch (e) {
      authError.value = e.toString();
      return false;
    } finally {
      isLoggingIn.value = false;
    }
  }

  /// Send passwordless Magic Link (OTP) via Email
  Future<bool> sendMagicLink(String email) async {
    isLoggingIn.value = true;
    authError.value = null;
    try {
      await _client.auth.signInWithOtp(
        email: email.trim(),
        emailRedirectTo: 'voca://login-callback',
      );
      return true;
    } on AuthException catch (e) {
      authError.value = e.message;
      return false;
    } catch (e) {
      authError.value = e.toString();
      return false;
    } finally {
      isLoggingIn.value = false;
    }
  }

  /// Send password reset email via Supabase Auth
  Future<bool> sendPasswordResetEmail(String email) async {
    isLoggingIn.value = true;
    authError.value = null;
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: 'voca://reset-callback',
      );
      return true;
    } on AuthException catch (e) {
      authError.value = e.message;
      return false;
    } catch (e) {
      authError.value = e.toString();
      return false;
    } finally {
      isLoggingIn.value = false;
    }
  }

  /// Sign Out and purge session cache
  Future<void> signOut() async {
    authError.value = null;
    try {
      await _client.auth.signOut();
      userProfile.value = null;
      await _clearCachedProfile();
    } catch (e) {
      debugPrint('[AuthService] signOut error: $e');
    }
  }

  /// Update user profile (name, avatar, country) in Supabase and local cache
  Future<bool> updateUserProfile({
    String? name,
    String? avatarUrl,
    String? country,
  }) async {
    final success = await supabaseService.updateUserProfile(
      name: name,
      avatarUrl: avatarUrl,
      country: country,
    );
    if (success && currentUser != null) {
      await _syncProfile(currentUser!);
    }
    return success;
  }

  /// Deterministic guest data migration:
  /// On sign-in, if local flashcards exist with `userId == 'guest'`, update their
  /// `userId` and deterministic ID (`base36(userId + '|' + word + '|' + lang)`) and upsert to Supabase.
  Future<void> migrateGuestData(String userId) async {
    if (userId.isEmpty || userId == 'guest') return;

    try {
      final localCards = supabaseService.getLocalCards();
      final guestCards = localCards.where((c) => c.userId == 'guest' || c.userId.isEmpty).toList();
      if (guestCards.isEmpty) return;

      final guestIds = guestCards.map((c) => c.id).toSet();
      final List<Flashcard> migratedCards = [];
      for (final card in guestCards) {
        final newDeterministicId = generateDeterministicRecordId([
          userId,
          card.word.trim().toLowerCase(),
          card.language.trim().toLowerCase(),
        ]);

        final updated = card.copyWith(
          id: newDeterministicId,
          userId: userId,
        );
        migratedCards.add(updated);

        // Upsert to remote Supabase database
        await supabaseService.upsertVocabularyCard(updated);
      }

      // Retain migrated cards and purge old guest card IDs
      final currentCards = supabaseService.getLocalCards();
      final cleaned = currentCards.where((c) => !guestIds.contains(c.id)).toList();
      await supabaseService.replaceLocalCards(cleaned);

      debugPrint('[AuthService] Migrated ${guestCards.length} guest cards to user $userId');
    } catch (e) {
      debugPrint('[AuthService] Guest data migration error: $e');
    }
  }

  /// Sync UserProfile from Supabase `profiles` table or fallback to `user_metadata`
  Future<UserProfile> _syncProfile(User user) async {
    final meta = user.userMetadata ?? {};
    final metaAvatar = (meta['avatar_url'] ?? meta['picture']) as String?;
    final metaName = (meta['full_name'] ?? meta['name']) as String? ??
        (user.email?.split('@').first ?? 'Learner');

    UserProfile profile;
    try {
      final row = await _client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      if (row != null) {
        profile = UserProfile(
          id: row['id'] as String? ?? user.id,
          email: row['email'] as String? ?? user.email ?? '',
          name: row['name'] as String? ?? metaName,
          avatarUrl: row['avatar_url'] as String? ?? metaAvatar,
          subscriptionTier: row['subscription_tier'] as String? ?? 'free',
          diamonds: (row['diamonds'] as num?)?.toInt() ?? 5,
          country: row['country'] as String?,
        );
      } else {
        profile = UserProfile(
          id: user.id,
          email: user.email ?? '',
          name: metaName,
          avatarUrl: metaAvatar,
          subscriptionTier: 'free',
          diamonds: 5,
        );
      }
    } catch (e) {
      debugPrint('[AuthService] Error fetching profile row: $e');
      profile = UserProfile(
        id: user.id,
        email: user.email ?? '',
        name: metaName,
        avatarUrl: metaAvatar,
        subscriptionTier: 'free',
        diamonds: 5,
      );
    }

    userProfile.value = profile;
    await _cacheProfile(profile);
    return profile;
  }

  Future<void> _loadCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_profileCacheKey);
      if (jsonStr != null) {
        final decoded = jsonDecode(jsonStr);
        userProfile.value = UserProfile.fromJson(Map<String, dynamic>.from(decoded as Map));
      }
    } catch (e) {
      debugPrint('[AuthService] Cache load error: $e');
    }
  }

  Future<void> _cacheProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileCacheKey, jsonEncode(profile.toJson()));
    } catch (_) {}
  }

  Future<void> _clearCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileCacheKey);
    } catch (_) {}
  }
}
