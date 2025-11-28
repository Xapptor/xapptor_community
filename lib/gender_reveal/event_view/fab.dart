// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

event_view_fab({
  required GlobalKey<ExpandableFabState> expandable_fab_key,
  required String load_label,
  required String save_label,
  required String delete_label,
  required String download_label,
  required String menu_label,
  required String close_label,
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
      // LOAD

      FloatingActionButton.extended(
        heroTag: null,
        onPressed: () {
          //
        },
        backgroundColor: Colors.pink,
        tooltip: load_label,
        label: Row(
          children: [
            Text(
              load_label,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              FontAwesomeIcons.server,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),

      // SAVE

      FloatingActionButton.extended(
        heroTag: null,
        onPressed: () {
          //
        },
        backgroundColor: Colors.green,
        tooltip: save_label,
        label: Row(
          children: [
            Text(
              save_label,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              FontAwesomeIcons.cloudArrowUp,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),

      // DELETE

      FloatingActionButton.extended(
        heroTag: null,
        onPressed: () {
          //
        },
        backgroundColor: Colors.red,
        tooltip: delete_label,
        label: Row(
          children: [
            Text(
              delete_label,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              FontAwesomeIcons.trash,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    ].reversed.toList(),
  );
}
