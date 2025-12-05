import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:xapptor_community/ui/slideshow/get_slideshow_matrix.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_view_item.dart';
import 'package:xapptor_logic/random/random_number_with_range.dart';
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

/// A stateful widget that represents a single slideshow view slot.
/// Using a proper widget (instead of a function) allows Flutter to properly
/// diff and reuse widgets, preventing unnecessary rebuilds and GPU texture leaks.
class SlideshowViewWidget extends StatefulWidget {
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

  /// Callback to request lazy loading of the next item when carousel advances
  final OnLazyLoadRequest? on_lazy_load_request;

  /// Callback to get a video controller by URL index (not by controller list index)
  final GetVideoControllerByIndex? get_video_controller_by_index;

  /// Total number of items available (including not-yet-loaded)
  final int total_video_count;
  final int total_image_count;

  const SlideshowViewWidget({
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
    this.on_lazy_load_request,
    this.get_video_controller_by_index,
    this.total_video_count = 0,
    this.total_image_count = 0,
    super.key,
  });

  @override
  State<SlideshowViewWidget> createState() => _SlideshowViewWidgetState();
}

class _SlideshowViewWidgetState extends State<SlideshowViewWidget> {
  late Duration _auto_play_interval;

  @override
  void initState() {
    super.initState();
    final bool is_video_slot = widget.possible_video_position_for_portrait ||
        widget.possible_video_position_for_landscape;
    _auto_play_interval = Duration(
      seconds: is_video_slot
          ? random_number_with_range(15, 25)
          : random_number_with_range(3, 7),
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
    final int effective_item_count =
        widget.item_count > 0 ? widget.item_count : 1;

    return Expanded(
      flex: view_config['flex'] as int,
      child: Container(
        margin: const EdgeInsets.all(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(outline_border_radius),
          clipBehavior: Clip.hardEdge,
          child: RepaintBoundary(
            child: CarouselSlider.builder(
              itemCount: effective_item_count,
              itemBuilder: (context, i, _) {
                return build_carousel_item(
                  index: i,
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
                  views_per_column:
                      widget.slideshow_matrix[widget.column_index].length,
                  test_mode: widget.test_mode,
                  portrait: widget.portrait,
                  portrait_images: widget.portrait_images,
                  landscape_images: widget.landscape_images,
                  all_images: widget.all_images,
                  get_video_controller_by_index:
                      widget.get_video_controller_by_index,
                );
              },
              options: CarouselOptions(
                height: double.maxFinite,
                viewportFraction: 1,
                enableInfiniteScroll: true,
                autoPlay: true,
                autoPlayInterval: _auto_play_interval,
                autoPlayAnimationDuration: widget.animation_duration,
                autoPlayCurve: widget.animation_curve,
                enlargeCenterPage: false,
                scrollDirection: Axis.horizontal,
                scrollPhysics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index, reason) {
                  _handle_page_changed(index);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handle_page_changed(int index) {
    final bool is_video_slot = widget.possible_video_position_for_portrait ||
        widget.possible_video_position_for_landscape;

    if (is_video_slot) {
      _handle_video_page_change(index);
    } else {
      _handle_image_page_change(index);
    }
  }

  void _handle_video_page_change(int index) async {
    // Use URL-based lookup to check if current video is loaded
    VideoPlayerController? current_controller;
    if (widget.get_video_controller_by_index != null) {
      current_controller = widget.get_video_controller_by_index!(
        index: index,
        is_portrait: widget.possible_video_position_for_portrait,
      );
    }

    // Request lazy loading of CURRENT video if not loaded
    // NOTE: We do NOT preload the next video because with max_active_videos_web = 2,
    // preloading would immediately dispose the video we just loaded (since we need
    // 1 portrait + 1 landscape active at all times)
    if (widget.on_lazy_load_request != null && widget.total_video_count > 0) {
      if (current_controller == null) {
        // AWAIT the load so we can play the video after it's ready
        await widget.on_lazy_load_request!(
          index: index,
          is_video: true,
          is_portrait: widget.possible_video_position_for_portrait,
          orientation: widget.slideshow_view_orientation,
        );

        // After loading, check again for the controller
        if (widget.get_video_controller_by_index != null) {
          current_controller = widget.get_video_controller_by_index!(
            index: index,
            is_portrait: widget.possible_video_position_for_portrait,
          );
        }

        // Force rebuild of this widget to show the newly loaded video
        if (mounted) setState(() {});
      }
    }

    if (current_controller == null) return;

    final int duration_ms = current_controller.value.duration.inMilliseconds;

    if (duration_ms <= 0) return;

    final int max_start = duration_ms - (duration_ms / 10).round();
    final int random_start = random_number_with_range(0, max_start);

    current_controller.setVolume(0);
    current_controller
      ..seekTo(Duration(milliseconds: random_start))
      ..play();
  }

  void _handle_image_page_change(int index) {
    if (widget.on_lazy_load_request != null && widget.total_image_count > 0) {
      final int next_index = (index + 1) % widget.total_image_count;
      widget.on_lazy_load_request!(
        index: next_index,
        is_video: false,
        is_portrait: false,
        orientation: widget.slideshow_view_orientation,
      );
    }
  }
}

/// Legacy function wrapper for backward compatibility.
/// Delegates to SlideshowViewWidget for proper widget lifecycle management.
Widget slideshow_view({
  required int column_index,
  required int view_index,
  required SlideshowViewOrientation slideshow_view_orientation,
  required int item_count,
  required bool possible_video_position_for_portrait,
  required bool possible_video_position_for_landscape,
  required List<VideoPlayerController> portrait_video_player_controllers,
  required List<VideoPlayerController> landscape_video_player_controllers,
  required double screen_width,
  required int number_of_columns,
  required Duration animation_duration,
  required Curve animation_curve,
  required bool test_mode,
  required bool portrait,
  required List<List<Map<String, dynamic>>> slideshow_matrix,
  required List<Image> portrait_images,
  required List<Image> landscape_images,
  required List<Image> all_images,
  OnLazyLoadRequest? on_lazy_load_request,
  GetVideoControllerByIndex? get_video_controller_by_index,
  int total_video_count = 0,
  int total_image_count = 0,
}) {
  return SlideshowViewWidget(
    key: ValueKey('slideshow_view_${column_index}_$view_index'),
    column_index: column_index,
    view_index: view_index,
    slideshow_view_orientation: slideshow_view_orientation,
    item_count: item_count,
    possible_video_position_for_portrait: possible_video_position_for_portrait,
    possible_video_position_for_landscape: possible_video_position_for_landscape,
    portrait_video_player_controllers: portrait_video_player_controllers,
    landscape_video_player_controllers: landscape_video_player_controllers,
    screen_width: screen_width,
    number_of_columns: number_of_columns,
    animation_duration: animation_duration,
    animation_curve: animation_curve,
    test_mode: test_mode,
    portrait: portrait,
    slideshow_matrix: slideshow_matrix,
    portrait_images: portrait_images,
    landscape_images: landscape_images,
    all_images: all_images,
    on_lazy_load_request: on_lazy_load_request,
    get_video_controller_by_index: get_video_controller_by_index,
    total_video_count: total_video_count,
    total_image_count: total_image_count,
  );
}
