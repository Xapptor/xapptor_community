import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  ResumeSection.from_snapshot(
    Map<dynamic, dynamic> snapshot,
  )   : icon = snapshot['icon'] != null
            ? IconData(
                int.parse(snapshot['icon']),
                fontFamily: "MaterialIcons",
              )
            : null,
        code_point = snapshot['code_point'] != null
            ? int.parse(
                snapshot['code_point'],
              )
            : null,
        title = snapshot['title'],
        subtitle = snapshot['subtitle'],
        description = snapshot['description'],
        begin = snapshot['begin'] != null ? (snapshot['begin'] as Timestamp).toDate() : null,
        end = snapshot['end'] != null ? (snapshot['end'] as Timestamp).toDate() : null;

  Map<String, dynamic> to_json() {
    return {
      'icon': icon?.codePoint.toString(),
      'code_point': code_point?.toString(),
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'begin': begin,
      'end': end,
    };
  }

  Map<String, dynamic> to_pretty_json() {
    return {
      'icon': icon?.codePoint.toString(),
      'code_point': code_point?.toString(),
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'begin': begin?.toIso8601String(),
      'end': end?.toIso8601String(),
    };
  }

  ResumeSection.from_json(
    Map<String, dynamic> json,
  )   : icon = json['icon'] != null
            ? IconData(
                int.parse(json['icon']),
                fontFamily: "MaterialIcons",
              )
            : null,
        code_point = json['code_point'] != null
            ? int.parse(
                json['code_point'],
              )
            : null,
        title = json['title'],
        subtitle = json['subtitle'],
        description = json['description'],
        begin = json['begin'] != null ? DateTime.parse(json['begin']) : null,
        end = json['end'] != null ? DateTime.parse(json['end']) : null;

  factory ResumeSection.empty() {
    return ResumeSection(
      icon: null,
      code_point: null,
      title: null,
      subtitle: null,
      description: null,
      begin: null,
      end: null,
    );
  }
}
