import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_media_loader.dart';

/// Mixin that handles loading content from Firebase Storage for the slideshow.
///
/// Uses batched URL fetching to prevent network congestion and improve
/// initial load performance.
mixin SlideshowContentLoaderMixin<T extends StatefulWidget>
    on State<T>, SlideshowMediaLoaderMixin<T> {
  final Reference image_storage_ref =
      FirebaseStorage.instance.ref('app/example_photos');
  final Reference video_storage_ref =
      FirebaseStorage.instance.ref('app/example_videos');

  List<String> image_urls = [];
  List<String> video_urls = [];

  bool is_content_initialized = false;

  /// Batch size for URL fetching to prevent network congestion.
  static const int _url_fetch_batch_size = 5;

  /// Delay between URL fetch batches to avoid overwhelming the network.
  static const Duration _url_fetch_batch_delay = Duration(milliseconds: 100);

  /// Load content from Firebase Storage or local paths.
  Future<void> load_content({
    required bool use_examples,
    required List<String>? image_paths,
    required List<String>? video_paths,
  }) async {
    if (use_examples) {
      await _load_example_urls();
    }

    await _categorize_and_load_content(
      use_examples: use_examples,
      image_paths: image_paths,
      video_paths: video_paths,
    );

    is_content_initialized = true;
    if (mounted) setState(() {});
  }

  /// Load example URLs from Firebase Storage using batched fetching.
  ///
  /// Fetches URLs in batches to prevent network congestion and enable
  /// faster initial rendering (starts displaying after first batch).
  Future<void> _load_example_urls() async {
    image_urls.clear();
    video_urls.clear();

    final ListResult image_list = await image_storage_ref.listAll();
    final ListResult video_list = await video_storage_ref.listAll();

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

    all_image_urls.addAll(paths);

    final int initial_count =
        paths.length > SlideshowMediaLoaderMixin.max_initial_images
            ? SlideshowMediaLoaderMixin.max_initial_images
            : paths.length;

    for (int i = 0; i < initial_count; i++) {
      await load_single_image(url: paths[i]);
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
