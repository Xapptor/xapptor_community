// ignore_for_file: must_be_immutable

import 'dart:async';
import 'dart:typed_data';
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
import 'package:xapptor_db/xapptor_db.dart';

class ResumeVisualizer extends StatefulWidget {
  final String? resume_id;
  final Resume? resume;
  String language_code;
  final String base_url;
  final double text_bottom_margin_for_section;

  ResumeVisualizer({
    super.key,
    this.resume_id,
    this.resume,
    this.language_code = "en",
    required this.base_url,
    this.text_bottom_margin_for_section = 3,
  });

  @override
  State<ResumeVisualizer> createState() => _ResumeVisualizerState();
}

class _ResumeVisualizerState extends State<ResumeVisualizer> {
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
      text_bottom_margin: widget.text_bottom_margin_for_section,
    );

    sections = sections_data[0];
    sections_pw = sections_data[1];

    setState(() {});
  }

  String resume_id = "";

  fetch_resume() async {
    resume_id = widget.resume_id ?? get_last_path_segment();

    DocumentSnapshot resume_doc = await XapptorDB.instance.collection("resumes").doc(resume_id).get();

    Map? resume_map = resume_doc.data() as Map?;
    if (resume_map != null) {
      var remote_resume = Resume.from_snapshot(resume_id, resume_map);

      current_resume = remote_resume;
      widget.language_code = current_resume!.id.split("_").last;
    }
    populate_skills_and_sections();
  }

  Widget get_name_and_skills(
    bool portrait,
    double screen_width,
  ) {
    return name_and_skills(
      resume: current_resume!,
      portrait: portrait,
      screen_width: screen_width,
      skills: skills,
      text_bottom_margin: widget.text_bottom_margin_for_section,
      resume_link: "${widget.base_url}/resumes/$resume_id",
      language_code: widget.language_code,
      context: context,
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

      widget.language_code = current_resume!.id.split("_").last;

      current_user = FirebaseAuth.instance.currentUser!;
      resume_id = "${current_user.uid}_${widget.language_code}";

      populate_skills_timer = Timer(const Duration(milliseconds: 300), () {
        populate_skills_and_sections();
      });
    }
  }

  Widget? profile_image() {
    if (current_resume != null) {
      Uint8List? image_bytes = current_resume!.chosen_image_bytes;
      String image_url = current_resume!.image_url;

      if (image_bytes != null || image_url.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: image_bytes != null
              ? Image.memory(
                  image_bytes,
                  fit: BoxFit.contain,
                )
              : Image.network(
                  image_url,
                  fit: BoxFit.contain,
                ),
        );
      } else {
        return null;
      }
    } else {
      return null;
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
                              ? [
                                  if (profile_image() != null) profile_image()!,
                                  get_name_and_skills(
                                    portrait,
                                    screen_width,
                                  ),
                                ]
                              : [
                                  profile_image() != null
                                      ? Expanded(
                                          flex: 1,
                                          child: profile_image()!,
                                        )
                                      : const Spacer(flex: 1),
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
        : const CircularProgressIndicator();

    return widget.resume != null
        ? body
        : Scaffold(
            body: body,
          );
  }
}
