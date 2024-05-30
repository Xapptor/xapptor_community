// ignore_for_file: invalid_use_of_protected_member

import 'package:xapptor_community/resume/resume_editor/apply_timer.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';

extension StateExtension on ResumeEditorState {
  update_source_language({
    required int new_source_language_index,
  }) {
    source_language_index = new_source_language_index;
    setState(() {});
    apply_timer();
  }
}
