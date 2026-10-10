// lib/services/supabase_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';
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

  /// Fetch user profile from Supabase profiles table
  Future<UserProfile?> fetchUserProfile([String? userId]) async {
    final uid = userId ?? currentUser?.id;
    if (uid == null) return null;
    try {
      final res = await client.from('profiles').select().eq('id', uid).maybeSingle();
      if (res != null) {
        return UserProfile.fromJson(res);
      }
    } catch (e) {
      debugPrint('[SupabaseService] Remote fetch profile error: $e');
    }

    // Fallback: create profile from currentUser auth metadata
    final user = currentUser;
    if (user != null && user.id == uid) {
      final meta = user.userMetadata;
      final name = (meta?['name'] ?? meta?['full_name']) as String?;
      final avatarUrl = (meta?['avatar_url'] ?? meta?['picture']) as String?;
      return UserProfile(
        id: user.id,
        email: user.email ?? '',
        name: name ?? (user.email ?? 'Learner').split('@').first,
        avatarUrl: avatarUrl,
      );
    }
    return null;
  }

  /// Update user profile in Supabase profiles table
  Future<bool> updateUserProfile({
    String? name,
    String? avatarUrl,
    String? country,
  }) async {
    final user = currentUser;
    if (user == null) return false;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null) updates['name'] = name.trim();
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl.trim();
    if (country != null) updates['country'] = country.trim();

    try {
      await client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        ...updates,
      });
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Error updating profile with upsert: $e');
      try {
        await client.from('profiles').update(updates).eq('id', user.id);
        return true;
      } catch (e2) {
        debugPrint('[SupabaseService] Error updating profile with update: $e2');
        return false;
      }
    }
  }

  final List<Flashcard> _localCards = [];

  /// Global reactive signal tracking all cached vocabulary cards.
  /// Any UI watching this signal updates instantly across tabs when words are saved or deleted.
  final Signal<List<Flashcard>> vocabularyCardsSignal = signal<List<Flashcard>>([]);

  void _notifyCardsChanged() {
    vocabularyCardsSignal.value = List.unmodifiable(_localCards);
  }

  List<Flashcard> getLocalCards() => List.unmodifiable(_localCards);

  /// 1. Vocabulary / Flashcards Sync
  Future<List<Flashcard>> getVocabularyCards({String? language}) async {
    final user = currentUser;
    final targetLang = language?.trim().toLowerCase();
    if (user != null) {
      try {
        var query = client.from('vocabulary').select().eq('user_id', user.id);
        if (targetLang != null) {
          query = query.eq('language', targetLang);
        }
        final data = await query.order('next_review_date', ascending: true);
        final rawList = (data as List).map((row) => Flashcard.fromJson(Map<String, dynamic>.from(row as Map))).toList();
        final list = deduplicateCards(rawList).where((c) {
          if (targetLang == null) return true;
          final l = c.language.trim().toLowerCase();
          return l == targetLang || l.startsWith('$targetLang-') || targetLang.startsWith('$l-');
        }).toList();

        if (targetLang != null) {
          _localCards.removeWhere((c) {
            final l = c.language.trim().toLowerCase();
            return l == targetLang || l.startsWith('$targetLang-') || targetLang.startsWith('$l-');
          });
          _localCards.addAll(list);
        } else {
          _localCards.clear();
          _localCards.addAll(list);
        }
        final cleanLocal = deduplicateCards(_localCards);
        _localCards.clear();
        _localCards.addAll(cleanLocal);
        await _saveCardsToLocal(_localCards);
        _notifyCardsChanged();
        return list;
      } catch (e) {
        debugPrint('[SupabaseService] Remote fetch error, falling back to local: $e');
      }
    }

    // Local / Guest fallback
    if (_localCards.isEmpty) {
      final cached = await _loadCardsFromLocal();
      if (cached.isNotEmpty) {
        _localCards.addAll(cached);
      }
    }
    final cleanLocal = deduplicateCards(_localCards);
    if (cleanLocal.length != _localCards.length) {
      _localCards.clear();
      _localCards.addAll(cleanLocal);
      await _saveCardsToLocal(_localCards);
    }
    _notifyCardsChanged();
    if (targetLang != null) {
      return _localCards.where((c) {
        final l = c.language.trim().toLowerCase();
        return l == targetLang || l.startsWith('$targetLang-') || targetLang.startsWith('$l-');
      }).toList();
    }
    return List.from(_localCards);
  }

  bool hasWord(String word, {String? language}) {
    final clean = word.trim().toLowerCase();
    return _localCards.any((c) {
      if (language != null && c.language != language) return false;
      return c.word.trim().toLowerCase() == clean;
    });
  }

  Flashcard? getCardByWord(String word, {String? language}) {
    final clean = word.trim().toLowerCase();
    try {
      return _localCards.firstWhere((c) {
        if (language != null && c.language != language) return false;
        return c.word.trim().toLowerCase() == clean;
      });
    } catch (_) {
      return null;
    }
  }

  Future<void> upsertVocabularyCard(Flashcard card) async {
    // 1. Update local cache (match by ID or word+language to prevent duplicate cards)
    final cleanWord = card.word.trim().toLowerCase();
    final cleanLang = card.language.trim().toLowerCase();
    final idx = _localCards.indexWhere((c) =>
        c.id == card.id ||
        (c.word.trim().toLowerCase() == cleanWord &&
            c.language.trim().toLowerCase() == cleanLang));
    if (idx >= 0) {
      _localCards[idx] = card;
    } else {
      _localCards.add(card);
    }
    final cleanLocal = deduplicateCards(_localCards);
    _localCards.clear();
    _localCards.addAll(cleanLocal);
    await _saveCardsToLocal(_localCards);
    _notifyCardsChanged();

    final user = currentUser;
    if (user == null) return;

    // 2. Sync to Supabase with canonical column mapping
    try {
      await client.from('vocabulary').upsert(card.toRemoteJson());
    } catch (e) {
      try {
        await client.from('vocabulary').upsert(card.toBaseJson());
      } catch (err) {
        debugPrint('[SupabaseService] Upsert vocabulary card error: $err');
      }
    }
  }

  Future<void> deleteVocabularyCard(String cardId) async {
    _localCards.removeWhere((c) => c.id == cardId);
    await _saveCardsToLocal(_localCards);
    _notifyCardsChanged();

    final user = currentUser;
    if (user == null) return;

    try {
      await client.from('vocabulary').delete().eq('id', cardId).eq('user_id', user.id);
    } catch (e) {
      debugPrint('[SupabaseService] Delete vocabulary error: $e');
    }
  }

  Future<void> replaceLocalCards(List<Flashcard> cards) async {
    _localCards.clear();
    _localCards.addAll(deduplicateCards(cards));
    await _saveCardsToLocal(_localCards);
    _notifyCardsChanged();
  }

  Future<void> _saveCardsToLocal(List<Flashcard> cards) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'voca_local_flashcards',
        jsonEncode(cards.map((c) => c.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<List<Flashcard>> _loadCardsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('voca_local_flashcards');
      if (jsonStr == null) return [];
      final List<dynamic> list = jsonDecode(jsonStr);
      final currentUserId = currentUser?.id ?? 'guest';
      bool healedAny = false;
      final rawCards = list
          .map((e) => Flashcard.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((c) => c.userId == currentUserId && !c.id.startsWith('sample_') && !c.id.startsWith('mock_'))
          .map((c) {
            if (c.sourceVideoId == null || c.sourceVideoId!.trim().isEmpty) {
              final s = c.contextSentence ?? '';
              if (s.contains('恋をしていたあなたに')) {
                healedAny = true;
                return c.copyWith(sourceVideoId: 'Opp9nqiN5m0', sourceTimestamp: 13.0);
              } else if (s.contains('忘れたものを取り')) {
                healedAny = true;
                return c.copyWith(sourceVideoId: 'SX_ViT4Ra7k', sourceTimestamp: 45.0);
              }
            }
            return c;
          })
          .toList();

      final cleanCards = deduplicateCards(rawCards);
      if (cleanCards.length != list.length || healedAny) {
        await _saveCardsToLocal(cleanCards);
      }
      return cleanCards;
    } catch (_) {
      return [];
    }
  }

  static List<Flashcard> deduplicateCards(List<Flashcard> cards) {
    final Map<String, Flashcard> deduped = {};
    for (final c in cards) {
      final key = '${c.language.trim().toLowerCase()}:${c.word.trim().toLowerCase()}';
      final existing = deduped[key];
      if (existing == null) {
        deduped[key] = c;
      } else {
        final cRank = levelRank(c.level);
        final existRank = levelRank(existing.level);
        if (cRank > existRank || (cRank == existRank && c.srsRepetition > existing.srsRepetition)) {
          deduped[key] = c;
        }
      }
    }
    return deduped.values.toList();
  }

  static int levelRank(String level) {
    return switch (level.toLowerCase().trim()) {
      'mastered' => 3,
      'known' => 2,
      'learning' => 1,
      _ => 0,
    };
  }

  /// 2. Atomic Streak Recording via RPC
  Future<Map<String, dynamic>?> recordStreakActivity(DateTime date) async {
    final user = currentUser;
    if (user == null) return null;

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    try {
      final res = await client.rpc('record_streak_activity', params: {
        'p_client_date': dateStr,
      });
      return res != null ? Map<String, dynamic>.from(res as Map) : null;
    } catch (e) {
      debugPrint('[SupabaseService] recordStreakActivity error: $e');
      return null;
    }
  }

  /// 2d. Atomic XP Spending via RPC
  Future<Map<String, dynamic>?> spendXp({
    required int cost,
    required String purpose,
    String? itemId,
  }) async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final res = await client.rpc('spend_xp', params: {
        'p_cost': cost,
        'p_purpose': purpose,
        if (itemId != null) 'p_item_id': itemId,
      });
      return res != null ? Map<String, dynamic>.from(res as Map) : null;
    } catch (e) {
      debugPrint('[SupabaseService] spendXp error: $e');
      return null;
    }
  }

  /// 2b. Atomic Study XP Awarding via RPC
  Future<Map<String, dynamic>?> awardStudyXp({
    required String activityType,
    required int amount,
    String? referenceId,
  }) async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final res = await client.rpc('award_study_xp', params: {
        'p_activity_type': activityType,
        'p_amount': amount,
        if (referenceId != null) 'p_reference_id': referenceId,
        'p_client_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });
      return res != null ? Map<String, dynamic>.from(res as Map) : null;
    } catch (e) {
      debugPrint('[SupabaseService] awardStudyXp error: $e');
      return null;
    }
  }

  /// 2c. Atomic Achievements Sync via RPC
  Future<bool> syncAchievements({
    required Map<String, dynamic> unlocked,
    List<String>? notified,
  }) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final res = await client.rpc('sync_achievements', params: {
        'p_unlocked': unlocked,
        'p_notified': notified ?? [],
      });
      return res != null && res['success'] == true;
    } catch (e) {
      debugPrint('[SupabaseService] syncAchievements error: $e');
      return false;
    }
  }

  /// 3. Watch History
  Future<List<Map<String, dynamic>>> getHistory({int limit = 20}) async {
    final user = currentUser;
    if (user != null) {
      try {
        final data = await client
            .from('history')
            .select()
            .eq('user_id', user.id)
            .order('watched_at', ascending: false)
            .limit(limit);

        final list = (data as List).map((row) => Map<String, dynamic>.from(row as Map)).toList();
        if (list.isNotEmpty) {
          // Sync to local cache
          await _saveHistoryToLocal(list);
          return list;
        }
      } catch (e) {
        debugPrint('[SupabaseService] getHistory remote error: $e');
      }
    }

    // Fallback to local storage (for guest users or offline)
    return await _getHistoryFromLocal(limit: limit);
  }

  /// Quickly retrieve last watched position in seconds for a specific video.
  Future<double?> getVideoResumeSeconds(String videoId) async {
    try {
      final local = await _getHistoryFromLocal(limit: 100);
      final match = local.firstWhere(
        (e) => e['video_id'] == videoId,
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty) {
        final rawProg = (match['progress'] as num?)?.toDouble() ?? 0.0;
        final progress = rawProg <= 1.0 && rawProg > 0.0 ? rawProg * 100.0 : rawProg;
        final dur = (match['duration'] as num?)?.toInt() ?? 0;
        if (progress > 0 && progress < 95 && dur > 0) {
          final calculated = (dur * progress / 100).round().toDouble();
          if (calculated > 3) return calculated;
        }
      }
    } catch (_) {}
    return null;
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
    final item = {
      'id': id,
      'user_id': currentUser?.id ?? 'guest',
      'video_id': videoId,
      'title': title,
      'thumbnail': thumbnail,
      'channel': channel,
      'duration': duration,
      'language': language,
      'progress': progress,
      'watched_at': DateTime.now().toIso8601String(),
    };

    // Save locally
    await _addHistoryItemLocal(item);

    // Save to Supabase if authenticated
    final user = currentUser;
    if (user != null) {
      try {
        await client.from('history').upsert(item);
      } catch (e) {
        debugPrint('[SupabaseService] saveHistory remote error: $e');
      }
    }
  }

  Future<void> deleteHistoryItem(String id) async {
    final user = currentUser;
    if (user != null) {
      try {
        await client.from('history').delete().eq('id', id).eq('user_id', user.id);
      } catch (e) {
        debugPrint('[SupabaseService] deleteHistoryItem remote error: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('voca_local_history');
    if (jsonStr != null) {
      final List<dynamic> list = jsonDecode(jsonStr);
      list.removeWhere((e) => e['id'] == id || e['video_id'] == id);
      await prefs.setString('voca_local_history', jsonEncode(list));
    }
  }

  Future<void> clearHistory() async {
    final user = currentUser;
    if (user != null) {
      try {
        await client.from('history').delete().eq('user_id', user.id);
      } catch (e) {
        debugPrint('[SupabaseService] clearHistory remote error: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('voca_local_history');
  }

  Future<List<Map<String, dynamic>>> _getHistoryFromLocal({int limit = 20}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('voca_local_history');
      if (jsonStr == null) return [];
      final List<dynamic> list = jsonDecode(jsonStr);
      final items = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      items.sort((a, b) {
        final ta = DateTime.tryParse(a['watched_at']?.toString() ?? '') ?? DateTime(1970);
        final tb = DateTime.tryParse(b['watched_at']?.toString() ?? '') ?? DateTime(1970);
        return tb.compareTo(ta);
      });
      return items.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveHistoryToLocal(List<Map<String, dynamic>> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('voca_local_history', jsonEncode(items));
    } catch (_) {}
  }

  Future<void> _addHistoryItemLocal(Map<String, dynamic> item) async {
    try {
      final items = await _getHistoryFromLocal(limit: 100);
      items.removeWhere((e) => e['video_id'] == item['video_id']);
      items.insert(0, item);
      await _saveHistoryToLocal(items);
    } catch (_) {}
  }

  /// 4. Playlists Management
  Future<List<PlaylistItem>> getPlaylists({String? language}) async {
    final user = currentUser;
    List<PlaylistItem> playlists = [];

    if (user != null) {
      try {
        var query = client.from('playlists').select().eq('user_id', user.id);
        if (language != null) {
          query = query.eq('language', language);
        }
        final data = await query.order('created_at', ascending: false);
        playlists = (data as List).map((row) => PlaylistItem.fromJson(row)).toList();
      } catch (e) {
        debugPrint('[SupabaseService] getPlaylists remote error: $e');
      }
    }

    // Merge or load from local cache
    final localPlaylists = await _getPlaylistsFromLocal();
    final map = <String, PlaylistItem>{};
    for (final p in localPlaylists) {
      map[p.id] = p;
    }
    for (final p in playlists) {
      map[p.id] = p;
    }

    // Ensure default "Saved Videos" playlist always exists
    if (!map.containsKey('default_saved')) {
      final defaultPlaylist = PlaylistItem(
        id: 'default_saved',
        userId: user?.id ?? 'guest',
        title: 'Saved Videos',
        description: 'Your favorite and bookmarked immersion videos',
        visibility: 'private',
        language: language ?? 'all',
        videoCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      map['default_saved'] = defaultPlaylist;
      await _savePlaylistToLocal(defaultPlaylist);
    }

    return map.values.toList();
  }

  /// Fetch published/community playlists from Supabase
  Future<List<PlaylistItem>> getCommunityPlaylists({String? language}) async {
    try {
      var query = client.from('playlists').select().inFilter('visibility', ['published', 'public']);
      if (language != null && language != 'all') {
        query = query.eq('language', language);
      }
      final data = await query.order('updated_at', ascending: false).limit(30);
      return (data as List).map((row) => PlaylistItem.fromJson(row)).toList();
    } catch (e) {
      debugPrint('[SupabaseService] getCommunityPlaylists error: $e');
      return [];
    }
  }

  /// Gathers all playlists available for the Explore screen:
  /// Published Community playlists + User playlists with videos
  Future<List<PlaylistItem>> getExplorePlaylists({String? language}) async {
    final List<PlaylistItem> result = [];
    final seenIds = <String>{};

    // 1. Published Community playlists from Supabase
    try {
      final community = await getCommunityPlaylists(language: language);
      for (final p in community) {
        if (seenIds.add(p.id)) {
          result.add(p);
        }
      }
    } catch (_) {}

    // 2. User's own playlists containing videos
    try {
      final userLists = await getPlaylists(language: language);
      for (final p in userLists) {
        if (p.videoIds.isNotEmpty && seenIds.add(p.id)) {
          result.add(p);
        }
      }
    } catch (_) {}

    return result;
  }

  Future<PlaylistItem> createPlaylist({
    required String title,
    String? description,
    String language = 'ja',
    String visibility = 'private',
    String? level,
  }) async {
    final user = currentUser;
    final now = DateTime.now();
    final id = 'pl_${now.millisecondsSinceEpoch}';

    final playlist = PlaylistItem(
      id: id,
      userId: user?.id ?? 'guest',
      title: title,
      description: description,
      language: language,
      visibility: visibility,
      level: level,
      videoCount: 0,
      createdAt: now,
      updatedAt: now,
    );

    await _savePlaylistToLocal(playlist);

    if (user != null) {
      try {
        await client.from('playlists').insert(playlist.toJson());
      } catch (e) {
        debugPrint('[SupabaseService] createPlaylist remote error: $e');
      }
    }

    return playlist;
  }

  Future<PlaylistItem> updatePlaylist({
    required String id,
    required String title,
    String? description,
    String language = 'ja',
    String visibility = 'private',
    String? level,
  }) async {
    final local = await _getPlaylistsFromLocal();
    final idx = local.indexWhere((p) => p.id == id);
    final existing = idx != -1 ? local[idx] : null;

    final updated = PlaylistItem(
      id: id,
      userId: existing?.userId ?? currentUser?.id ?? 'guest',
      title: title,
      description: description,
      language: language,
      visibility: visibility,
      level: level,
      videoCount: existing?.videoCount ?? 0,
      thumbnail: existing?.thumbnail,
      videoIds: existing?.videoIds ?? const [],
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _savePlaylistToLocal(updated);

    final user = currentUser;
    if (user != null) {
      try {
        await client.from('playlists').upsert(updated.toJson());
      } catch (e) {
        debugPrint('[SupabaseService] updatePlaylist remote error: $e');
      }
    }

    return updated;
  }

  Future<void> deletePlaylist(String playlistId) async {
    final user = currentUser;
    if (user != null) {
      try {
        await client.from('playlists').delete().eq('id', playlistId).eq('user_id', user.id);
      } catch (e) {
        debugPrint('[SupabaseService] deletePlaylist remote error: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('voca_local_playlists');
    if (jsonStr != null) {
      final List<dynamic> list = jsonDecode(jsonStr);
      list.removeWhere((e) => e['id'] == playlistId);
      await prefs.setString('voca_local_playlists', jsonEncode(list));
    }
  }

  Future<void> addVideoToPlaylist({
    required String playlistId,
    required String videoId,
    String? thumbnail,
  }) async {
    final local = await _getPlaylistsFromLocal();
    final idx = local.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final p = local[idx];
      if (!p.videoIds.contains(videoId)) {
        final updatedIds = [...p.videoIds, videoId];
        final updated = PlaylistItem(
          id: p.id,
          userId: p.userId,
          title: p.title,
          description: p.description,
          visibility: p.visibility,
          language: p.language,
          videoCount: updatedIds.length,
          thumbnail: thumbnail ?? p.thumbnail ?? 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
          videoIds: updatedIds,
          createdAt: p.createdAt,
          updatedAt: DateTime.now(),
        );
        local[idx] = updated;
        await _savePlaylistsToLocal(local);

        final user = currentUser;
        if (user != null) {
          try {
            await client.from('playlists').upsert(updated.toJson());
          } catch (e) {
            debugPrint('[SupabaseService] addVideoToPlaylist remote error: $e');
          }
        }
      }
    }
  }

  Future<void> removeVideoFromPlaylist({
    required String playlistId,
    required String videoId,
  }) async {
    final local = await _getPlaylistsFromLocal();
    final idx = local.indexWhere((p) => p.id == playlistId);
    if (idx != -1) {
      final p = local[idx];
      if (p.videoIds.contains(videoId)) {
        final updatedIds = p.videoIds.where((id) => id != videoId).toList();
        final updated = PlaylistItem(
          id: p.id,
          userId: p.userId,
          title: p.title,
          description: p.description,
          visibility: p.visibility,
          language: p.language,
          videoCount: updatedIds.length,
          thumbnail: p.thumbnail,
          videoIds: updatedIds,
          createdAt: p.createdAt,
          updatedAt: DateTime.now(),
        );
        local[idx] = updated;
        await _savePlaylistsToLocal(local);

        final user = currentUser;
        if (user != null) {
          try {
            await client.from('playlists').upsert(updated.toJson());
          } catch (e) {
            debugPrint('[SupabaseService] removeVideoFromPlaylist remote error: $e');
          }
        }
      }
    }
  }

  Future<bool> isVideoSaved(String videoId) async {
    final playlists = await getPlaylists();
    final saved = playlists.firstWhere(
      (p) => p.id == 'default_saved' || p.title.toLowerCase().contains('saved'),
      orElse: () => playlists.isNotEmpty
          ? playlists.first
          : PlaylistItem(
              id: 'default_saved',
              userId: currentUser?.id ?? 'guest',
              title: 'Saved Videos',
              language: 'all',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
    );
    return saved.videoIds.contains(videoId);
  }

  Future<bool> toggleSaveVideo({
    required String videoId,
    String? thumbnail,
  }) async {
    final isSaved = await isVideoSaved(videoId);
    if (isSaved) {
      await removeVideoFromPlaylist(playlistId: 'default_saved', videoId: videoId);
      return false;
    } else {
      await addVideoToPlaylist(
        playlistId: 'default_saved',
        videoId: videoId,
        thumbnail: thumbnail,
      );
      return true;
    }
  }

  Future<List<PlaylistItem>> _getPlaylistsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('voca_local_playlists');
      if (jsonStr == null) return [];
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => PlaylistItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _savePlaylistsToLocal(List<PlaylistItem> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('voca_local_playlists', jsonEncode(list.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> _savePlaylistToLocal(PlaylistItem playlist) async {
    final list = await _getPlaylistsFromLocal();
    final idx = list.indexWhere((p) => p.id == playlist.id);
    if (idx != -1) {
      list[idx] = playlist;
    } else {
      list.insert(0, playlist);
    }
    await _savePlaylistsToLocal(list);
  }
}
