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
}
