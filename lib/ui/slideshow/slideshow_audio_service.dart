import 'dart:async';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_audio_cache.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_audio_state.dart';

export 'package:xapptor_community/ui/slideshow/slideshow_audio_state.dart';

/// Manages background music playback. Uses single-song mode on web.
class SlideshowAudioService {
  SlideshowAudioService._();
  static final SlideshowAudioService _instance = SlideshowAudioService._();
  static SlideshowAudioService get instance => _instance;

  final AudioPlayer _audio_player = AudioPlayer();
  final List<AudioSource> _audio_sources = [];
  final List<String> _song_urls = [];
  final SlideshowAudioCache _cache = SlideshowAudioCache();

  // Web platform detection - use single-song mode for ALL web browsers
  bool get _use_single_song_mode => kIsWeb;
  bool _playlist_set = false;
  bool _is_initialized = false, _is_loading = false, _is_muted = false, _is_shuffle_enabled = false;
  double _volume = 1.0;
  int _current_index = 0;
  LoopMode _loop_mode = LoopMode.all;
  List<int> _shuffle_indices = [];
  int _shuffle_position = 0;
  StreamSubscription? _player_state_subscription, _current_index_subscription;
  Timer? _debounce_timer;
  static const Duration _debounce_duration = Duration(milliseconds: 100);
  SlideshowAudioState? _pending_state;
  Future<void>? _initialization_future;
  final StreamController<SlideshowAudioState> _state_controller = StreamController.broadcast();

  Stream<SlideshowAudioState> get state_stream => _state_controller.stream;
  bool get is_playing => _audio_player.playing;
  bool get is_muted => _is_muted;
  bool get is_loading => _is_loading;
  bool get is_initialized => _is_initialized;
  bool get is_shuffle_enabled => _is_shuffle_enabled;
  LoopMode get loop_mode => _loop_mode;
  int get current_index => _current_index;
  int get total_songs => _song_urls.length;
  double get volume => _volume;

  Future<void> initialize({required Reference storage_ref}) async {
    if (_is_initialized) return;
    if (_initialization_future != null) {
      await _initialization_future;
      return;
    }
    _initialization_future = _do_initialize(storage_ref: storage_ref);
    await _initialization_future;
    _initialization_future = null;
  }

  Future<void> _do_initialize({required Reference storage_ref}) async {
    _is_loading = true;
    _emit_state();
    try {
      final list = await storage_ref.listAll();
      if (list.items.isEmpty) {
        _is_loading = false;
        _emit_state();
        return;
      }
      _song_urls.clear();
      _song_urls.addAll(await Future.wait(list.items.map((r) => r.getDownloadURL())));
      if (_use_single_song_mode) {
        _audio_sources.clear();
      } else {
        await _load_all_songs();
      }
      await _create_playlist();
      _is_initialized = true;
    } catch (e) {
      debugPrint('SlideshowAudioService: Error initializing: $e');
    } finally {
      _is_loading = false;
      _emit_state();
    }
  }

  Future<void> _load_all_songs() async {
    await Future.wait(List.generate(_song_urls.length, (i) => _load_song(i)));
  }

  Future<void> _load_song(int index) async {
    if (index < 0 || index >= _song_urls.length) return;
    try {
      final source = await _cache.create_audio_source(url: _song_urls[index], index: index);
      if (index < _audio_sources.length) {
        _audio_sources[index] = source;
      } else {
        _audio_sources.add(source);
      }
    } catch (e) {
      debugPrint('SlideshowAudioService: Error loading song $index: $e');
    }
  }

  Future<void> _create_playlist() async {
    final has_songs = _use_single_song_mode ? _song_urls.isNotEmpty : _audio_sources.isNotEmpty;
    if (!has_songs) return;
    try {
      await _player_state_subscription?.cancel();
      await _current_index_subscription?.cancel();
      if (_use_single_song_mode) {
        await _load_single_song(0);
        _playlist_set = true;
        _player_state_subscription = _audio_player.playerStateStream.listen((s) {
          _emit_state();
          if (s.processingState == ProcessingState.completed) _handle_web_completion();
        });
      } else {
        // ignore: deprecated_member_use
        final playlist = ConcatenatingAudioSource(
          useLazyPreparation: true,
          shuffleOrder: DefaultShuffleOrder(),
          children: _audio_sources,
        );
        await _audio_player.setAudioSource(playlist, initialIndex: 0);
        _playlist_set = true;
        _player_state_subscription = _audio_player.playerStateStream.listen((_) => _emit_state());
        _current_index_subscription = _audio_player.currentIndexStream.listen((i) {
          if (i != null && i != _current_index) {
            _current_index = i;
            _emit_state();
          }
        });
        await _audio_player.setLoopMode(LoopMode.all);
      }
      _emit_state();
    } catch (e) {
      _playlist_set = false;
      _emit_state();
    }
  }

  Future<void> _load_single_song(int index) async {
    if (index < 0 || index >= _song_urls.length) return;
    try {
      await _audio_player.stop();
      await _audio_player.setUrl(_song_urls[index]);
      _current_index = index;
    } catch (_) {}
  }

  void _handle_web_completion() {
    if (!_use_single_song_mode) return;
    int next;
    if (_loop_mode == LoopMode.one) {
      next = _current_index;
    } else if (_is_shuffle_enabled && _shuffle_indices.isNotEmpty) {
      _shuffle_position = (_shuffle_position + 1) % _shuffle_indices.length;
      next = _shuffle_indices[_shuffle_position];
    } else {
      next = (_current_index + 1) % _song_urls.length;
      if (_loop_mode == LoopMode.off && next == 0) {
        _emit_state();
        return;
      }
    }
    _load_single_song(next).then((_) {
      if (_audio_player.playing || _loop_mode != LoopMode.off) _audio_player.play();
      _emit_state();
    });
  }

  Future<void> play() async {
    final has_songs = _use_single_song_mode ? _song_urls.isNotEmpty : _audio_sources.isNotEmpty;
    if (!_is_initialized || !has_songs) return;
    if (!_playlist_set) await _create_playlist();
    try {
      await _audio_player.play();
      _emit_state();
    } catch (_) {
      _emit_state();
    }
  }

  Future<void> pause() async {
    await _audio_player.pause();
    _emit_state();
  }

  Future<void> toggle_play_pause() async {
    try {
      _audio_player.playing ? await pause() : await play();
    } catch (_) {
      _emit_state();
    }
  }

  Future<void> next() async {
    final has_songs = _use_single_song_mode ? _song_urls.isNotEmpty : _audio_sources.isNotEmpty;
    if (!_is_initialized || !has_songs) return;
    if (!_playlist_set) await _create_playlist();
    try {
      final next_idx = _is_shuffle_enabled && _shuffle_indices.isNotEmpty
          ? _shuffle_indices[(_shuffle_position = (_shuffle_position + 1) % _shuffle_indices.length)]
          : (_current_index + 1) % _song_urls.length;
      if (_use_single_song_mode) {
        final p = _audio_player.playing;
        await _load_single_song(next_idx);
        if (p) await _audio_player.play();
      } else {
        await _audio_player.seek(Duration.zero, index: next_idx);
      }
      _emit_state();
    } catch (_) {}
  }

  Future<void> previous() async {
    final has_songs = _use_single_song_mode ? _song_urls.isNotEmpty : _audio_sources.isNotEmpty;
    if (!_is_initialized || !has_songs) return;
    if (!_playlist_set) await _create_playlist();
    try {
      final prev_idx = _is_shuffle_enabled && _shuffle_indices.isNotEmpty
          ? _shuffle_indices[(_shuffle_position =
              (_shuffle_position - 1 + _shuffle_indices.length) % _shuffle_indices.length)]
          : (_current_index - 1 + _song_urls.length) % _song_urls.length;
      if (_use_single_song_mode) {
        final p = _audio_player.playing;
        await _load_single_song(prev_idx);
        if (p) await _audio_player.play();
      } else {
        await _audio_player.seek(Duration.zero, index: prev_idx);
      }
      _emit_state();
    } catch (_) {}
  }

  void toggle_mute() {
    _is_muted = !_is_muted;
    _audio_player.setVolume(_is_muted ? 0 : _volume);
    _emit_state_immediate();
  }

  Future<void> toggle_shuffle() async {
    final has_songs = _use_single_song_mode ? _song_urls.isNotEmpty : _audio_sources.isNotEmpty;
    if (!_playlist_set && has_songs) await _create_playlist();
    _is_shuffle_enabled = !_is_shuffle_enabled;
    if (_is_shuffle_enabled) {
      _shuffle_indices = List.generate(_song_urls.length, (i) => i)..shuffle(Random());
      _shuffle_position = _shuffle_indices.indexOf(_current_index);
      if (_shuffle_position < 0) _shuffle_position = 0;
    } else {
      _shuffle_indices.clear();
      _shuffle_position = 0;
    }
    _emit_state_immediate();
  }

  Future<void> toggle_loop() async {
    _loop_mode = _loop_mode == LoopMode.all
        ? LoopMode.one
        : _loop_mode == LoopMode.one
            ? LoopMode.off
            : LoopMode.all;
    await _audio_player.setLoopMode(_loop_mode);
    _emit_state_immediate();
  }

  void set_mute(bool m) {
    _is_muted = m;
    _audio_player.setVolume(_is_muted ? 0 : _volume);
    _emit_state_immediate();
  }

  void set_volume(double v) {
    _volume = v.clamp(0.0, 1.0);
    if (!_is_muted) _audio_player.setVolume(_volume);
    _emit_state_immediate();
  }

  void _emit_state() {
    final s = _build_state();
    if (_pending_state != null && _pending_state!.equals(s)) return;
    _pending_state = s;
    _debounce_timer?.cancel();
    _debounce_timer = Timer(_debounce_duration, () {
      if (_pending_state != null) _state_controller.add(_pending_state!);
    });
  }

  void _emit_state_immediate() {
    _debounce_timer?.cancel();
    _pending_state = _build_state();
    _state_controller.add(_pending_state!);
  }

  SlideshowAudioState _build_state() => SlideshowAudioState(
        is_playing: _audio_player.playing,
        is_muted: _is_muted,
        is_loading: _is_loading,
        is_initialized: _is_initialized,
        is_shuffle_enabled: _is_shuffle_enabled,
        loop_mode: _loop_mode,
        current_index: _current_index,
        total_songs: _song_urls.length,
        volume: _volume,
      );

  Future<void> dispose() async {
    _debounce_timer?.cancel();
    await _player_state_subscription?.cancel();
    await _current_index_subscription?.cancel();
    await _audio_player.stop();
    await _audio_player.dispose();
    await _state_controller.close();
    _is_initialized = false;
    _playlist_set = false;
    _audio_sources.clear();
    _song_urls.clear();
    _cache.clear();
  }

  Future<void> reset() async {
    _debounce_timer?.cancel();
    _pending_state = null;
    await _player_state_subscription?.cancel();
    await _current_index_subscription?.cancel();
    await _audio_player.stop();
    _is_initialized = _is_loading = _is_shuffle_enabled = false;
    _loop_mode = LoopMode.all;
    _initialization_future = null;
    _audio_sources.clear();
    _song_urls.clear();
    _playlist_set = false;
    _current_index = 0;
    _shuffle_indices.clear();
    _shuffle_position = 0;
    _cache.clear();
    _emit_state();
  }
}
