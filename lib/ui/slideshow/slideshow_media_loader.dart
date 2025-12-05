import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:xapptor_community/ui/slideshow/get_slideshow_matrix.dart';
import 'package:xapptor_logic/image/get_image_size.dart';

/// Mixin that handles lazy loading of images and videos for the slideshow.
///
/// Strategy:
/// - Images: Store URLs, load Image objects on-demand (max cache size)
/// - Videos: Store URLs, load VideoPlayerController on-demand (max 2 on web)
/// This prevents memory accumulation on web browsers
mixin SlideshowMediaLoaderMixin<T extends StatefulWidget> on State<T> {
  // Image URLs (lazy loaded - only URLs stored initially)
  List<String> portrait_image_urls = [];
  List<String> landscape_image_urls = [];
  List<String> all_image_urls = [];

  // Loaded images cache - Key: URL, Value: Image widget
  final Map<String, Image> loaded_images_cache = {};

  // For backward compatibility with slideshow_view
  List<Image> landscape_images = [];
  List<Image> portrait_images = [];
  List<Image> all_images = [];

  // Video URLs (lazy loaded)
  List<String> portrait_video_urls = [];
  List<String> landscape_video_urls = [];

  // Active video controllers - only 2 at a time on web
  // Key: URL, Value: VideoPlayerController
  final Map<String, VideoPlayerController> active_video_controllers = {};

  // For backward compatibility
  List<VideoPlayerController> portrait_video_player_controllers = [];
  List<VideoPlayerController> landscape_video_player_controllers = [];

  // Maximum active videos/images on web to prevent memory issues
  // Keep this LOW to prevent iOS Safari crashes
  static const int max_active_videos_web = 2;
  static const int max_cached_images_per_orientation = 5;

  // Initial load counts
  static const int max_initial_images = 6;
  static const int max_initial_videos = 2;

  // Track video orientations separately from controllers (URL -> is_portrait)
  final Map<String, bool> video_orientation_cache = {};

  /// Load a single image and categorize by orientation.
  /// Returns true if a new image was loaded, false if already cached.
  Future<bool> load_single_image({
    required String url,
  }) async {
    // Check if already loaded
    if (loaded_images_cache.containsKey(url)) return false;

    try {
      final Image current_image = Image.network(url);
      final Size size = await get_image_size(image: current_image);

      loaded_images_cache[url] = current_image;

      // Add to appropriate lists for backward compatibility
      if (size.width >= size.height) {
        if (!landscape_images.contains(current_image)) {
          landscape_images.add(current_image);
        }
      } else {
        if (!portrait_images.contains(current_image)) {
          portrait_images.add(current_image);
        }
      }
      if (!all_images.contains(current_image)) {
        all_images.add(current_image);
      }
      return true;
    } catch (e) {
      debugPrint('Slideshow: Error loading image: $e');
      return false;
    }
  }

  /// Load a single video controller on demand.
  /// Videos are categorized by their actual aspect ratio:
  /// - Portrait videos (height > width) go to portrait_video_player_controllers
  /// - Landscape videos (width >= height) go to landscape_video_player_controllers
  /// The is_portrait parameter indicates which SLOT is requesting the video.
  /// Returns a record with the controller and whether it was newly loaded.
  Future<({VideoPlayerController? controller, bool did_load})> load_video_controller({
    required String url,
    required bool is_portrait,
  }) async {
    // Check if already loaded
    if (active_video_controllers.containsKey(url)) {
      return (controller: active_video_controllers[url], did_load: false);
    }

    // On web, enforce maximum active videos - dispose oldest OF THE SAME ORIENTATION
    // This prevents disposing the video from the other slot that's currently displayed
    if (kIsWeb && active_video_controllers.length >= max_active_videos_web) {
      await dispose_oldest_video_controller_for_orientation(is_portrait: is_portrait);
    }

    try {
      final VideoPlayerController controller = VideoPlayerController.networkUrl(Uri.parse(url));

      await controller.initialize();
      await controller.setVolume(0); // Always muted - background music handles audio
      await controller.setLooping(true);
      await controller.play();

      active_video_controllers[url] = controller;

      // Categorize by the video's ACTUAL aspect ratio
      final video_width = controller.value.size.width;
      final video_height = controller.value.size.height;
      final bool video_is_portrait = video_height > video_width;

      // Cache the orientation for future reference
      video_orientation_cache[url] = video_is_portrait;

      // Add to the appropriate controller list based on video's actual orientation
      if (video_is_portrait) {
        if (!portrait_video_player_controllers.contains(controller)) {
          portrait_video_player_controllers.add(controller);
        }
        debugPrint('Slideshow: Loaded PORTRAIT video for $url '
            '(${video_width.toInt()}x${video_height.toInt()})');
      } else {
        if (!landscape_video_player_controllers.contains(controller)) {
          landscape_video_player_controllers.add(controller);
        }
        debugPrint('Slideshow: Loaded LANDSCAPE video for $url '
            '(${video_width.toInt()}x${video_height.toInt()})');
      }

      return (controller: controller, did_load: true);
    } catch (e) {
      debugPrint('Slideshow: Error loading video controller: $e');
      return (controller: null, did_load: false);
    }
  }

  /// Check video orientation without keeping controller loaded (for categorization)
  Future<bool?> check_video_orientation(String url) async {
    // Return cached orientation if available
    if (video_orientation_cache.containsKey(url)) {
      return video_orientation_cache[url];
    }

    try {
      final VideoPlayerController temp_controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await temp_controller.initialize();

      final video_width = temp_controller.value.size.width;
      final video_height = temp_controller.value.size.height;
      final bool is_portrait = video_height > video_width;

      // Cache the result
      video_orientation_cache[url] = is_portrait;

      // Dispose immediately - we only needed the dimensions
      await temp_controller.dispose();

      debugPrint('Slideshow: Checked orientation for $url: ${is_portrait ? "PORTRAIT" : "LANDSCAPE"} '
          '(${video_width.toInt()}x${video_height.toInt()})');

      return is_portrait;
    } catch (e) {
      debugPrint('Slideshow: Error checking video orientation: $e');
      return null;
    }
  }

  /// Dispose the oldest video controller of a specific orientation to free memory.
  /// This ensures we don't accidentally dispose the video from the OTHER orientation
  /// that's currently being displayed.
  Future<void> dispose_oldest_video_controller_for_orientation({
    required bool is_portrait,
  }) async {
    if (active_video_controllers.isEmpty) return;

    // Find the oldest video URL of the requested orientation
    String? url_to_dispose;
    for (final url in active_video_controllers.keys) {
      final bool? video_is_portrait = video_orientation_cache[url];
      if (video_is_portrait == is_portrait) {
        url_to_dispose = url;
        break; // First match is the oldest (Map preserves insertion order)
      }
    }

    // If no video of the same orientation found, dispose the oldest regardless
    // This handles edge cases where we only have videos of one orientation
    url_to_dispose ??= active_video_controllers.keys.first;

    final VideoPlayerController? controller = active_video_controllers.remove(url_to_dispose);

    if (controller != null) {
      // Remove from backward compatibility lists
      portrait_video_player_controllers.remove(controller);
      landscape_video_player_controllers.remove(controller);

      await controller.dispose();
      debugPrint('Slideshow: Disposed ${is_portrait ? "portrait" : "landscape"} '
          'video controller for $url_to_dispose');
    }
  }

  /// Request to load a video for a specific carousel position.
  /// Called by slideshow_view when carousel advances to a video slot.
  /// Only calls setState if a new video was actually loaded.
  Future<void> request_video_load({
    required int index,
    required bool is_portrait,
  }) async {
    final List<String> urls = is_portrait ? portrait_video_urls : landscape_video_urls;
    if (index < 0 || index >= urls.length) return;

    final String url = urls[index];
    final result = await load_video_controller(url: url, is_portrait: is_portrait);

    // Only rebuild if we actually loaded a new video
    if (result.did_load && mounted) setState(() {});
  }

  /// Request to load an image for a specific carousel position.
  /// Only calls setState if a new image was actually loaded.
  Future<void> request_image_load({
    required int index,
    required SlideshowViewOrientation orientation,
  }) async {
    List<String> urls;
    switch (orientation) {
      case SlideshowViewOrientation.portrait:
        urls = portrait_image_urls;
        break;
      case SlideshowViewOrientation.landscape:
        urls = landscape_image_urls;
        break;
      case SlideshowViewOrientation.square_or_similar:
        urls = all_image_urls;
        break;
    }

    if (index < 0 || index >= urls.length) return;

    final String url = urls[index];
    final bool did_load = await load_single_image(url: url);

    // Clean up cache if too large
    cleanup_image_cache();

    // Only rebuild if we actually loaded a new image
    if (did_load && mounted) setState(() {});
  }

  /// Clean up image cache to prevent memory bloat
  void cleanup_image_cache() {
    // For all orientations
    const int max_cache_size = max_cached_images_per_orientation * 3;

    if (loaded_images_cache.length > max_cache_size) {
      // Remove oldest entries (first added)
      final int to_remove = loaded_images_cache.length - max_cache_size;
      final keys_to_remove = loaded_images_cache.keys.take(to_remove).toList();

      for (final key in keys_to_remove) {
        final image = loaded_images_cache.remove(key);
        landscape_images.remove(image);
        portrait_images.remove(image);
        all_images.remove(image);
      }

      debugPrint('Slideshow: Cleaned up $to_remove images from cache');
    }
  }

  /// Dispose all media resources
  void dispose_media_resources() {
    // Dispose all active video controllers
    for (var controller in active_video_controllers.values) {
      controller.dispose();
    }
    active_video_controllers.clear();
    portrait_video_player_controllers.clear();
    landscape_video_player_controllers.clear();
    video_orientation_cache.clear();

    // Clear image cache
    loaded_images_cache.clear();
    landscape_images.clear();
    portrait_images.clear();
    all_images.clear();
  }

  /// Handler for lazy loading requests from slideshow_view
  Future<void> handle_lazy_load_request({
    required int index,
    required bool is_video,
    required bool is_portrait,
    required SlideshowViewOrientation orientation,
  }) async {
    if (is_video) {
      await request_video_load(index: index, is_portrait: is_portrait);
    } else {
      await request_image_load(index: index, orientation: orientation);
    }
  }

  /// Get a video controller by URL index (not by controller list index).
  /// This correctly maps carousel index → URL → controller.
  /// Returns null if the video at that index hasn't been loaded yet.
  VideoPlayerController? get_video_controller_by_index({
    required int index,
    required bool is_portrait,
  }) {
    final List<String> urls = is_portrait ? portrait_video_urls : landscape_video_urls;
    if (index < 0 || index >= urls.length) return null;

    final String url = urls[index];
    return active_video_controllers[url];
  }

  /// Get an image by URL index (not by loaded image list index).
  /// This correctly maps carousel index → URL → cached Image.
  /// The index is wrapped using modulo to cycle through all images.
  /// Returns null if the image at that index hasn't been loaded yet.
  Image? get_image_by_index({
    required int index,
    required SlideshowViewOrientation orientation,
  }) {
    List<String> urls;
    switch (orientation) {
      case SlideshowViewOrientation.portrait:
        urls = portrait_image_urls;
        break;
      case SlideshowViewOrientation.landscape:
        urls = landscape_image_urls;
        break;
      case SlideshowViewOrientation.square_or_similar:
        urls = all_image_urls;
        break;
    }

    if (urls.isEmpty) return null;

    // Use modulo to wrap the index and cycle through all images
    final int wrapped_index = index % urls.length;
    final String url = urls[wrapped_index];
    return loaded_images_cache[url];
  }
}
