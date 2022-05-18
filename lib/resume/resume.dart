import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome5_icons.dart';
import 'package:xapptor_community/resume/download_resume_pdf.dart';
import 'package:xapptor_community/resume/models/resume.dart' as ResumeData;
import 'package:xapptor_community/resume/resume_skill.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:xapptor_translation/language_picker.dart';
import 'package:xapptor_translation/model/text_list.dart';
import 'package:xapptor_translation/translation_stream.dart';
import 'package:xapptor_ui/widgets/topbar.dart';
import 'package:xapptor_ui/widgets/url_text.dart';
import 'resume_section.dart';
import 'package:intl/date_symbol_data_local.dart';

class Resume extends StatefulWidget {
  Resume({
    this.resume,
    this.language_code = "en",
    this.text_list,
    this.color_topbar = Colors.blueGrey,
  });

  ResumeData.Resume? resume;
  String language_code;
  List<String>? text_list;
  Color color_topbar;

  @override
  _ResumeState createState() => _ResumeState();
}

class _ResumeState extends State<Resume> {
  TranslationTextListArray text_list = TranslationTextListArray(
    [
      TranslationTextList(
        source_language: "en",
        text_list: [
          "Present",
        ],
      ),
      TranslationTextList(
        source_language: "es",
        text_list: [
          "Presente",
        ],
      ),
    ],
  );

  late TranslationStream translation_stream;
  List<TranslationStream> translation_stream_list = [];

  int source_language_index = 1;

  update_source_language({
    required int new_source_language_index,
  }) {
    source_language_index = new_source_language_index;
    setState(() {});
  }

  update_text_list({
    required int index,
    required String new_text,
    required int list_index,
  }) {
    text_list.get(source_language_index)[index] = new_text;
    setState(() {});
  }

  double text_bottom_margin = 3;

  List<Widget> skills = [];
  List<pw.Widget> skills_pw = [];

  List<Widget> sections = [];
  List<pw.Widget> sections_pw = [];

  late ResumeData.Resume current_resume;

  populate_skills() {
    skills.clear();
    skills_pw.clear();
    sections.clear();
    sections_pw.clear();

    if (widget.text_list == null) {
      widget.text_list = text_list.get(source_language_index);
    }

    current_resume.skills.forEach((skill) {
      skills.add(
        ResumeSkill(
          skill: skill,
          apply_variation: current_resume.skills.indexOf(skill) != 0,
        ),
      );

      skills_pw.add(
        resume_skill_pw(
          skill: skill,
          context: context,
        ),
      );
    });

    current_resume.sections.forEach((section) {
      sections.add(
        resume_section(
          resume: current_resume,
          resume_section: section,
          text_bottom_margin: text_bottom_margin,
          context: context,
          language_code: widget.language_code,
          text_list: widget.text_list!,
        ),
      );

      sections_pw.add(
        resume_section_pw(
          resume: current_resume,
          resume_section: section,
          text_bottom_margin: text_bottom_margin,
          context: context,
          language_code: widget.language_code,
          text_list: widget.text_list!,
        ),
      );
    });
  }

  fetch_resume() {
    populate_skills();
  }

  @override
  void initState() {
    super.initState();

    initializeDateFormatting();

    if (widget.resume == null) {
      fetch_resume();
    } else {
      current_resume = widget.resume!;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screen_height = MediaQuery.of(context).size.height;
    double screen_width = MediaQuery.of(context).size.width;
    bool portrait = screen_height > screen_width;

    if (widget.resume != null) {
      current_resume = widget.resume!;
      populate_skills();
    }

    Widget image = Container(
      child: current_resume.image_src.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                current_resume.image_src,
                fit: BoxFit.contain,
              ),
            )
          : Container(),
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
              current_resume.name,
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
                  current_resume.job_title,
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
                      resume: current_resume,
                      skills_pw: skills_pw,
                      sections_pw: sections_pw,
                      text_bottom_margin: text_bottom_margin,
                    );
                  },
                  icon: Icon(
                    FontAwesome5.file_download,
                    color: current_resume.icon_color,
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
              text: current_resume.email,
              url: "mailto:${current_resume.email}",
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              top: 10,
              bottom: text_bottom_margin,
            ),
            child: SelectableText(
              widget.resume!.skills_title,
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

    Widget body = FractionallySizedBox(
      widthFactor: portrait ? 0.9 : 0.5,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: screen_height / 10,
          horizontal: screen_width * 0.05,
        ),
        color: Colors.white,
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
    );

    return widget.text_list != null
        ? body
        : Scaffold(
            appBar: TopBar(
              background_color: widget.color_topbar,
              has_back_button: false,
              actions: [
                Container(
                  width: 150,
                  child: LanguagePicker(
                    translation_stream_list: translation_stream_list,
                    language_picker_items_text_color: widget.color_topbar,
                    update_source_language: update_source_language,
                  ),
                ),
              ],
              custom_leading: null,
              logo_path: "assets/images/logo.png",
            ),
            body: body,
          );
  }
}
