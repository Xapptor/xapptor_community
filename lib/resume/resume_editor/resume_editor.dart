import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/resume_editor/generate_resume.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_fab.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_init_state.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_preview.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_text_fields.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_text_lists.dart';
import 'package:xapptor_community/resume/models/resume_section.dart';
import 'package:xapptor_community/resume/models/resume_skill.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_top_option_buttons.dart';
import 'package:xapptor_community/resume/resume_editor/resume_sections.dart';
import 'package:xapptor_community/resume/resume_editor/update_source_language.dart';
import 'package:xapptor_translation/language_picker.dart';
import 'package:xapptor_translation/model/text_list.dart';
import 'package:xapptor_translation/translation_stream.dart';
import 'package:xapptor_ui/widgets/topbar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResumeEditor extends StatefulWidget {
  final Color color_topbar;
  final String base_url;
  final double text_bottom_margin_for_section;

  const ResumeEditor({
    super.key,
    required this.color_topbar,
    required this.base_url,
    this.text_bottom_margin_for_section = 3,
  });

  @override
  State<ResumeEditor> createState() => ResumeEditorState();
}

class ResumeEditorState extends State<ResumeEditor> {
  TextEditingController name_input_controller = TextEditingController();
  TextEditingController job_title_input_controller = TextEditingController();
  TextEditingController email_input_controller = TextEditingController();
  TextEditingController website_input_controller = TextEditingController();
  TextEditingController profile_input_controller = TextEditingController();
  TextEditingController sections_by_page_input_controller = TextEditingController();

  FocusNode focus_node_1 = FocusNode();
  FocusNode focus_node_2 = FocusNode();
  FocusNode focus_node_3 = FocusNode();
  FocusNode focus_node_4 = FocusNode();
  FocusNode focus_node_5 = FocusNode();
  FocusNode focus_node_6 = FocusNode();
  FocusNode focus_node_7 = FocusNode();
  FocusNode focus_node_8 = FocusNode();
  FocusNode focus_node_9 = FocusNode();
  FocusNode focus_node_10 = FocusNode();

  double screen_height = 0;
  double screen_width = 0;

  ResumeEditorTextLists resume_editor_text_lists = ResumeEditorTextLists();

  TranslationTextListArray text_list = ResumeEditorTextLists().text_list;
  TranslationTextListArray skill_text_list = ResumeEditorTextLists().skill_text_list;
  TranslationTextListArray employment_text_list = ResumeEditorTextLists().employment_text_list;
  TranslationTextListArray education_text_list = ResumeEditorTextLists().education_text_list;
  TranslationTextListArray picker_text_list = ResumeEditorTextLists().picker_text_list;
  TranslationTextListArray sections_by_page_text_list = ResumeEditorTextLists().sections_by_page_text_list;

  late TranslationStream translation_stream;
  late TranslationStream skill_translation_stream;
  late TranslationStream employment_translation_stream;
  late TranslationStream education_translation_stream;
  late TranslationStream picker_translation_stream;
  late TranslationStream sections_by_page_translation_stream;

  List<TranslationStream> translation_stream_list = [];

  int source_language_index = 1;

  String chosen_image_src = "";
  String chosen_image_ext = "";

  List<ResumeSkill> skill_sections = [];
  List<ResumeSection> employment_sections = [];
  List<ResumeSection> education_sections = [];
  List<ResumeSection> custom_sections = [];

  Color picker_color = Colors.blue;
  Color current_color = Colors.blue;

  late User current_user;

  @override
  void initState() {
    super.initState();
    resume_editor_init_state();
  }

  @override
  Widget build(BuildContext context) {
    screen_height = MediaQuery.of(context).size.height;
    screen_width = MediaQuery.of(context).size.width;
    bool portrait = screen_height > screen_width;

    Resume resume = generate_resume();

    return Scaffold(
      appBar: TopBar(
        context: context,
        background_color: widget.color_topbar,
        has_back_button: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
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
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: resume_editor_fab(resume),
      body: Container(
        color: Colors.white,
        width: double.maxFinite,
        child: ListView(
          children: [
            FractionallySizedBox(
              widthFactor: portrait ? 0.9 : 0.4,
              child: Column(
                children: [
                  resume_editor_top_option_buttons(),
                  resume_editor_text_fields(),
                  resume_sections(),
                ],
              ),
            ),
            resume_editor_preview(
              context: context,
              portrait: portrait,
              resume: resume,
              source_language_index: source_language_index,
              base_url: widget.base_url,
            ),
          ],
        ),
      ),
    );
  }
}
