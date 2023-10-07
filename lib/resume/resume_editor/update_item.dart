// ignore_for_file: invalid_use_of_protected_member

import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';

extension StateExtension on ResumeEditorState {
  update_item(int item_index, int section_index, dynamic section) {
    if (section_index == 0) {
      //
      if (item_index < skill_sections.length) {
        skill_sections[item_index] = section;
      } else {
        skill_sections.add(section);
      }
      //
    } else if (section_index == 1) {
      //
      if (item_index < employment_sections.length) {
        employment_sections[item_index] = section;
      } else {
        employment_sections.add(section);
      }
      //
    } else if (section_index == 2) {
      //
      if (item_index < education_sections.length) {
        education_sections[item_index] = section;
      } else {
        education_sections.add(section);
      }
      //
    } else if (section_index == 3) {
      //
      if (item_index < custom_sections.length) {
        custom_sections[item_index] = section;
      } else {
        custom_sections.add(section);
      }
      //
    }
    setState(() {});
  }
}
