import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_audio_service.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_custom_text.dart';
import 'package:xapptor_community/ui/slideshow/get_slideshow_matrix.dart';
import 'package:xapptor_community/ui/slideshow/loading_message.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_fab_data.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_content_loader.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_media_loader.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_view.dart';
import 'package:xapptor_ui/values/ui.dart';

// Re-export for external usage
export 'package:xapptor_community/ui/slideshow/slideshow_fab_data.dart';

class Slideshow extends StatefulWidget {
  final List<String>? image_paths;
  final List<String>? video_paths;
  final bool use_examples;
  final String title;
  final String subtitle;
  final String loading_message;
  final String? songs_storage_path;
  final String share_url;
  final String share_subject;
  final Color primary_color;
  final Color secondary_color;
  final String menu_label;
  final String close_label;
  final String volume_label;
  final String shuffle_label;
  final String repeat_label;
  final String back_label;
  final String play_label;
  final String forward_label;
  final String share_label;
  final TextStyle? title_style;
  final TextStyle? subtitle_style;
  final TextStyle? body_style;
  final BoxDecoration? text_container_decoration;
  final EdgeInsets? text_container_padding;
  final EdgeInsets? text_container_margin;
  final OnFabDataCallback? on_fab_data;

  const Slideshow({
    super.key,
    this.image_paths,
    this.video_paths,
    this.use_examples = false,
    this.title = "",
    this.subtitle = "",
    this.loading_message = "Loading...",
    this.songs_storage_path,
    this.share_subject = "Prepare to be amazed!",
    this.primary_color = const Color(0xFFD9C7FF),
    this.secondary_color = const Color(0xFFFFC2E0),
    this.menu_label = "Music Menu",
    this.close_label = "Close",
    this.volume_label = "Toggle Volume",
    this.shuffle_label = "Toggle Shuffle",
    this.repeat_label = "Toggle Repeat",
    this.back_label = "Previous Song",
    this.play_label = "Play/Pause",
    this.forward_label = "Next Song",
    this.share_label = "Share",
    this.title_style,
    this.subtitle_style,
    this.body_style,
    this.text_container_decoration,
    this.text_container_padding,
    this.text_container_margin,
    this.on_fab_data,
    this.share_url = "",
  });

  @override
  State<Slideshow> createState() => _SlideshowState();
}

class _SlideshowState extends State<Slideshow>
    with SlideshowMediaLoaderMixin, SlideshowContentLoaderMixin {
  final Cubic _animation_curve = Curves.fastOutSlowIn;
  final Duration _animation_duration = const Duration(milliseconds: 1000);

  final SlideshowAudioService _audio_service = SlideshowAudioService.instance;
  StreamSubscription<SlideshowAudioState>? _audio_state_subscription;

  bool _is_music_playing = false;
  bool _is_music_muted = false;
  bool _is_music_loading = false;
  bool _is_shuffle_enabled = false;
  LoopMode _loop_mode = LoopMode.all;

  List<List<Map<String, dynamic>>>? _slideshow_matrix;
  Orientation? _last_orientation;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() {
    load_content(
      use_examples: widget.use_examples,
      image_paths: widget.image_paths,
      video_paths: widget.video_paths,
    );
    _initialize_audio_service();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify_fab_data());
  }

  @override
  void didUpdateWidget(covariant Slideshow old_widget) {
    super.didUpdateWidget(old_widget);
    if (_fab_labels_changed(old_widget)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _notify_fab_data();
      });
    }
  }

  bool _fab_labels_changed(Slideshow old_widget) {
    return old_widget.menu_label != widget.menu_label ||
        old_widget.close_label != widget.close_label ||
        old_widget.volume_label != widget.volume_label ||
        old_widget.shuffle_label != widget.shuffle_label ||
        old_widget.repeat_label != widget.repeat_label ||
        old_widget.back_label != widget.back_label ||
        old_widget.play_label != widget.play_label ||
        old_widget.forward_label != widget.forward_label ||
        old_widget.share_label != widget.share_label;
  }

  @override
  void dispose() {
    dispose_media_resources();
    _audio_state_subscription?.cancel();
    super.dispose();
  }

  Future<void> _initialize_audio_service() async {
    final String songs_path = widget.songs_storage_path ?? 'app/example_songs';
    final Reference songs_ref = FirebaseStorage.instance.ref(songs_path);

    _audio_state_subscription = _audio_service.state_stream.listen((state) {
      if (!mounted) return;

      final bool changed = _is_music_playing != state.is_playing ||
          _is_music_muted != state.is_muted ||
          _is_music_loading != state.is_loading ||
          _is_shuffle_enabled != state.is_shuffle_enabled ||
          _loop_mode != state.loop_mode;

      if (changed) {
        _is_music_playing = state.is_playing;
        _is_music_muted = state.is_muted;
        _is_music_loading = state.is_loading;
        _is_shuffle_enabled = state.is_shuffle_enabled;
        _loop_mode = state.loop_mode;
        _notify_fab_data();
      }
    });

    await _audio_service.initialize(storage_ref: songs_ref);
  }

  void _notify_fab_data() {
    widget.on_fab_data?.call(SlideshowFabData(
      sound_is_on: !_is_music_muted,
      shuffle_is_on: _is_shuffle_enabled,
      loop_mode: _loop_mode,
      is_playing: _is_music_playing,
      is_loading: _is_music_loading,
      on_volume_pressed: () => _audio_service.toggle_mute(),
      on_shuffle_pressed: () => _audio_service.toggle_shuffle(),
      on_repeat_pressed: () => _audio_service.toggle_loop(),
      on_back_pressed: () => _audio_service.previous(),
      on_play_pressed: () => _audio_service.toggle_play_pause(),
      on_forward_pressed: () => _audio_service.next(),
      on_share_pressed: () => SharePlus.instance.share(
        ShareParams(text: widget.share_url, subject: widget.share_subject),
      ),
      menu_label: widget.menu_label,
      close_label: widget.close_label,
      volume_label: widget.volume_label,
      shuffle_label: widget.shuffle_label,
      repeat_label: widget.repeat_label,
      back_label: widget.back_label,
      play_label: widget.play_label,
      forward_label: widget.forward_label,
      share_label: widget.share_label,
      primary_color: widget.primary_color,
      secondary_color: widget.secondary_color,
      share_url: widget.share_url,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (all_images.isEmpty) {
      return loading_message(loading_message: widget.loading_message);
    }

    final mq = MediaQuery.of(context);
    final portrait = mq.size.height > mq.size.width;
    final number_of_columns = portrait ? 2 : 4;

    if (_last_orientation != mq.orientation) {
      _last_orientation = mq.orientation;
      _slideshow_matrix = get_slideshow_matrix(
        screen_height: mq.size.height,
        screen_width: mq.size.width,
        portrait: portrait,
        number_of_columns: number_of_columns,
      );
      portrait_images.shuffle();
      landscape_images.shuffle();
      all_images.shuffle();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        _build_grid(mq.size.width, number_of_columns, portrait),
        if (all_images.isNotEmpty) _build_title_overlay(portrait),
      ],
    );
  }

  Widget _build_grid(double screen_width, int columns, bool portrait) {
    return Row(
      children: List.generate(
        _slideshow_matrix!.length,
        (col) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(
              _slideshow_matrix![col].length,
              (view) => _build_view(col, view, screen_width, columns, portrait),
            ),
          ),
        ),
      ),
    );
  }

  Widget _build_view(int col, int view, double width, int columns, bool port) {
    final config = _slideshow_matrix![col][view];
    final SlideshowViewOrientation orient = config['orientation'];
    final bool video_p = config['possible_video_position_for_portrait'] ?? false;
    final bool video_l = config['possible_video_position_for_landscape'] ?? false;

    int item_count = (!video_p && !video_l)
        ? (orient == SlideshowViewOrientation.landscape
            ? landscape_images.length
            : orient == SlideshowViewOrientation.portrait
                ? portrait_images.length
                : all_images.length)
        : (video_p
            ? portrait_video_player_controllers.length
            : landscape_video_player_controllers.length);

    return slideshow_view(
      column_index: col,
      view_index: view,
      slideshow_view_orientation: orient,
      item_count: item_count,
      possible_video_position_for_portrait: video_p,
      possible_video_position_for_landscape: video_l,
      portrait_video_player_controllers: portrait_video_player_controllers,
      landscape_video_player_controllers: landscape_video_player_controllers,
      screen_width: width,
      number_of_columns: columns,
      animation_duration: _animation_duration,
      animation_curve: _animation_curve,
      test_mode: false,
      portrait: port,
      slideshow_matrix: _slideshow_matrix!,
      portrait_images: portrait_images,
      landscape_images: landscape_images,
      all_images: all_images,
      on_lazy_load_request: handle_lazy_load_request,
      total_video_count: video_p ? portrait_video_urls.length : landscape_video_urls.length,
      total_image_count: orient == SlideshowViewOrientation.portrait
          ? portrait_image_urls.length
          : orient == SlideshowViewOrientation.landscape
              ? landscape_image_urls.length
              : all_image_urls.length,
    );
  }

  Widget _build_title_overlay(bool portrait) {
    return Container(
      alignment: Alignment.center,
      margin: widget.text_container_margin,
      child: Container(
        decoration: widget.text_container_decoration,
        padding: widget.text_container_padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            slideshow_custom_text(widget.title, type: CustomTextType.title,
                portrait: portrait, custom_title_style: widget.title_style,
                custom_subtitle_style: widget.subtitle_style,
                custom_body_style: widget.body_style),
            const SizedBox(height: sized_box_space),
            slideshow_custom_text(widget.subtitle, type: CustomTextType.subtitle,
                portrait: portrait, custom_title_style: widget.title_style,
                custom_subtitle_style: widget.subtitle_style,
                custom_body_style: widget.body_style),
          ],
        ),
      ),
    );
  }
}
