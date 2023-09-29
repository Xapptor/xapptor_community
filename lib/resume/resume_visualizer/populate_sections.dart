import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/resume_visualizer/resume_section.dart';

List<dynamic> populate_sections({
  required Resume resume,
  required BuildContext context,
  required String language_code,
  required double text_bottom_margin,
}) {
  List<Widget> sections = [];
  List<pw.Widget> sections_pw = [];

  sections.add(
    resume_section(
      resume: resume,
      resume_section: resume.profile_section,
      text_bottom_margin: text_bottom_margin,
      context: context,
      language_code: language_code,
    ),
  );

  sections_pw.add(
    resume_section_pw(
      resume: resume,
      resume_section: resume.profile_section,
      text_bottom_margin: text_bottom_margin,
      context: context,
      language_code: language_code,
    ),
  );

  for (var section in resume.employment_sections) {
    sections.add(
      resume_section(
        resume: resume,
        resume_section: section,
        text_bottom_margin: text_bottom_margin,
        context: context,
        language_code: language_code,
      ),
    );

    sections_pw.add(
      resume_section_pw(
        resume: resume,
        resume_section: section,
        text_bottom_margin: text_bottom_margin,
        context: context,
        language_code: language_code,
      ),
    );
  }

  for (var section in resume.education_sections) {
    sections.add(
      resume_section(
        resume: resume,
        resume_section: section,
        text_bottom_margin: text_bottom_margin,
        context: context,
        language_code: language_code,
      ),
    );

    sections_pw.add(
      resume_section_pw(
        resume: resume,
        resume_section: section,
        text_bottom_margin: text_bottom_margin,
        context: context,
        language_code: language_code,
      ),
    );
  }

  for (var section in resume.custom_sections) {
    sections.add(
      resume_section(
        resume: resume,
        resume_section: section,
        text_bottom_margin: text_bottom_margin,
        context: context,
        language_code: language_code,
      ),
    );

    sections_pw.add(
      resume_section_pw(
        resume: resume,
        resume_section: section,
        text_bottom_margin: text_bottom_margin,
        context: context,
        language_code: language_code,
      ),
    );
  }
  return [sections, sections_pw];
}
