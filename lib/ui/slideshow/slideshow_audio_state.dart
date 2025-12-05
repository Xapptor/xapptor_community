import 'package:just_audio/just_audio.dart';

/// State class representing the current state of the audio service.
class SlideshowAudioState {
  final bool is_playing;
  final bool is_muted;
  final bool is_loading;
  final bool is_initialized;
  final bool is_shuffle_enabled;
  final LoopMode loop_mode;
  final int current_index;
  final int total_songs;
  final double volume;

  const SlideshowAudioState({
    required this.is_playing,
    required this.is_muted,
    required this.is_loading,
    required this.is_initialized,
    required this.is_shuffle_enabled,
    required this.loop_mode,
    required this.current_index,
    required this.total_songs,
    required this.volume,
  });

  /// Creates a default empty state.
  const SlideshowAudioState.initial()
      : is_playing = false,
        is_muted = false,
        is_loading = false,
        is_initialized = false,
        is_shuffle_enabled = false,
        loop_mode = LoopMode.all,
        current_index = 0,
        total_songs = 0,
        volume = 1.0;

  /// Creates a copy with updated fields.
  SlideshowAudioState copy_with({
    bool? is_playing,
    bool? is_muted,
    bool? is_loading,
    bool? is_initialized,
    bool? is_shuffle_enabled,
    LoopMode? loop_mode,
    int? current_index,
    int? total_songs,
    double? volume,
  }) {
    return SlideshowAudioState(
      is_playing: is_playing ?? this.is_playing,
      is_muted: is_muted ?? this.is_muted,
      is_loading: is_loading ?? this.is_loading,
      is_initialized: is_initialized ?? this.is_initialized,
      is_shuffle_enabled: is_shuffle_enabled ?? this.is_shuffle_enabled,
      loop_mode: loop_mode ?? this.loop_mode,
      current_index: current_index ?? this.current_index,
      total_songs: total_songs ?? this.total_songs,
      volume: volume ?? this.volume,
    );
  }

  /// Check if this state equals another (for debouncing purposes).
  bool equals(SlideshowAudioState other) {
    return is_playing == other.is_playing &&
        is_muted == other.is_muted &&
        is_loading == other.is_loading &&
        is_initialized == other.is_initialized &&
        is_shuffle_enabled == other.is_shuffle_enabled &&
        loop_mode == other.loop_mode &&
        current_index == other.current_index &&
        total_songs == other.total_songs &&
        volume == other.volume;
  }

  @override
  String toString() {
    return 'SlideshowAudioState(is_playing: $is_playing, is_muted: $is_muted, '
        'is_loading: $is_loading, is_shuffle_enabled: $is_shuffle_enabled, '
        'loop_mode: $loop_mode, current_index: $current_index/$total_songs)';
  }
}
