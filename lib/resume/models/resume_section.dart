import 'package:flutter/material.dart';

// ResumeSection model.

class ResumeSection {
  IconData? icon;
  int? code_point;
  String? title;
  String? subtitle;
  String? description;
  DateTime? begin;
  DateTime? end;

  ResumeSection({
    this.icon,
    this.code_point,
    this.title,
    this.subtitle,
    this.description,
    this.begin,
    this.end,
  });
}
