import 'package:flutter/material.dart';
import 'package:xapptor_logic/color/hex_color.dart';

class ResumeSkill {
  final String name;
  final double percentage;
  final Color color;

  const ResumeSkill({
    required this.name,
    required this.percentage,
    required this.color,
  });

  ResumeSkill.from_snapshot(
    Map<dynamic, dynamic> snapshot,
  )   : name = snapshot['name'],
        percentage = snapshot['percentage'].toDouble(),
        color = HexColor.fromHex(snapshot['color']);

  Map<String, dynamic> to_json() {
    return {
      'name': name,
      'percentage': percentage,
      'color': color.toHex(),
    };
  }

  factory ResumeSkill.empty() {
    return const ResumeSkill(
      name: "",
      percentage: 0.2,
      color: Colors.blue,
    );
  }
}
