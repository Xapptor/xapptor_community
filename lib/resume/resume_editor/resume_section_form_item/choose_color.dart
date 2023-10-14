// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:xapptor_community/resume/resume_editor/resume_section_form_item/resume_section_form_item.dart';
import 'package:xapptor_community/resume/resume_editor/resume_section_form_item/update_item.dart';

extension StateExtension on ResumeSectionFormItemState {
  choose_color() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            widget.text_list[10],
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: picker_color,
              onColorChanged: (Color new_color) {
                picker_color = new_color;
                setState(() {});
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Ok'),
              onPressed: () {
                current_color = picker_color;
                setState(() {});
                Navigator.of(context).pop();
                update_item();
              },
            ),
          ],
        );
      },
    );
  }
}
