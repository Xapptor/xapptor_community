import 'dart:async';
import 'dart:io';
import 'dart:math';
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
  bool _is_shuffle_enabled = false;
  double _volume = 1.0;

  int _current_index = 0;

  // Repeat/Loop mode: 0 = Loop All, 1 = Loop One, 2 = No Loop
  LoopMode _loop_mode = LoopMode.all;

  // Manual shuffle implementation since just_audio shuffle doesn't work reliably on web
  List<int> _shuffle_indices = [];
  int _shuffle_position = 0; // Current position in the shuffled order

  // Track if initialization is in progress to prevent concurrent init calls
  Future<void>? _initialization_future;

  // Stream controllers for state updates
  final StreamController<SlideshowAudioState> _state_controller =
      StreamController<SlideshowAudioState>.broadcast();

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

  /// Initialize the audio service with songs from Firebase Storage
  Future<void> initialize({
    required Reference storage_ref,
  }) async {
    // If already initialized, just return
    if (_is_initialized) return;

    // If initialization is already in progress, wait for it
    if (_initialization_future != null) {
      await _initialization_future;
      return;
    }

    // Start initialization
    _initialization_future = _do_initialize(storage_ref: storage_ref);
    await _initialization_future;
    _initialization_future = null;
  }

  Future<void> _do_initialize({
    required Reference storage_ref,
  }) async {
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

      // Load ALL songs before creating playlist
      // Load them in parallel for faster initialization
      final List<Future<void>> load_futures = [];
      for (int i = 0; i < _song_urls.length; i++) {
        load_futures.add(_load_song(i));
      }
      await Future.wait(load_futures);

      debugPrint(
          'SlideshowAudioService: Loaded ${_audio_sources.length} audio sources');

      // Create playlist with all songs loaded
      await _create_playlist();

      _is_initialized = true;
    } catch (e) {
      debugPrint('SlideshowAudioService: Error initializing: $e');
    } finally {
      _is_loading = false;
      _emit_state();
    }
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
  Future<void> _create_playlist() async {
    if (_audio_sources.isEmpty) return;

    _playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      shuffleOrder: DefaultShuffleOrder(),
      children: _audio_sources,
    );

    await _audio_player.setAudioSource(_playlist!, initialIndex: 0);

    debugPrint('SlideshowAudioService: Playlist created with ${_audio_sources.length} songs');

    // Listen to playback state changes
    _audio_player.playerStateStream.listen((state) {
      _emit_state();
    });

    // Listen to current index changes
    _audio_player.currentIndexStream.listen((index) {
      if (index != null) {
        debugPrint('SlideshowAudioService: currentIndexStream changed to $index');
        _current_index = index;
        _emit_state();
      }
    });

    // Enable looping of playlist
    await _audio_player.setLoopMode(LoopMode.all);

    debugPrint('SlideshowAudioService: LoopMode.all enabled');

    _emit_state();
  }

  /// Play the current song
  Future<void> play() async {
    if (!_is_initialized || _audio_sources.isEmpty) return;

    // If playlist hasn't been created yet, create it now
    if (_playlist == null && _audio_sources.isNotEmpty) {
      await _create_playlist();
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

  /// Generate a new shuffled order of indices
  void _generate_shuffle_indices() {
    _shuffle_indices = List.generate(_audio_sources.length, (i) => i);
    _shuffle_indices.shuffle(Random());
    _shuffle_position = 0;
    debugPrint('SlideshowAudioService: Generated shuffle indices: $_shuffle_indices');
  }

  /// Skip to next song
  Future<void> next() async {
    if (!_is_initialized || _audio_sources.isEmpty) return;

    // Ensure playlist exists before navigating
    if (_playlist == null) {
      debugPrint('SlideshowAudioService: Playlist not ready yet, creating now');
      await _create_playlist();
    }

    try {
      debugPrint('SlideshowAudioService: next() called - shuffle: $_is_shuffle_enabled, current: $_current_index, total: ${_audio_sources.length}');

      if (_is_shuffle_enabled) {
        // Use our manual shuffle indices
        _shuffle_position = (_shuffle_position + 1) % _shuffle_indices.length;
        final int next_index = _shuffle_indices[_shuffle_position];
        debugPrint('SlideshowAudioService: Shuffle next, position=$_shuffle_position, seeking to index $next_index');
        await _audio_player.seek(Duration.zero, index: next_index);
      } else {
        // Sequential order - manual index calculation
        final int next_index = (_current_index + 1) % _audio_sources.length;
        debugPrint('SlideshowAudioService: Sequential next, seeking to index $next_index');
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

    // Ensure playlist exists before navigating
    if (_playlist == null) {
      debugPrint('SlideshowAudioService: Playlist not ready yet, creating now');
      await _create_playlist();
    }

    try {
      debugPrint('SlideshowAudioService: previous() called - shuffle: $_is_shuffle_enabled, current: $_current_index, total: ${_audio_sources.length}');

      if (_is_shuffle_enabled) {
        // Use our manual shuffle indices
        _shuffle_position = (_shuffle_position - 1 + _shuffle_indices.length) % _shuffle_indices.length;
        final int prev_index = _shuffle_indices[_shuffle_position];
        debugPrint('SlideshowAudioService: Shuffle previous, position=$_shuffle_position, seeking to index $prev_index');
        await _audio_player.seek(Duration.zero, index: prev_index);
      } else {
        // Sequential order - manual index calculation
        final int prev_index = (_current_index - 1 + _audio_sources.length) % _audio_sources.length;
        debugPrint('SlideshowAudioService: Sequential previous, seeking to index $prev_index');
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

  /// Toggle shuffle mode
  Future<void> toggle_shuffle() async {
    // Ensure playlist exists before toggling shuffle
    if (_playlist == null && _audio_sources.isNotEmpty) {
      debugPrint('SlideshowAudioService: Playlist not ready yet, creating now');
      await _create_playlist();
    }

    _is_shuffle_enabled = !_is_shuffle_enabled;

    if (_is_shuffle_enabled) {
      // Generate our own shuffle indices since just_audio's shuffle doesn't work on web
      _generate_shuffle_indices();

      // Find current song position in shuffle order
      _shuffle_position = _shuffle_indices.indexOf(_current_index);
      if (_shuffle_position < 0) _shuffle_position = 0;

      debugPrint('SlideshowAudioService: Shuffle enabled, indices: $_shuffle_indices, starting at position $_shuffle_position');
    } else {
      // Clear shuffle indices when disabled
      _shuffle_indices.clear();
      _shuffle_position = 0;
      debugPrint('SlideshowAudioService: Shuffle disabled');
    }

    _emit_state();
  }

  /// Set shuffle mode
  Future<void> set_shuffle(bool enabled) async {
    if (_is_shuffle_enabled == enabled) return;

    _is_shuffle_enabled = enabled;

    if (_is_shuffle_enabled) {
      _generate_shuffle_indices();
      _shuffle_position = _shuffle_indices.indexOf(_current_index);
      if (_shuffle_position < 0) _shuffle_position = 0;
    } else {
      _shuffle_indices.clear();
      _shuffle_position = 0;
    }
    _emit_state();
  }

  /// Toggle loop mode: Loop All -> Loop One -> No Loop -> Loop All
  Future<void> toggle_loop() async {
    switch (_loop_mode) {
      case LoopMode.all:
        _loop_mode = LoopMode.one;
        break;
      case LoopMode.one:
        _loop_mode = LoopMode.off;
        break;
      case LoopMode.off:
        _loop_mode = LoopMode.all;
        break;
    }

    await _audio_player.setLoopMode(_loop_mode);
    debugPrint('SlideshowAudioService: Loop mode changed to $_loop_mode');
    _emit_state();
  }

  /// Set loop mode
  Future<void> set_loop_mode(LoopMode mode) async {
    if (_loop_mode == mode) return;

    _loop_mode = mode;
    await _audio_player.setLoopMode(_loop_mode);
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
        is_shuffle_enabled: _is_shuffle_enabled,
        loop_mode: _loop_mode,
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
    _is_shuffle_enabled = false;
    _loop_mode = LoopMode.all;
    _initialization_future = null;
    _audio_sources.clear();
    _song_urls.clear();
    _playlist = null;
    _current_index = 0;
    _shuffle_indices.clear();
    _shuffle_position = 0;
    _emit_state();
  }
}

/// State class representing the current state of the audio service
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

  @override
  String toString() {
    return 'SlideshowAudioState(is_playing: $is_playing, is_muted: $is_muted, '
        'is_loading: $is_loading, is_shuffle_enabled: $is_shuffle_enabled, '
        'loop_mode: $loop_mode, current_index: $current_index/$total_songs)';
  }
}
