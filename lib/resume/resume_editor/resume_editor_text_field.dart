import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';

extension ResumeEditorTextField on ResumeEditorState {
  resume_editor_text_field({
    required String label_text,
    required TextEditingController controller,
    required String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
  }) =>
      TextFormField(
        style: TextStyle(
          color: widget.color_topbar,
        ),
        decoration: InputDecoration(
          labelText: label_text,
          labelStyle: TextStyle(
            color: widget.color_topbar,
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: widget.color_topbar,
            ),
          ),
        ),
        controller: controller,
        validator: validator,
      );
}
