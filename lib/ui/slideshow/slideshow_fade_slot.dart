import 'dart:math';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:xapptor_community/ui/slideshow/get_slideshow_matrix.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_timer_coordinator.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_view_item.dart';
import 'package:xapptor_ui/values/ui.dart';

/// Callback type for lazy loading requests
typedef OnLazyLoadRequest = Future<void> Function({
  required int index,
  required bool is_video,
  required bool is_portrait,
  required SlideshowViewOrientation orientation,
});

/// Callback type for getting a video controller by URL index
typedef GetVideoControllerByIndex = VideoPlayerController? Function({
  required int index,
  required bool is_portrait,
});

/// Callback type for getting an image by URL index
typedef GetImageByIndex = Image? Function({
  required int index,
  required SlideshowViewOrientation orientation,
});

/// A lightweight slideshow slot that uses AnimatedSwitcher with FadeTransition
/// instead of CarouselSlider.
///
/// Memory savings vs CarouselSlider:
/// - No PageController (~2-3 MB per instance with GPU textures)
/// - No TickerProviderStateMixin overhead
/// - No GestureRecognizer (we don't need gestures anyway)
/// - Single coordinated Timer instead of per-slot Timer
///
/// This widget displays one item at a time and fades to the next item
/// when the coordinator triggers an advance.
class SlideshowFadeSlot extends StatefulWidget {
  final int column_index;
  final int view_index;
  final SlideshowViewOrientation slideshow_view_orientation;
  final int item_count;
  final bool possible_video_position_for_portrait;
  final bool possible_video_position_for_landscape;
  final List<VideoPlayerController> portrait_video_player_controllers;
  final List<VideoPlayerController> landscape_video_player_controllers;
  final double screen_width;
  final int number_of_columns;
  final Duration animation_duration;
  final Curve animation_curve;
  final bool test_mode;
  final bool portrait;
  final List<List<Map<String, dynamic>>> slideshow_matrix;
  final List<Image> portrait_images;
  final List<Image> landscape_images;
  final List<Image> all_images;

  /// Shared timer coordinator (single instance for all slots)
  final SlideshowTimerCoordinator timer_coordinator;

  /// Callback to request lazy loading of the next item
  final OnLazyLoadRequest? on_lazy_load_request;

  /// Callback to get a video controller by URL index
  final GetVideoControllerByIndex? get_video_controller_by_index;

  /// Callback to get an image by URL index
  final GetImageByIndex? get_image_by_index;

  /// Total number of items available (including not-yet-loaded)
  final int total_video_count;
  final int total_image_count;

  const SlideshowFadeSlot({
    required this.column_index,
    required this.view_index,
    required this.slideshow_view_orientation,
    required this.item_count,
    required this.possible_video_position_for_portrait,
    required this.possible_video_position_for_landscape,
    required this.portrait_video_player_controllers,
    required this.landscape_video_player_controllers,
    required this.screen_width,
    required this.number_of_columns,
    required this.animation_duration,
    required this.animation_curve,
    required this.test_mode,
    required this.portrait,
    required this.slideshow_matrix,
    required this.portrait_images,
    required this.landscape_images,
    required this.all_images,
    required this.timer_coordinator,
    this.on_lazy_load_request,
    this.get_video_controller_by_index,
    this.get_image_by_index,
    this.total_video_count = 0,
    this.total_image_count = 0,
    super.key,
  });

  @override
  State<SlideshowFadeSlot> createState() => _SlideshowFadeSlotState();
}

class _SlideshowFadeSlotState extends State<SlideshowFadeSlot> {
  late String _slot_id;
  int _current_index = 0;

  /// Unique key for AnimatedSwitcher to detect changes
  int _switch_key = 0;

  /// Random instance for video start position (reused to avoid allocation)
  static final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _slot_id = 'slot_${widget.column_index}_${widget.view_index}';
    _register_with_coordinator();

    // Trigger initial lazy load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _on_index_changed(_current_index);
    });
  }

  @override
  void didUpdateWidget(covariant SlideshowFadeSlot oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update coordinator if item count changed
    if (oldWidget.item_count != widget.item_count) {
      widget.timer_coordinator.update_item_count(_slot_id, widget.item_count);
    }
  }

  @override
  void dispose() {
    widget.timer_coordinator.unregister_slot(_slot_id);
    super.dispose();
  }

  void _register_with_coordinator() {
    final bool is_video_slot = widget.possible_video_position_for_portrait ||
        widget.possible_video_position_for_landscape;

    // Video slots: 15-25 seconds, Image slots: 3-7 seconds
    final int min_seconds = is_video_slot ? 15 : 3;
    final int max_seconds = is_video_slot ? 25 : 7;

    widget.timer_coordinator.register_slot(
      slot_id: _slot_id,
      min_interval_seconds: min_seconds,
      max_interval_seconds: max_seconds,
      on_advance: _handle_advance,
      item_count: widget.item_count > 0 ? widget.item_count : 1,
    );
  }

  void _handle_advance(int new_index) {
    if (!mounted) return;

    setState(() {
      _current_index = new_index;
      _switch_key++; // Force AnimatedSwitcher to animate
    });

    _on_index_changed(new_index);
  }

  Future<void> _on_index_changed(int index) async {
    final bool is_video_slot = widget.possible_video_position_for_portrait ||
        widget.possible_video_position_for_landscape;

    if (is_video_slot) {
      await _handle_video_change(index);
    } else {
      await _handle_image_change(index);
    }
  }

  Future<void> _handle_video_change(int index) async {
    // Use URL-based lookup to check if current video is loaded
    VideoPlayerController? current_controller;
    if (widget.get_video_controller_by_index != null) {
      current_controller = widget.get_video_controller_by_index!(
        index: index,
        is_portrait: widget.possible_video_position_for_portrait,
      );
    }

    // Request lazy loading of CURRENT video if not loaded
    if (widget.on_lazy_load_request != null && widget.total_video_count > 0) {
      if (current_controller == null) {
        await widget.on_lazy_load_request!(
          index: index,
          is_video: true,
          is_portrait: widget.possible_video_position_for_portrait,
          orientation: widget.slideshow_view_orientation,
        );

        // After loading, get the controller again
        if (widget.get_video_controller_by_index != null) {
          current_controller = widget.get_video_controller_by_index!(
            index: index,
            is_portrait: widget.possible_video_position_for_portrait,
          );
        }

        // Force rebuild to show the newly loaded video
        if (mounted) setState(() {});
      }
    }

    if (current_controller == null) return;

    // Pause and reset ALL other videos to release Safari decoder buffers
    final controllers = widget.possible_video_position_for_portrait
        ? widget.portrait_video_player_controllers
        : widget.landscape_video_player_controllers;

    for (int i = 0; i < controllers.length; i++) {
      final controller = controllers[i];
      if (controller != current_controller) {
        controller.pause();
        controller.seekTo(Duration.zero);
      }
    }

    // Start playing from a random position
    final int duration_ms = current_controller.value.duration.inMilliseconds;
    if (duration_ms <= 0) return;

    final int max_start = duration_ms - (duration_ms ~/ 10);
    final int random_start = (max_start > 0) ? _random.nextInt(max_start) : 0;

    current_controller.setVolume(0);
    current_controller
      ..seekTo(Duration(milliseconds: random_start))
      ..play();
  }

  Future<void> _handle_image_change(int index) async {
    if (widget.on_lazy_load_request == null || widget.total_image_count <= 0) {
      return;
    }

    // Calculate the view offset for this specific view
    final int views_per_column =
        widget.slideshow_matrix[widget.column_index].length;
    final int view_offset =
        widget.column_index * views_per_column + widget.view_index;

    // Calculate the effective index with view offset
    final int effective_index = index + view_offset;

    // Check if current image is loaded
    Image? current_image;
    if (widget.get_image_by_index != null) {
      current_image = widget.get_image_by_index!(
        index: effective_index,
        orientation: widget.slideshow_view_orientation,
      );
    }

    // Load current image if not yet loaded
    if (current_image == null) {
      await widget.on_lazy_load_request!(
        index: effective_index % widget.total_image_count,
        is_video: false,
        is_portrait: false,
        orientation: widget.slideshow_view_orientation,
      );
      // Force rebuild after loading
      if (mounted) setState(() {});
    }

    // Preload next image (fire-and-forget)
    final int next_effective_index = effective_index + 1;
    widget.on_lazy_load_request!(
      index: next_effective_index % widget.total_image_count,
      is_video: false,
      is_portrait: false,
      orientation: widget.slideshow_view_orientation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final view_config =
        widget.slideshow_matrix[widget.column_index][widget.view_index];
    final SlideshowViewOrientation orientation =
        view_config['orientation'] as SlideshowViewOrientation;
    final double ratio_difference =
        (view_config['ratio_difference'] as num).toDouble();
    final int view_height = (view_config['height'] as num).round();

    return Expanded(
      flex: view_config['flex'] as int,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(outline_border_radius),
          clipBehavior: Clip.hardEdge,
          child: RepaintBoundary(
            child: AnimatedSwitcher(
              duration: widget.animation_duration,
              switchInCurve: widget.animation_curve,
              switchOutCurve: widget.animation_curve,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: _build_current_item(
                key: ValueKey('item_${widget.column_index}_${widget.view_index}_$_switch_key'),
                orientation: orientation,
                ratio_difference: ratio_difference,
                view_height: view_height,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _build_current_item({
    required Key key,
    required SlideshowViewOrientation orientation,
    required double ratio_difference,
    required int view_height,
  }) {
    return build_carousel_item(
      key: key,
      index: _current_index,
      orientation: orientation,
      ratio_difference: ratio_difference,
      view_height: view_height,
      column_index: widget.column_index,
      view_index: widget.view_index,
      possible_video_position_for_portrait:
          widget.possible_video_position_for_portrait,
      possible_video_position_for_landscape:
          widget.possible_video_position_for_landscape,
      portrait_video_player_controllers:
          widget.portrait_video_player_controllers,
      landscape_video_player_controllers:
          widget.landscape_video_player_controllers,
      screen_width: widget.screen_width,
      number_of_columns: widget.number_of_columns,
      views_per_column: widget.slideshow_matrix[widget.column_index].length,
      test_mode: widget.test_mode,
      portrait: widget.portrait,
      portrait_images: widget.portrait_images,
      landscape_images: widget.landscape_images,
      all_images: widget.all_images,
      get_video_controller_by_index: widget.get_video_controller_by_index,
      get_image_by_index: widget.get_image_by_index,
      device_pixel_ratio: MediaQuery.of(context).devicePixelRatio,
    );
  }
}
