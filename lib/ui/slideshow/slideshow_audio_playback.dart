import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Mixin containing playback control logic for the audio service.
mixin SlideshowAudioPlaybackMixin {
  /// Override in implementing class
  AudioPlayer get audio_player;
  List<String> get song_urls;
  List<AudioSource> get audio_sources;

  bool get playlist_set;
  set playlist_set(bool value);

  bool get is_initialized;

  bool get is_shuffle_enabled;
  set is_shuffle_enabled(bool value);

  bool get is_muted;
  set is_muted(bool value);

  int get current_index;
  set current_index(int value);

  double get volume;
  set volume(double value);

  LoopMode get loop_mode;
  set loop_mode(LoopMode value);

  bool get use_single_song_mode;

  // Shuffle state
  List<int> shuffle_indices = [];
  int shuffle_position = 0;

  void emit_state();
  void emit_state_immediate();
  Future<void> create_playlist();
  Future<void> load_single_song_for_web(int index);

  /// Play the current song.
  Future<void> play() async {
    final bool has_songs = use_single_song_mode ? song_urls.isNotEmpty : audio_sources.isNotEmpty;
    if (!is_initialized || !has_songs) return;

    if (!playlist_set && has_songs) {
      await create_playlist();
    }

    try {
      await audio_player.play();
      emit_state();
    } catch (e) {
      debugPrint('SlideshowAudioService: Error playing audio: $e');
      emit_state();
    }
  }

  /// Pause playback.
  Future<void> pause() async {
    await audio_player.pause();
    emit_state();
  }

  /// Toggle play/pause.
  Future<void> toggle_play_pause() async {
    try {
      if (audio_player.playing) {
        await pause();
      } else {
        await play();
      }
    } catch (e) {
      debugPrint('SlideshowAudioService: Error toggling play/pause: $e');
      emit_state();
    }
  }

  void generate_shuffle_indices() {
    shuffle_indices = List.generate(song_urls.length, (i) => i);
    shuffle_indices.shuffle(Random());
    shuffle_position = 0;
  }

  /// Skip to next song.
  Future<void> next() async {
    final bool has_songs = use_single_song_mode ? song_urls.isNotEmpty : audio_sources.isNotEmpty;
    if (!is_initialized || !has_songs) return;

    if (!playlist_set) await create_playlist();

    try {
      final int next_index = calculate_next_index();

      if (use_single_song_mode) {
        final was_playing = audio_player.playing;
        await load_single_song_for_web(next_index);
        if (was_playing) await audio_player.play();
      } else {
        await audio_player.seek(Duration.zero, index: next_index);
      }

      emit_state();
    } catch (e) {
      debugPrint('SlideshowAudioService: Error skipping to next: $e');
    }
  }

  int calculate_next_index() {
    if (is_shuffle_enabled && shuffle_indices.isNotEmpty) {
      shuffle_position = (shuffle_position + 1) % shuffle_indices.length;
      return shuffle_indices[shuffle_position];
    }
    return (current_index + 1) % song_urls.length;
  }

  /// Skip to previous song.
  Future<void> previous() async {
    final bool has_songs = use_single_song_mode ? song_urls.isNotEmpty : audio_sources.isNotEmpty;
    if (!is_initialized || !has_songs) return;

    if (!playlist_set) await create_playlist();

    try {
      final int prev_index = calculate_previous_index();

      if (use_single_song_mode) {
        final was_playing = audio_player.playing;
        await load_single_song_for_web(prev_index);
        if (was_playing) await audio_player.play();
      } else {
        await audio_player.seek(Duration.zero, index: prev_index);
      }

      emit_state();
    } catch (e) {
      debugPrint('SlideshowAudioService: Error skipping to previous: $e');
    }
  }

  int calculate_previous_index() {
    if (is_shuffle_enabled && shuffle_indices.isNotEmpty) {
      shuffle_position = (shuffle_position - 1 + shuffle_indices.length) % shuffle_indices.length;
      return shuffle_indices[shuffle_position];
    }
    return (current_index - 1 + song_urls.length) % song_urls.length;
  }

  /// Toggle mute state.
  void toggle_mute() {
    is_muted = !is_muted;
    audio_player.setVolume(is_muted ? 0 : volume);
    emit_state_immediate();
  }

  /// Toggle shuffle mode.
  Future<void> toggle_shuffle() async {
    final bool has_songs = use_single_song_mode ? song_urls.isNotEmpty : audio_sources.isNotEmpty;
    if (!playlist_set && has_songs) await create_playlist();

    is_shuffle_enabled = !is_shuffle_enabled;

    if (is_shuffle_enabled) {
      generate_shuffle_indices();
      shuffle_position = shuffle_indices.indexOf(current_index);
      if (shuffle_position < 0) shuffle_position = 0;
    } else {
      shuffle_indices.clear();
      shuffle_position = 0;
    }

    emit_state_immediate();
  }

  /// Toggle loop mode: Loop All -> Loop One -> No Loop -> Loop All.
  Future<void> toggle_loop() async {
    switch (loop_mode) {
      case LoopMode.all:
        loop_mode = LoopMode.one;
        break;
      case LoopMode.one:
        loop_mode = LoopMode.off;
        break;
      case LoopMode.off:
        loop_mode = LoopMode.all;
        break;
    }

    await audio_player.setLoopMode(loop_mode);
    emit_state_immediate();
  }

  /// Set mute state.
  void set_mute(bool muted) {
    is_muted = muted;
    audio_player.setVolume(is_muted ? 0 : volume);
    emit_state_immediate();
  }

  /// Set volume (0.0 to 1.0).
  void set_volume(double new_volume) {
    volume = new_volume.clamp(0.0, 1.0);
    if (!is_muted) audio_player.setVolume(volume);
    emit_state_immediate();
  }
}
