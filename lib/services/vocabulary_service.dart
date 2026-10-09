// lib/services/vocabulary_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../models/voca_models.dart';
import '../state/app_state.dart';
import 'gamification_service.dart';
import 'grammar_engine.dart';
import 'srs_service.dart';
import 'supabase_service.dart';
import '../utils/cyrb53_hasher.dart';

/// Centralized, Signal-first Vocabulary Service.
/// Serves as the single source of truth for vocabulary and grammar cards across
/// VideoPlayerScreen, DictionaryBottomSheet, StudyDeckScreen, and VocabularyScreen.
class VocabularyService {
  static final VocabularyService instance = VocabularyService._();
  VocabularyService._();

  SupabaseService get _supabase => AppState.instance.supabaseService;
  GamificationService get _gamification => AppState.instance.gamificationService;
  GrammarEngine get _grammar => AppState.instance.grammarEngine;

  /// Reactive signal of all cached vocabulary cards, synchronized with SupabaseService
  Signal<List<Flashcard>> get cards => _supabase.vocabularyCardsSignal;

  final isSyncing = signal<bool>(false);
  final lastDeletedCard = signal<Flashcard?>(null);

  final Map<String, bool> _grammarCache = {};

  bool isGrammarCard(Flashcard card) {
    if (card.partOfSpeech != null && card.partOfSpeech!.toLowerCase().contains('grammar')) {
      return true;
    }
    final key = '${card.language}:${card.word}';
    return _grammarCache.putIfAbsent(key, () {
      try {
        return _grammar.isGrammar(card.word, card.language);
      } catch (_) {
        return false;
      }
    });
  }

  /// Initial load or background sync from Supabase
  Future<void> syncVocabulary({String? language}) async {
    isSyncing.value = true;
    try {
      await _supabase.getVocabularyCards(language: language);
    } catch (e) {
      debugPrint('[VocabularyService] Sync error: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  /// Get cards filtered for a specific language
  List<Flashcard> getCardsForLanguage(String language) {
    final cleanLang = language.trim().toLowerCase();
    return cards.value.where((c) {
      final l = c.language.trim().toLowerCase();
      return l == cleanLang || l.startsWith('$cleanLang-') || cleanLang.startsWith('$l-');
    }).toList();
  }

  /// Save or update a card.
  /// Mutates local reactive signals immediately with 0ms lag and syncs in background.
  Future<void> upsertCard(Flashcard card, {bool notifyGamification = false}) async {
    final existing = _supabase.getCardByWord(card.word, language: card.language);
    final isNew = existing == null;

    if (isNew || notifyGamification) {
      try {
        await _gamification.onWordSaved(cards.value.length + (isNew ? 1 : 0));
      } catch (_) {}
    }

    await _supabase.upsertVocabularyCard(card);
  }

  /// Delete a card with undo support
  Future<void> deleteCard(Flashcard card) async {
    lastDeletedCard.value = card;
    await _supabase.deleteVocabularyCard(card.id);
  }

  /// Undo the last deletion
  Future<bool> undoLastDelete() async {
    final card = lastDeletedCard.value;
    if (card == null) return false;
    lastDeletedCard.value = null;
    await _supabase.upsertVocabularyCard(card);
    return true;
  }

  /// In-place stage/level update
  Future<void> updateLevel(String cardId, String newLevel) async {
    final cleanLevel = WordLevels.normalize(newLevel);
    final card = cards.value.firstWhere(
      (c) => c.id == cardId,
      orElse: () => throw Exception('Card $cardId not found'),
    );

    final seed = SpacedRepetitionService.seedSrsParamsForLevel(cleanLevel);
    final updated = card.copyWith(
      level: cleanLevel,
      srsRepetition: seed.repetition,
      srsInterval: seed.interval,
      srsEaseFactor: seed.easeFactor,
      srsNextReviewAt: seed.nextReviewAt,
    );

    await _supabase.upsertVocabularyCard(updated);
  }

  /// Check if a word is already in the notebook
  bool hasWord(String word, {String? language}) {
    return _supabase.hasWord(word, language: language);
  }

  /// Get a card by headword
  Flashcard? getCardByWord(String word, {String? language}) {
    return _supabase.getCardByWord(word, language: language);
  }

  /// Export cards as formatted JSON
  String exportAsJson({String? language}) {
    final list = language != null ? getCardsForLanguage(language) : cards.value;
    final jsonList = list.map((c) => c.toRemoteJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(jsonList);
  }

  /// Export cards as Anki TSV format (Front [reading]\tBack)
  String exportAsAnki({String? language}) {
    final list = language != null ? getCardsForLanguage(language) : cards.value;
    return list.map((item) {
      final reading = item.reading ?? item.pinyin ?? item.romanization;
      final rawFront = item.word + (reading != null && reading.isNotEmpty ? ' [$reading]' : '');
      final front = rawFront.replaceAll('\t', ' ').replaceAll('\r\n', '<br>').replaceAll('\n', '<br>');
      final back = item.meaning.replaceAll('\t', ' ').replaceAll('\r\n', '<br>').replaceAll('\n', '<br>');
      return '$front\t$back';
    }).join('\n');
  }

  /// Import cards from JSON string (supports web exports & backup restores)
  Future<int> importFromJson(String jsonString, {String? defaultLanguage}) async {
    try {
      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! List) return 0;

      final currentUserId = _supabase.currentUser?.id ?? 'guest';
      final List<Flashcard> importedCards = [];

      for (final item in decoded) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);

        // Fill required fields if missing
        if (!map.containsKey('user_id')) map['user_id'] = currentUserId;
        if (!map.containsKey('language') && defaultLanguage != null) {
          map['language'] = defaultLanguage;
        }

        final word = (map['word'] ?? '').toString().trim();
        final lang = (map['language'] ?? defaultLanguage ?? 'ja').toString().trim();
        if (!map.containsKey('id') || (map['id'] as String?)?.trim().isEmpty == true) {
          map['id'] = generateDeterministicRecordId([currentUserId, word.toLowerCase(), lang]);
        }

        try {
          final card = Flashcard.fromJson(map);
          if (card.word.trim().isNotEmpty) {
            importedCards.add(card);
          }
        } catch (_) {}
      }

      if (importedCards.isEmpty) return 0;

      for (final card in importedCards) {
        await _supabase.upsertVocabularyCard(card);
      }

      return importedCards.length;
    } catch (e) {
      debugPrint('[VocabularyService] Import JSON error: $e');
      return 0;
    }
  }
}
