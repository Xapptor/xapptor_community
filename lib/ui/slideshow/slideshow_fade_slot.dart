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

/// Callback type for getting the next random image index for a slot.
/// This is called by each slot when it needs to advance to a new image.
/// The parent tracks which indices are in use to avoid duplicates.
typedef GetRandomImageIndex = int Function(String slot_id);

/// Callback type for getting the current image index for a slot.
/// Returns the currently assigned index, or assigns a new random one if not set.
typedef GetCurrentImageIndex = int Function(String slot_id);

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

  /// Callback to get the next random image index (avoiding duplicates across slots)
  final GetRandomImageIndex? get_random_image_index;

  /// Callback to get the current image index for this slot
  final GetCurrentImageIndex? get_current_image_index;

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
    this.get_random_image_index,
    this.get_current_image_index,
    super.key,
  });

  @override
  State<SlideshowFadeSlot> createState() => _SlideshowFadeSlotState();
}

class _SlideshowFadeSlotState extends State<SlideshowFadeSlot> {
  late String _slot_id;

  /// For video slots: sequential index (0, 1, 2...)
  /// For image slots: actual image index from random selection
  int _current_index = 0;

  /// Unique key for AnimatedSwitcher to detect changes
  int _switch_key = 0;

  /// Random instance for video start position (reused to avoid allocation)
  static final Random _random = Random();

  /// Whether this is an image slot (uses random selection)
  bool get _is_image_slot =>
      !widget.possible_video_position_for_portrait &&
      !widget.possible_video_position_for_landscape;

  @override
  void initState() {
    super.initState();
    _slot_id = 'slot_${widget.column_index}_${widget.view_index}';

    // For image slots, get initial random index from parent
    if (_is_image_slot && widget.get_current_image_index != null) {
      _current_index = widget.get_current_image_index!(_slot_id);
    }

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

    // Video slots: 15-25 seconds, Image slots: 6-12 seconds
    // Increased minimum from 5 to 6 seconds to ensure smooth pacing with 2s transition lockout
    final int min_seconds = is_video_slot ? 15 : 6;
    final int max_seconds = is_video_slot ? 25 : 12;

    final int item_count = widget.item_count > 0 ? widget.item_count : 1;

    // IMPORTANT: The coordinator tracks raw indices (0, 1, 2...).
    // The view_offset is applied ONLY at image retrieval time in _build_image_item
    // to ensure each view displays a different image.
    // Starting all slots at index 0 is correct - they'll display different images
    // because view_offset is added when getting the actual image.

    widget.timer_coordinator.register_slot(
      slot_id: _slot_id,
      min_interval_seconds: min_seconds,
      max_interval_seconds: max_seconds,
      on_advance: _handle_advance,
      item_count: item_count,
      initial_index: 0, // All slots start at raw index 0
    );
  }

  /// Flag to prevent concurrent transitions
  bool _is_transitioning = false;

  /// Timestamp of the last transition start.
  /// Used to enforce minimum time between transitions.
  DateTime? _last_transition_time;

  /// Minimum time an image must be VISIBLE before transitioning to the next.
  /// This ensures users have adequate time to see each image.
  /// Set to 4 seconds: animation (1.5s) + 2.5s viewing time minimum.
  /// The timer coordinator uses 6-12 second intervals, but this provides
  /// a hard floor for visibility duration regardless of coordinator timing.
  static const Duration _min_transition_interval = Duration(milliseconds: 4000);

  void _handle_advance(int new_index) {
    if (!mounted) return;

    // Prevent concurrent transitions which can cause animation glitches
    if (_is_transitioning) return;

    // Additional safeguard: enforce minimum time between transitions.
    // _last_transition_time is set when the image BECOMES VISIBLE (in setState),
    // not when the advance is requested. This ensures the user sees the image
    // for at least _min_transition_interval before it can change again.
    final now = DateTime.now();
    if (_last_transition_time != null) {
      final elapsed = now.difference(_last_transition_time!);
      if (elapsed < _min_transition_interval) {
        // Too soon for another transition, ignore this advance
        return;
      }
    }

    _is_transitioning = true;
    // Note: _last_transition_time is set in setState below, not here

    // For image slots, use random selection from parent instead of sequential index.
    // This ensures no two slots display the same image simultaneously.
    int actual_index = new_index;
    if (_is_image_slot && widget.get_random_image_index != null) {
      actual_index = widget.get_random_image_index!(_slot_id);
    }

    // Pre-load the image BEFORE updating state to avoid animation interruption.
    // This ensures the image is ready when AnimatedSwitcher begins the transition.
    _preload_image_for_index(actual_index).then((_) {
      if (!mounted) {
        _is_transitioning = false;
        return;
      }

      // Use WidgetsBinding to schedule the setState after the current frame
      // This ensures proper frame timing for AnimatedSwitcher
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          _is_transitioning = false;
          return;
        }

        // Set _last_transition_time NOW when the image becomes visible,
        // not when the advance was requested. This ensures the user sees
        // the image for at least _min_transition_interval.
        _last_transition_time = DateTime.now();

        setState(() {
          _current_index = actual_index;
          _switch_key++; // Force AnimatedSwitcher to animate
        });

        // Handle video changes after state update (videos need playback control)
        _on_index_changed_post_update(actual_index);

        // Reset transition flag after animation duration plus buffer.
        // The _min_transition_interval check provides additional protection,
        // but we still reset the flag to allow transitions after the interval.
        Future.delayed(widget.animation_duration + const Duration(milliseconds: 500), () {
          _is_transitioning = false;
        });
      });
    });
  }

  /// Pre-loads the image for the given index before the transition starts.
  /// This ensures smooth fade animations without interruption from lazy loading.
  ///
  /// For image slots using random selection, the index is already the actual image index
  /// (no view_offset needed - parent handles duplicate prevention).
  ///
  /// CRITICAL: This method must ensure the image is fully DECODED into GPU memory
  /// before returning. Otherwise, the AnimatedSwitcher will start fading to an
  /// image that's still loading, causing cut-off animations.
  Future<void> _preload_image_for_index(int index) async {
    // Videos don't need preloading here (handled separately)
    if (!_is_image_slot) return;

    if (widget.on_lazy_load_request == null || widget.total_image_count <= 0) {
      return;
    }

    // The index is already the actual image index (from random selection or initial assignment)
    // No need for view_offset - the parent's random selection handles uniqueness

    // Check if current image is loaded
    Image? current_image;
    if (widget.get_image_by_index != null) {
      current_image = widget.get_image_by_index!(
        index: index,
        orientation: widget.slideshow_view_orientation,
      );
    }

    // Load current image if not yet loaded
    if (current_image == null) {
      await widget.on_lazy_load_request!(
        index: index % widget.total_image_count,
        is_video: false,
        is_portrait: false,
        orientation: widget.slideshow_view_orientation,
      );

      // Re-fetch the image after loading
      if (widget.get_image_by_index != null) {
        current_image = widget.get_image_by_index!(
          index: index,
          orientation: widget.slideshow_view_orientation,
        );
      }
    }

    // CRITICAL: Precache the image to ensure it's fully decoded into GPU memory.
    // Without this, the image may still be decoding when AnimatedSwitcher starts,
    // causing the frameBuilder to show placeholder mid-transition (cut-off effect).
    if (current_image != null && mounted) {
      try {
        // Use a completer to properly wait for the image to be fully decoded.
        // precacheImage returns when the image is in the cache, but we want
        // to ensure it's also decoded for the GPU.
        await precacheImage(current_image.image, context);

        // Add a small delay to ensure the GPU has processed the image.
        // This helps prevent cut-off animations on slower devices.
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        // Ignore precache errors - image will load during transition (fallback)
      }
    }
  }

  /// Called after state update for video playback control
  void _on_index_changed_post_update(int index) {
    final bool is_video_slot = widget.possible_video_position_for_portrait ||
        widget.possible_video_position_for_landscape;

    if (is_video_slot) {
      _handle_video_change(index);
    }
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

  /// Handles image loading for the initial display (called from initState).
  /// For subsequent transitions, _preload_image_for_index is used instead
  /// to ensure images are loaded BEFORE the animation starts.
  Future<void> _handle_image_change(int index) async {
    // Image preloading is now handled by _preload_image_for_index
    // which is called before setState to avoid animation interruption.
    // This method is kept for initial load in initState.
    await _preload_image_for_index(index);
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
              // Custom layoutBuilder ensures both old and new widgets fill the space
              // during the crossfade transition
              layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
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
    // For image slots using random selection, the index is already the direct image index.
    // No offset calculation needed - pass use_direct_index=true.
    final bool use_direct_index =
        _is_image_slot && widget.get_random_image_index != null;

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
      use_direct_index: use_direct_index,
    );
  }
}
