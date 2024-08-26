import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/models/resume_section.dart';
import 'package:xapptor_community/resume/models/resume_skill.dart';
import 'package:xapptor_community/resume/resume_editor/resume_section_form.dart';
import 'package:xapptor_community/resume/resume_editor/resume_section_form_item/resume_section_form_item.dart';

extension StateExtension on ResumeSectionFormItemState {
  update_item({
    bool update_widget = true,
  }) async {
    String title = "";
    switch (widget.resume_section_form_type) {
      case ResumeSectionFormType.skill:
        title = widget.text_list[0];
        break;
      case ResumeSectionFormType.employment_history:
        title = widget.text_list[0];
        break;
      case ResumeSectionFormType.education:
        title = widget.text_list[8];
        break;
      case ResumeSectionFormType.custom:
        title = widget.text_list[9];
        break;
    }

    switch (widget.resume_section_form_type) {
      case ResumeSectionFormType.skill:
        widget.update_item(
          item_index: widget.item_index,
          section_index: widget.section_index,
          section: ResumeSkill(
            name: field_1_input_controller.text,
            percentage: current_slider_value / 10,
            color: current_color,
          ),
          update_widget: update_widget,
        );
        break;
      case ResumeSectionFormType.employment_history:
        String subtitle =
            "${field_1_input_controller.text}${field_2_input_controller.text.isEmpty ? "" : " ${widget.text_list[11]} "}${field_2_input_controller.text}, ${field_3_input_controller.text}";

        widget.update_item(
          item_index: widget.item_index,
          section_index: widget.section_index,
          section: ResumeSection(
            icon: widget.item_index == 0 ? Icons.dvr_rounded : null,
            code_point: widget.item_index == 0 ? 0xe1b2 : null,
            title: widget.item_index == 0 ? title : null,
            subtitle: subtitle,
            description: field_4_input_controller.text,
            begin: selected_date_1,
            end: selected_date_2,
          ),
          update_widget: update_widget,
        );
        break;
      case ResumeSectionFormType.education:
        widget.update_item(
          item_index: widget.item_index,
          section_index: widget.section_index,
          section: ResumeSection(
            icon: widget.item_index == 0 ? Icons.history_edu_rounded : null,
            code_point: widget.item_index == 0 ? 0xea3e : null,
            title: widget.item_index == 0 ? title : null,
            subtitle:
                "${field_1_input_controller.text}, ${field_2_input_controller.text}, ${field_3_input_controller.text}",
            begin: selected_date_1,
            end: selected_date_2,
          ),
          update_widget: update_widget,
        );
        break;
      case ResumeSectionFormType.custom:
        widget.update_item(
          item_index: widget.item_index,
          section_index: widget.section_index,
          section: ResumeSection(
            title: field_1_input_controller.text,
            subtitle: field_2_input_controller.text,
            description: field_3_input_controller.text,
            begin: selected_date_1,
            end: selected_date_2,
          ),
          update_widget: update_widget,
        );
        break;
    }
  }
}
