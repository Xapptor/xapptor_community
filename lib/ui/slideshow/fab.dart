// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

event_view_fab({
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
}) {
  return ExpandableFab(
    key: expandable_fab_key,
    distance: 200,
    duration: const Duration(milliseconds: 150),
    overlayStyle: const ExpandableFabOverlayStyle(
      blur: 5,
    ),
    openButtonBuilder: FloatingActionButtonBuilder(
      size: 20,
      builder: (context, on_pressed, progress) {
        return FloatingActionButton(
          heroTag: null,
          onPressed: on_pressed,
          tooltip: menu_label,
          child: const Icon(
            Icons.menu,
            color: Colors.white,
          ),
        );
      },
    ),
    closeButtonBuilder: FloatingActionButtonBuilder(
      size: 20,
      builder: (context, onPressed, progress) {
        return FloatingActionButton(
          heroTag: null,
          onPressed: onPressed,
          tooltip: close_label,
          child: const Icon(
            Icons.close,
            color: Colors.white,
          ),
        );
      },
    ),
    children: [
      // VOLUME ON/OFF
      //
      FloatingActionButton.extended(
        heroTag: null,
        onPressed: () {
          //
        },
        backgroundColor: Colors.pink,
        tooltip: volume_label,
        label: Icon(
          sound_is_on ? FontAwesomeIcons.volumeHigh : FontAwesomeIcons.volumeXmark,
          color: Colors.white,
          size: 20,
        ),
      ),

      // BACK SONG
      //
      FloatingActionButton.extended(
        heroTag: null,
        onPressed: () {
          //
        },
        backgroundColor: Colors.green,
        tooltip: back_label,
        label: const Icon(
          FontAwesomeIcons.backward,
          color: Colors.white,
          size: 20,
        ),
      ),

      // PLAY/STOP SONG
      //
      FloatingActionButton.extended(
        heroTag: null,
        onPressed: () {
          //
        },
        backgroundColor: Colors.red,
        tooltip: play_label,
        label: Icon(
          is_playing ? FontAwesomeIcons.stop : FontAwesomeIcons.play,
          color: Colors.white,
          size: 20,
        ),
      ),

      // FORWARD SONG
      //
      FloatingActionButton.extended(
        heroTag: null,
        onPressed: () {
          //
        },
        backgroundColor: Colors.green,
        tooltip: forward_label,
        label: const Icon(
          FontAwesomeIcons.forward,
          color: Colors.white,
          size: 20,
        ),
      ),

      // SHARE BUTTON
      //
      FloatingActionButton.extended(
        heroTag: null,
        onPressed: () {
          //
        },
        backgroundColor: Colors.red,
        tooltip: share_label,
        label: const Icon(
          FontAwesomeIcons.share,
          color: Colors.white,
          size: 20,
        ),
      ),
    ].reversed.toList(),
  );
}
