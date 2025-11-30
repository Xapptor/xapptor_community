import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_audio_service.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_custom_text.dart';
import 'package:xapptor_community/ui/slideshow/get_slideshow_matrix.dart';
import 'package:xapptor_community/ui/slideshow/loading_message.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_fab.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_view.dart';
import 'package:xapptor_logic/image/get_image_size.dart';
import 'package:xapptor_logic/video/get_video_size.dart';
import 'package:xapptor_ui/values/ui.dart';

/// Data class containing all state needed to build the slideshow FAB.
/// This allows the parent widget to build the FAB in its own widget tree
/// with its own GlobalKey, while the Slideshow manages the audio state.
class SlideshowFabData {
  final bool sound_is_on;
  final bool is_playing;
  final bool is_loading;
  final VoidCallback on_volume_pressed;
  final VoidCallback on_back_pressed;
  final VoidCallback on_play_pressed;
  final VoidCallback on_forward_pressed;
  final VoidCallback on_share_pressed;
  final String menu_label;
  final String close_label;
  final String volume_label;
  final String back_label;
  final String play_label;
  final String forward_label;
  final String share_label;
  final Color primary_color;
  final Color secondary_color;
  final String share_url;

  const SlideshowFabData({
    required this.sound_is_on,
    required this.is_playing,
    required this.is_loading,
    required this.on_volume_pressed,
    required this.on_back_pressed,
    required this.on_play_pressed,
    required this.on_forward_pressed,
    required this.on_share_pressed,
    required this.menu_label,
    required this.close_label,
    required this.volume_label,
    required this.back_label,
    required this.play_label,
    required this.forward_label,
    required this.share_label,
    required this.primary_color,
    required this.secondary_color,
    required this.share_url,
  });

  /// Builds the FAB widget using the provided GlobalKey.
  /// The parent should create and maintain the GlobalKey.
  Widget build_fab(GlobalKey<ExpandableFabState> fab_key) {
    return slideshow_fab(
      expandable_fab_key: fab_key,
      menu_label: menu_label,
      close_label: close_label,
      volume_label: volume_label,
      back_label: back_label,
      play_label: play_label,
      forward_label: forward_label,
      share_label: share_label,
      sound_is_on: sound_is_on,
      is_playing: is_playing,
      is_loading: is_loading,
      on_volume_pressed: on_volume_pressed,
      on_back_pressed: on_back_pressed,
      on_play_pressed: on_play_pressed,
      on_forward_pressed: on_forward_pressed,
      on_share_pressed: on_share_pressed,
      primary_color: primary_color,
      secondary_color: secondary_color,
      share_url: share_url,
    );
  }
}

/// Callback type for when the FAB data is ready/updated.
/// The parent widget should use this data to build the FAB in its Scaffold.
typedef OnFabDataCallback = void Function(SlideshowFabData data);

class Slideshow extends StatefulWidget {
  final List<String>? image_paths;
  final List<String>? video_paths;
  final bool use_examples;
  final String title;
  final String subtitle;
  final String loading_message;

  /// Firebase Storage path for background music songs.
  /// Example: 'app/example_songs'
  /// If null, background music will be disabled.
  final String? songs_storage_path;

  /// URL to share when the share button is pressed.
  final String share_url;

  /// Subject for the share action.
  final String share_subject;

  /// Primary color for the FAB and controls.
  final Color primary_color;

  /// Secondary color for alternating FAB buttons.
  final Color secondary_color;

  /// Labels for the FAB buttons.
  final String menu_label;
  final String close_label;
  final String volume_label;
  final String back_label;
  final String play_label;
  final String forward_label;
  final String share_label;

  /// Callback to provide FAB data to the parent.
  /// The parent should use this to build the FAB in its Scaffold's floatingActionButton.
  /// The parent must create and maintain its own GlobalKey<ExpandableFabState>.
  final OnFabDataCallback? onFabData;

  const Slideshow({
    super.key,
    this.image_paths,
    this.video_paths,
    this.use_examples = false,
    this.title = "",
    this.subtitle = "",
    this.loading_message = "Loading...",
    this.songs_storage_path,
    this.share_subject = "Slideshow",
    this.primary_color = const Color(0xFFD9C7FF),
    this.secondary_color = const Color(0xFFFFC2E0),
    this.menu_label = "Music Menu",
    this.close_label = "Close",
    this.volume_label = "Toggle Volume",
    this.back_label = "Previous Song",
    this.play_label = "Play/Pause",
    this.forward_label = "Next Song",
    this.share_label = "Share",
    this.onFabData,
    this.share_url = "",
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

  Cubic animation_curve = Curves.fastOutSlowIn;
  Duration animation_duration = const Duration(milliseconds: 1000);

  static const int max_initial_images = 12;
  static const int image_batch_size = 8;
  static const Duration image_batch_delay = Duration(milliseconds: 300);

  static const int max_initial_videos = 4;
  static const int video_batch_size = 1;
  static const Duration video_batch_delay = Duration(seconds: 2);

  // Audio service for background music
  final SlideshowAudioService _audio_service = SlideshowAudioService.instance;
  StreamSubscription<SlideshowAudioState>? _audio_state_subscription;

  // Audio state
  bool _is_music_playing = false;
  bool _is_music_muted = false;
  bool _is_music_loading = false;

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

    // Videos are always muted - background music handles audio
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

  Future<void> _initialize_audio_service() async {
    // Determine the songs storage path
    final String songs_path = widget.songs_storage_path ?? 'app/example_songs';

    final Reference songs_storage_ref = FirebaseStorage.instance.ref(songs_path);

    // Subscribe to audio state changes
    _audio_state_subscription = _audio_service.state_stream.listen((state) {
      if (mounted) {
        setState(() {
          _is_music_playing = state.is_playing;
          _is_music_muted = state.is_muted;
          _is_music_loading = state.is_loading;
        });
        // Update the FAB data when audio state changes
        _notify_fab_data();
      }
    });

    // Initialize the audio service
    await _audio_service.initialize(storage_ref: songs_storage_ref);
  }

  void _notify_fab_data() {
    if (widget.onFabData != null) {
      widget.onFabData!(_build_fab_data());
    }
  }

  SlideshowFabData _build_fab_data() {
    return SlideshowFabData(
      sound_is_on: !_is_music_muted,
      is_playing: _is_music_playing,
      is_loading: _is_music_loading,
      on_volume_pressed: _on_volume_pressed,
      on_back_pressed: _on_back_pressed,
      on_play_pressed: _on_play_pressed,
      on_forward_pressed: _on_forward_pressed,
      on_share_pressed: _on_share_pressed,
      menu_label: widget.menu_label,
      close_label: widget.close_label,
      volume_label: widget.volume_label,
      back_label: widget.back_label,
      play_label: widget.play_label,
      forward_label: widget.forward_label,
      share_label: widget.share_label,
      primary_color: widget.primary_color,
      secondary_color: widget.secondary_color,
      share_url: widget.share_url,
    );
  }

  @override
  initState() {
    super.initState();

    if (!widget.use_examples) {
      get_image_sizes();
    } else {
      get_example_urls();
    }

    // Initialize background music
    _initialize_audio_service();

    // Notify parent with initial FAB data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notify_fab_data();
    });
  }

  @override
  void dispose() {
    for (var controller in portrait_video_player_controllers) {
      controller.dispose();
    }
    for (var controller in landscape_video_player_controllers) {
      controller.dispose();
    }
    _audio_state_subscription?.cancel();
    // Note: We don't dispose the audio service singleton here
    // as it may be reused
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

  void _on_volume_pressed() {
    _audio_service.toggle_mute();
  }

  void _on_back_pressed() {
    _audio_service.previous();
  }

  void _on_play_pressed() {
    _audio_service.toggle_play_pause();
  }

  void _on_forward_pressed() {
    _audio_service.next();
  }

  void _on_share_pressed() {
    SharePlus.instance.share(
      ShareParams(
        text: widget.share_url,
        subject: widget.share_subject,
      ),
    );
  }

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
        // Slideshow grid
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
                        item_count = slideshow_view_orientation == SlideshowViewOrientation.landscape
                            ? landscape_images.length
                            : slideshow_view_orientation == SlideshowViewOrientation.portrait
                                ? portrait_images.length
                                : all_images.length;
                      } else {
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

        // Center title and subtitle
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
}
