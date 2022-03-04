import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:printing/printing.dart';
import 'package:xapptor_logic/file_downloader/file_downloader.dart';
import 'package:xapptor_community/resume/models/resume.dart' as ResumeData;
import 'package:xapptor_community/resume/resume_skill.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:xapptor_ui/widgets/url_text.dart';
import 'resume_section.dart';

class Resume extends StatefulWidget {
  const Resume({
    required this.resume,
    required this.visible,
  });

  final ResumeData.Resume resume;
  final bool visible;
  @override
  _ResumeState createState() => _ResumeState();
}

class _ResumeState extends State<Resume> {
  double screen_height = 0;
  double screen_width = 0;
  double text_bottom_margin = 3;

  // Download resume PDF.

  download_resume_pdf() async {
    final pdf = pw.Document();

    final profile_image = pw.MemoryImage(
      (await rootBundle.load(widget.resume.image_src)).buffer.asUint8List(),
    );

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
                          child: pw.Image(profile_image),
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
                              widget.resume.name,
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
                                widget.resume.job_title,
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
                                      text: widget.resume.email,
                                      url: "mailto:${widget.resume.email}",
                                    ),
                                  ),
                                  pw.Expanded(
                                    flex: 1,
                                    child: PdfUrlText(
                                      text: "My Website " + widget.resume.url,
                                      url: widget.resume.url,
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
              pw.Container(
                margin: pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Column(
                  children: sections_pw,
                ),
              ),
            ],
          )
        ],
      ),
    );

    await pdf.save().then((pdf_bytes) {
      FileDownloader.save(
        base64_string: base64Encode(pdf_bytes),
        file_name:
            "resume_${widget.resume.name.toLowerCase().replaceAll(" ", "_")}.pdf",
      );
    });
  }

  List<Widget> skills = [];
  List<pw.Widget> skills_pw = [];

  List<Widget> sections = [];
  List<pw.Widget> sections_pw = [];

  populate_skills() {
    skills.clear();
    skills_pw.clear();
    sections.clear();
    sections_pw.clear();

    widget.resume.skills.forEach((skill) {
      skills.add(
        ResumeSkill(
          skill: skill,
          apply_variation: widget.resume.skills.indexOf(skill) != 0,
        ),
      );

      skills_pw.add(
        resume_skill_pw(
          skill: skill,
          context: context,
        ),
      );
    });

    widget.resume.sections.forEach((section) {
      sections.add(
        resume_section(
          resume: widget.resume,
          resume_section: section,
          text_bottom_margin: text_bottom_margin,
          context: context,
        ),
      );

      sections_pw.add(
        resume_section_pw(
          resume: widget.resume,
          resume_section: section,
          text_bottom_margin: text_bottom_margin,
          context: context,
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
  }

  bool first_time_populating_skills = true;

  @override
  Widget build(BuildContext context) {
    screen_height = MediaQuery.of(context).size.height;
    screen_width = MediaQuery.of(context).size.width;
    bool portrait = screen_height > screen_width;

    if (first_time_populating_skills) {
      first_time_populating_skills = false;
      populate_skills();
    }

    Widget image = AnimatedOpacity(
      opacity: widget.visible ? 1 : 0,
      duration: Duration(milliseconds: 600),
      child: Container(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset(
            widget.resume.image_src,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );

    Widget name_and_skills = Container(
      margin:
          EdgeInsets.symmetric(horizontal: portrait ? 0 : (screen_width / 100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(
              top: portrait ? 10 : 0,
            ),
            child: SelectableText(
              widget.resume.name,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.black,
                fontSize: portrait ? 18 : 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SelectableText(
                  widget.resume.job_title,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: portrait ? 16 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    download_resume_pdf();
                  },
                  icon: Icon(
                    FontAwesome5.file_download,
                    color: widget.resume.icon_color,
                  ),
                )
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              bottom: 3,
            ),
            child: UrlText(
              text: widget.resume.email,
              url: "mailto:${widget.resume.email}",
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              top: 10,
              bottom: text_bottom_margin,
            ),
            child: SelectableText(
              "Dexterity Points",
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.black,
                fontSize: portrait ? 14 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: EdgeInsets.only(
                    right: 5,
                  ),
                  child: Column(
                    children: skills.sublist(0, (skills.length / 2).round()),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  margin: EdgeInsets.only(
                    left: 5,
                  ),
                  child: Column(
                    children: skills.sublist((skills.length / 2).round()),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return FractionallySizedBox(
      widthFactor: portrait ? 0.9 : 0.5,
      child: Container(
        color: Colors.white,
        child: Container(
          margin: EdgeInsets.symmetric(
            vertical: screen_height / 10,
            horizontal: screen_width * 0.05,
          ),
          child: Column(
            children: [
              Flex(
                direction: portrait ? Axis.vertical : Axis.horizontal,
                children: portrait
                    ? <Widget>[
                        image,
                        name_and_skills,
                      ]
                    : <Widget>[
                        Expanded(
                          flex: 1,
                          child: image,
                        ),
                        Expanded(
                          flex: 2,
                          child: name_and_skills,
                        ),
                      ],
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: sections,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
