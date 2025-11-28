import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/resume_editor/crud/delete/remove_item.dart';
import 'package:xapptor_community/resume/resume_editor/crud/update/clone_item.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:xapptor_community/resume/resume_editor/resume_section_form.dart';
import 'package:xapptor_community/resume/resume_editor/crud/update/update_section.dart';
import 'package:xapptor_ui/values/ui.dart';

extension StateExtension on ResumeEditorState {
  resume_sections() => Column(
        children: [
          ResumeSectionForm(
            resume_section_form_type: ResumeSectionFormType.skill,
            text_list: text_list.get(source_language_index).sublist(7, 18) +
                skill_text_list.get(source_language_index) +
                picker_text_list.get(source_language_index) +
                text_list.get(source_language_index).sublist(4, 5),
            time_text_list: time_text_list.get(source_language_index),
            text_color: widget.color_topbar,
            language_code: text_list.list[source_language_index].source_language,
            section_index: 0,
            update_section: update_section,
            remove_item: remove_item,
            clone_item: clone_item,
            section_list: skill_sections,
          ),
          const SizedBox(height: sized_box_space * 2),

          // Old Way to manually asign sections in each page

          // Align(
          //   alignment: Alignment.centerLeft,
          //   child: Text(
          //     sections_by_page_text_list.get(source_language_index)[0],
          //     style: const TextStyle(
          //       fontSize: 18,
          //       fontWeight: FontWeight.bold,
          //     ),
          //   ),
          // ),
          // resume_editor_text_field(
          //   label_text: sections_by_page_text_list.get(source_language_index)[1],
          //   controller: sections_by_page_input_controller,
          //   validator: (value) => FormFieldValidators(
          //     value: value!,
          //     type: FormFieldValidatorsType.name,
          //   ).validate(),
          // ),
          // SizedBox(
          //   height: sized_box_space * 2,
          // ),
          ResumeSectionForm(
            resume_section_form_type: ResumeSectionFormType.employment_history,
            text_list:
                text_list.get(source_language_index).sublist(7, 18) + employment_text_list.get(source_language_index),
            time_text_list: time_text_list.get(source_language_index),
            text_color: widget.color_topbar,
            language_code: text_list.list[source_language_index].source_language,
            section_index: 1,
            update_section: update_section,
            remove_item: remove_item,
            clone_item: clone_item,
            section_list: employment_sections,
          ),
          const SizedBox(height: sized_box_space * 2),
          ResumeSectionForm(
            resume_section_form_type: ResumeSectionFormType.education,
            text_list:
                text_list.get(source_language_index).sublist(7, 18) + education_text_list.get(source_language_index),
            time_text_list: time_text_list.get(source_language_index),
            text_color: widget.color_topbar,
            language_code: text_list.list[source_language_index].source_language,
            section_index: 2,
            update_section: update_section,
            remove_item: remove_item,
            clone_item: clone_item,
            section_list: education_sections,
          ),
          const SizedBox(height: sized_box_space * 2),
          ResumeSectionForm(
            resume_section_form_type: ResumeSectionFormType.custom,
            text_list: text_list.get(source_language_index).sublist(7, 18),
            time_text_list: time_text_list.get(source_language_index),
            text_color: widget.color_topbar,
            language_code: text_list.list[source_language_index].source_language,
            section_index: 3,
            update_section: update_section,
            remove_item: remove_item,
            clone_item: clone_item,
            section_list: custom_sections,
          ),
          const SizedBox(height: sized_box_space * 4),
        ],
      );
}
