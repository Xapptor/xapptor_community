// ignore_for_file: invalid_use_of_protected_member

import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';

extension RemoveItem on ResumeEditorState {
  remove_item(int item_index, int section_index) {
    if (section_index == 0) {
      skill_sections.removeAt(item_index);
    } else if (section_index == 1) {
      employment_sections.removeAt(item_index);
    } else if (section_index == 2) {
      education_sections.removeAt(item_index);
    } else if (section_index == 3) {
      custom_sections.removeAt(item_index);
    }
    setState(() {});
  }
}
