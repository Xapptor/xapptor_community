// ignore_for_file: invalid_use_of_protected_member

import 'package:xapptor_community/resume/models/resume_section.dart';
import 'package:xapptor_community/resume/models/resume_skill.dart';
import 'package:xapptor_community/resume/resume_editor/resume_section_form.dart';
import 'package:xapptor_community/resume/resume_editor/resume_section_form_item/resume_section_form_item.dart';

extension StateExtension on ResumeSectionFormItemState {
  populate_fields() {
    switch (widget.resume_section_form_type) {
      case ResumeSectionFormType.skill:
        ResumeSkill skill = widget.section;
        field_1_input_controller.text = skill.name;
        current_color = skill.color;
        current_slider_value = skill.percentage * 10;
        break;

      case ResumeSectionFormType.employment_history:
        ResumeSection section = widget.section;
        String at_text = widget.text_list[11];

        if (section.subtitle != null) {
          int at_index = section.subtitle!.indexOf(" $at_text ");
          int coma_index = section.subtitle!.lastIndexOf(", ");

          if (at_index > 0) {
            field_1_input_controller.text = section.subtitle!.substring(0, at_index);

            field_2_input_controller.text = section.subtitle!.substring(at_index + 4, coma_index);

            field_3_input_controller.text = section.subtitle!.substring(coma_index + 2);
          } else {
            field_1_input_controller.text = section.subtitle!.substring(0, coma_index);

            field_3_input_controller.text = section.subtitle!.substring(coma_index + 2);
          }
        }

        field_4_input_controller.text = section.description ?? "";

        selected_date_1 = section.begin;
        selected_date_2 = section.end;
        break;

      case ResumeSectionFormType.education:
        ResumeSection section = widget.section;

        if (section.subtitle != null) {
          int coma_index_1 = section.subtitle!.indexOf(", ");
          int coma_index_2 = section.subtitle!.lastIndexOf(", ");

          field_1_input_controller.text = section.subtitle!.substring(0, coma_index_1);

          field_2_input_controller.text = section.subtitle!.substring(coma_index_1 + 2, coma_index_2);

          field_3_input_controller.text = section.subtitle!.substring(coma_index_2 + 2);
        }

        selected_date_1 = section.begin;
        selected_date_2 = section.end;
        break;

      case ResumeSectionFormType.custom:
        ResumeSection section = widget.section;
        field_1_input_controller.text = section.title ?? "";
        field_2_input_controller.text = section.subtitle ?? "";
        field_3_input_controller.text = section.description ?? "";
        selected_date_1 = section.begin;
        selected_date_2 = section.end;
        break;
    }

    setState(() {});
  }
}
