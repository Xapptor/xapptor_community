import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:xapptor_community/ui/slideshow/get_slideshow_matrix.dart';
import 'package:xapptor_logic/random/random_number_with_range.dart';
import 'package:xapptor_ui/values/ui.dart';
import 'package:xapptor_ui/widgets/fade_in_video.dart';

/// Placeholder widget shown while content is loading
Widget _placeholder_widget() {
  return Image.asset(
    'assets/images/placeholder_gradient_64.jpg',
    fit: BoxFit.cover,
    width: double.infinity,
    height: double.infinity,
  );
}

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
}) {
  final view_config = slideshow_matrix[column_index][view_index];
  final SlideshowViewOrientation orientation = view_config['orientation'] as SlideshowViewOrientation;

  final double ratio_difference = (view_config['ratio_difference'] as num).toDouble();
  final int view_height = (view_config['height'] as num).round();

  // Ensure at least 1 item so we can show a placeholder
  final int effective_item_count = item_count > 0 ? item_count : 1;

  return Expanded(
    flex: view_config['flex'] as int,
    child: Container(
      margin: const EdgeInsets.all(4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(outline_border_radius),
        clipBehavior: Clip.hardEdge,
        child: CarouselSlider.builder(
          itemCount: effective_item_count,
          itemBuilder: (context, i, _) {
            final Image? image = _get_random_image_for_orientation(
              orientation: slideshow_view_orientation,
              portrait_images: portrait_images,
              landscape_images: landscape_images,
              all_images: all_images,
            );

            String test_mode_text = orientation == SlideshowViewOrientation.square_or_similar
                ? "P/L"
                : orientation == SlideshowViewOrientation.portrait
                    ? "P"
                    : "L";

            if (orientation == SlideshowViewOrientation.square_or_similar) {
              test_mode_text += "\nDifference: $ratio_difference";
            }

            test_mode_text += "\nHeight: $view_height";
            if (possible_video_position_for_portrait) test_mode_text += "\nV-P";
            if (possible_video_position_for_landscape) test_mode_text += "\nV-L";

            // Handle video slots
            if (possible_video_position_for_portrait || possible_video_position_for_landscape) {
              final controllers = possible_video_position_for_portrait
                  ? portrait_video_player_controllers
                  : landscape_video_player_controllers;

              Widget video_player_widget;

              if (controllers.isNotEmpty && i < controllers.length) {
                final current_video_player_controller = controllers[i];

                video_player_widget = FadeInVideo(
                  controller: current_video_player_controller,
                  placeholder: const AssetImage(
                    'assets/images/placeholder_gradient_64.jpg',
                  ),
                );
              } else {
                // Video not loaded yet - show placeholder
                video_player_widget = _placeholder_widget();
              }

              return ClipRRect(
                borderRadius: BorderRadius.circular(outline_border_radius),
                child: Stack(
                  alignment: Alignment.center,
                  fit: StackFit.expand,
                  children: [
                    video_player_widget,
                    if (test_mode)
                      Center(
                        child: Text(
                          test_mode_text,
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
                      ),
                  ],
                ),
              );
            }

            // Handle image slots
            // If no image available for this orientation, show placeholder
            if (image == null) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(outline_border_radius),
                child: Stack(
                  alignment: Alignment.center,
                  fit: StackFit.expand,
                  children: [
                    _placeholder_widget(),
                    if (test_mode)
                      Center(
                        child: Text(
                          test_mode_text,
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
                      ),
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
                  if (test_mode)
                    Center(
                      child: Text(
                        test_mode_text,
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
                    ),
                ],
              ),
            );
          },
          options: CarouselOptions(
            height: double.maxFinite,
            viewportFraction: 1,
            enableInfiniteScroll: true,
            autoPlay: true,
            autoPlayInterval: Duration(
              seconds: !possible_video_position_for_portrait && !possible_video_position_for_landscape
                  ? random_number_with_range(3, 7)
                  : random_number_with_range(15, 25),
            ),
            autoPlayAnimationDuration: animation_duration,
            autoPlayCurve: animation_curve,
            enlargeCenterPage: false,
            scrollDirection: Axis.horizontal,
            scrollPhysics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index, reason) {
              if (possible_video_position_for_portrait || possible_video_position_for_landscape) {
                final controllers = possible_video_position_for_portrait
                    ? portrait_video_player_controllers
                    : landscape_video_player_controllers;

                if (controllers.isEmpty || index >= controllers.length) return;

                final current_video_player_controller = controllers[index];
                final int duration_ms = current_video_player_controller.value.duration.inMilliseconds;

                if (duration_ms <= 0) return;

                final int max_start = duration_ms - (duration_ms / 10).round();
                final int random_start = random_number_with_range(0, max_start);

                current_video_player_controller
                  ..seekTo(Duration(milliseconds: random_start))
                  ..play();
              }
            },
          ),
        ),
      ),
    ),
  );
}

Image? _get_random_image_for_orientation({
  required SlideshowViewOrientation orientation,
  required List<Image> portrait_images,
  required List<Image> landscape_images,
  required List<Image> all_images,
}) {
  switch (orientation) {
    case SlideshowViewOrientation.portrait:
      if (portrait_images.isEmpty) return null;
      return portrait_images[random_number_with_range(0, portrait_images.length - 1)];
    case SlideshowViewOrientation.landscape:
      if (landscape_images.isEmpty) return null;
      return landscape_images[random_number_with_range(0, landscape_images.length - 1)];
    case SlideshowViewOrientation.square_or_similar:
      if (all_images.isEmpty) return null;
      return all_images[random_number_with_range(0, all_images.length - 1)];
  }
}
