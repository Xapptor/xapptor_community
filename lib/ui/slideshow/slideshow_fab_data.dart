import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:just_audio/just_audio.dart';
import 'package:xapptor_community/ui/slideshow/slideshow_fab.dart';

/// Data class containing all state needed to build the slideshow FAB.
/// This allows the parent widget to build the FAB in its own widget tree
/// with its own GlobalKey, while the Slideshow manages the audio state.
class SlideshowFabData {
  final bool sound_is_on;
  final bool shuffle_is_on;
  final LoopMode loop_mode;
  final bool is_playing;
  final bool is_loading;
  final VoidCallback on_volume_pressed;
  final VoidCallback on_shuffle_pressed;
  final VoidCallback on_repeat_pressed;
  final VoidCallback on_back_pressed;
  final VoidCallback on_play_pressed;
  final VoidCallback on_forward_pressed;
  final VoidCallback on_share_pressed;
  final String menu_label;
  final String close_label;
  final String volume_label;
  final String shuffle_label;
  final String repeat_label;
  final String back_label;
  final String play_label;
  final String forward_label;
  final String share_label;
  final Color primary_color;
  final Color secondary_color;
  final String share_url;

  const SlideshowFabData({
    required this.sound_is_on,
    required this.shuffle_is_on,
    required this.loop_mode,
    required this.is_playing,
    required this.is_loading,
    required this.on_volume_pressed,
    required this.on_shuffle_pressed,
    required this.on_repeat_pressed,
    required this.on_back_pressed,
    required this.on_play_pressed,
    required this.on_forward_pressed,
    required this.on_share_pressed,
    required this.menu_label,
    required this.close_label,
    required this.volume_label,
    required this.shuffle_label,
    required this.repeat_label,
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
      shuffle_label: shuffle_label,
      repeat_label: repeat_label,
      back_label: back_label,
      play_label: play_label,
      forward_label: forward_label,
      share_label: share_label,
      sound_is_on: sound_is_on,
      shuffle_is_on: shuffle_is_on,
      loop_mode: loop_mode,
      is_playing: is_playing,
      is_loading: is_loading,
      on_volume_pressed: on_volume_pressed,
      on_shuffle_pressed: on_shuffle_pressed,
      on_repeat_pressed: on_repeat_pressed,
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
