import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

/// Manages caching of audio files for the slideshow audio service.
///
/// On web, songs are streamed directly.
/// On mobile/desktop, songs are downloaded to a local cache for better performance.
class SlideshowAudioCache {
  final Map<String, String> _cached_paths = {};

  /// Get cached file path if exists.
  Future<String?> get_cached_path(String url, int index) async {
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
      final String file_path =
          '${cache_dir.path}/slideshow_songs/$cache_key.mp3';
      final File file = File(file_path);

      if (await file.exists()) {
        _cached_paths[cache_key] = file_path;
        return file_path;
      }
    } catch (e) {
      debugPrint('SlideshowAudioCache: Error checking cache: $e');
    }

    return null;
  }

  /// Download song and save to cache.
  Future<String?> download_and_cache(String url, int index) async {
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
        debugPrint('SlideshowAudioCache: Cached song $index');
        return file_path;
      }
    } catch (e) {
      debugPrint('SlideshowAudioCache: Error downloading song $index: $e');
    }

    return null;
  }

  /// Create an audio source for the given URL and index.
  /// Uses cached file if available, otherwise streams from network.
  Future<AudioSource> create_audio_source({
    required String url,
    required int index,
  }) async {
    // For web, use network URL directly
    if (kIsWeb) {
      return AudioSource.uri(Uri.parse(url), tag: 'song_$index');
    }

    // For mobile/desktop, check cache first
    final String? cached_path = await get_cached_path(url, index);

    if (cached_path != null) {
      return AudioSource.file(cached_path, tag: 'song_$index');
    }

    // Download and cache the song
    final String? downloaded_path = await download_and_cache(url, index);

    if (downloaded_path != null) {
      return AudioSource.file(downloaded_path, tag: 'song_$index');
    }

    // Fallback to streaming
    return AudioSource.uri(Uri.parse(url), tag: 'song_$index');
  }

  /// Clear all cached paths (does not delete files).
  void clear() {
    _cached_paths.clear();
  }
}
