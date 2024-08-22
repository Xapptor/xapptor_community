// ignore_for_file: invalid_use_of_protected_member

import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';

extension StateExtension on ResumeEditorState {
  clone_item({
    required int item_index,
    required int section_index,
  }) {
    if (section_index == 0) {
      skill_sections.insert(item_index, skill_sections[item_index]);
    } else if (section_index == 1) {
      employment_sections.insert(item_index, employment_sections[item_index]);
    } else if (section_index == 2) {
      education_sections.insert(item_index, education_sections[item_index]);
    } else if (section_index == 3) {
      custom_sections.insert(item_index, custom_sections[item_index]);
    }
    setState(() {});
  }
}
