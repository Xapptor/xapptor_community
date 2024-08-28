import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/resume_visualizer/download_resume_pdf.dart';
import 'package:xapptor_ui/values/ui.dart';
import 'package:xapptor_ui/widgets/url/url_text.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Widget name_and_skills({
  required Resume resume,
  required bool portrait,
  required double screen_width,
  required List<Widget> skills,
  required double text_bottom_margin,
  required String resume_link,
  required String language_code,
  required BuildContext context,
}) {
  return Container(
    margin: EdgeInsets.symmetric(horizontal: portrait ? 0 : (screen_width / 100)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(
            top: portrait ? 10 : 0,
          ),
          child: SelectableText(
            resume.name,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: Colors.black,
              fontSize: portrait ? 18 : 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SelectableText(
              resume.job_title,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.black,
                fontSize: portrait ? 16 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () {
                download_resume_pdf(
                  resume: resume,
                  text_bottom_margin_for_section: text_bottom_margin,
                  resume_link: resume_link,
                  context: context,
                  language_code: language_code,
                );
              },
              icon: Icon(
                FontAwesomeIcons.fileArrowDown,
                color: resume.icon_color,
              ),
            )
          ],
        ),
        Container(
          margin: const EdgeInsets.only(
            bottom: 3,
          ),
          child: Row(
            children: [
              UrlText(
                text: resume.email,
                url: "mailto:${resume.email}",
              ),
              SizedBox(width: sized_box_space),
              UrlText(
                text: 'Website',
                url: resume.website,
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(
            top: 10,
            bottom: text_bottom_margin,
          ),
          child: SelectableText(
            resume.skills_title,
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
                padding: const EdgeInsets.only(
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
                margin: const EdgeInsets.only(
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
}
