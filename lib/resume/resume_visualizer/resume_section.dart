import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/font_configuration.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/models/resume_section.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:xapptor_community/resume/get_timeframe_text.dart';
import 'package:xapptor_ui/utils/is_portrait.dart';

// Resume, descriptive section for PDF.

pw.Widget resume_section_pw({
  required Resume resume,
  required ResumeSection resume_section,
  required double text_bottom_margin,
  required BuildContext context,
  required String language_code,
}) {
  String timeframe_text = "";
  if (resume_section.begin != null && resume_section.end != null) {
    timeframe_text = get_timeframe_text(
      begin: resume_section.begin!,
      end: resume_section.end!,
      language_code: language_code,
      present_text: resume.text_list[0],
      text_list: resume.text_list.sublist(4),
    );
  }

  return pw.Container(
    margin: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 1,
          child: resume_section.code_point != null
              ? pw.Icon(
                  pw.IconData(
                    resume_section.code_point!,
                  ),
                  color: PdfColor(
                    resume.icon_color.r,
                    resume.icon_color.g,
                    resume.icon_color.b,
                    resume.icon_color.a,
                  ),
                  size: 16,
                )
              : pw.SizedBox(),
        ),
        pw.Expanded(
          flex: 20,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (resume_section.title != null)
                if (resume_section.title!.isNotEmpty)
                  pw.Container(
                    margin: pw.EdgeInsets.only(bottom: text_bottom_margin),
                    child: pw.Text(
                      resume_section.title!,
                      textAlign: pw.TextAlign.left,
                      style: pw.TextStyle(
                        color: PdfColors.black,
                        fontSize: font_size_section_title,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
              if (resume_section.subtitle != null)
                if (resume_section.subtitle!.isNotEmpty)
                  pw.Container(
                    margin: pw.EdgeInsets.only(bottom: text_bottom_margin),
                    child: pw.Text(
                      resume_section.subtitle!,
                      textAlign: pw.TextAlign.left,
                      style: pw.TextStyle(
                        color: PdfColors.black,
                        fontSize: font_size_section_subtitle,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
              if (resume_section.begin != null && resume_section.end != null)
                pw.Container(
                  margin: pw.EdgeInsets.only(bottom: text_bottom_margin),
                  child: pw.Text(
                    timeframe_text,
                    textAlign: pw.TextAlign.left,
                    style: pw.TextStyle(
                      color: PdfColors.black,
                      fontSize: font_size_section_timeframe,
                    ),
                  ),
                ),
              if (resume_section.description != null)
                if (resume_section.description!.isNotEmpty)
                  pw.Container(
                    margin: pw.EdgeInsets.only(bottom: text_bottom_margin),
                    child: pw.Text(
                      resume_section.description!,
                      textAlign: pw.TextAlign.left,
                      style: pw.TextStyle(
                        color: PdfColors.black,
                        fontSize: font_size_section_description,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    ),
  );
}

// Resume, descriptive section for visualizer.

resume_section({
  required Resume resume,
  required ResumeSection resume_section,
  required double text_bottom_margin,
  required BuildContext context,
  required String language_code,
}) {
  bool portrait = is_portrait(context);

  String timeframe_text = "";
  if (resume_section.begin != null && resume_section.end != null) {
    timeframe_text = get_timeframe_text(
      begin: resume_section.begin!,
      end: resume_section.end!,
      language_code: language_code,
      present_text: resume.text_list[0],
      text_list: resume.text_list.sublist(4),
    );
  }

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: resume_section.icon != null
              ? Icon(
                  resume_section.icon,
                  color: resume.icon_color,
                  size: portrait ? 18 : 22,
                )
              : const SizedBox(),
        ),
        Expanded(
          flex: portrait ? 8 : 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (resume_section.title != null)
                if (resume_section.title!.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(bottom: text_bottom_margin),
                    child: SelectableText(
                      resume_section.title!,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: portrait ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              if (resume_section.subtitle != null)
                if (resume_section.subtitle!.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(bottom: text_bottom_margin),
                    child: SelectableText(
                      resume_section.subtitle!,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              if (resume_section.begin != null && resume_section.end != null)
                Container(
                  margin: EdgeInsets.only(bottom: text_bottom_margin),
                  child: SelectableText(
                    timeframe_text,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (resume_section.description != null)
                if (resume_section.description!.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(bottom: text_bottom_margin),
                    child: SelectableText(
                      resume_section.description!,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    ),
  );
}
