import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/resume_editor/crud/read/get_slot_label.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_additional_options.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_fab.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_init_state.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_preview.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_text_fields.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_text_lists.dart';
import 'package:xapptor_community/resume/models/resume_section.dart';
import 'package:xapptor_community/resume/models/resume_skill.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_top_option_buttons.dart';
import 'package:xapptor_community/resume/resume_editor/resume_sections.dart';
import 'package:xapptor_community/resume/resume_editor/crud/update/update_source_language.dart';
import 'package:xapptor_translation/language_picker.dart';
import 'package:xapptor_translation/model/text_list.dart';
import 'package:xapptor_translation/translation_stream.dart';
import 'package:xapptor_ui/widgets/top_and_bottom/topbar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResumeEditor extends StatefulWidget {
  final Color color_topbar;
  final String base_url;
  final double text_bottom_margin_for_section;
  final String organization_name;

  const ResumeEditor({
    super.key,
    required this.color_topbar,
    required this.base_url,
    this.text_bottom_margin_for_section = 3,
    required this.organization_name,
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

  late TranslationTextListArray text_list;
  TranslationTextListArray alert_text_list = ResumeEditorTextLists().alert_text_list;
  TranslationTextListArray skill_text_list = ResumeEditorTextLists().skill_text_list;
  TranslationTextListArray employment_text_list = ResumeEditorTextLists().employment_text_list;
  TranslationTextListArray education_text_list = ResumeEditorTextLists().education_text_list;
  TranslationTextListArray picker_text_list = ResumeEditorTextLists().picker_text_list;
  TranslationTextListArray sections_by_page_text_list = ResumeEditorTextLists().sections_by_page_text_list;
  TranslationTextListArray time_text_list = ResumeEditorTextLists().time_text_list;

  late TranslationStream translation_stream;
  late TranslationStream skill_translation_stream;
  late TranslationStream employment_translation_stream;
  late TranslationStream education_translation_stream;
  late TranslationStream picker_translation_stream;
  late TranslationStream sections_by_page_translation_stream;
  late TranslationStream time_translation_stream;

  List<TranslationStream> translation_stream_list = [];

  int source_language_index = 1;

  String chosen_image_path = "";
  String chosen_image_url = "";
  Uint8List? chosen_image_bytes;

  List<ResumeSkill> skill_sections = [];
  List<ResumeSection> employment_sections = [];
  List<ResumeSection> education_sections = [];
  List<ResumeSection> custom_sections = [];

  Color picker_color = Colors.blue;
  Color current_color = Colors.blue;

  User? current_user;

  int slot_index = 0;
  String slot_value = "";

  GlobalKey<ExpandableFabState> expandable_fab_key = GlobalKey<ExpandableFabState>();

  List<Resume> resumes = [];

  bool asked_for_backup_alert = false;

  String current_resume_id = "";

  @override
  void initState() {
    init_text_lists();

    super.initState();

    resume_editor_init_state();
  }

  init_text_lists() {
    text_list = ResumeEditorTextLists().text_list(
      organization_name: widget.organization_name,
    );
  }

  @override
  Widget build(BuildContext context) {
    screen_height = MediaQuery.of(context).size.height;
    screen_width = MediaQuery.of(context).size.width;
    bool portrait = screen_height > screen_width;

    Widget body = Container(
      color: Colors.white,
      width: double.maxFinite,
      child: Center(
        child: CircularProgressIndicator(
          color: widget.color_topbar,
        ),
      ),
    );

    if (resumes.isNotEmpty) {
      Resume current_resume = resumes.firstWhere((element) => element.id == current_resume_id, orElse: () {
        return resumes.firstWhere((element) => !element.id.contains("_bu"));
      });

      String slot_label = get_slot_label(
        slot_index: slot_index,
      );

      body = Stack(
        children: [
          Container(
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
                      if (font_families_value.isNotEmpty)
                        ResumeEditorAdditionalOptions(
                          callback: () {
                            setState(() {});
                          },
                        ),
                      resume_sections(),
                    ],
                  ),
                ),
                resume_editor_preview(
                  context: context,
                  portrait: portrait,
                  resume: current_resume,
                  base_url: widget.base_url,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          Container(
            color: widget.color_topbar.withOpacity(0.7),
            width: double.maxFinite,
            height: 40,
            child: Center(
              child: Text(
                "${alert_text_list.get(source_language_index)[13]}: $slot_label",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      );
    }

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
      floatingActionButton: current_user != null ? resume_editor_fab() : null,
      body: body,
    );
  }
}
