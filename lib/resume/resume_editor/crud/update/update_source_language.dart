// ignore_for_file: invalid_use_of_protected_member

import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/resume_editor/apply_timer.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';

extension StateExtension on ResumeEditorState {
  update_source_language({
    required int new_source_language_index,
  }) {
    String past_language_code = text_list.list[source_language_index].source_language;
    source_language_index = new_source_language_index;
    String new_language_code = text_list.list[source_language_index].source_language;

    setState(() {});

    Resume? last_resume;

    if (slot_index < resumes.length) {
      last_resume = resumes[slot_index];
    }

    apply_timer(
      last_resume: last_resume,
      past_language_code: past_language_code,
      new_language_code: new_language_code,
    );
  }
}
