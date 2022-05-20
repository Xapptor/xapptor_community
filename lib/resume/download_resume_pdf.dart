import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:xapptor_logic/file_downloader/file_downloader.dart';
import 'package:xapptor_ui/widgets/url_text.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:http/http.dart';

download_resume_pdf({
  required Resume resume,
  required List<pw.Widget> skills_pw,
  required List<pw.Widget> sections_pw,
  required double text_bottom_margin,
}) async {
  final pdf = pw.Document();

  var profile_image;

  if (resume.image_src.isNotEmpty) {
    if (resume.image_src.contains("http")) {
      //
      var response = await get(Uri.parse(resume.image_src));
      Uint8List? bytes = response.bodyBytes;
      profile_image = pw.MemoryImage(bytes);
      //
    } else if (resume.image_src.contains(".")) {
      //
      profile_image = pw.MemoryImage(
        (await rootBundle.load(resume.image_src)).buffer.asUint8List(),
      );
      //
    } else {
      profile_image = pw.MemoryImage(base64Decode(resume.image_src));
    }

    profile_image = pw.Image(profile_image);
  } else {
    profile_image = pw.Container();
  }

  pdf.addPage(
    pw.MultiPage(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.quicksandRegular(),
        bold: await PdfGoogleFonts.quicksandMedium(),
        icons: await PdfGoogleFonts.materialIcons(),
      ),
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context page_context) => [
        pw.Column(
          children: [
                pw.Container(
                  height: 150,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Expanded(
                        flex: 1,
                        child: pw.Container(
                          padding: pw.EdgeInsets.only(
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
                          padding: pw.EdgeInsets.only(
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
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Container(
                                margin: pw.EdgeInsets.only(
                                  top: 3,
                                ),
                                child: pw.Text(
                                  resume.job_title,
                                  textAlign: pw.TextAlign.left,
                                  style: pw.TextStyle(
                                    color: PdfColors.black,
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                              pw.Container(
                                margin: pw.EdgeInsets.only(
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
                                        text: "My Website " + resume.website,
                                        url: resume.website,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              pw.Container(
                                margin: pw.EdgeInsets.only(
                                  top: 3,
                                  bottom: text_bottom_margin,
                                ),
                                child: pw.Text(
                                  "Dexterity Points",
                                  textAlign: pw.TextAlign.left,
                                  style: pw.TextStyle(
                                    color: PdfColors.black,
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                              pw.Row(
                                children: [
                                  pw.Expanded(
                                    flex: 1,
                                    child: pw.Container(
                                      padding: pw.EdgeInsets.only(
                                        right: 3,
                                      ),
                                      child: pw.Column(
                                        children: skills_pw.sublist(
                                            0, (skills_pw.length / 2).round()),
                                      ),
                                    ),
                                  ),
                                  pw.Expanded(
                                    flex: 1,
                                    child: pw.Container(
                                      margin: pw.EdgeInsets.only(
                                        left: 3,
                                      ),
                                      child: pw.Column(
                                        children: skills_pw.sublist(
                                            (skills_pw.length / 2).round()),
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
              get_sections_by_lengths(
                resume: resume,
                sections_pw: sections_pw,
              ),
        )
      ],
    ),
  );

  await pdf.save().then((pdf_bytes) {
    FileDownloader.save(
      src: base64Encode(pdf_bytes),
      file_name: "resume_${resume.name.toLowerCase().replaceAll(" ", "_")}.pdf",
    );
  });
}

List<pw.Container> get_sections_by_lengths({
  required Resume resume,
  required List<pw.Widget> sections_pw,
}) {
  var sections = [resume.profile_section] +
      resume.employment_sections +
      resume.education_sections +
      resume.custom_sections;

  var sections_lengths = resume.sections_by_page;
  List<pw.Container> widgets = [];
  int index = 0;

  sections_lengths.forEach((section_length) {
    widgets.add(
      pw.Container(
        margin: pw.EdgeInsets.symmetric(vertical: 10),
        child: pw.Column(
          children: sections_pw.sublist(index, index + section_length),
        ),
      ),
    );
    index += section_length;
  });

  return widgets;
}
