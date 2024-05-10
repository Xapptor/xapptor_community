// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/models/resume_section.dart';
import 'package:xapptor_community/resume/models/resume_skill.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:xapptor_community/resume/resume_editor/show_result_snack_bar.dart';

extension StateExtension on ResumeEditorState {
  load_resume({
    bool load_example = false,
    required int new_slot_index,
  }) async {
    slot_index = new_slot_index;

    String resume_doc_id = load_example
        ? "CH47ZwgMDrftCTsfnSoTW6KxTwE2_en"
        : ("${current_user!.uid}_${text_list.list[source_language_index].source_language}");

    if (new_slot_index != 0 && !load_example) {
      resume_doc_id += "_bu_$new_slot_index";
    }

    DocumentSnapshot resume_doc = await FirebaseFirestore.instance.collection("resumes").doc(resume_doc_id).get();

    Map? resume_map = resume_doc.data() as Map?;

    if (resume_map != null) {
      var remote_resume = Resume.from_snapshot(resume_doc_id, resume_map);

      chosen_image_url = remote_resume.image_url;
      current_color = remote_resume.icon_color;
      picker_color = remote_resume.icon_color;

      name_input_controller.text = remote_resume.name;
      job_title_input_controller.text = remote_resume.job_title;
      email_input_controller.text = remote_resume.email;
      website_input_controller.text = remote_resume.website;
      profile_input_controller.text = remote_resume.profile_section.description!;

      sections_by_page_input_controller.text = remote_resume.sections_by_page.join(", ");

      if (load_example) {
        skill_sections.clear();
        employment_sections.clear();
        education_sections.clear();
        custom_sections.clear();
        setState(() {});
      }

      Timer(Duration(milliseconds: load_example ? 100 : 0), () {
        skill_sections = remote_resume.skills;
        employment_sections = remote_resume.employment_sections;
        education_sections = remote_resume.education_sections;
        custom_sections = remote_resume.custom_sections;
        setState(() {});
      });
    } else {
      skill_sections = [
        const ResumeSkill(
          name: "",
          percentage: 0.2,
          color: Colors.blue,
        ),
      ];
      employment_sections = [
        ResumeSection(),
      ];
      education_sections = [
        ResumeSection(),
      ];
      setState(() {});
    }

    show_result_snack_bar(
      result_snack_bar_type: ResultSnackBarType.loaded,
      slot_index: new_slot_index,
    );
  }
}
