import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:xapptor_logic/random_number_with_range.dart';
import 'package:xapptor_community/resume/models/resume_skill.dart' as SkillData;
import 'package:pdf/widgets.dart' as pw;

// Resume, skill widget por PDF.

pw.Widget resume_skill_pw({
  required SkillData.ResumeSkill skill,
  required BuildContext context,
}) {
  double current_bar_width = 165 * skill.percentage;

  PdfColor pdf_color = PdfColor.fromInt(
    skill.color.value,
  );

  PdfColor background_color = PdfColor(
    (pdf_color.red + ((1 - pdf_color.red) * 0.5)).clamp(0, 1),
    (pdf_color.green + ((1 - pdf_color.green) * 0.5)).clamp(0, 1),
    (pdf_color.blue + ((1 - pdf_color.blue) * 0.5)).clamp(0, 1),
  );

  return pw.Container(
    margin: pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          margin: pw.EdgeInsets.only(bottom: 2),
          child: pw.Text(
            skill.name,
            textAlign: pw.TextAlign.left,
            style: pw.TextStyle(
              color: PdfColors.black,
              fontSize: 8,
            ),
          ),
        ),
        pw.Stack(
          children: [
            pw.Container(
              height: 7,
              width: double.maxFinite,
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(3.5),
                color: background_color,
              ),
            ),
            pw.Container(
              height: 7,
              width: current_bar_width,
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(3.5),
                color: PdfColor.fromInt(
                  skill.color.value,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// Resume, skill widget.

class ResumeSkill extends StatefulWidget {
  const ResumeSkill({
    required this.skill,
    required this.apply_variation,
  });

  final SkillData.ResumeSkill skill;
  final bool apply_variation;

  @override
  _ResumeSkillState createState() => _ResumeSkillState();
}

class _ResumeSkillState extends State<ResumeSkill> {
  double current_percentage = 0.1;
  double percentage_variation = 0;

  Timer initial_timer = Timer(Duration(seconds: 0), () {});
  Timer timer_initial_variation = Timer(Duration(seconds: 0), () {});
  Timer periodic_timer_variation = Timer(Duration(seconds: 0), () {});

  update_bar_width() {
    initial_timer = Timer(Duration(milliseconds: 2000), () {
      current_percentage = widget.skill.percentage;
      setState(() {});
    });

    if (widget.apply_variation) {
      timer_initial_variation = Timer(Duration(milliseconds: 3000), () {
        periodic_timer_variation = Timer.periodic(
            Duration(milliseconds: random_number_with_range(2000, 3500)),
            (timer) {
          percentage_variation = random_number_with_range(-50, 50) / 1000;
          setState(() {});
        });
      });
    }
  }

  @override
  void dispose() {
    initial_timer.cancel();
    timer_initial_variation.cancel();
    periodic_timer_variation.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    update_bar_width();
  }

  @override
  Widget build(BuildContext context) {
    double screen_height = MediaQuery.of(context).size.height;
    double screen_width = MediaQuery.of(context).size.width;
    bool portrait = screen_height > screen_width;
    double current_bar_width = (screen_width * (portrait ? 0.38 : 0.13)) *
        (current_percentage + percentage_variation);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 4),
            child: SelectableText(
              widget.skill.name,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
          ),
          Stack(
            children: [
              Container(
                height: 7,
                width: double.maxFinite,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1000),
                  color: widget.skill.color.withOpacity(0.5),
                ),
              ),
              AnimatedContainer(
                curve: Curves.elasticOut,
                duration: Duration(milliseconds: 2000),
                height: 7,
                width: current_bar_width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1000),
                  color: widget.skill.color,
                  boxShadow: [
                    BoxShadow(
                      color: widget.skill.color,
                      blurRadius: 4,
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
