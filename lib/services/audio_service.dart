// lib/services/audio_service.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../state/app_state.dart';

class AudioService {
  static final AudioService instance = AudioService._();
  AudioService._();

  AudioPlayer? _playerInstance;
  AudioPlayer? _sfxPlayerInstance;

  AudioPlayer? get _player {
    if (_playerInstance == null) {
      try {
        final p = AudioPlayer();
        p.onPlayerComplete.listen((_) {
          _currentPlaying.value = null;
        });
        p.onPlayerStateChanged.listen((state) {
          if (state == PlayerState.stopped || state == PlayerState.completed) {
            _currentPlaying.value = null;
          }
        });
        _playerInstance = p;
      } catch (e) {
        debugPrint('[AudioService] Could not initialize player: $e');
        return null;
      }
    }
    return _playerInstance;
  }

  AudioPlayer? get _sfxPlayer {
    if (_sfxPlayerInstance == null) {
      try {
        _sfxPlayerInstance = AudioPlayer();
      } catch (e) {
        debugPrint('[AudioService] Could not initialize sfx player: $e');
        return null;
      }
    }
    return _sfxPlayerInstance;
  }

  final Map<String, Uint8List> _cache = {};
  final ValueNotifier<String?> _currentPlaying = ValueNotifier<String?>(null);

  ValueListenable<String?> get currentPlaying => _currentPlaying;

  /// Play celebratory session completion fanfare chime
  Future<void> playVictoryChime() async {
    try {
      final sfx = _sfxPlayer;
      if (sfx == null) return;
      await sfx.stop();
      await sfx.setVolume(0.45);
      await sfx.play(
        AssetSource('audio/victory_chime.wav'),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      debugPrint('[AudioService] SFX victory playback error: $e');
    }
  }

  bool isPlaying(String text) => _currentPlaying.value == text;

  void clearCache() {
    _cache.clear();
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
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
      final player = _player;
      if (player == null) {
        _currentPlaying.value = null;
        return;
      }
      if (bytes != null && bytes.isNotEmpty) {
        await player.stop();
        await player.play(BytesSource(bytes));
      } else if (fallbackAudioUrl != null && fallbackAudioUrl.startsWith('http')) {
        await player.stop();
        await player.play(UrlSource(fallbackAudioUrl));
      } else {
        _currentPlaying.value = null;
      }
    } catch (e) {
      print('[AudioService] Playback error for "$clean": $e');
      _currentPlaying.value = null;
    }
  }

  void dispose() {
    _playerInstance?.dispose();
    _sfxPlayerInstance?.dispose();
  }
}
