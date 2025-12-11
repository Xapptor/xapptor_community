import 'dart:async';
import 'dart:ui' as ui;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_media_loader.dart';

/// Cached content data for sharing between State instances.
class _CachedContentData {
  final List<String> image_urls;
  final List<String> video_urls;
  final List<String> portrait_image_urls;
  final List<String> landscape_image_urls;
  final List<String> all_image_urls;
  final List<String> portrait_video_urls;
  final List<String> landscape_video_urls;
  final Map<String, Image> loaded_images_cache;
  final List<Image> all_images;
  final List<Image> portrait_images;
  final List<Image> landscape_images;

  _CachedContentData({
    required this.image_urls,
    required this.video_urls,
    required this.portrait_image_urls,
    required this.landscape_image_urls,
    required this.all_image_urls,
    required this.portrait_video_urls,
    required this.landscape_video_urls,
    required this.loaded_images_cache,
    required this.all_images,
    required this.portrait_images,
    required this.landscape_images,
  });
}

/// Mixin that handles loading content from Firebase Storage for the slideshow.
///
/// Uses batched URL fetching to prevent network congestion and improve
/// initial load performance.
///
/// TODO: VIDEO UPLOAD - FAST-START OPTIMIZATION (CRITICAL FOR PERFORMANCE)
/// =========================================================================
/// When implementing user video uploads (mobile app), videos MUST be processed
/// with FFmpeg "fast-start" before uploading to Firebase Storage.
///
/// WHY: Without fast-start, the "moov" atom (metadata with video dimensions)
/// is at the END of the file. This forces VideoMetadataExtractor to download
/// the ENTIRE video just to check orientation, causing:
/// - 18+ seconds delay for 6 videos vs ~0.6 seconds with fast-start
/// - Excessive memory usage on iOS Safari (can cause crashes)
///
/// HOW TO IMPLEMENT (Mobile only - not possible on web):
/// 1. Add dependency: ffmpeg_kit_flutter: ^6.0.3
/// 2. Before uploading, process the video:
///
///    import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
///
///    Future<String?> addFastStart(String inputPath, String outputPath) async {
///      final session = await FFmpegKit.execute(
///        '-i "$inputPath" -c copy -movflags +faststart "$outputPath"'
///      );
///      final returnCode = await session.getReturnCode();
///      if (returnCode?.isValueSuccess() ?? false) {
///        return outputPath;  // Upload this file to Firebase
///      }
///      return null;
///    }
///
/// 3. Upload the processed file (outputPath) to Firebase Storage
///
/// MANUAL CONVERSION (for existing videos):
///    ffmpeg -i input.mp4 -c copy -movflags +faststart output.mp4
///
/// This is LOSSLESS and FAST (just moves bytes, no re-encoding).
/// =========================================================================
mixin SlideshowContentLoaderMixin<T extends StatefulWidget>
    on State<T>, SlideshowMediaLoaderMixin<T> {
  final Reference image_storage_ref =
      FirebaseStorage.instance.ref('app/example_photos');
  final Reference video_storage_ref =
      FirebaseStorage.instance.ref('app/example_videos');

  List<String> image_urls = [];
  List<String> video_urls = [];

  bool is_content_initialized = false;
  bool _is_loading_content = false;

  /// Static set to track which storage paths are currently being loaded across ALL instances.
  /// This prevents duplicate loading when widget tree changes cause State recreation.
  static final Set<String> _globally_loading_paths = {};

  /// Static set to track which storage paths have been fully initialized.
  /// This prevents re-initialization when widget rebuilds create new State objects.
  static final Set<String> _globally_initialized_paths = {};

  /// Static cache of loaded content data, keyed by content_key.
  /// When a new State is created while content was already loaded,
  /// this allows copying the loaded data to the new instance.
  static final Map<String, _CachedContentData> _globally_cached_content = {};

  /// Maximum number of content caches to keep. Prevents unbounded memory growth
  /// when navigating between different slideshow instances.
  /// Reduced to 1 for iOS Safari memory constraints - each cache holds decoded images.
  static const int _max_cached_content_entries = 1;

  /// Batch size for URL fetching to prevent network congestion.
  static const int _url_fetch_batch_size = 5;

  /// Delay between URL fetch batches to avoid overwhelming the network.
  static const Duration _url_fetch_batch_delay = Duration(milliseconds: 100);

  /// Load content from Firebase Storage or local paths.
  /// Guards against duplicate calls during initialization using both instance AND static flags.
  /// Static flags prevent duplicate loading when Flutter recreates State objects.
  Future<void> load_content({
    required bool use_examples,
    required List<String>? image_paths,
    required List<String>? video_paths,
  }) async {
    // Create a unique key for this content source
    final String content_key = use_examples
        ? 'examples:${image_storage_ref.fullPath}'
        : 'local:${image_paths?.length ?? 0}:${video_paths?.length ?? 0}';

    // Check GLOBAL static flags first (survives State recreation)
    if (_globally_initialized_paths.contains(content_key)) {
      debugPrint('Slideshow: Already globally initialized for $content_key, restoring from cache');
      _restore_from_cache(content_key);
      is_content_initialized = true;
      if (mounted) setState(() {});
      return;
    }

    if (_globally_loading_paths.contains(content_key)) {
      debugPrint('Slideshow: Content is being loaded by another instance for $content_key, waiting...');
      // Wait for the other instance to finish loading, then restore from cache
      await _wait_for_loading_to_complete(content_key);
      if (_globally_initialized_paths.contains(content_key)) {
        debugPrint('Slideshow: Loading completed, restoring from cache');
        _restore_from_cache(content_key);
        is_content_initialized = true;
        if (mounted) setState(() {});
      }
      return;
    }

    // Also check instance flags (for same-instance duplicate calls)
    if (is_content_initialized || _is_loading_content) {
      debugPrint('Slideshow: Skipping duplicate load_content call '
          '(initialized: $is_content_initialized, loading: $_is_loading_content)');
      return;
    }

    // Mark as loading in both instance and global scope
    _is_loading_content = true;
    _globally_loading_paths.add(content_key);

    if (use_examples) {
      await _load_example_urls();
    }

    try {
      await _categorize_and_load_content(
        use_examples: use_examples,
        image_paths: image_paths,
        video_paths: video_paths,
      );

      is_content_initialized = true;
      _globally_initialized_paths.add(content_key);
      _save_to_cache(content_key);
    } finally {
      _is_loading_content = false;
      _globally_loading_paths.remove(content_key);
    }
    if (mounted) setState(() {});
  }

  /// Save current content data to the global cache.
  /// Enforces maximum cache size to prevent unbounded memory growth.
  void _save_to_cache(String content_key) {
    // Enforce maximum cache size before adding new entry
    _enforce_cache_limit();

    _globally_cached_content[content_key] = _CachedContentData(
      image_urls: List.from(image_urls),
      video_urls: List.from(video_urls),
      portrait_image_urls: List.from(portrait_image_urls),
      landscape_image_urls: List.from(landscape_image_urls),
      all_image_urls: List.from(all_image_urls),
      portrait_video_urls: List.from(portrait_video_urls),
      landscape_video_urls: List.from(landscape_video_urls),
      loaded_images_cache: Map.from(loaded_images_cache),
      all_images: List.from(all_images),
      portrait_images: List.from(portrait_images),
      landscape_images: List.from(landscape_images),
    );
    debugPrint('Slideshow: Saved content to cache for $content_key');
  }

  /// Enforce maximum cache size by removing oldest entries.
  /// This prevents unbounded memory growth when navigating between slideshows.
  /// Also evicts images from Flutter's internal cache to free GPU memory.
  void _enforce_cache_limit() {
    while (_globally_cached_content.length >= _max_cached_content_entries) {
      // Remove the oldest entry (first key in insertion order)
      final oldest_key = _globally_cached_content.keys.first;
      final oldest_cache = _globally_cached_content.remove(oldest_key);
      _globally_initialized_paths.remove(oldest_key);

      // CRITICAL: Evict images from Flutter's internal cache to free GPU memory
      // Without this, decoded image bitmaps remain in memory even after removal
      if (oldest_cache != null) {
        for (final url in oldest_cache.loaded_images_cache.keys) {
          _evict_image_from_flutter_cache(url);
        }
      }

      debugPrint('Slideshow: Evicted oldest cache entry: $oldest_key');
    }
  }

  /// Evict an image from Flutter's internal image cache.
  /// This is critical for iOS Safari memory management.
  static void _evict_image_from_flutter_cache(String url) {
    try {
      final NetworkImage provider = NetworkImage(url);
      PaintingBinding.instance.imageCache.evict(provider);
    } catch (e) {
      debugPrint('Slideshow: Error evicting image from cache: $e');
    }
  }

  /// Clear all static caches. Call this when the slideshow is permanently disposed
  /// (e.g., when navigating away from the page containing the slideshow).
  /// This is important for iOS Safari memory management.
  static void clear_all_static_caches() {
    // CRITICAL: Evict all images from Flutter's cache before clearing
    for (final cached in _globally_cached_content.values) {
      for (final url in cached.loaded_images_cache.keys) {
        _evict_image_from_flutter_cache(url);
      }
    }

    _globally_loading_paths.clear();
    _globally_initialized_paths.clear();
    _globally_cached_content.clear();
    debugPrint('Slideshow: Cleared all static content caches');
  }

  /// Restore content data from the global cache.
  /// IMPORTANT: Clears existing data before restoring to prevent memory duplication.
  void _restore_from_cache(String content_key) {
    final cached = _globally_cached_content[content_key];
    if (cached == null) {
      debugPrint('Slideshow: No cached data found for $content_key');
      return;
    }

    // CRITICAL: Clear existing data BEFORE restoring to prevent memory duplication
    // Without this, repeated navigation would accumulate duplicate image references
    image_urls.clear();
    video_urls.clear();
    portrait_image_urls.clear();
    landscape_image_urls.clear();
    all_image_urls.clear();
    portrait_video_urls.clear();
    landscape_video_urls.clear();
    loaded_images_cache.clear();
    all_images.clear();
    portrait_images.clear();
    landscape_images.clear();

    // Now restore from cache
    image_urls = List.from(cached.image_urls);
    video_urls = List.from(cached.video_urls);
    portrait_image_urls = List.from(cached.portrait_image_urls);
    landscape_image_urls = List.from(cached.landscape_image_urls);
    all_image_urls = List.from(cached.all_image_urls);
    portrait_video_urls = List.from(cached.portrait_video_urls);
    landscape_video_urls = List.from(cached.landscape_video_urls);
    loaded_images_cache.addAll(cached.loaded_images_cache);
    all_images.addAll(cached.all_images);
    portrait_images.addAll(cached.portrait_images);
    landscape_images.addAll(cached.landscape_images);

    debugPrint('Slideshow: Restored ${all_images.length} images from cache for $content_key');
  }

  /// Wait for another instance to finish loading content.
  /// Polls until the content_key is no longer in the loading set.
  Future<void> _wait_for_loading_to_complete(String content_key) async {
    const poll_interval = Duration(milliseconds: 100);
    const max_wait = Duration(seconds: 30);
    final start_time = DateTime.now();

    while (_globally_loading_paths.contains(content_key)) {
      if (!mounted) return;
      if (DateTime.now().difference(start_time) > max_wait) {
        debugPrint('Slideshow: Timed out waiting for loading to complete');
        return;
      }
      await Future.delayed(poll_interval);
    }
  }

  /// Load example URLs from Firebase Storage using batched fetching.
  ///
  /// Fetches URLs in batches to prevent network congestion and enable
  /// faster initial rendering (starts displaying after first batch).
  Future<void> _load_example_urls() async {
    image_urls.clear();
    video_urls.clear();

    // OPTIMIZATION: Fetch both lists in parallel instead of sequentially.
    // This saves ~200-400ms (one Firebase round-trip).
    final results = await Future.wait([
      image_storage_ref.listAll(),
      video_storage_ref.listAll(),
    ]);
    final ListResult image_list = results[0];
    final ListResult video_list = results[1];

    debugPrint('Slideshow: Found ${image_list.items.length} images and '
        '${video_list.items.length} videos to fetch');

    // Fetch image URLs in batches
    bool first_image_batch_loaded = false;
    for (int i = 0; i < image_list.items.length; i += _url_fetch_batch_size) {
      if (!mounted) return;

      final batch_end = (i + _url_fetch_batch_size).clamp(0, image_list.items.length);
      final batch = image_list.items.sublist(i, batch_end);

      final batch_urls = await Future.wait(
        batch.map((ref) => ref.getDownloadURL()),
      );
      image_urls.addAll(batch_urls);

      // Start categorizing and loading images after first batch
      // This enables faster initial rendering
      if (!first_image_batch_loaded && image_urls.isNotEmpty) {
        first_image_batch_loaded = true;
        debugPrint('Slideshow: First image batch loaded (${batch_urls.length} URLs)');
      }

      // Small delay between batches to avoid network congestion
      if (i + _url_fetch_batch_size < image_list.items.length) {
        await Future.delayed(_url_fetch_batch_delay);
      }
    }

    // Fetch video URLs in smaller batches (videos are larger/slower)
    const video_batch_size = 3;
    for (int i = 0; i < video_list.items.length; i += video_batch_size) {
      if (!mounted) return;

      final batch_end = (i + video_batch_size).clamp(0, video_list.items.length);
      final batch = video_list.items.sublist(i, batch_end);

      final batch_urls = await Future.wait(
        batch.map((ref) => ref.getDownloadURL()),
      );
      video_urls.addAll(batch_urls);

      // Slightly longer delay for video URLs
      if (i + video_batch_size < video_list.items.length) {
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }

    debugPrint('Slideshow: Fetched ${image_urls.length} image URLs and '
        '${video_urls.length} video URLs');
  }

  Future<void> _categorize_and_load_content({
    required bool use_examples,
    required List<String>? image_paths,
    required List<String>? video_paths,
  }) async {
    await _categorize_image_urls(
      use_examples: use_examples,
      image_paths: image_paths,
    );
    await _load_video_urls(
      use_examples: use_examples,
      video_paths: video_paths,
    );
  }

  Future<void> _categorize_image_urls({
    required bool use_examples,
    required List<String>? image_paths,
  }) async {
    portrait_image_urls.clear();
    landscape_image_urls.clear();
    all_image_urls.clear();

    final List<String> paths = use_examples ? image_urls : image_paths ?? [];

    if (paths.isEmpty) return;

    // Shuffle URLs before adding to all_image_urls for randomized display order.
    // This ensures different images appear each time the slideshow starts.
    final List<String> shuffled_paths = List.from(paths)..shuffle();
    all_image_urls.addAll(shuffled_paths);

    // Determine initial image count based on current device orientation.
    // Portrait: 2 columns × 2-3 views = 4-6 slots, minus 2 video slots = 2-4 image slots
    // Landscape: 4 columns × 1-3 views = 4-12 slots, minus 2 video slots = 2-10 image slots
    final ui.FlutterView view = ui.PlatformDispatcher.instance.implicitView!;
    final Size screen_size = view.physicalSize / view.devicePixelRatio;
    final bool is_portrait = screen_size.height > screen_size.width;

    final int max_initial = is_portrait
        ? SlideshowMediaLoaderMixin.max_initial_images_portrait
        : SlideshowMediaLoaderMixin.max_initial_images_landscape;

    final int initial_count =
        shuffled_paths.length > max_initial ? max_initial : shuffled_paths.length;

    for (int i = 0; i < initial_count; i++) {
      await load_single_image(url: shuffled_paths[i]);
    }

    for (final url in paths) {
      if (loaded_images_cache.containsKey(url)) {
        final image = loaded_images_cache[url]!;
        if (landscape_images.contains(image)) {
          landscape_image_urls.add(url);
        } else if (portrait_images.contains(image)) {
          portrait_image_urls.add(url);
        }
      } else {
        landscape_image_urls.add(url);
        portrait_image_urls.add(url);
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> _load_video_urls({
    required bool use_examples,
    required List<String>? video_paths,
  }) async {
    portrait_video_urls.clear();
    landscape_video_urls.clear();

    final List<String> paths =
        use_examples ? video_urls : video_paths ?? const <String>[];

    if (paths.isEmpty) return;

    // First, categorize all videos by checking their orientation
    // This loads each video temporarily just to get dimensions, then disposes
    for (final url in paths) {
      final bool? is_portrait = await check_video_orientation(url);
      if (is_portrait != null) {
        if (is_portrait) {
          portrait_video_urls.add(url);
        } else {
          landscape_video_urls.add(url);
        }
      }
    }

    debugPrint('Slideshow: Categorized videos - ${portrait_video_urls.length} portrait, ${landscape_video_urls.length} landscape');

    // Now load initial videos for each orientation (limited count)
    // Load first portrait video if available
    if (portrait_video_urls.isNotEmpty) {
      await load_video_controller(url: portrait_video_urls[0], is_portrait: true);
    }
    // Load first landscape video if available
    if (landscape_video_urls.isNotEmpty) {
      await load_video_controller(url: landscape_video_urls[0], is_portrait: false);
    }

    if (mounted) setState(() {});
  }
}
