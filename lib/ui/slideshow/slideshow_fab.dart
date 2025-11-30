import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Creates an expandable FAB for slideshow music controls.
///
/// This widget provides controls for:
/// - Volume on/off (mute toggle)
/// - Previous song
/// - Play/Pause
/// - Next song
/// - Share functionality
///
/// The FAB expands to show all controls and collapses to a menu icon.
Widget slideshow_fab({
  required GlobalKey<ExpandableFabState> expandable_fab_key,
  required String menu_label,
  required String close_label,
  required String volume_label,
  required String back_label,
  required String play_label,
  required String forward_label,
  required String share_label,
  required bool sound_is_on,
  required bool is_playing,
  required bool is_loading,
  required VoidCallback on_volume_pressed,
  required VoidCallback on_back_pressed,
  required VoidCallback on_play_pressed,
  required VoidCallback on_forward_pressed,
  required VoidCallback on_share_pressed,
  Color primary_color = const Color(0xFFD9C7FF),
  Color secondary_color = const Color(0xFFFFC2E0),
}) {
  return ExpandableFab(
    key: expandable_fab_key,
    type: ExpandableFabType.fan,
    pos: ExpandableFabPos.center,
    fanAngle: 180,
    distance: 100,
    duration: const Duration(milliseconds: 250),
    overlayStyle: null,
    openButtonBuilder: RotateFloatingActionButtonBuilder(
      child: Icon(
        is_playing ? Icons.music_note : Icons.music_off,
        color: Colors.white,
        size: 28,
      ),
      fabSize: ExpandableFabSize.small,
      foregroundColor: Colors.white,
      backgroundColor: primary_color,
      shape: const CircleBorder(),
    ),
    closeButtonBuilder: RotateFloatingActionButtonBuilder(
      child: const Icon(
        Icons.close,
        color: Colors.white,
        size: 28,
      ),
      fabSize: ExpandableFabSize.small,
      foregroundColor: Colors.white,
      backgroundColor: primary_color,
      shape: const CircleBorder(),
    ),
    children: [
      // VOLUME ON/OFF
      _build_fab_child(
        heroTag: 'slideshow_fab_volume',
        icon: sound_is_on ? FontAwesomeIcons.volumeHigh : FontAwesomeIcons.volumeXmark,
        tooltip: volume_label,
        color: secondary_color,
        on_pressed: on_volume_pressed,
      ),

      // BACK SONG
      _build_fab_child(
        heroTag: 'slideshow_fab_back',
        icon: FontAwesomeIcons.backward,
        tooltip: back_label,
        color: primary_color,
        on_pressed: on_back_pressed,
      ),

      // PLAY/STOP SONG
      _build_fab_child(
        heroTag: 'slideshow_fab_play',
        icon: is_loading
            ? FontAwesomeIcons.spinner
            : is_playing
                ? FontAwesomeIcons.pause
                : FontAwesomeIcons.play,
        tooltip: play_label,
        color: secondary_color,
        on_pressed: is_loading ? null : on_play_pressed,
        is_loading: is_loading,
      ),

      // FORWARD SONG
      _build_fab_child(
        heroTag: 'slideshow_fab_forward',
        icon: FontAwesomeIcons.forward,
        tooltip: forward_label,
        color: primary_color,
        on_pressed: on_forward_pressed,
      ),

      // SHARE BUTTON
      _build_fab_child(
        heroTag: 'slideshow_fab_share',
        icon: FontAwesomeIcons.share,
        tooltip: share_label,
        color: secondary_color,
        on_pressed: on_share_pressed,
      ),
    ],
  );
}

Widget _build_fab_child({
  required String heroTag,
  required IconData icon,
  required String tooltip,
  required Color color,
  required VoidCallback? on_pressed,
  bool is_loading = false,
}) {
  return FloatingActionButton.small(
    heroTag: heroTag,
    onPressed: on_pressed,
    backgroundColor: color,
    tooltip: tooltip,
    child: is_loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
  );
}
