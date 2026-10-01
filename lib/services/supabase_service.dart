// lib/services/supabase_service.dart

import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/voca_models.dart';

class SupabaseService {
  final SupabaseClient client;

  SupabaseService(this.client);

  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  /// Sign In with Google OAuth
  Future<bool> signInWithGoogle() async {
    return await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'voca://login-callback',
    );
  }

  /// Sign Out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// 1. Vocabulary / Flashcards Sync
  Future<List<Flashcard>> getVocabularyCards({String? language}) async {
    final user = currentUser;
    if (user == null) return [];

    var query = client.from('vocabulary').select().eq('user_id', user.id);
    if (language != null) {
      query = query.eq('language', language);
    }

    final data = await query.order('srs_next_review_at', ascending: true);
    return (data as List).map((row) => Flashcard.fromJson(row)).toList();
  }

  Future<void> upsertVocabularyCard(Flashcard card) async {
    final user = currentUser;
    if (user == null) return;

    await client.from('vocabulary').upsert(card.toJson());
  }

  Future<void> deleteVocabularyCard(String cardId) async {
    final user = currentUser;
    if (user == null) return;

    await client.from('vocabulary').delete().eq('id', cardId).eq('user_id', user.id);
  }

  /// 2. Atomic Streak Recording via RPC
  Future<Map<String, dynamic>?> recordStreakActivity(DateTime date) async {
    final user = currentUser;
    if (user == null) return null;

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final res = await client.rpc('record_streak_activity', params: {
      'p_user_id': user.id,
      'p_activity_date': dateStr,
    });
    return res != null ? Map<String, dynamic>.from(res as Map) : null;
  }

  /// 3. Watch History
  Future<List<Map<String, dynamic>>> getHistory({int limit = 20}) async {
    final user = currentUser;
    if (user == null) return [];

    final data = await client
        .from('history')
        .select()
        .eq('user_id', user.id)
        .order('watched_at', ascending: false)
        .limit(limit);

    return (data as List).map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  Future<void> saveHistory({
    required String id,
    required String videoId,
    required String title,
    required String thumbnail,
    required String channel,
    required int duration,
    required String language,
    required double progress,
  }) async {
    final user = currentUser;
    if (user == null) return;

    await client.from('history').upsert({
      'id': id,
      'user_id': user.id,
      'video_id': videoId,
      'title': title,
      'thumbnail': thumbnail,
      'channel': channel,
      'duration': duration,
      'language': language,
      'progress': progress,
      'watched_at': DateTime.now().toIso8601String(),
    });
  }
}
