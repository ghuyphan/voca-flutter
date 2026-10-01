// lib/ui/study/study_deck_screen.dart

import 'package:flutter/material.dart';
import '../../models/voca_models.dart';
import '../../services/srs_service.dart';
import '../../state/app_state.dart';

class StudyDeckScreen extends StatefulWidget {
  const StudyDeckScreen({super.key});

  @override
  State<StudyDeckScreen> createState() => _StudyDeckScreenState();
}

class _StudyDeckScreenState extends State<StudyDeckScreen> {
  List<Flashcard> _dueCards = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _loadDueCards();
  }

  Future<void> _loadDueCards() async {
    setState(() => _isLoading = true);
    final supabase = AppState.instance.supabaseService;
    final lang = AppState.instance.activeLanguage.value;

    try {
      final allCards = await supabase.getVocabularyCards(language: lang);
      final now = DateTime.now();
      final due = allCards.where((c) => c.srsNextReviewAt.isBefore(now) || c.srsNextReviewAt.isAtSameMomentAs(now)).toList();

      if (mounted) {
        setState(() {
          _dueCards = due.isNotEmpty ? due : allCards.take(10).toList();
          _isLoading = false;
          _currentIndex = 0;
          _isFlipped = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rateCard(SRSReviewRating rating) async {
    if (_dueCards.isEmpty || _currentIndex >= _dueCards.length) return;

    final currentCard = _dueCards[_currentIndex];
    final result = SpacedRepetitionService.calculateNextReview(
      rating: rating,
      currentRepetitions: currentCard.srsRepetition,
      currentInterval: currentCard.srsInterval,
      currentEaseFactor: currentCard.srsEaseFactor,
    );

    final updatedCard = Flashcard(
      id: currentCard.id,
      userId: currentCard.userId,
      word: currentCard.word,
      reading: currentCard.reading,
      romanization: currentCard.romanization,
      pinyin: currentCard.pinyin,
      meaning: currentCard.meaning,
      language: currentCard.language,
      level: result.level,
      srsInterval: result.interval,
      srsRepetition: result.repetition,
      srsEaseFactor: result.easeFactor,
      srsNextReviewAt: result.nextReviewAt,
      srsLastReviewedAt: DateTime.now(),
    );

    // Save update to Supabase
    await AppState.instance.supabaseService.upsertVocabularyCard(updatedCard);

    // Record streak activity
    await AppState.instance.supabaseService.recordStreakActivity(DateTime.now());

    setState(() {
      _currentIndex += 1;
      _isFlipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isFinished = _dueCards.isEmpty || _currentIndex >= _dueCards.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text('Spaced Repetition Review', style: TextStyle(color: Colors.white, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadDueCards,
          ),
        ],
      ),
      body: SafeArea(
        child: isFinished
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 72),
                    const SizedBox(height: 16),
                    const Text(
                      'All caught up for today!',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Great job keeping your practice streak alive.',
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadDueCards,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Review Again'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Progress counter
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Card ${_currentIndex + 1} of ${_dueCards.length}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _dueCards[_currentIndex].level.toUpperCase(),
                          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // Flashcard Box
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _isFlipped = !_isFlipped),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 6)),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_dueCards[_currentIndex].reading != null ||
                                  _dueCards[_currentIndex].pinyin != null)
                                Text(
                                  _dueCards[_currentIndex].reading ?? _dueCards[_currentIndex].pinyin!,
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 18),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                _dueCards[_currentIndex].word,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_dueCards[_currentIndex].romanization != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _dueCards[_currentIndex].romanization!,
                                  style: const TextStyle(color: Colors.white54, fontSize: 15),
                                ),
                              ],
                              const SizedBox(height: 32),
                              if (!_isFlipped)
                                const Text(
                                  'Tap card to reveal answer',
                                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontStyle: FontStyle.italic),
                                )
                              else ...[
                                const Divider(color: Colors.white12),
                                const SizedBox(height: 16),
                                Text(
                                  _dueCards[_currentIndex].meaning,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFF1F5F9),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // SM-2 Review Actions (Visible when flipped)
                  if (_isFlipped)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          _buildRateButton('Again', const Color(0xFFEF4444), SRSReviewRating.again),
                          const SizedBox(width: 8),
                          _buildRateButton('Hard', const Color(0xFFF59E0B), SRSReviewRating.hard),
                          const SizedBox(width: 8),
                          _buildRateButton('Good', const Color(0xFF3B82F6), SRSReviewRating.good),
                          const SizedBox(width: 8),
                          _buildRateButton('Easy', const Color(0xFF10B981), SRSReviewRating.easy),
                        ],
                      ),
                    )
                  else
                    const SizedBox(height: 72),
                ],
              ),
      ),
    );
  }

  Widget _buildRateButton(String label, Color color, SRSReviewRating rating) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => _rateCard(rating),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.15),
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }
}
