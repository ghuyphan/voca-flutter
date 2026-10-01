// lib/ui/sheets/dictionary_bottom_sheet.dart

import 'package:flutter/material.dart';
import '../../models/voca_models.dart';
import '../../services/voca_api_client.dart';
import '../../services/supabase_service.dart';
import '../../utils/cyrb53_hasher.dart';
import '../../state/app_state.dart';

class DictionaryBottomSheet extends StatefulWidget {
  final Token token;
  final String sourceLang;
  final String explanationLang;

  const DictionaryBottomSheet({
    super.key,
    required this.token,
    required this.sourceLang,
    this.explanationLang = 'vi',
  });

  static Future<void> show(
    BuildContext context, {
    required Token token,
    required String sourceLang,
    String explanationLang = 'vi',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DictionaryBottomSheet(
        token: token,
        sourceLang: sourceLang,
        explanationLang: explanationLang,
      ),
    );
  }

  @override
  State<DictionaryBottomSheet> createState() => _DictionaryBottomSheetState();
}

class _DictionaryBottomSheetState extends State<DictionaryBottomSheet> {
  DictionaryResult? _result;
  bool _isLoading = true;
  String? _error;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _fetchDefinition();
  }

  Future<void> _fetchDefinition() async {
    final word = widget.token.baseForm ?? widget.token.surface;
    try {
      final res = await AppState.instance.apiClient.lookupDictionary(
        word: word,
        from: widget.sourceLang,
        to: widget.explanationLang,
      );
      if (mounted) {
        setState(() {
          _result = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addToFlashcards() async {
    final supabase = AppState.instance.supabaseService;
    final user = supabase.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save vocabulary')),
      );
      return;
    }

    final word = widget.token.surface;
    final reading = widget.token.reading;
    final romanization = widget.token.romanization;
    final pinyin = widget.token.pinyin;
    final meaning = _result?.entries.firstOrNull?.definitions.join(', ') ?? '';

    final id = generateDeterministicRecordId([user.id, word.toLowerCase(), widget.sourceLang]);

    final card = Flashcard(
      id: id,
      userId: user.id,
      word: word,
      reading: reading,
      romanization: romanization,
      pinyin: pinyin,
      meaning: meaning,
      language: widget.sourceLang,
      srsNextReviewAt: DateTime.now(),
    );

    try {
      await supabase.upsertVocabularyCard(card);
      setState(() => _isSaved = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "$word" to your study deck!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save word: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Word Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.token.reading != null || widget.token.pinyin != null)
                    Text(
                      widget.token.reading ?? widget.token.pinyin!,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  Text(
                    widget.token.surface,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _isSaved ? null : _addToFlashcards,
                icon: Icon(
                  _isSaved ? Icons.check : Icons.bookmark_add_outlined,
                  size: 20,
                ),
                label: Text(_isSaved ? 'Saved' : 'Add to Deck'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),

          // Content body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          'Could not load definition: $_error',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      )
                    : _result == null || _result!.entries.isEmpty
                        ? const Center(
                            child: Text(
                              'No definition found',
                              style: TextStyle(color: Colors.white60),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _result!.entries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final entry = _result!.entries[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (entry.partOfSpeech != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      margin: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        entry.partOfSpeech!,
                                        style: const TextStyle(
                                          color: Color(0xFF38BDF8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  // Definitions
                                  ...entry.definitions.asMap().entries.map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '${e.key + 1}. ${e.value}',
                                        style: const TextStyle(
                                          color: Color(0xFFF1F5F9),
                                          fontSize: 16,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Examples
                                  if (entry.examples.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: entry.examples.map((ex) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Text(
                                              '• ${ex['sentence']} ${ex['translation'] ?? ''}',
                                              style: const TextStyle(
                                                color: Color(0xFFCBD5E1),
                                                fontSize: 13,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
