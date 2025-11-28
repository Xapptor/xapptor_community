import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_custom_text.dart';
import 'package:xapptor_community/ui/slideshow/get_slideshow_matrix.dart';
import 'package:xapptor_community/ui/slideshow/loading_message.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_view.dart';
import 'package:xapptor_logic/image/get_image_size.dart';
import 'package:xapptor_logic/video/get_video_size.dart';
import 'package:xapptor_ui/values/ui.dart';

class Slideshow extends StatefulWidget {
  final List<String>? image_paths;
  final List<String>? video_paths;
  final bool use_examples;
  final String title;
  final String subtitle;
  final String loading_message;

  const Slideshow({
    super.key,
    this.image_paths,
    this.video_paths,
    this.use_examples = false,
    this.title = "",
    this.subtitle = "",
    this.loading_message = "Loading...",
  });

  @override
  State<Slideshow> createState() => _SlideshowState();
}

class _SlideshowState extends State<Slideshow> {
  List<Image> landscape_images = [];
  List<Image> portrait_images = [];
  List<Image> all_images = [];
  List<VideoPlayerController> portrait_video_player_controllers = [];
  List<VideoPlayerController> landscape_video_player_controllers = [];

  final Reference image_storage_ref = FirebaseStorage.instance.ref('app/example_photos');
  final Reference video_storage_ref = FirebaseStorage.instance.ref('app/example_videos');
  List<String> image_urls = [];
  List<String> video_urls = [];

  bool mute_videos = true;
  Cubic animation_curve = Curves.fastOutSlowIn;
  Duration animation_duration = const Duration(milliseconds: 1000);

  static const int max_initial_images = 12;
  static const int image_batch_size = 8;
  static const Duration image_batch_delay = Duration(milliseconds: 300);

  static const int max_initial_videos = 4;
  static const int video_batch_size = 1;
  static const Duration video_batch_delay = Duration(seconds: 2);

  Future<void> _load_single_image({
    required String path,
    required bool using_examples,
  }) async {
    final Image current_image = using_examples ? Image.network(path) : Image.asset(path);

    final Size size = await get_image_size(image: current_image);

    if (size.width >= size.height) {
      landscape_images.add(current_image);
    } else {
      portrait_images.add(current_image);
    }
    all_images.add(current_image);
  }

  Future<void> _process_in_batches({
    required int total,
    required int start_index,
    required int batch_size,
    required Duration delay,
    required Future<void> Function(int index) process_item,
  }) async {
    int current_index = start_index;

    while (mounted && current_index < total) {
      final int remaining = total - current_index;
      final int current_batch_size = remaining > batch_size ? batch_size : remaining;

      final List<Future<void>> futures = [];

      for (int i = 0; i < current_batch_size; i++) {
        futures.add(process_item(current_index + i));
      }

      await Future.wait(futures);

      if (!mounted) return;

      setState(() {});

      current_index += current_batch_size;

      await Future.delayed(delay);
    }
  }

  Future<void> get_image_sizes() async {
    landscape_images.clear();
    portrait_images.clear();
    all_images.clear();

    final bool using_examples = widget.use_examples;
    final List<String> paths = using_examples
        ? image_urls
        : widget.image_paths != null
            ? widget.image_paths!
            : [];

    if (paths.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    final int total = paths.length;
    final int initial_count = total > max_initial_images ? max_initial_images : total;

    for (int i = 0; i < initial_count; i++) {
      await _load_single_image(
        path: paths[i],
        using_examples: using_examples,
      );
    }

    if (mounted) {
      setState(() {});
    }

    if (initial_count < total) {
      unawaited(
        _process_in_batches(
          total: total,
          start_index: initial_count,
          batch_size: image_batch_size,
          delay: image_batch_delay,
          process_item: (index) async {
            await _load_single_image(
              path: paths[index],
              using_examples: using_examples,
            );
          },
        ),
      );
    }
    unawaited(get_video_sizes());
  }

  Future<void> get_video_sizes() async {
    portrait_video_player_controllers.clear();
    landscape_video_player_controllers.clear();

    final List<String> video_paths = widget.video_paths ?? const <String>[];
    final bool using_examples = widget.use_examples;
    final List<String> paths = using_examples ? video_urls : video_paths;

    if (paths.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    final int total = paths.length;
    final int initial_count = total > max_initial_videos ? max_initial_videos : total;

    for (int i = 0; i < initial_count; i++) {
      await _load_single_video(
        video_location: paths[i],
        using_examples: using_examples,
      );
    }

    if (mounted) {
      setState(() {});
    }

    if (initial_count < total) {
      unawaited(
        _process_in_batches(
          total: total,
          start_index: initial_count,
          batch_size: video_batch_size,
          delay: video_batch_delay,
          process_item: (index) async {
            await _load_single_video(
              video_location: paths[index],
              using_examples: using_examples,
            );
          },
        ),
      );
    }
  }

  Future<void> _load_single_video({
    required String video_location,
    required bool using_examples,
  }) async {
    final VideoPlayerController controller = using_examples
        ? VideoPlayerController.networkUrl(Uri.parse(video_location))
        : VideoPlayerController.asset(video_location);

    await controller.initialize();

    final Size size = await get_video_size(controller: controller);

    await controller.setVolume(0);
    await controller.setLooping(true);
    await controller.play();

    if (size.width >= size.height) {
      landscape_video_player_controllers.add(controller);
    } else {
      portrait_video_player_controllers.add(controller);
    }
  }

  Future<void> get_example_urls() async {
    image_urls.clear();
    video_urls.clear();
    final ListResult image_list_result = await image_storage_ref.listAll();
    final ListResult video_list_result = await video_storage_ref.listAll();

    final List<Future<String>> image_url_futures = image_list_result.items.map((ref) => ref.getDownloadURL()).toList();
    final List<Future<String>> video_url_futures = video_list_result.items.map((ref) => ref.getDownloadURL()).toList();
    image_urls = await Future.wait(image_url_futures);
    video_urls = await Future.wait(video_url_futures);

    if (!mounted) return;
    await get_image_sizes();
  }

  @override
  initState() {
    super.initState();

    if (!widget.use_examples) {
      get_image_sizes();
    } else {
      get_example_urls();
    }
  }

  @override
  void dispose() {
    for (var controller in portrait_video_player_controllers) {
      controller.dispose();
    }
    for (var controller in landscape_video_player_controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<List<Map<String, dynamic>>>? slideshow_matrix;

  set_slideshow_matrix({
    required double screen_height,
    required double screen_width,
    required bool portrait,
    required int number_of_columns,
  }) {
    slideshow_matrix = get_slideshow_matrix(
      screen_height: screen_height,
      screen_width: screen_width,
      portrait: portrait,
      number_of_columns: number_of_columns,
    );

    portrait_images.shuffle();
    landscape_images.shuffle();
    all_images.shuffle();
  }

  Orientation? last_orientation;

  @override
  Widget build(BuildContext context) {
    const bool test_mode = false;

    MediaQueryData mq = MediaQuery.of(context);
    double screen_height = mq.size.height;
    double screen_width = mq.size.width;
    bool portrait = screen_height > screen_width;
    Orientation orientation = mq.orientation;

    int number_of_columns = 0;

    if (portrait) {
      number_of_columns = 2;
    } else {
      number_of_columns = 4;
    }

    if (last_orientation != orientation) {
      last_orientation = orientation;

      set_slideshow_matrix(
        screen_height: screen_height,
        screen_width: screen_width,
        portrait: portrait,
        number_of_columns: number_of_columns,
      );
    }

    if (all_images.isEmpty) {
      return loading_message(
        loading_message: widget.loading_message,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          children: List.generate(
            slideshow_matrix!.length,
            (column_index) {
              return Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(
                    slideshow_matrix![column_index].length,
                    (view_index) {
                      SlideshowViewOrientation slideshow_view_orientation =
                          slideshow_matrix![column_index][view_index]['orientation'];

                      bool possible_video_position_for_portrait = false;

                      if (slideshow_matrix![column_index][view_index]['possible_video_position_for_portrait'] != null) {
                        possible_video_position_for_portrait =
                            slideshow_matrix![column_index][view_index]['possible_video_position_for_portrait'];
                      }

                      bool possible_video_position_for_landscape = false;

                      if (slideshow_matrix![column_index][view_index]['possible_video_position_for_landscape'] !=
                          null) {
                        possible_video_position_for_landscape =
                            slideshow_matrix![column_index][view_index]['possible_video_position_for_landscape'];
                      }

                      int item_count = 0;

                      if (!possible_video_position_for_portrait && !possible_video_position_for_landscape) {
                        //
                        item_count = slideshow_view_orientation == SlideshowViewOrientation.landscape
                            ? landscape_images.length
                            : slideshow_view_orientation == SlideshowViewOrientation.portrait
                                ? portrait_images.length
                                : all_images.length;
                      } else {
                        //
                        if (possible_video_position_for_portrait) {
                          item_count = portrait_video_player_controllers.length;
                        } else {
                          item_count = landscape_video_player_controllers.length;
                        }
                      }

                      return slideshow_view(
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
                        slideshow_matrix: slideshow_matrix!,
                        portrait_images: portrait_images,
                        landscape_images: landscape_images,
                        all_images: all_images,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          alignment: Alignment.bottomRight,
          margin: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                onPressed: () {
                  mute_videos = !mute_videos;
                  _set_all_videos_volume(mute_videos ? 0 : 1);
                  setState(() {});
                },
                child: Icon(
                  mute_videos ? Icons.volume_off : Icons.volume_up,
                ),
              ),
              const SizedBox(width: sized_box_space),
              FloatingActionButton(
                onPressed: () {
                  set_slideshow_matrix(
                    screen_height: screen_height,
                    screen_width: screen_width,
                    portrait: portrait,
                    number_of_columns: number_of_columns,
                  );
                  setState(() {});
                },
                backgroundColor: const Color(0xFFD9C7FF),
                tooltip: "Refresh Slideshow",
                child: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (all_images.isNotEmpty)
          Container(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                slideshow_custom_text(
                  widget.title,
                  type: CustomTextType.title,
                  portrait: portrait,
                ),
                const SizedBox(height: sized_box_space),
                slideshow_custom_text(
                  widget.subtitle,
                  type: CustomTextType.subtitle,
                  portrait: portrait,
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _set_all_videos_volume(double volume) {
    for (final c in portrait_video_player_controllers) {
      c.setVolume(volume);
    }
    for (final c in landscape_video_player_controllers) {
      c.setVolume(volume);
    }
  }
}
