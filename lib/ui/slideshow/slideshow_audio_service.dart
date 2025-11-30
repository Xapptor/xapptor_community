import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// A service that manages background music playback for the slideshow.
///
/// Features:
/// - Downloads songs from Firebase Storage on-demand
/// - Caches downloaded songs locally for performance
/// - Manages playlist with 2-10 songs dynamically
/// - Provides playback controls (play, pause, next, previous)
/// - Handles volume and mute states
class SlideshowAudioService {
  SlideshowAudioService._();
  static final SlideshowAudioService _instance = SlideshowAudioService._();
  static SlideshowAudioService get instance => _instance;

  final AudioPlayer _audio_player = AudioPlayer();
  final List<AudioSource> _audio_sources = [];
  final List<String> _song_urls = [];
  final Map<String, String> _cached_paths = {};

  ConcatenatingAudioSource? _playlist;

  bool _is_initialized = false;
  bool _is_loading = false;
  bool _is_muted = false;
  double _volume = 1.0;

  int _current_index = 0;

  // Stream controllers for state updates
  final StreamController<SlideshowAudioState> _state_controller =
      StreamController<SlideshowAudioState>.broadcast();

  Stream<SlideshowAudioState> get state_stream => _state_controller.stream;

  bool get is_playing => _audio_player.playing;
  bool get is_muted => _is_muted;
  bool get is_loading => _is_loading;
  bool get is_initialized => _is_initialized;
  int get current_index => _current_index;
  int get total_songs => _song_urls.length;
  double get volume => _volume;

  /// Initialize the audio service with songs from Firebase Storage
  Future<void> initialize({
    required Reference storage_ref,
  }) async {
    if (_is_initialized) return;

    _is_loading = true;
    _emit_state();

    try {
      // List all songs in the storage reference
      final ListResult list_result = await storage_ref.listAll();

      if (list_result.items.isEmpty) {
        debugPrint('SlideshowAudioService: No songs found in storage');
        _is_loading = false;
        _emit_state();
        return;
      }

      // Get download URLs for all songs (2-10 expected)
      final List<Future<String>> url_futures =
          list_result.items.map((ref) => ref.getDownloadURL()).toList();

      _song_urls.clear();
      _song_urls.addAll(await Future.wait(url_futures));

      debugPrint(
          'SlideshowAudioService: Found ${_song_urls.length} songs in storage');

      // Load the first song immediately for quick playback start
      if (_song_urls.isNotEmpty) {
        await _load_song(0);
      }

      // Preload remaining songs in background
      _preload_remaining_songs();

      _is_initialized = true;
    } catch (e) {
      debugPrint('SlideshowAudioService: Error initializing: $e');
    } finally {
      _is_loading = false;
      _emit_state();
    }
  }

  /// Preload remaining songs in the background for smooth transitions
  Future<void> _preload_remaining_songs() async {
    for (int i = 1; i < _song_urls.length; i++) {
      if (!_is_initialized) break;
      await _load_song(i);
    }

    // Create playlist after all songs are loaded
    _create_playlist();
  }

  /// Load a single song, downloading if necessary
  Future<void> _load_song(int index) async {
    if (index < 0 || index >= _song_urls.length) return;

    final String url = _song_urls[index];

    try {
      AudioSource source;

      // For web, use network URL directly
      if (kIsWeb) {
        source = AudioSource.uri(Uri.parse(url), tag: 'song_$index');
      } else {
        // For mobile/desktop, check cache first
        final String? cached_path = await _get_cached_path(url, index);

        if (cached_path != null) {
          source = AudioSource.file(cached_path, tag: 'song_$index');
        } else {
          // Download and cache the song
          final String? downloaded_path = await _download_and_cache(url, index);

          if (downloaded_path != null) {
            source = AudioSource.file(downloaded_path, tag: 'song_$index');
          } else {
            // Fallback to streaming
            source = AudioSource.uri(Uri.parse(url), tag: 'song_$index');
          }
        }
      }

      if (index < _audio_sources.length) {
        _audio_sources[index] = source;
      } else {
        _audio_sources.add(source);
      }
    } catch (e) {
      debugPrint('SlideshowAudioService: Error loading song $index: $e');
    }
  }

  /// Get cached file path if exists
  Future<String?> _get_cached_path(String url, int index) async {
    if (kIsWeb) return null;

    final String cache_key = 'song_$index';

    if (_cached_paths.containsKey(cache_key)) {
      final String path = _cached_paths[cache_key]!;
      final File file = File(path);

      if (await file.exists()) {
        return path;
      }
    }

    // Check if file exists in cache directory
    try {
      final Directory cache_dir = await getTemporaryDirectory();
      final String file_path = '${cache_dir.path}/slideshow_songs/$cache_key.mp3';
      final File file = File(file_path);

      if (await file.exists()) {
        _cached_paths[cache_key] = file_path;
        return file_path;
      }
    } catch (e) {
      debugPrint('SlideshowAudioService: Error checking cache: $e');
    }

    return null;
  }

  /// Download song and save to cache
  Future<String?> _download_and_cache(String url, int index) async {
    if (kIsWeb) return null;

    try {
      final Directory cache_dir = await getTemporaryDirectory();
      final Directory songs_dir =
          Directory('${cache_dir.path}/slideshow_songs');

      if (!await songs_dir.exists()) {
        await songs_dir.create(recursive: true);
      }

      final String cache_key = 'song_$index';
      final String file_path = '${songs_dir.path}/$cache_key.mp3';
      final File file = File(file_path);

      // Download using Firebase Storage reference
      final ref = FirebaseStorage.instance.refFromURL(url);
      final data = await ref.getData();

      if (data != null) {
        await file.writeAsBytes(data);
        _cached_paths[cache_key] = file_path;
        debugPrint('SlideshowAudioService: Cached song $index');
        return file_path;
      }
    } catch (e) {
      debugPrint('SlideshowAudioService: Error downloading song $index: $e');
    }

    return null;
  }

  /// Create the playlist from loaded audio sources
  void _create_playlist() {
    if (_audio_sources.isEmpty) return;

    _playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      shuffleOrder: DefaultShuffleOrder(),
      children: _audio_sources,
    );

    _audio_player.setAudioSource(_playlist!, initialIndex: 0);

    // Listen to playback state changes
    _audio_player.playerStateStream.listen((state) {
      _emit_state();
    });

    // Listen to current index changes
    _audio_player.currentIndexStream.listen((index) {
      if (index != null) {
        _current_index = index;
        _emit_state();
      }
    });

    // Enable looping of playlist
    _audio_player.setLoopMode(LoopMode.all);

    _emit_state();
  }

  /// Play the current song
  Future<void> play() async {
    if (!_is_initialized || _audio_sources.isEmpty) return;

    // If playlist hasn't been created yet, create it now
    if (_playlist == null && _audio_sources.isNotEmpty) {
      _create_playlist();
    }

    await _audio_player.play();
    _emit_state();
  }

  /// Pause playback
  Future<void> pause() async {
    await _audio_player.pause();
    _emit_state();
  }

  /// Toggle play/pause
  Future<void> toggle_play_pause() async {
    if (_audio_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  /// Skip to next song
  Future<void> next() async {
    if (!_is_initialized || _audio_sources.isEmpty) return;

    try {
      final bool was_playing = _audio_player.playing;

      // Calculate next index manually
      final int next_index = (_current_index + 1) % _audio_sources.length;
      _current_index = next_index;

      // On web, we need to stop, set source with new index, then play
      if (kIsWeb) {
        await _audio_player.stop();
        if (_playlist != null) {
          await _audio_player.setAudioSource(_playlist!, initialIndex: next_index);
        }
        if (was_playing) {
          await _audio_player.play();
        }
      } else {
        // On native platforms, seek should work
        await _audio_player.seek(Duration.zero, index: next_index);
      }

      _emit_state();
    } catch (e) {
      debugPrint('SlideshowAudioService: Error skipping to next: $e');
    }
  }

  /// Skip to previous song
  Future<void> previous() async {
    if (!_is_initialized || _audio_sources.isEmpty) return;

    try {
      final bool was_playing = _audio_player.playing;

      // Calculate previous index manually
      final int prev_index = (_current_index - 1 + _audio_sources.length) % _audio_sources.length;
      _current_index = prev_index;

      // On web, we need to stop, set source with new index, then play
      if (kIsWeb) {
        await _audio_player.stop();
        if (_playlist != null) {
          await _audio_player.setAudioSource(_playlist!, initialIndex: prev_index);
        }
        if (was_playing) {
          await _audio_player.play();
        }
      } else {
        // On native platforms, seek should work
        await _audio_player.seek(Duration.zero, index: prev_index);
      }

      _emit_state();
    } catch (e) {
      debugPrint('SlideshowAudioService: Error skipping to previous: $e');
    }
  }

  /// Toggle mute state
  void toggle_mute() {
    _is_muted = !_is_muted;
    _audio_player.setVolume(_is_muted ? 0 : _volume);
    _emit_state();
  }

  /// Set mute state
  void set_mute(bool muted) {
    _is_muted = muted;
    _audio_player.setVolume(_is_muted ? 0 : _volume);
    _emit_state();
  }

  /// Set volume (0.0 to 1.0)
  void set_volume(double volume) {
    _volume = volume.clamp(0.0, 1.0);

    if (!_is_muted) {
      _audio_player.setVolume(_volume);
    }
    _emit_state();
  }

  /// Emit current state to listeners
  void _emit_state() {
    _state_controller.add(
      SlideshowAudioState(
        is_playing: _audio_player.playing,
        is_muted: _is_muted,
        is_loading: _is_loading,
        is_initialized: _is_initialized,
        current_index: _current_index,
        total_songs: _song_urls.length,
        volume: _volume,
      ),
    );
  }

  /// Dispose resources
  void dispose() {
    _audio_player.dispose();
    _state_controller.close();
    _is_initialized = false;
    _audio_sources.clear();
    _song_urls.clear();
    _cached_paths.clear();
  }

  /// Reset the service for reuse
  void reset() {
    _audio_player.stop();
    _is_initialized = false;
    _is_loading = false;
    _audio_sources.clear();
    _song_urls.clear();
    _playlist = null;
    _current_index = 0;
    _emit_state();
  }
}

/// State class representing the current state of the audio service
class SlideshowAudioState {
  final bool is_playing;
  final bool is_muted;
  final bool is_loading;
  final bool is_initialized;
  final int current_index;
  final int total_songs;
  final double volume;

  const SlideshowAudioState({
    required this.is_playing,
    required this.is_muted,
    required this.is_loading,
    required this.is_initialized,
    required this.current_index,
    required this.total_songs,
    required this.volume,
  });

  @override
  String toString() {
    return 'SlideshowAudioState(is_playing: $is_playing, is_muted: $is_muted, '
        'is_loading: $is_loading, current_index: $current_index/$total_songs)';
  }
}
