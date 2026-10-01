// lib/state/player_state.dart

import 'package:signals_flutter/signals_flutter.dart';
import '../models/voca_models.dart';
import '../services/voca_api_client.dart';
import '../services/grammar_engine.dart';
import 'app_state.dart';

class VideoPlayerController {
  final VocaApiClient apiClient;
  final GrammarEngine grammarEngine;

  VideoPlayerController({
    required this.apiClient,
    required this.grammarEngine,
  }) {
    // Computed signal: Find active cue using the Sticky Subtitle Rule
    activeCue = computed(() {
      final time = currentTime.value;
      final cueList = cues.value;
      if (cueList.isEmpty) return null;

      for (int i = 0; i < cueList.length; i++) {
        final cue = cueList[i];
        final nextStart = (i + 1 < cueList.length) ? cueList[i + 1].start : double.infinity;

        // In duration
        if (time >= cue.start && time < (cue.start + cue.duration)) {
          return cue;
        }

        // Sticky gap hold (< 3.0s)
        if (time >= (cue.start + cue.duration) && time < nextStart) {
          if ((nextStart - (cue.start + cue.duration)) <= 3.0) {
            return cue;
          }
        }
      }
      return null;
    });

    // Automatically detect grammar patterns whenever the active cue changes
    activeGrammarMatches = computed(() {
      final cue = activeCue.value;
      final lang = AppState.instance.activeLanguage.value;
      if (cue == null || cue.tokens.isEmpty) return <GrammarMatch>[];
      return grammarEngine.detectPatterns(cue.tokens, lang);
    });
  }

  final currentVideoId = signal<String?>(null);
  final videoTitle = signal<String>('');
  final currentTime = signal<double>(0.0);
  final isPlaying = signal<bool>(false);
  final cues = signal<List<SubtitleCue>>([]);
  final isLoading = signal<bool>(false);
  final statusMessage = signal<String?>(null);
  final languageMismatch = signal<bool>(false);
  final availableLanguages = signal<AvailableLanguages>(AvailableLanguages());

  late final ReadonlySignal<SubtitleCue?> activeCue;
  late final ReadonlySignal<List<GrammarMatch>> activeGrammarMatches;

  /// Load video and fetch synchronized transcripts
  Future<void> loadVideo(String videoId, {bool preferAI = false, String? turnstileToken}) async {
    currentVideoId.value = videoId;
    isLoading.value = true;
    statusMessage.value = 'Loading subtitles...';
    languageMismatch.value = false;
    cues.value = [];

    final targetLang = AppState.instance.activeLanguage.value;
    await grammarEngine.loadLanguage(targetLang);

    try {
      final res = await apiClient.getTranscript(
        videoId: videoId,
        lang: targetLang,
        preferAI: preferAI,
        turnstileToken: turnstileToken,
        onProgress: (status) => statusMessage.value = status,
      );

      availableLanguages.value = res.availableLanguages;

      if (res.languageMismatch) {
        languageMismatch.value = true;
        isLoading.value = false;
        statusMessage.value = 'Captions available in other languages';
        return;
      }

      if (res.success && res.segments.isNotEmpty) {
        final rawCues = res.segments;
        cues.value = rawCues;
        statusMessage.value = null;
        isLoading.value = false;

        // Asynchronously batch tokenize cues if needed
        _tokenizeCues(videoId, targetLang, rawCues);
      } else {
        isLoading.value = false;
        statusMessage.value = res.error ?? 'No subtitles found for this video';
      }
    } catch (e) {
      isLoading.value = false;
      statusMessage.value = 'Error loading transcript: $e';
    }
  }

  Future<void> _tokenizeCues(String videoId, String lang, List<SubtitleCue> cueList) async {
    try {
      final texts = cueList.map((c) => c.text).toList();
      final tokenizedLines = await apiClient.tokenizeBatch(
        videoId: videoId,
        lang: lang,
        texts: texts,
      );

      for (int i = 0; i < cueList.length && i < tokenizedLines.length; i++) {
        cueList[i].tokens = tokenizedLines[i];
      }

      // Trigger update on cues signal
      cues.value = List.from(cueList);
    } catch (e) {
      print('[VideoPlayerController] Batch tokenize error: $e');
    }
  }

  /// Urgent seek translation micro-batch (< 200ms)
  Future<void> handleSeek(double time) async {
    currentTime.value = time;
    final cueList = cues.value;
    if (cueList.isEmpty) return;

    final index = cueList.indexWhere((c) => time >= c.start && time < (c.start + c.duration + 2.0));
    if (index != -1) {
      final targetLang = AppState.instance.activeLanguage.value;
      await apiClient.translateUrgentSeek(
        cues: cueList,
        activeIndex: index,
        sourceLang: targetLang,
        targetLang: 'vi', // Default UI explanation language
      );
      cues.value = List.from(cueList);
    }
  }
}
