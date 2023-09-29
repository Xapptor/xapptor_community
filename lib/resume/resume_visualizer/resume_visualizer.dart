// ignore_for_file: must_be_immutable

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/resume_visualizer/name_and_skills.dart';
import 'package:xapptor_community/resume/resume_visualizer/populate_sections.dart';
import 'package:xapptor_community/resume/resume_visualizer/populate_skills.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xapptor_router/get_last_path_segment.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResumeVisualizer extends StatefulWidget {
  ResumeVisualizer({
    super.key,
    this.resume,
    this.language_code = "en",
    required this.base_url,
  });

  Resume? resume;
  String language_code;
  String base_url;

  @override
  State<ResumeVisualizer> createState() => _ResumeVisualizerState();
}

class _ResumeVisualizerState extends State<ResumeVisualizer> {
  double text_bottom_margin = 3;

  List<Widget> skills = [];
  List<pw.Widget> skills_pw = [];

  List<Widget> sections = [];
  List<pw.Widget> sections_pw = [];

  Resume? current_resume;

  populate_skills_and_sections() {
    skills.clear();
    skills_pw.clear();
    sections.clear();
    sections_pw.clear();

    List<dynamic> skills_data = populate_skills(
      resume: current_resume!,
      context: context,
    );

    skills = skills_data[0];
    skills_pw = skills_data[1];

    List<dynamic> sections_data = populate_sections(
      resume: current_resume!,
      context: context,
      language_code: widget.language_code,
      text_bottom_margin: text_bottom_margin,
    );

    sections = sections_data[0];
    sections_pw = sections_data[1];

    setState(() {});
  }

  String resume_doc_id = "";

  fetch_resume() async {
    resume_doc_id = get_last_path_segment();

    DocumentSnapshot resume_doc = await FirebaseFirestore.instance.collection("resumes").doc(resume_doc_id).get();

    Map? resume_map = resume_doc.data() as Map?;
    if (resume_map != null) {
      var remote_resume = Resume.from_snapshot(resume_doc_id, resume_map);

      current_resume = remote_resume;
    }
    populate_skills_and_sections();
  }

  Widget get_name_and_skills(bool portrait, double screen_width) {
    return name_and_skills(
      resume: current_resume!,
      portrait: portrait,
      screen_width: screen_width,
      skills: skills,
      skills_pw: skills_pw,
      sections_pw: sections_pw,
      text_bottom_margin: text_bottom_margin,
      resume_link: "${widget.base_url}/resumes/$resume_doc_id",
    );
  }

  late User current_user;

  Timer populate_skills_timer = Timer(const Duration(seconds: 0), () {});

  @override
  void dispose() {
    populate_skills_timer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    initializeDateFormatting();

    if (widget.resume == null) {
      fetch_resume();
    } else {
      current_resume = widget.resume!;
      current_user = FirebaseAuth.instance.currentUser!;
      resume_doc_id = "${current_user.uid}_${widget.language_code}";

      populate_skills_timer = Timer(const Duration(milliseconds: 300), () {
        populate_skills_and_sections();
      });
    }
  }

  Widget image() {
    if (current_resume != null) {
      String image_src = current_resume!.image_src;
      if (image_src.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: image_src.contains("http")
              ? Image.network(
                  image_src,
                  fit: BoxFit.contain,
                )
              : Image.memory(
                  base64Decode(image_src),
                  fit: BoxFit.contain,
                ),
        );
      } else {
        return Container();
      }
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    double screen_height = MediaQuery.of(context).size.height;
    double screen_width = MediaQuery.of(context).size.width;
    bool portrait = screen_height > screen_width;

    Widget body = current_resume != null
        ? Container(
            color: Colors.white,
            child: ListView(
              physics: widget.resume == null ? const ScrollPhysics() : const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: [
                Container(
                  margin: EdgeInsets.symmetric(
                    vertical: screen_height / 10,
                  ),
                  child: FractionallySizedBox(
                    widthFactor: portrait ? 0.85 : 0.5,
                    child: Column(
                      children: [
                        Flex(
                          direction: portrait ? Axis.vertical : Axis.horizontal,
                          children: portrait
                              ? <Widget>[
                                  image(),
                                  get_name_and_skills(
                                    portrait,
                                    screen_width,
                                  ),
                                ]
                              : <Widget>[
                                  Expanded(
                                    flex: 1,
                                    child: image(),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: get_name_and_skills(
                                      portrait,
                                      screen_width,
                                    ),
                                  ),
                                ],
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            children: sections,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        : Container();

    return widget.resume != null
        ? body
        : Scaffold(
            body: body,
          );
  }
}
