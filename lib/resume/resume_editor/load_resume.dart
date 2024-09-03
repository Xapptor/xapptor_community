// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:xapptor_community/resume/font_configuration.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/models/resume_font.dart';
import 'package:xapptor_community/resume/models/resume_skill.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_additional_options.dart';
import 'package:xapptor_community/resume/resume_editor/show_result_snack_bar.dart';
import 'package:xapptor_db/xapptor_db.dart';

extension StateExtension on ResumeEditorState {
  Future<Resume> load_resume_from_json(String resume_id) async {
    String resume_string = await rootBundle.loadString('packages/xapptor_community/assets/resume_example.json');
    Map<String, dynamic> resume_map = jsonDecode(resume_string);
    Resume resume = Resume.from_json(
      resume_id,
      resume_map,
    );
    return resume;
  }

  load_resume({
    bool load_example = false,
    required int new_slot_index,
  }) async {
    slot_index = new_slot_index;

    String resume_id = load_example
        ? "9999qDVf8FNmF9999TsmZhyk9999_en"
        : ("${current_user!.uid}_${text_list.list[source_language_index].source_language}");

    if (new_slot_index != 0 && !load_example) {
      resume_id += "_bu_$new_slot_index";
    }

    Resume current_resume = Resume.empty();

    if (resumes.map((e) => e.id).contains(resume_id)) {
      current_resume = resumes.firstWhere((element) => element.id == resume_id);
    } else {
      if (load_example) {
        current_resume = await load_resume_from_json(resume_id);
        chosen_image_path = 'packages/xapptor_community/assets/resume_photo_small.png';
        chosen_image_bytes = await rootBundle.load(chosen_image_path).then(
              (ByteData byteData) => byteData.buffer.asUint8List(),
            );
        resumes.add(current_resume);
      } else {
        DocumentSnapshot resume_doc = await XapptorDB.instance.collection("resumes").doc(resume_id).get();

        Map? resume_map = resume_doc.data() as Map?;
        if (resume_map != null) {
          current_resume = Resume.from_snapshot(resume_id, resume_map);
        }
      }
    }

    Timestamp current_resume_date = current_resume.creation_date;
    Timestamp empty_resume_date = Resume.empty().creation_date;

    if (current_resume_date != empty_resume_date) {
      // SETTING TRANSLATED TITLES

      List<String> text_array = text_list.get(source_language_index);
      current_resume.skills_title = text_array[4];
      current_resume.profile_section.title = text_array[5];

      current_resume.employment_sections.first.title = text_array[7];
      current_resume.education_sections.first.title = text_array[15];

      List<String> time_text_array = time_text_list.get(source_language_index);

      current_resume.text_list = [
            text_array[11],
          ] +
          text_array.sublist(18, 20) +
          [
            widget.base_url,
          ] +
          time_text_array;

      current_resume_id = current_resume.id;

      chosen_image_url = current_resume.image_url;

      current_color = current_resume.icon_color;
      picker_color = current_resume.icon_color;

      name_input_controller.text = current_resume.name;
      job_title_input_controller.text = current_resume.job_title;
      email_input_controller.text = current_resume.email;
      website_input_controller.text = current_resume.website;
      profile_input_controller.text = current_resume.profile_section.description!;

      sections_by_page_input_controller.text = current_resume.sections_by_page.join(", ");

      if (load_example) {
        skill_sections.clear();
        employment_sections.clear();
        education_sections.clear();
        custom_sections.clear();
        setState(() {});
      }

      font_families_value = await font_families();

      current_font_value = font_families_value.first;

      current_font_value = font_families_value.firstWhere(
        (ResumeFont font) => font.name.toLowerCase() == current_resume.font_name.toLowerCase(),
      );

      show_time_amount = current_resume.show_time_amount;

      Timer(Duration(milliseconds: load_example ? 100 : 0), () {
        skill_sections = current_resume.skills;
        employment_sections = current_resume.employment_sections;
        education_sections = current_resume.education_sections;
        custom_sections = current_resume.custom_sections;
        setState(() {});
      });
    } else {
      name_input_controller.text = current_resume.name;
      job_title_input_controller.text = current_resume.job_title;
      email_input_controller.text = current_resume.email;
      website_input_controller.text = current_resume.website;
      profile_input_controller.text = current_resume.profile_section.description ?? "";

      skill_sections = [ResumeSkill.empty()];
      employment_sections = [];
      education_sections = [];
      custom_sections = [];

      setState(() {});
    }

    show_result_snack_bar(
      result_snack_bar_type: ResultSnackBarType.loaded,
      slot_index: new_slot_index,
    );
  }
}
