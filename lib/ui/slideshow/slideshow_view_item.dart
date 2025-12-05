import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:xapptor_community/ui/slideshow/get_slideshow_matrix.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_view.dart';
import 'package:xapptor_logic/random/random_number_with_range.dart';
import 'package:xapptor_ui/values/ui.dart';
import 'package:xapptor_ui/widgets/fade_in_video.dart';

/// Builds a single carousel item for the slideshow view.
/// This can be either a video or an image, depending on the slot configuration.
Widget build_carousel_item({
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
  required bool test_mode,
  required bool portrait,
  required List<Image> portrait_images,
  required List<Image> landscape_images,
  required List<Image> all_images,
  GetVideoControllerByIndex? get_video_controller_by_index,
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
    return _build_video_item(
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
  }

  // Handle image slots
  return _build_image_item(
    orientation: orientation,
    screen_width: screen_width,
    number_of_columns: number_of_columns,
    test_mode: test_mode,
    portrait: portrait,
    test_mode_text: test_mode_text,
    portrait_images: portrait_images,
    landscape_images: landscape_images,
    all_images: all_images,
  );
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
    video_player_widget = FadeInVideo(
      key: ValueKey('video_${column_index}_${view_index}_$index'),
      controller: controller,
      placeholder: const AssetImage(
        'assets/images/placeholder_gradient_64.jpg',
      ),
    );
  } else {
    video_player_widget = _placeholder_widget();
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(outline_border_radius),
    child: Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        video_player_widget,
        if (test_mode) _build_test_mode_overlay(test_mode_text, portrait),
      ],
    ),
  );
}

Widget _build_image_item({
  required SlideshowViewOrientation orientation,
  required double screen_width,
  required int number_of_columns,
  required bool test_mode,
  required bool portrait,
  required String test_mode_text,
  required List<Image> portrait_images,
  required List<Image> landscape_images,
  required List<Image> all_images,
}) {
  final Image? image = _get_image_for_orientation(
    orientation: orientation,
    portrait_images: portrait_images,
    landscape_images: landscape_images,
    all_images: all_images,
  );

  if (image == null) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(outline_border_radius),
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          _placeholder_widget(),
          if (test_mode) _build_test_mode_overlay(test_mode_text, portrait),
        ],
      ),
    );
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(outline_border_radius),
    child: Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        FadeInImage(
          placeholder: const AssetImage(
            'assets/images/placeholder_gradient_64.jpg',
          ),
          image: ResizeImage(
            image.image,
            width: 1000,
          ),
          fit: BoxFit.cover,
          width: screen_width / number_of_columns,
        ),
        if (test_mode) _build_test_mode_overlay(test_mode_text, portrait),
      ],
    ),
  );
}

Image? _get_image_for_orientation({
  required SlideshowViewOrientation orientation,
  required List<Image> portrait_images,
  required List<Image> landscape_images,
  required List<Image> all_images,
}) {
  switch (orientation) {
    case SlideshowViewOrientation.portrait:
      if (portrait_images.isEmpty) return null;
      return portrait_images[
          random_number_with_range(0, portrait_images.length - 1)];
    case SlideshowViewOrientation.landscape:
      if (landscape_images.isEmpty) return null;
      return landscape_images[
          random_number_with_range(0, landscape_images.length - 1)];
    case SlideshowViewOrientation.square_or_similar:
      if (all_images.isEmpty) return null;
      return all_images[random_number_with_range(0, all_images.length - 1)];
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
