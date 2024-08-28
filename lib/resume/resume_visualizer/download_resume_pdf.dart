import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:xapptor_community/resume/font_configuration.dart';
import 'package:xapptor_community/resume/models/resume_font.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_additional_options.dart';
import 'package:xapptor_community/resume/resume_visualizer/populate_sections.dart';
import 'package:xapptor_community/resume/resume_visualizer/populate_skills.dart';
import 'package:xapptor_logic/file_downloader/file_downloader.dart';
import 'package:xapptor_ui/widgets/url/url_text.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:http/http.dart';

download_resume_pdf({
  required Resume resume,
  required double text_bottom_margin_for_section,
  required String resume_link,
  required BuildContext context,
  required String language_code,
}) async {
  final pdf = pw.Document();

  List<pw.Widget> skills_pw = populate_skills(
    resume: resume,
    context: context,
  )[1];

  List<pw.Widget> sections_pw = populate_sections(
    resume: resume,
    context: context,
    language_code: language_code,
    text_bottom_margin: text_bottom_margin_for_section,
  )[1];

  dynamic profile_image;

  if (resume.image_url.isNotEmpty) {
    if (resume.image_url.contains("http")) {
      //
      var response = await get(Uri.parse(resume.image_url));
      Uint8List? bytes = response.bodyBytes;
      profile_image = pw.MemoryImage(bytes);
      //
    } else if (resume.image_url.contains(".")) {
      //
      profile_image = pw.MemoryImage(
        (await rootBundle.load(resume.image_url)).buffer.asUint8List(),
      );
      //
    } else {
      profile_image = pw.MemoryImage(base64Decode(resume.image_url));
    }

    profile_image = pw.Image(profile_image);
  } else {
    profile_image = pw.Container();
  }

  ResumeFont font = current_font_value;

  pdf.addPage(
    pw.MultiPage(
      theme: pw.ThemeData.withFont(
        base: font.base,
        bold: font.bold,
        icons: await PdfGoogleFonts.materialIcons(),
      ),
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context page_context) => [
        pw.Wrap(
          children: [
                pw.Container(
                  height: 150,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Expanded(
                        flex: 1,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.only(
                            right: 0,
                          ),
                          child: pw.ClipRRect(
                            verticalRadius: 14,
                            horizontalRadius: 14,
                            child: profile_image,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Container(
                          padding: const pw.EdgeInsets.only(
                            left: 0,
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: <pw.Widget>[
                              pw.Text(
                                resume.name,
                                textAlign: pw.TextAlign.left,
                                style: pw.TextStyle(
                                  color: PdfColors.black,
                                  fontSize: font_size_name,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Container(
                                margin: const pw.EdgeInsets.only(
                                  top: 3,
                                ),
                                child: pw.Text(
                                  resume.job_title,
                                  textAlign: pw.TextAlign.left,
                                  style: pw.TextStyle(
                                    color: PdfColors.black,
                                    fontSize: font_size_job_title,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                              pw.Container(
                                margin: const pw.EdgeInsets.only(
                                  top: 3,
                                ),
                                child: pw.Row(
                                  children: [
                                    pw.Expanded(
                                      flex: 1,
                                      child: PdfUrlText(
                                        text: resume.email,
                                        url: "mailto:${resume.email}",
                                      ),
                                    ),
                                    pw.Expanded(
                                      flex: 1,
                                      child: PdfUrlText(
                                        text: resume.website,
                                        url: resume.website,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              pw.Container(
                                margin: pw.EdgeInsets.only(
                                  top: 3,
                                  bottom: text_bottom_margin_for_section,
                                ),
                                child: pw.Text(
                                  resume.skills_title,
                                  textAlign: pw.TextAlign.left,
                                  style: pw.TextStyle(
                                    color: PdfColors.black,
                                    fontSize: font_size_skills_title,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                              pw.Row(
                                children: [
                                  pw.Expanded(
                                    flex: 1,
                                    child: pw.Container(
                                      padding: const pw.EdgeInsets.only(
                                        right: 3,
                                      ),
                                      child: pw.Column(
                                        children: skills_pw.sublist(0, (skills_pw.length / 2).round()),
                                      ),
                                    ),
                                  ),
                                  pw.Expanded(
                                    flex: 1,
                                    child: pw.Container(
                                      margin: const pw.EdgeInsets.only(
                                        left: 3,
                                      ),
                                      child: pw.Column(
                                        children: skills_pw.sublist((skills_pw.length / 2).round()),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] +
              sections_pw.map((section) {
                return pw.Container(
                  child: section,
                );
              }).toList() +
              resume_available_info_text(
                resume: resume,
                resume_link: resume_link,
              ),

          // Old Way to manually asign sections in each page

          // ] +
          // get_sections_by_lengths(
          //   resume: resume,
          //   sections_pw: sections_pw,
          //   resume_link: resume_link,
          // ),
        ),
      ],
    ),
  );

  await pdf.save().then((pdf_bytes) {
    FileDownloader.save(
      src: pdf_bytes,
      file_name: "resume_${resume.name.toLowerCase().replaceAll(" ", "_")}.pdf",
    );
  });
}

List<pw.Container> get_sections_by_lengths({
  required Resume resume,
  required List<pw.Widget> sections_pw,
  required String resume_link,
}) {
  var sections_lengths = resume.sections_by_page;
  List<pw.Container> widgets = [];
  int index = 0;

  for (var section_length in sections_lengths) {
    widgets.add(
      pw.Container(
        margin: const pw.EdgeInsets.symmetric(vertical: 10),
        child: pw.Column(
          children: sections_pw.sublist(index, index + section_length),
        ),
      ),
    );
    index += section_length;
  }

  widgets = widgets +
      resume_available_info_text(
        resume: resume,
        resume_link: resume_link,
      );

  return widgets;
}

List<pw.Container> resume_available_info_text({
  required Resume resume,
  required String resume_link,
}) {
  return [
    pw.Container(
      alignment: pw.Alignment.centerLeft,
      margin: const pw.EdgeInsets.only(
        top: 20,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            resume.text_list[1],
            textAlign: pw.TextAlign.left,
            style: pw.TextStyle(
              color: PdfColors.black,
              fontSize: font_size_info_title,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          PdfUrlText(
            text: resume_link,
            url: resume_link,
            font_size: font_size_info_url,
          ),
          pw.Text(
            resume.text_list[2],
            textAlign: pw.TextAlign.left,
            style: pw.TextStyle(
              color: PdfColors.black,
              fontSize: font_size_info_title,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          PdfUrlText(
            text: resume.text_list[3],
            url: resume.text_list[3],
            font_size: font_size_info_url,
          ),
        ],
      ),
    ),
  ];
}
