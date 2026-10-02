// lib/services/supabase_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  final List<Flashcard> _localCards = [];

  /// 1. Vocabulary / Flashcards Sync
  Future<List<Flashcard>> getVocabularyCards({String? language}) async {
    final user = currentUser;
    if (user != null) {
      try {
        var query = client.from('vocabulary').select().eq('user_id', user.id);
        if (language != null) {
          query = query.eq('language', language);
        }
        final data = await query.order('srs_next_review_at', ascending: true);
        final list = (data as List).map((row) => Flashcard.fromJson(row)).toList();
        if (list.isNotEmpty) {
          _localCards.clear();
          _localCards.addAll(list);
          return list;
        }
      } catch (e) {
        print('[SupabaseService] Remote fetch error, falling back to local: $e');
      }
    }

    // Local / Guest fallback
    if (_localCards.isEmpty) {
      _seedDefaultCards();
    }
    if (language != null) {
      return _localCards.where((c) => c.language == language).toList();
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
    // 1. Update local cache
    final idx = _localCards.indexWhere((c) => c.id == card.id);
    if (idx >= 0) {
      _localCards[idx] = card;
    } else {
      _localCards.add(card);
    }

    final user = currentUser;
    if (user == null) return;

    // 2. Sync to Supabase with resilient fallback
    try {
      await client.from('vocabulary').upsert(card.toJson());
    } catch (_) {
      try {
        await client.from('vocabulary').upsert(card.toBaseJson());
      } catch (e) {
        print('[SupabaseService] Upsert error: $e');
      }
    }
  }

  Future<void> deleteVocabularyCard(String cardId) async {
    _localCards.removeWhere((c) => c.id == cardId);

    final user = currentUser;
    if (user == null) return;

    try {
      await client.from('vocabulary').delete().eq('id', cardId).eq('user_id', user.id);
    } catch (e) {
      print('[SupabaseService] Delete error: $e');
    }
  }

  void _seedDefaultCards() {
    final now = DateTime.now();
    _localCards.addAll([
      // Japanese
      Flashcard(
        id: 'sample_ja_1',
        userId: 'guest',
        word: '食べる',
        reading: 'たべる',
        romanization: 'taberu',
        meaning: 'to eat, to consume',
        language: 'ja',
        level: 'learning',
        partOfSpeech: 'verb',
        contextSentence: '毎朝、美味しいご飯を食べるのが楽しみです。',
        contextTranslation: 'I look forward to eating delicious meals every morning.',
        srsInterval: 1,
        srsRepetition: 1,
        srsEaseFactor: 2.5,
        srsNextReviewAt: now.subtract(const Duration(minutes: 5)),
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Flashcard(
        id: 'sample_ja_2',
        userId: 'guest',
        word: '約束',
        reading: 'やくそく',
        romanization: 'yakusoku',
        meaning: 'promise, commitment, appointment',
        language: 'ja',
        level: 'learning',
        partOfSpeech: 'noun',
        contextSentence: '大切な友達との約束を絶対に守る。',
        contextTranslation: 'I will definitely keep my promise with my dear friend.',
        srsInterval: 3,
        srsRepetition: 2,
        srsEaseFactor: 2.5,
        srsNextReviewAt: now.subtract(const Duration(minutes: 2)),
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      Flashcard(
        id: 'sample_ja_3',
        userId: 'guest',
        word: '美しい',
        reading: 'うつくしい',
        romanization: 'utsukushii',
        meaning: 'beautiful, lovely, graceful',
        language: 'ja',
        level: 'known',
        partOfSpeech: 'adjective',
        contextSentence: '夕暮れの富士山は息を呑むほど美しい。',
        contextTranslation: 'Mount Fuji at dusk is breathtakingly beautiful.',
        srsInterval: 6,
        srsRepetition: 3,
        srsEaseFactor: 2.6,
        srsNextReviewAt: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      Flashcard(
        id: 'sample_ja_4',
        userId: 'guest',
        word: '練習',
        reading: 'れんしゅう',
        romanization: 'renshuu',
        meaning: 'practice, training, drill',
        language: 'ja',
        level: 'new',
        partOfSpeech: 'noun',
        contextSentence: '毎日少しずつ日本語の会話練習を重ねる。',
        contextTranslation: 'I practice Japanese conversation little by little every day.',
        srsInterval: 0,
        srsRepetition: 0,
        srsEaseFactor: 2.5,
        srsNextReviewAt: now.subtract(const Duration(minutes: 10)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Flashcard(
        id: 'sample_ja_5',
        userId: 'guest',
        word: '未来',
        reading: 'みらい',
        romanization: 'mirai',
        meaning: 'future (distant or abstract)',
        language: 'ja',
        level: 'mastered',
        partOfSpeech: 'noun',
        contextSentence: '希望に満ちた明るい未来へ向かって進む。',
        contextTranslation: 'Moving forward toward a bright future full of hope.',
        srsInterval: 15,
        srsRepetition: 5,
        srsEaseFactor: 2.7,
        srsNextReviewAt: now.add(const Duration(days: 12)),
        createdAt: now.subtract(const Duration(days: 20)),
      ),

      // Chinese
      Flashcard(
        id: 'sample_zh_1',
        userId: 'guest',
        word: '朋友',
        pinyin: 'péngyou',
        meaning: 'friend, companion',
        language: 'zh',
        level: 'known',
        partOfSpeech: 'noun',
        contextSentence: '我们是认识很多年的好朋友。',
        contextTranslation: 'We have been good friends for many years.',
        srsInterval: 4,
        srsRepetition: 2,
        srsEaseFactor: 2.5,
        srsNextReviewAt: now.subtract(const Duration(minutes: 5)),
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Flashcard(
        id: 'sample_zh_2',
        userId: 'guest',
        word: '学习',
        pinyin: 'xuéxí',
        meaning: 'to study, to learn',
        language: 'zh',
        level: 'learning',
        partOfSpeech: 'verb',
        contextSentence: '每天学习新词汇有助于提高语言能力。',
        contextTranslation: 'Studying new vocabulary daily helps improve language proficiency.',
        srsInterval: 2,
        srsRepetition: 1,
        srsEaseFactor: 2.5,
        srsNextReviewAt: now.subtract(const Duration(minutes: 2)),
        createdAt: now.subtract(const Duration(days: 3)),
      ),

      // Korean
      Flashcard(
        id: 'sample_ko_1',
        userId: 'guest',
        word: '행복',
        reading: 'haengbok',
        romanization: 'haengbok',
        meaning: 'happiness, bliss',
        language: 'ko',
        level: 'learning',
        partOfSpeech: 'noun',
        contextSentence: '소소한 일상 속에서 행복을 찾아요.',
        contextTranslation: 'Finding happiness in small daily moments.',
        srsInterval: 2,
        srsRepetition: 1,
        srsEaseFactor: 2.5,
        srsNextReviewAt: now.subtract(const Duration(minutes: 5)),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Flashcard(
        id: 'sample_ko_2',
        userId: 'guest',
        word: '시작',
        reading: 'sijak',
        romanization: 'sijak',
        meaning: 'beginning, start',
        language: 'ko',
        level: 'new',
        partOfSpeech: 'noun',
        contextSentence: '새로운 도전의 시작이 정말 기대됩니다.',
        contextTranslation: 'I am really looking forward to the start of a new challenge.',
        srsInterval: 0,
        srsRepetition: 0,
        srsEaseFactor: 2.5,
        srsNextReviewAt: now.subtract(const Duration(minutes: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
      ),

      // English
      Flashcard(
        id: 'sample_en_1',
        userId: 'guest',
        word: 'serendipity',
        reading: 'ser-uhn-dip-i-tee',
        meaning: 'finding valuable things unexpectedly',
        language: 'en',
        level: 'learning',
        partOfSpeech: 'noun',
        contextSentence: 'Finding this peaceful cafe was sheer serendipity.',
        contextTranslation: 'Finding this peaceful cafe was sheer good fortune.',
        srsInterval: 1,
        srsRepetition: 1,
        srsEaseFactor: 2.5,
        srsNextReviewAt: now.subtract(const Duration(minutes: 5)),
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Flashcard(
        id: 'sample_en_2',
        userId: 'guest',
        word: 'resilience',
        reading: 'ri-zil-yuhns',
        meaning: 'capacity to recover quickly from difficulties',
        language: 'en',
        level: 'known',
        partOfSpeech: 'noun',
        contextSentence: 'Her resilience through challenging times inspired everyone.',
        contextTranslation: 'Her resilience through difficult times inspired everyone.',
        srsInterval: 6,
        srsRepetition: 3,
        srsEaseFactor: 2.6,
        srsNextReviewAt: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(days: 8)),
      ),
    ]);
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

  /// Curated fallback playlists for rich offline or guest immersion
  List<PlaylistItem> _getCuratedPresets(String lang) {
    final now = DateTime.now();
    switch (lang) {
      case 'ja':
        return [
          PlaylistItem(
            id: 'curated_ja_anime',
            userId: 'voca_curated',
            title: 'Anime & J-Pop Immersion',
            description: 'Learn Japanese through popular songs and anime clips',
            language: 'ja',
            visibility: 'public',
            videoCount: 3,
            thumbnail: 'https://i.ytimg.com/vi/clU8c2fpk2s/hqdefault.jpg',
            videoIds: const ['clU8c2fpk2s', '8dqNwVUofxo', 'HWdaevrnCnQ'],
            createdAt: now,
            updatedAt: now,
          ),
          PlaylistItem(
            id: 'curated_ja_conversation',
            userId: 'voca_curated',
            title: 'JLPT N4/N3 Core Comprehension',
            description: 'Natural pacing and everyday conversation for intermediate learners',
            language: 'ja',
            visibility: 'public',
            videoCount: 2,
            thumbnail: 'https://i.ytimg.com/vi/BZRT37f8zZY/hqdefault.jpg',
            videoIds: const ['BZRT37f8zZY', 'clU8c2fpk2s'],
            createdAt: now,
            updatedAt: now,
          ),
        ];
      case 'zh':
        return [
          PlaylistItem(
            id: 'curated_zh_hsk',
            userId: 'voca_curated',
            title: 'HSK Practical Dialogue & Stories',
            description: 'Essential Chinese conversation with pinyin subtitles',
            language: 'zh',
            visibility: 'public',
            videoCount: 2,
            thumbnail: 'https://i.ytimg.com/vi/clU8c2fpk2s/hqdefault.jpg',
            videoIds: const ['clU8c2fpk2s'],
            createdAt: now,
            updatedAt: now,
          ),
        ];
      case 'ko':
        return [
          PlaylistItem(
            id: 'curated_ko_kdrama',
            userId: 'voca_curated',
            title: 'K-Drama & Daily Korean Expressions',
            description: 'Everyday colloquial Korean from authentic immersion videos',
            language: 'ko',
            visibility: 'public',
            videoCount: 2,
            thumbnail: 'https://i.ytimg.com/vi/clU8c2fpk2s/hqdefault.jpg',
            videoIds: const ['clU8c2fpk2s'],
            createdAt: now,
            updatedAt: now,
          ),
        ];
      case 'en':
      default:
        return [
          PlaylistItem(
            id: 'curated_en_ted',
            userId: 'voca_curated',
            title: 'Conversational English & Ideas',
            description: 'Engaging talks and natural expressions for ESL learners',
            language: 'en',
            visibility: 'public',
            videoCount: 2,
            thumbnail: 'https://i.ytimg.com/vi/clU8c2fpk2s/hqdefault.jpg',
            videoIds: const ['clU8c2fpk2s'],
            createdAt: now,
            updatedAt: now,
          ),
        ];
    }
  }

  /// Gathers all playlists available for the Explore screen:
  /// User playlists + Published Community playlists + Curated presets
  Future<List<PlaylistItem>> getExplorePlaylists({String? language}) async {
    final List<PlaylistItem> result = [];
    final seenIds = <String>{};

    // 1. User playlists with videos
    try {
      final userLists = await getPlaylists(language: language);
      for (final p in userLists) {
        if (p.videoIds.isNotEmpty && seenIds.add(p.id)) {
          result.add(p);
        }
      }
    } catch (_) {}

    // 2. Published Community playlists from Supabase
    try {
      final community = await getCommunityPlaylists(language: language);
      for (final p in community) {
        if (seenIds.add(p.id)) {
          result.add(p);
        }
      }
    } catch (_) {}

    // 3. Fallback curated presets for the active language
    final seed = _getCuratedPresets(language ?? 'ja');
    for (final p in seed) {
      if (seenIds.add(p.id)) {
        result.add(p);
      }
    }

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
