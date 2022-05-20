import 'package:flutter/material.dart';
import 'resume_section.dart';
import 'resume_skill.dart';
import 'package:xapptor_logic/hex_color.dart';

// Resume model.

class Resume {
  final String id;
  final String image_src;
  final String name;
  final String job_title;
  final String email;
  final String website;
  final String skills_title;
  final List<ResumeSkill> skills;
  final List<int> sections_by_page;
  final ResumeSection profile_section;
  final List<ResumeSection> employment_sections;
  final List<ResumeSection> education_sections;
  final List<ResumeSection> custom_sections;
  final Color icon_color;
  final String language_code;
  final List<String> text_list;

  const Resume({
    this.id = "",
    required this.image_src,
    required this.name,
    required this.job_title,
    required this.email,
    required this.website,
    required this.skills_title,
    required this.skills,
    required this.sections_by_page,
    required this.profile_section,
    required this.employment_sections,
    required this.education_sections,
    required this.custom_sections,
    required this.icon_color,
    required this.language_code,
    required this.text_list,
  });

  Resume.from_snapshot(
    String id,
    Map<dynamic, dynamic> snapshot,
  )   : id = id,
        image_src = snapshot['image_src'],
        name = snapshot['name'],
        job_title = snapshot['job_title'],
        email = snapshot['email'],
        website = snapshot['website'],
        skills_title = snapshot['skills_title'],
        skills = (snapshot['skills'] as List)
            .map((skill) => ResumeSkill.from_snapshot(skill))
            .toList(),
        sections_by_page = (snapshot['sections_by_page'] as List)
            .map((e) => e as int)
            .toList(),
        profile_section =
            ResumeSection.from_snapshot(snapshot['profile_section']),
        employment_sections = (snapshot['employment_sections'] as List)
            .map((section) => ResumeSection.from_snapshot(section))
            .toList(),
        education_sections = (snapshot['education_sections'] as List)
            .map((section) => ResumeSection.from_snapshot(section))
            .toList(),
        custom_sections = (snapshot['custom_sections'] as List)
            .map((section) => ResumeSection.from_snapshot(section))
            .toList(),
        icon_color = HexColor.fromHex(snapshot['icon_color']),
        language_code = snapshot['language_code'],
        text_list =
            (snapshot['text_list'] as List).map((e) => e as String).toList();

  Map<String, dynamic> to_json() {
    return {
      'image_src': image_src,
      'name': name,
      'job_title': job_title,
      'email': email,
      'website': website,
      'skills_title': skills_title,
      'skills': skills.map((e) => e.to_json()),
      'sections_by_page': sections_by_page,
      'profile_section': profile_section.to_json(),
      'employment_sections': employment_sections.map((e) => e.to_json()),
      'education_sections': education_sections.map((e) => e.to_json()),
      'custom_sections': custom_sections.map((e) => e.to_json()),
      'icon_color': icon_color.toHex(),
      'language_code': language_code,
      'text_list': text_list,
    };
  }
}
