import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';

/// Creates an expandable FAB for slideshow music controls.
///
/// This widget provides 7 controls arranged in a fan pattern:
/// 1. Volume on/off (mute toggle)
/// 2. Shuffle toggle
/// 3. Repeat/Loop mode toggle
/// 4. Previous song
/// 5. Play/Pause (CENTER)
/// 6. Next song
/// 7. Share functionality
///
/// The FAB expands to show all controls and collapses to a menu icon.
Widget slideshow_fab({
  required GlobalKey<ExpandableFabState> expandable_fab_key,
  required String menu_label,
  required String close_label,
  required String volume_label,
  required String shuffle_label,
  required String repeat_label,
  required String back_label,
  required String play_label,
  required String forward_label,
  required String share_label,
  required bool sound_is_on,
  required bool shuffle_is_on,
  required LoopMode loop_mode,
  required bool is_playing,
  required bool is_loading,
  required VoidCallback on_volume_pressed,
  required VoidCallback on_shuffle_pressed,
  required VoidCallback on_repeat_pressed,
  required VoidCallback on_back_pressed,
  required VoidCallback on_play_pressed,
  required VoidCallback on_forward_pressed,
  required VoidCallback on_share_pressed,
  Color primary_color = const Color(0xFFD9C7FF),
  Color secondary_color = const Color(0xFFFFC2E0),
  required String share_url,
}) {
  // Get the appropriate icon for loop mode
  IconData loop_icon;
  switch (loop_mode) {
    case LoopMode.all:
      loop_icon = FontAwesomeIcons.repeat;
      break;
    case LoopMode.one:
      loop_icon = FontAwesomeIcons.rotate; // Represents "repeat one"
      break;
    case LoopMode.off:
      loop_icon = FontAwesomeIcons.rightLong;
      break;
  }

  return ExpandableFab(
    key: expandable_fab_key,
    type: ExpandableFabType.fan,
    pos: ExpandableFabPos.center,
    fanAngle: 180,
    distance: 110,
    duration: const Duration(milliseconds: 250),
    overlayStyle: null,
    openButtonBuilder: RotateFloatingActionButtonBuilder(
      fabSize: ExpandableFabSize.small,
      foregroundColor: Colors.white,
      backgroundColor: primary_color,
      child: Tooltip(
        message: menu_label,
        child: Icon(
          is_playing ? Icons.music_note : Icons.music_off,
          color: Colors.white,
          size: 28,
        ),
      ),
    ),
    closeButtonBuilder: RotateFloatingActionButtonBuilder(
      fabSize: ExpandableFabSize.small,
      foregroundColor: Colors.white,
      backgroundColor: primary_color,
      child: Tooltip(
        message: close_label,
        child: const Icon(
          Icons.close,
          color: Colors.white,
          size: 28,
        ),
      ),
    ),
    children: [
      // 1. SHUFFLE ON/OFF
      _build_fab_child(
        hero_tag: 'slideshow_fab_shuffle',
        icon: FontAwesomeIcons.shuffle,
        tooltip: shuffle_label,
        color: primary_color,
        on_pressed: on_shuffle_pressed,
        is_active: shuffle_is_on,
      ),

      // 2. REPEAT/LOOP MODE
      _build_fab_child(
        hero_tag: 'slideshow_fab_repeat',
        icon: loop_icon,
        tooltip: repeat_label,
        color: secondary_color,
        on_pressed: on_repeat_pressed,
        is_active: loop_mode != LoopMode.off,
        show_badge: loop_mode == LoopMode.one,
        badge_text: '1',
      ),

      // 3. PREVIOUS SONG
      _build_fab_child(
        hero_tag: 'slideshow_fab_back',
        icon: FontAwesomeIcons.backward,
        tooltip: back_label,
        color: primary_color,
        on_pressed: on_back_pressed,
      ),

      // 4. PLAY/PAUSE (CENTER - 4th of 7)
      _build_fab_child(
        hero_tag: 'slideshow_fab_play',
        icon: is_loading
            ? FontAwesomeIcons.spinner
            : is_playing
                ? FontAwesomeIcons.pause
                : FontAwesomeIcons.play,
        tooltip: play_label,
        color: secondary_color,
        on_pressed: is_loading ? null : on_play_pressed,
        is_loading: is_loading,
        is_center: false,
      ),

      // 5. NEXT SONG
      _build_fab_child(
        hero_tag: 'slideshow_fab_forward',
        icon: FontAwesomeIcons.forward,
        tooltip: forward_label,
        color: primary_color,
        on_pressed: on_forward_pressed,
      ),

      // 6. VOLUME ON/OFF
      _build_fab_child(
        hero_tag: 'slideshow_fab_volume',
        icon: sound_is_on ? FontAwesomeIcons.volumeHigh : FontAwesomeIcons.volumeXmark,
        tooltip: volume_label,
        color: secondary_color,
        on_pressed: on_volume_pressed,
        is_active: sound_is_on,
      ),

      // 7. SHARE BUTTON
      _build_fab_child(
        hero_tag: 'slideshow_fab_share',
        icon: FontAwesomeIcons.share,
        tooltip: share_label,
        color: primary_color,
        on_pressed: on_share_pressed,
      ),
    ],
  );
}

Widget _build_fab_child({
  required String hero_tag,
  required IconData icon,
  required String tooltip,
  required Color color,
  required VoidCallback? on_pressed,
  bool is_loading = false,
  bool is_active = false,
  bool is_center = false,
  bool show_badge = false,
  String badge_text = '',
}) {
  final double button_size = is_center ? 48.0 : 40.0;
  final double icon_size = is_center ? 20.0 : 18.0;

  // Dim inactive toggle buttons
  final Color button_color = is_active || !_is_toggle_button(hero_tag) ? color : color.withAlpha((255 * 0.5).round());

  Widget button = SizedBox(
    width: button_size,
    height: button_size,
    child: FloatingActionButton(
      heroTag: hero_tag,
      onPressed: on_pressed,
      backgroundColor: button_color,
      elevation: is_center ? 6 : 4,
      tooltip: tooltip,
      mini: !is_center,
      child: is_loading
          ? SizedBox(
              width: icon_size,
              height: icon_size,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(
              icon,
              color: Colors.white,
              size: icon_size,
            ),
    ),
  );

  // Add badge for "repeat one" mode
  if (show_badge) {
    button = Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Text(
              badge_text,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  return button;
}

/// Check if button is a toggle button (should show active/inactive state)
bool _is_toggle_button(String hero_tag) {
  return hero_tag == 'slideshow_fab_volume' || hero_tag == 'slideshow_fab_shuffle' || hero_tag == 'slideshow_fab_repeat';
}
