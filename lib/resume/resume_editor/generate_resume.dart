import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/models/resume_section.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';

extension StateExtension on ResumeEditorState {
  Resume generate_resume() {
    return Resume(
      image_src: chosen_image_src,
      name: name_input_controller.text,
      job_title: job_title_input_controller.text,
      email: email_input_controller.text,
      website: website_input_controller.text,
      skills_title: text_list.get(source_language_index)[4],
      skills: skill_sections,
      sections_by_page: sections_by_page_input_controller.text
          .replaceAll(" ", "")
          .split(",")
          .map((e) => int.tryParse(e) ?? 1)
          .toList(),
      profile_section: ResumeSection(
        icon: Icons.badge,
        code_point: 0xea67,
        title: text_list.get(source_language_index)[5],
        description: profile_input_controller.text,
      ),
      employment_sections: employment_sections,
      education_sections: education_sections,
      custom_sections: custom_sections,
      icon_color: current_color,
      language_code: text_list.list[source_language_index].source_language,
      text_list: [
            text_list.get(source_language_index)[11],
          ] +
          text_list.get(source_language_index).sublist(18, 20) +
          [
            widget.base_url,
          ],
    );
  }
}
