import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/get_timeframe_text.dart';
import 'package:xapptor_community/resume/models/resume_section.dart';
import 'package:xapptor_community/resume/models/resume_skill.dart';
import 'package:xapptor_community/resume/resume_editor/resume_section_form_item.dart';
import 'package:xapptor_ui/values/ui.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum ResumeSectionFormType {
  skill,
  employment_history,
  education,
  custom,
}

class ResumeSectionForm extends StatefulWidget {
  ResumeSectionForm({
    required this.resume_section_form_type,
    required this.text_list,
    required this.text_color,
    required this.language_code,
    required this.section_index,
    required this.update_item,
    required this.remove_item,
    required this.section_list,
  });

  final ResumeSectionFormType resume_section_form_type;
  final List<String> text_list;
  final Color text_color;
  final String language_code;
  final int section_index;
  final Function(int item_index, int section_index, dynamic section)
      update_item;
  final Function(int item_index, int section_index) remove_item;
  final List<dynamic> section_list;

  @override
  _ResumeSectionFormState createState() => _ResumeSectionFormState();
}

class _ResumeSectionFormState extends State<ResumeSectionForm> {
  TextEditingController title_input_controller = TextEditingController();
  TextEditingController subtitle_input_controller = TextEditingController();
  TextEditingController description_input_controller = TextEditingController();

  DateTime? selected_date_1;
  DateTime? selected_date_2;
  int selected_date_index = 0;
  String timeframe_text = "";

  remove_item(int item_index, int section_index) {
    widget.remove_item(item_index, section_index);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
  }

  add_item() {
    if (widget.resume_section_form_type == ResumeSectionFormType.skill) {
      widget.update_item(
        widget.section_list.length,
        widget.section_index,
        ResumeSkill(
          name: "",
          percentage: 0.2,
          color: Colors.blue,
        ),
      );
    } else {
      widget.update_item(
        widget.section_list.length,
        widget.section_index,
        ResumeSection(),
      );
    }
    setState(() {});
  }

  show_snack_bar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectableText(
          widget.text_list[10],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screen_height = MediaQuery.of(context).size.height;
    double screen_width = MediaQuery.of(context).size.width;
    bool portrait = screen_height > screen_width;

    if (selected_date_1 != null && selected_date_2 != null) {
      timeframe_text = get_timeframe_text(
        begin: selected_date_1!,
        end: selected_date_2!,
        language_code: widget.language_code,
        present_text: widget.text_list[4],
      );
    } else {
      timeframe_text = widget.text_list[5];
    }

    String title = "";

    switch (widget.resume_section_form_type) {
      case ResumeSectionFormType.skill:
        title = widget.text_list.last;
        break;
      case ResumeSectionFormType.employment_history:
        title = widget.text_list[0];
        break;
      case ResumeSectionFormType.education:
        title = widget.text_list[8];
        break;
      case ResumeSectionFormType.custom:
        title = widget.text_list[9];
        break;
    }

    return Container(
      child: Column(
        children: [
          SizedBox(
            height: sized_box_space * 2,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  if (widget.section_list.length > 0) {
                    if (widget.resume_section_form_type ==
                        ResumeSectionFormType.skill) {
                      ResumeSkill last_section = widget.section_list.last;

                      if (last_section.name.isNotEmpty) {
                        add_item();
                      } else {
                        show_snack_bar();
                      }
                    } else {
                      ResumeSection last_section = widget.section_list.last;

                      if (last_section.title != null ||
                          last_section.subtitle != null ||
                          last_section.description != null) {
                        add_item();
                      } else {
                        show_snack_bar();
                      }
                    }
                  } else {
                    add_item();
                  }
                },
                icon: Icon(
                  FontAwesomeIcons.squarePlus,
                ),
                color: Colors.blue,
              ),
            ],
          ),
          ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: widget.section_list.length,
            itemBuilder: (context, index) {
              return ResumeSectionFormItem(
                resume_section_form_type: widget.resume_section_form_type,
                text_list: widget.text_list.sublist(0, 10) +
                    widget.text_list.sublist(11),
                text_color: widget.text_color,
                language_code: widget.language_code,
                item_index: index,
                section_index: widget.section_index,
                update_item: widget.update_item,
                remove_item: remove_item,
                section: widget.section_list[index],
              );
            },
          ),
        ],
      ),
    );
  }
}
