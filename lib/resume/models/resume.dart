import 'package:flutter/material.dart';
import 'resume_section.dart';
import 'resume_skill.dart';

// Resume model.

class Resume {
  final String image_src;
  final String name;
  final String job_title;
  final String email;
  final String url;
  final List<ResumeSkill> skills;
  final List<ResumeSection> sections;
  final Color icon_color;

  const Resume({
    required this.image_src,
    required this.name,
    required this.job_title,
    required this.email,
    required this.url,
    required this.skills,
    required this.sections,
    required this.icon_color,
  });
}
