// lib/services/audio_service.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../state/app_state.dart';

class AudioService {
  static final AudioService instance = AudioService._();
  AudioService._() {
    _player.onPlayerComplete.listen((_) {
      _currentPlaying.value = null;
    });
    _player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.stopped || state == PlayerState.completed) {
        _currentPlaying.value = null;
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  final Map<String, Uint8List> _cache = {};
  final ValueNotifier<String?> _currentPlaying = ValueNotifier<String?>(null);

  ValueListenable<String?> get currentPlaying => _currentPlaying;

  bool isPlaying(String text) => _currentPlaying.value == text;

  void clearCache() {
    _cache.clear();
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    _currentPlaying.value = null;
  }

  /// Play audio pronunciation for word or sentence using Edge Neural TTS
  Future<void> playWord(
    String word, {
    String? language,
    String? fallbackAudioUrl,
  }) async {
    final clean = word.trim();
    if (clean.isEmpty) return;

    if (isPlaying(clean)) {
      await stop();
      return;
    }

    final lang = language ?? AppState.instance.activeLanguage.value;
    final cacheKey = '$lang:$clean';

    _currentPlaying.value = clean;

    try {
      // 1. Check in-memory RAM cache (<1ms)
      Uint8List? bytes = _cache[cacheKey];

      // 2. If not cached, fetch via VocaApiClient (with mandatory User-Agent)
      if (bytes == null) {
        bytes = await AppState.instance.apiClient.fetchTtsAudio(
          text: clean,
          lang: lang,
        );
        if (bytes != null && bytes.isNotEmpty) {
          _cache[cacheKey] = bytes;
        }
      }

      // 3. Play bytes or fallback to audio URL
      if (bytes != null && bytes.isNotEmpty) {
        await _player.stop();
        await _player.play(BytesSource(bytes));
      } else if (fallbackAudioUrl != null && fallbackAudioUrl.startsWith('http')) {
        await _player.stop();
        await _player.play(UrlSource(fallbackAudioUrl));
      } else {
        _currentPlaying.value = null;
      }
    } catch (e) {
      print('[AudioService] Playback error for "$clean": $e');
      _currentPlaying.value = null;
    }
  }

  void dispose() {
    _player.dispose();
  }
}
