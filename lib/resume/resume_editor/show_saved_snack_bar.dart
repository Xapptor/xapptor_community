import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';

extension ShowSavedSnackBar on ResumeEditorState {
  show_saved_snack_bar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectableText(
          text_list.get(source_language_index)[21],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
