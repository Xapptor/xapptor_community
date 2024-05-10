// ignore_for_file: invalid_use_of_protected_member

import 'package:xapptor_community/resume/models/resume_section.dart';
import 'package:xapptor_community/resume/models/resume_skill.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';

enum ChangeItemPositionType {
  none,
  move_up,
  move_down,
}

extension StateExtension on ResumeEditorState {
  update_item({
    required int item_index,
    required int section_index,
    required dynamic section,
    ChangeItemPositionType change_item_position_type = ChangeItemPositionType.none,
  }) {
    late List<dynamic> dynamic_sections;

    if (section_index == 0) {
      dynamic_sections = skill_sections;
    } else if (section_index == 1) {
      dynamic_sections = employment_sections;
    } else if (section_index == 2) {
      dynamic_sections = education_sections;
    } else if (section_index == 3) {
      dynamic_sections = custom_sections;
    }

    for (var i = 0; i < dynamic_sections.length; i++) {
      print(dynamic_sections[i].to_json());
    }

    dynamic_sections = _update_dynamic(
      dynamic_sections: dynamic_sections,
      item_index: item_index,
      section_index: section_index,
      section: section,
      change_item_position_type: change_item_position_type,
    );

    print("");

    if (section_index == 0) {
      skill_sections = dynamic_sections as List<ResumeSkill>;
      for (var i = 0; i < skill_sections.length; i++) {
        print(skill_sections[i].to_json());
      }
    } else if (section_index == 1) {
      employment_sections = dynamic_sections as List<ResumeSection>;
    } else if (section_index == 2) {
      education_sections = dynamic_sections as List<ResumeSection>;
    } else if (section_index == 3) {
      custom_sections = dynamic_sections as List<ResumeSection>;
    }
    setState(() {});
  }

  List<dynamic> _update_dynamic({
    required List<dynamic> dynamic_sections,
    required int item_index,
    required int section_index,
    required dynamic section,
    ChangeItemPositionType change_item_position_type = ChangeItemPositionType.none,
  }) {
    if (change_item_position_type != ChangeItemPositionType.none) {
      if (change_item_position_type == ChangeItemPositionType.move_up) {
        dynamic_sections.swap(item_index, item_index - 1);
      } else if (change_item_position_type == ChangeItemPositionType.move_down) {
        dynamic_sections.swap(item_index, item_index + 1);
      }
    } else {
      if (item_index < skill_sections.length) {
        dynamic_sections[item_index] = section;
      } else {
        dynamic_sections.add(section);
      }
    }
    return dynamic_sections;
  }
}

// TODO: delete this extension
extension on List {
  void swap(int firstIndex, int secondIndex) {
    final temp = this[firstIndex];
    this[firstIndex] = this[secondIndex];
    this[secondIndex] = temp;
  }
}
