// lib/state/player_state.dart

import 'dart:async';
import 'package:signals_flutter/signals_flutter.dart';
import '../models/voca_models.dart';
import '../services/voca_api_client.dart';
import '../services/grammar_engine.dart';
import '../services/dual_sub_service.dart';
import '../utils/language_utils.dart';
import 'app_state.dart';

class VideoPlayerController {
  final VocaApiClient apiClient;
  final GrammarEngine grammarEngine;
  late final DualSubService dualSubService;

  // Language state tracking (1:1 port of lingua-tube subtitle.service.ts)
  final loadedLanguage = signal<String?>(null);
  late final ReadonlySignal<String> activeLanguage;

  VideoPlayerController({
    required this.apiClient,
    required this.grammarEngine,
  }) {
    dualSubService = DualSubService(apiClient: apiClient);

    // Computed signal: Evaluates authentic language of subtitles (1:1 port of lingua-tube)
    activeLanguage = computed(() {
      final cueList = cues.value;
      if (cueList.isNotEmpty) {
        return detectSubtitleLanguage(
          cueList,
          loadedLanguage.value ?? AppState.instance.activeLanguage.value,
        );
      }
      final loaded = loadedLanguage.value;
      if (loaded != null && loaded.isNotEmpty) return loaded;
      return AppState.instance.activeLanguage.value;
    });

    // Computed signal: Find active cue using the Sticky Subtitle Rule (Rule 6)
    activeCue = computed(() {
      final time = currentTime.value;
      final cueList = cues.value;
      return findActiveCue(time, cueList);
    });

    // Automatically detect grammar patterns whenever the active cue or loaded grammar changes
    activeGrammarMatches = computed(() {
      // Re-evaluate when grammar patterns finish loading in background
      grammarEngine.loadedLanguages.value;

      final cue = activeCue.value;
      final lang = activeLanguage.value;
      if (cue == null || cue.tokens.isEmpty) return <GrammarMatch>[];
      return grammarEngine.detectPatterns(cue.tokens, lang);
    });
  }

  // --- Core Playback & Video Metadata Signals ---
  final currentVideoId = signal<String?>(null);
  String get videoId => currentVideoId.value ?? '';
  final videoTitle = signal<String>('');
  final currentTime = signal<double>(0.0);
  final isPlaying = signal<bool>(false);
  final cues = signal<List<SubtitleCue>>([]);
  final isLoading = signal<bool>(false);
  final statusMessage = signal<String?>(null);
  final languageMismatch = signal<bool>(false);
  final availableLanguages = signal<AvailableLanguages>(AvailableLanguages());
  final difficultyLevel = signal<String?>(null);
  final isAIGenerated = signal<bool>(false);

  // --- Immersion & Subtitle Display Signals ---
  final playbackRate = signal<double>(1.0);
  final isLoopingCue = signal<bool>(false);
  final loopingCue = signal<SubtitleCue?>(null);
  final showFurigana = signal<bool>(true);
  final showTranslation = signal<bool>(true);
  final subtitleSize = signal<SubtitleSize>(SubtitleSize.medium);
  final isTranscriptMode = signal<bool>(false);
  final autoScrollTranscript = signal<bool>(true);

  // --- Subtitles Visibility Toggle ---
  final subtitlesVisible = signal<bool>(true);

  // --- Miniplayer State ---
  final isMiniplayer = signal<bool>(false);

  // --- Fullscreen State ---
  final isFullscreen = signal<bool>(false);

  // --- Quiz Mode Active Signal ---
  final isQuizActive = signal<bool>(false);

  // --- Saved Words Count ---
  final savedWordCount = signal<int>(0);

  // --- Dual Subtitles Target Language & Lookahead ---
  final dualSubLanguage = signal<String?>('vi');
  Signal<bool> get isDualSubLoading => dualSubService.isDualSubLoading;

  // --- Sleep Timer Signals ---
  final sleepTimerOption = signal<String>('off'); // 'off' | '10' | '15' | '30' | '45' | '60' | 'end'
  final sleepTimerRemainingSeconds = signal<int?>(null);

  // --- Readonly Computed Signals ---
  late final ReadonlySignal<SubtitleCue?> activeCue;
  late final ReadonlySignal<List<GrammarMatch>> activeGrammarMatches;

  // --- Pause Lock Coordinator ---
  final Set<String> _pauseLocks = <String>{};
  bool _wasPlayingBeforeLock = false;

  bool get isPauseLocked => _pauseLocks.isNotEmpty;

  // --- Internal State & Timers ---
  Timer? _sleepTimer;
  void Function()? _onSleepTimerEnd;

  // ============================================================================
  // Pause Lock Coordinator API
  // ============================================================================

  /// Acquire pause lock when opening a modal bottom sheet (dictionary, grammar, playlist, settings).
  /// If the player was playing before the first lock, calls [onPause] and records playing state.
  void acquirePauseLock(String reason, {required void Function() onPause}) {
    if (_pauseLocks.isEmpty) {
      _wasPlayingBeforeLock = isPlaying.value;
      _pauseLocks.add(reason);
      if (_wasPlayingBeforeLock) {
        onPause();
      }
    } else {
      _pauseLocks.add(reason);
    }
  }

  /// Release pause lock when a modal is dismissed.
  /// When all active locks are cleared, resumes playback via [onResume] if it was playing before locks.
  void releasePauseLock(String reason, {required void Function() onResume}) {
    final wasRemoved = _pauseLocks.remove(reason);
    if (wasRemoved && _pauseLocks.isEmpty) {
      if (_wasPlayingBeforeLock) {
        _wasPlayingBeforeLock = false;
        onResume();
      }
    }
  }

  /// Clear all pause locks unconditionally
  void clearPauseLocks() {
    _pauseLocks.clear();
    _wasPlayingBeforeLock = false;
  }

  // ============================================================================
  // Sticky Subtitle Rule (Rule 6) & Cue Search
  // ============================================================================

  /// Find active cue index using O(log n) binary search with Rule 6 Sticky Subtitle logic.
  /// Holds the last ended cue for up to 2.0s - 3.0s (2.5s) into timestamp gaps before the next cue starts.
  int findActiveCueIndex(double time, [List<SubtitleCue>? cueList]) {
    final list = cueList ?? cues.value;
    if (list.isEmpty) return -1;

    int left = 0;
    int right = list.length - 1;
    int candidate = -1;

    while (left <= right) {
      final mid = (left + right) ~/ 2;
      if (list[mid].start <= time) {
        candidate = mid;
        left = mid + 1;
      } else {
        right = mid - 1;
      }
    }

    if (candidate != -1) {
      // 1. Scan backwards from candidate to find latest overlapping active cue
      final startScan = (candidate - 6).clamp(0, candidate);
      for (int i = candidate; i >= startScan; i--) {
        final c = list[i];
        if (time >= c.start && time < (c.start + c.duration)) {
          return i;
        }
      }

      // 2. Rule 6 Sticky Subtitle: hold ended cue for up to 2.5s gap if next cue hasn't started
      final candCue = list[candidate];
      final candEnd = candCue.start + candCue.duration;
      final nextStart = (candidate + 1 < list.length) ? list[candidate + 1].start : double.infinity;

      if (time >= candEnd && time < nextStart) {
        if ((time - candEnd) <= 2.5) {
          return candidate;
        }
      }
    }

    return -1;
  }

  /// Returns the active cue (or sticky held cue) for the given timestamp
  SubtitleCue? findActiveCue(double time, [List<SubtitleCue>? cueList]) {
    final list = cueList ?? cues.value;
    if (list.isEmpty) return null;
    final idx = findActiveCueIndex(time, list);
    return (idx >= 0 && idx < list.length) ? list[idx] : null;
  }

  // ============================================================================
  // Miniplayer API
  // ============================================================================

  void toggleMiniplayer() {
    isMiniplayer.value = !isMiniplayer.value;
  }

  void setMiniplayer(bool value) {
    isMiniplayer.value = value;
  }

  // ============================================================================
  // Sleep Timer API
  // ============================================================================

  /// Sets sleep timer option: 'off' | '10' | '15' | '30' | '45' | '60' | 'end'
  /// On expiry or end-of-video, triggers [onTimerEnd] callback and resets to 'off'.
  void setSleepTimer(String option, {required void Function() onTimerEnd}) {
    cancelSleepTimer();
    sleepTimerOption.value = option;
    _onSleepTimerEnd = onTimerEnd;

    if (option == 'off') {
      return;
    }

    if (option == 'end') {
      sleepTimerRemainingSeconds.value = null;
      return;
    }

    final minutes = int.tryParse(option);
    if (minutes == null || minutes <= 0) {
      sleepTimerOption.value = 'off';
      return;
    }

    int secondsLeft = minutes * 60;
    sleepTimerRemainingSeconds.value = secondsLeft;

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsLeft--;
      if (secondsLeft <= 0) {
        cancelSleepTimer();
        sleepTimerOption.value = 'off';
        _onSleepTimerEnd?.call();
      } else {
        sleepTimerRemainingSeconds.value = secondsLeft;
      }
    });
  }

  /// Cancels active sleep timer countdown
  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepTimerRemainingSeconds.value = null;
  }

  /// Clears sleep timer and resets option to 'off'
  void clearSleepTimer() {
    cancelSleepTimer();
    sleepTimerOption.value = 'off';
    _onSleepTimerEnd = null;
  }

  /// Call when video reaches the end to handle 'end' sleep timer setting
  void handleVideoEnded() {
    if (sleepTimerOption.value == 'end') {
      cancelSleepTimer();
      sleepTimerOption.value = 'off';
      _onSleepTimerEnd?.call();
    }
  }

  // ============================================================================
  // Subtitles Visibility API
  // ============================================================================

  void toggleSubtitlesVisible() {
    subtitlesVisible.value = !subtitlesVisible.value;
  }

  void setSubtitlesVisible(bool visible) {
    subtitlesVisible.value = visible;
  }

  // ============================================================================
  // Quiz Mode API
  // ============================================================================

  void toggleQuizMode() {
    isQuizActive.value = !isQuizActive.value;
  }

  void setQuizMode(bool active) {
    isQuizActive.value = active;
  }

  // ============================================================================
  // Dual Subtitles & Lookahead Streaming Buffer
  // ============================================================================

  void setDualSubLanguage(String? lang) {
    if (dualSubLanguage.value != lang) {
      dualSubLanguage.value = lang;
      if (lang != null && lang.isNotEmpty) {
        dualSubService.setTargetLanguage(lang);
      }
    }
  }

  /// Update playback time and trigger dual subtitle lookahead progress
  void updatePlaybackTime(double time) {
    currentTime.value = time;
    final idx = findActiveCueIndex(time);
    if (idx != -1) {
      dualSubService.onPlaybackProgress(idx);
    }
  }

  // ============================================================================
  // Video Loading & Tokenization
  // ============================================================================

  /// Load video and fetch synchronized transcripts
  Future<void> loadVideo(
    String videoId, {
    bool preferAI = false,
    String? turnstileToken,
    String? language,
  }) async {
    currentVideoId.value = videoId;
    isLoading.value = true;
    statusMessage.value = 'Loading subtitles...';
    languageMismatch.value = false;
    difficultyLevel.value = null;
    isAIGenerated.value = false;
    cues.value = [];
    isLoopingCue.value = false;
    loopingCue.value = null;

    final requestedLang = language ?? AppState.instance.activeLanguage.value;
    loadedLanguage.value = normalizeLanguageCode(requestedLang);
    await grammarEngine.loadLanguage(requestedLang);

    try {
      final res = await apiClient.getTranscript(
        videoId: videoId,
        lang: requestedLang,
        preferAI: preferAI,
        turnstileToken: turnstileToken,
        onProgress: (status) => statusMessage.value = status,
      );

      availableLanguages.value = res.availableLanguages;
      if (res.source == 'ai') {
        isAIGenerated.value = true;
      }
      if (res.levels.isNotEmpty) {
        difficultyLevel.value = res.levels[requestedLang] ?? res.levels['overall'] ?? res.levels.values.first;
      }

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

        // Detect authentic language from subtitle cues (1:1 port of lingua-tube)
        final authenticLang = activeLanguage.value;
        loadedLanguage.value = authenticLang;

        // Preload grammar patterns for authentic language
        grammarEngine.loadLanguage(authenticLang);

        // Asynchronously batch tokenize cues with authentic language
        _tokenizeCues(videoId, authenticLang, rawCues);

        // Initialize DualSubService (Cloudflare R2 cache lookup + Two-tier streaming)
        final dualTarget = dualSubLanguage.value ?? 'vi';
        dualSubService.initializeForVideo(
          videoId: videoId,
          sourceLang: authenticLang,
          targetLang: dualTarget,
          cues: cues.value,
          onCuesUpdated: (updatedCues) {
            cues.value = List.from(updatedCues);
          },
        );
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

  /// Urgent seek translation micro-batch (< 200ms) with lookahead buffer follow-up
  Future<void> handleSeek(double time) async {
    currentTime.value = time;
    final cueList = cues.value;
    if (cueList.isEmpty) return;

    final index = cueList.indexWhere((c) => time >= c.start && time < (c.start + c.duration + 2.0));
    if (index != -1) {
      dualSubService.onPlaybackProgress(index);
    }
  }

  // ============================================================================
  // Playback Navigation & Loop Controls
  // ============================================================================

  /// Toggle looping the currently active cue
  void toggleLoopCurrentCue() {
    if (isLoopingCue.value) {
      isLoopingCue.value = false;
      loopingCue.value = null;
    } else {
      final current = activeCue.value;
      if (current != null) {
        loopingCue.value = current;
        isLoopingCue.value = true;
      }
    }
  }

  /// Explicitly set or clear the loop cue
  void setLoopCue(SubtitleCue? cue) {
    if (cue == null) {
      isLoopingCue.value = false;
      loopingCue.value = null;
    } else {
      loopingCue.value = cue;
      isLoopingCue.value = true;
    }
  }

  /// Jump to the previous cue in the list
  void seekToPreviousCue({required void Function(double seconds) onSeek}) {
    final cueList = cues.value;
    if (cueList.isEmpty) return;
    final time = currentTime.value;

    int currentIndex = cueList.indexWhere((c) => time >= c.start && time < (c.start + c.duration));
    if (currentIndex == -1) {
      currentIndex = cueList.lastIndexWhere((c) => c.start <= time);
    }

    if (currentIndex > 0) {
      final currentCue = cueList[currentIndex];
      // If already > 2s into current cue, restart current cue; otherwise jump to previous cue
      if (time - currentCue.start > 2.0) {
        onSeek(currentCue.start);
        currentTime.value = currentCue.start;
        if (isLoopingCue.value) loopingCue.value = currentCue;
      } else {
        final prevCue = cueList[currentIndex - 1];
        onSeek(prevCue.start);
        currentTime.value = prevCue.start;
        if (isLoopingCue.value) loopingCue.value = prevCue;
      }
    } else if (currentIndex == 0) {
      final firstCue = cueList[0];
      onSeek(firstCue.start);
      currentTime.value = firstCue.start;
      if (isLoopingCue.value) loopingCue.value = firstCue;
    }
  }

  /// Jump to the next cue in the list
  void seekToNextCue({required void Function(double seconds) onSeek}) {
    final cueList = cues.value;
    if (cueList.isEmpty) return;
    final time = currentTime.value;

    final nextIndex = cueList.indexWhere((c) => c.start > time + 0.2);
    if (nextIndex != -1 && nextIndex < cueList.length) {
      final nextCue = cueList[nextIndex];
      onSeek(nextCue.start);
      currentTime.value = nextCue.start;
      if (isLoopingCue.value) loopingCue.value = nextCue;
    }
  }

  void toggleFurigana() {
    showFurigana.value = !showFurigana.value;
  }

  void toggleTranslation() {
    showTranslation.value = !showTranslation.value;
    if (showTranslation.value) {
      final currentIdx = findActiveCueIndex(currentTime.value);
      dualSubService.onPlaybackProgress(currentIdx >= 0 ? currentIdx : 0);
    }
  }

  void toggleTranscriptMode() {
    isTranscriptMode.value = !isTranscriptMode.value;
  }

  void toggleAutoScroll() {
    autoScrollTranscript.value = !autoScrollTranscript.value;
  }

  void cycleSubtitleSize() {
    switch (subtitleSize.value) {
      case SubtitleSize.small:
        subtitleSize.value = SubtitleSize.medium;
        break;
      case SubtitleSize.medium:
        subtitleSize.value = SubtitleSize.large;
        break;
      case SubtitleSize.large:
        subtitleSize.value = SubtitleSize.small;
        break;
    }
  }

  void dispose() {
    dualSubService.dispose();
    cancelSleepTimer();
    clearPauseLocks();
  }
}
