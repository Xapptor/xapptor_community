// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';

extension StateExtension on ResumeEditorState {
  choose_color() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            picker_text_list.get(source_language_index)[1],
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
          actions: [
            ElevatedButton(
              child: const Text('Got it'),
              onPressed: () {
                current_color = picker_color;
                setState(() => ());
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
