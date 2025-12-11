import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:xapptor_community/ui/slideshow/get_slideshow_matrix.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_fade_slot.dart';
import 'package:xapptor_ui/widgets/fade_in_video.dart';

/// Builds a single carousel item for the slideshow view.
/// This can be either a video or an image, depending on the slot configuration.
Widget build_carousel_item({
  Key? key,
  required int index,
  required SlideshowViewOrientation orientation,
  required double ratio_difference,
  required int view_height,
  required int column_index,
  required int view_index,
  required bool possible_video_position_for_portrait,
  required bool possible_video_position_for_landscape,
  required List<VideoPlayerController> portrait_video_player_controllers,
  required List<VideoPlayerController> landscape_video_player_controllers,
  required double screen_width,
  required int number_of_columns,
  required int views_per_column,
  required bool test_mode,
  required bool portrait,
  required List<Image> portrait_images,
  required List<Image> landscape_images,
  required List<Image> all_images,
  GetVideoControllerByIndex? get_video_controller_by_index,
  GetImageByIndex? get_image_by_index,
  double device_pixel_ratio = 1.0,
  /// When true, the index is already the direct image index (from random selection).
  /// No view_offset calculation is needed. Parent handles duplicate prevention.
  bool use_direct_index = false,
}) {
  final String test_mode_text = _build_test_mode_text(
    orientation: orientation,
    ratio_difference: ratio_difference,
    view_height: view_height,
    possible_video_position_for_portrait: possible_video_position_for_portrait,
    possible_video_position_for_landscape: possible_video_position_for_landscape,
  );

  // Handle video slots
  if (possible_video_position_for_portrait || possible_video_position_for_landscape) {
    final widget = _build_video_item(
      index: index,
      column_index: column_index,
      view_index: view_index,
      possible_video_position_for_portrait: possible_video_position_for_portrait,
      portrait_video_player_controllers: portrait_video_player_controllers,
      landscape_video_player_controllers: landscape_video_player_controllers,
      test_mode: test_mode,
      portrait: portrait,
      test_mode_text: test_mode_text,
      get_video_controller_by_index: get_video_controller_by_index,
    );
    // Apply key if provided (for AnimatedSwitcher support)
    return key != null ? KeyedSubtree(key: key, child: widget) : widget;
  }

  // Handle image slots
  final widget = _build_image_item(
    index: index,
    column_index: column_index,
    view_index: view_index,
    views_per_column: views_per_column,
    orientation: orientation,
    screen_width: screen_width,
    number_of_columns: number_of_columns,
    test_mode: test_mode,
    portrait: portrait,
    test_mode_text: test_mode_text,
    portrait_images: portrait_images,
    landscape_images: landscape_images,
    all_images: all_images,
    get_image_by_index: get_image_by_index,
    device_pixel_ratio: device_pixel_ratio,
    use_direct_index: use_direct_index,
  );
  // Apply key if provided (for AnimatedSwitcher support)
  return key != null ? KeyedSubtree(key: key, child: widget) : widget;
}

String _build_test_mode_text({
  required SlideshowViewOrientation orientation,
  required double ratio_difference,
  required int view_height,
  required bool possible_video_position_for_portrait,
  required bool possible_video_position_for_landscape,
}) {
  String text = orientation == SlideshowViewOrientation.square_or_similar
      ? "P/L"
      : orientation == SlideshowViewOrientation.portrait
          ? "P"
          : "L";

  if (orientation == SlideshowViewOrientation.square_or_similar) {
    text += "\nDifference: $ratio_difference";
  }

  text += "\nHeight: $view_height";
  if (possible_video_position_for_portrait) text += "\nV-P";
  if (possible_video_position_for_landscape) text += "\nV-L";

  return text;
}

Widget _build_video_item({
  required int index,
  required int column_index,
  required int view_index,
  required bool possible_video_position_for_portrait,
  required List<VideoPlayerController> portrait_video_player_controllers,
  required List<VideoPlayerController> landscape_video_player_controllers,
  required bool test_mode,
  required bool portrait,
  required String test_mode_text,
  GetVideoControllerByIndex? get_video_controller_by_index,
}) {
  Widget video_player_widget;

  // Use URL-based lookup if available (preferred method)
  // This correctly maps carousel index to video URL, then gets the controller
  VideoPlayerController? controller;
  if (get_video_controller_by_index != null) {
    controller = get_video_controller_by_index(
      index: index,
      is_portrait: possible_video_position_for_portrait,
    );
  }

  // Fallback to old list-based lookup (for backward compatibility)
  if (controller == null) {
    final controllers = possible_video_position_for_portrait
        ? portrait_video_player_controllers
        : landscape_video_player_controllers;
    if (controllers.isNotEmpty && index < controllers.length) {
      controller = controllers[index];
    }
  }

  if (controller != null) {
    // Include controller's hashCode in the key to force rebuild when controller changes
    video_player_widget = FadeInVideo(
      key: ValueKey('video_${column_index}_${view_index}_${index}_${controller.hashCode}'),
      controller: controller,
      placeholder: const AssetImage(
        'assets/images/placeholder_gradient_64.jpg',
      ),
    );
  } else {
    // Use a distinct key for placeholder so it's replaced when video loads
    video_player_widget = Container(
      key: ValueKey('placeholder_${column_index}_${view_index}_$index'),
      child: _placeholder_widget(),
    );
  }

  // Removed redundant ClipRRect - parent already clips
  return Stack(
    alignment: Alignment.center,
    fit: StackFit.expand,
    children: [
      video_player_widget,
      if (test_mode) _build_test_mode_overlay(test_mode_text, portrait),
    ],
  );
}

Widget _build_image_item({
  required int index,
  required int column_index,
  required int view_index,
  required int views_per_column,
  required SlideshowViewOrientation orientation,
  required double screen_width,
  required int number_of_columns,
  required bool test_mode,
  required bool portrait,
  required String test_mode_text,
  required List<Image> portrait_images,
  required List<Image> landscape_images,
  required List<Image> all_images,
  GetImageByIndex? get_image_by_index,
  // ignore: unused_element_parameter - kept for API compatibility, may be used in future
  double device_pixel_ratio = 1.0,
  bool use_direct_index = false,
}) {
  // Use URL-based lookup if available (preferred method for lazy loading)
  // This correctly maps carousel index to image URL, then gets the cached image
  Image? image;
  if (get_image_by_index != null) {
    // When use_direct_index is true, the index is already the actual image index
    // (from parent's random selection). No offset calculation needed.
    // Otherwise, calculate offset for uniqueness across views (legacy behavior).
    final int effective_index;
    if (use_direct_index) {
      effective_index = index;
    } else {
      final int view_offset = column_index * views_per_column + view_index;
      effective_index = index + view_offset;
    }
    image = get_image_by_index(
      index: effective_index,
      orientation: orientation,
    );
  }

  // Fallback to old list-based lookup (for backward compatibility)
  image ??= _get_image_for_orientation(
    index: index,
    column_index: column_index,
    view_index: view_index,
    views_per_column: views_per_column,
    orientation: orientation,
    portrait_images: portrait_images,
    landscape_images: landscape_images,
    all_images: all_images,
  );

  if (image == null) {
    // Removed redundant ClipRRect - parent already clips
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        _placeholder_widget(),
        if (test_mode) _build_test_mode_overlay(test_mode_text, portrait),
      ],
    );
  }

  // NOTE: We no longer use ResizeImage here because cacheWidth/cacheHeight
  // is now applied at image load time in load_single_image().
  // This avoids double-resizing which can cause quality loss and aspect ratio issues.
  // The image.image provider already has the decode size constraints applied.

  // Use a regular Image widget instead of FadeInImage.
  // The parent AnimatedSwitcher handles the fade transition between images.
  // Using FadeInImage here causes a conflict: when the image is cached,
  // FadeInImage shows it instantly while AnimatedSwitcher expects to animate,
  // resulting in abrupt/cut-off transitions.
  //
  // IMPORTANT: No frameBuilder here! The image should be precached (decoded)
  // BEFORE AnimatedSwitcher starts the transition. If we use frameBuilder
  // to show a placeholder during decode, it can cause visual jumps mid-animation.
  // The precacheImage() call in _preload_image_for_index ensures decode completes first.
  //
  // NOTE: gaplessPlayback is intentionally NOT used here because it conflicts
  // with AnimatedSwitcher. gaplessPlayback keeps the old image visible until
  // the new one is ready, but AnimatedSwitcher needs full control over the
  // crossfade animation. Using both together causes abrupt transitions.
  return Stack(
    alignment: Alignment.center,
    fit: StackFit.expand,
    children: [
      Image(
        image: image.image,
        fit: BoxFit.cover,
        width: screen_width / number_of_columns,
      ),
      if (test_mode) _build_test_mode_overlay(test_mode_text, portrait),
    ],
  );
}

/// Gets an image for the given orientation using index-based selection.
/// Each view gets a unique offset based on its position in the grid,
/// preventing the same image from appearing in multiple views simultaneously.
Image? _get_image_for_orientation({
  required int index,
  required int column_index,
  required int view_index,
  required int views_per_column,
  required SlideshowViewOrientation orientation,
  required List<Image> portrait_images,
  required List<Image> landscape_images,
  required List<Image> all_images,
}) {
  // Calculate a unique offset for this view based on its position in the grid.
  // This ensures different views start at different points in the image list.
  final int view_offset = column_index * views_per_column + view_index;

  switch (orientation) {
    case SlideshowViewOrientation.portrait:
      if (portrait_images.isEmpty) return null;
      // Use modulo to cycle through images, offset by view position
      final int image_index = (index + view_offset) % portrait_images.length;
      return portrait_images[image_index];
    case SlideshowViewOrientation.landscape:
      if (landscape_images.isEmpty) return null;
      final int image_index = (index + view_offset) % landscape_images.length;
      return landscape_images[image_index];
    case SlideshowViewOrientation.square_or_similar:
      if (all_images.isEmpty) return null;
      final int image_index = (index + view_offset) % all_images.length;
      return all_images[image_index];
  }
}

Widget _placeholder_widget() {
  return Image.asset(
    'assets/images/placeholder_gradient_64.jpg',
    fit: BoxFit.cover,
    width: double.infinity,
    height: double.infinity,
  );
}

Widget _build_test_mode_overlay(String text, bool portrait) {
  return Center(
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.yellow,
        fontSize: portrait ? 26 : 36,
        fontWeight: FontWeight.bold,
        shadows: const [
          Shadow(
            blurRadius: 8.0,
            color: Colors.black,
            offset: Offset(2.0, 2.0),
          ),
        ],
      ),
    ),
  );
}
