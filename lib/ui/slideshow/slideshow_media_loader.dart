import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_view.dart';
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
  static const int max_active_videos_web = 2;
  static const int max_cached_images_per_orientation = 5;

  // Reduced initial load counts for lazy loading
  static const int max_initial_images = 6;
  static const int max_initial_videos = 2;

  /// Load a single image and categorize by orientation
  Future<void> load_single_image({
    required String url,
  }) async {
    // Check if already loaded
    if (loaded_images_cache.containsKey(url)) return;

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
    } catch (e) {
      debugPrint('Slideshow: Error loading image: $e');
    }
  }

  /// Load a single video controller on demand
  Future<VideoPlayerController?> load_video_controller({
    required String url,
    required bool is_portrait,
  }) async {
    // Check if already loaded
    if (active_video_controllers.containsKey(url)) {
      return active_video_controllers[url];
    }

    // On web, enforce maximum active videos
    if (kIsWeb && active_video_controllers.length >= max_active_videos_web) {
      // Dispose oldest controller to make room
      await dispose_oldest_video_controller();
    }

    try {
      final VideoPlayerController controller =
          VideoPlayerController.networkUrl(Uri.parse(url));

      await controller.initialize();
      await controller.setVolume(0); // Always muted - background music handles audio
      await controller.setLooping(true);
      await controller.play();

      active_video_controllers[url] = controller;

      // Add to appropriate list for backward compatibility
      if (is_portrait) {
        portrait_video_player_controllers.add(controller);
      } else {
        landscape_video_player_controllers.add(controller);
      }

      debugPrint(
        'Slideshow: Loaded video controller for $url '
        '(total: ${active_video_controllers.length})'
      );
      return controller;
    } catch (e) {
      debugPrint('Slideshow: Error loading video controller: $e');
      return null;
    }
  }

  /// Dispose the oldest video controller to free memory
  Future<void> dispose_oldest_video_controller() async {
    if (active_video_controllers.isEmpty) return;

    final String oldest_url = active_video_controllers.keys.first;
    final VideoPlayerController? controller =
        active_video_controllers.remove(oldest_url);

    if (controller != null) {
      // Remove from backward compatibility lists
      portrait_video_player_controllers.remove(controller);
      landscape_video_player_controllers.remove(controller);

      await controller.dispose();
      debugPrint('Slideshow: Disposed video controller for $oldest_url');
    }
  }

  /// Request to load a video for a specific carousel position
  /// Called by slideshow_view when carousel advances to a video slot
  Future<void> request_video_load({
    required int index,
    required bool is_portrait,
  }) async {
    final List<String> urls =
        is_portrait ? portrait_video_urls : landscape_video_urls;
    if (index < 0 || index >= urls.length) return;

    final String url = urls[index];
    await load_video_controller(url: url, is_portrait: is_portrait);

    if (mounted) setState(() {});
  }

  /// Request to load an image for a specific carousel position
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
    await load_single_image(url: url);

    // Clean up cache if too large
    cleanup_image_cache();

    if (mounted) setState(() {});
  }

  /// Clean up image cache to prevent memory bloat
  void cleanup_image_cache() {
    // For all orientations
    final int max_cache_size = max_cached_images_per_orientation * 3;

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
}
