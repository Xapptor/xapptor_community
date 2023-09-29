import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:xapptor_community/resume/get_timeframe_text.dart';
import 'package:xapptor_community/resume/models/resume_section.dart';
import 'package:xapptor_community/resume/models/resume_skill.dart';
import 'package:xapptor_community/resume/resume_editor/resume_section_form.dart';
import 'package:xapptor_ui/values/ui.dart';
import 'package:xapptor_logic/form_field_validators.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ResumeSectionFormItem extends StatefulWidget {
  const ResumeSectionFormItem({
    super.key,
    required this.resume_section_form_type,
    required this.text_list,
    required this.text_color,
    required this.language_code,
    required this.item_index,
    required this.section_index,
    required this.update_item,
    required this.remove_item,
    required this.section,
  });

  final ResumeSectionFormType resume_section_form_type;
  final List<String> text_list;
  final Color text_color;
  final String language_code;
  final int item_index;
  final int section_index;
  final Function(int item_index, int section_index, dynamic section) update_item;
  final Function(int item_index, int section_index) remove_item;
  final dynamic section;

  @override
  _ResumeSectionFormItemState createState() => _ResumeSectionFormItemState();
}

class _ResumeSectionFormItemState extends State<ResumeSectionFormItem> {
  TextEditingController field_1_input_controller = TextEditingController();
  TextEditingController field_2_input_controller = TextEditingController();
  TextEditingController field_3_input_controller = TextEditingController();
  TextEditingController field_4_input_controller = TextEditingController();

  DateTime? selected_date_1;
  DateTime? selected_date_2;
  int selected_date_index = 0;
  String timeframe_text = "";

  populate_fields() {
    switch (widget.resume_section_form_type) {
      case ResumeSectionFormType.skill:
        ResumeSkill skill = widget.section;
        field_1_input_controller.text = skill.name;
        current_color = skill.color;
        _current_slider_value = skill.percentage * 10;
        break;

      case ResumeSectionFormType.employment_history:
        ResumeSection section = widget.section;
        String at_text = widget.text_list[11];

        if (section.subtitle != null) {
          int at_index = section.subtitle!.indexOf(" $at_text ");
          int coma_index = section.subtitle!.indexOf(", ");

          if (at_index > 0) {
            field_1_input_controller.text = section.subtitle!.substring(0, at_index);

            field_2_input_controller.text = section.subtitle!.substring(at_index + 4, coma_index);

            field_3_input_controller.text = section.subtitle!.substring(coma_index + 2);
          } else {
            field_1_input_controller.text = section.subtitle!.substring(0, coma_index);

            field_3_input_controller.text = section.subtitle!.substring(coma_index + 2);
          }
        }

        field_4_input_controller.text = section.description ?? "";

        selected_date_1 = section.begin;
        selected_date_2 = section.end;
        break;

      case ResumeSectionFormType.education:
        ResumeSection section = widget.section;

        if (section.subtitle != null) {
          int coma_index_1 = section.subtitle!.indexOf(", ");
          int coma_index_2 = section.subtitle!.lastIndexOf(", ");

          field_1_input_controller.text = section.subtitle!.substring(0, coma_index_1);

          field_2_input_controller.text = section.subtitle!.substring(coma_index_1 + 2, coma_index_2);

          field_3_input_controller.text = section.subtitle!.substring(coma_index_2 + 2);
        }

        selected_date_1 = section.begin;
        selected_date_2 = section.end;
        break;

      case ResumeSectionFormType.custom:
        ResumeSection section = widget.section;
        field_1_input_controller.text = section.title ?? "";
        field_2_input_controller.text = section.subtitle ?? "";
        field_3_input_controller.text = section.description ?? "";
        selected_date_1 = section.begin;
        selected_date_2 = section.end;
        break;
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    populate_fields();
  }

  update_item() {
    String title = "";
    switch (widget.resume_section_form_type) {
      case ResumeSectionFormType.skill:
        title = widget.text_list[0];
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

    switch (widget.resume_section_form_type) {
      case ResumeSectionFormType.skill:
        widget.update_item(
          widget.item_index,
          widget.section_index,
          ResumeSkill(
            name: field_1_input_controller.text,
            percentage: _current_slider_value / 10,
            color: current_color,
          ),
        );
        break;
      case ResumeSectionFormType.employment_history:
        String subtitle =
            "${field_1_input_controller.text}${field_2_input_controller.text.isEmpty ? "" : " ${widget.text_list[11]} "}${field_2_input_controller.text}, ${field_3_input_controller.text}";

        widget.update_item(
          widget.item_index,
          widget.section_index,
          ResumeSection(
            icon: widget.item_index == 0 ? Icons.dvr_rounded : null,
            code_point: widget.item_index == 0 ? 0xe1b2 : null,
            title: widget.item_index == 0 ? title : null,
            subtitle: subtitle,
            description: field_4_input_controller.text,
            begin: selected_date_1,
            end: selected_date_2,
          ),
        );
        break;
      case ResumeSectionFormType.education:
        widget.update_item(
          widget.item_index,
          widget.section_index,
          ResumeSection(
            icon: widget.item_index == 0 ? Icons.history_edu_rounded : null,
            code_point: widget.item_index == 0 ? 0xea3e : null,
            title: widget.item_index == 0 ? title : null,
            subtitle:
                "${field_1_input_controller.text}, ${field_2_input_controller.text}, ${field_3_input_controller.text}",
            begin: selected_date_1,
            end: selected_date_2,
          ),
        );
        break;
      case ResumeSectionFormType.custom:
        widget.update_item(
          widget.item_index,
          widget.section_index,
          ResumeSection(
            title: field_1_input_controller.text,
            subtitle: field_2_input_controller.text,
            description: field_3_input_controller.text,
            begin: selected_date_1,
            end: selected_date_2,
          ),
        );
        break;
    }
  }

  double _current_slider_value = 2;

  Color picker_color = Colors.blue;
  Color current_color = Colors.blue;

  choose_color() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            widget.text_list[10],
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: picker_color,
              onColorChanged: (Color new_color) {
                picker_color = new_color;
                setState(() {});
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Ok'),
              onPressed: () {
                current_color = picker_color;
                setState(() {});
                Navigator.of(context).pop();
                update_item();
              },
            ),
          ],
        );
      },
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

    String field_1_hint = "";
    String field_2_hint = "";
    String field_3_hint = "";
    String field_4_hint = "";

    switch (widget.resume_section_form_type) {
      case ResumeSectionFormType.skill:
        field_1_hint = widget.text_list[10];
        break;
      case ResumeSectionFormType.employment_history:
        field_1_hint = widget.text_list[10];
        field_2_hint = widget.text_list[12];
        field_3_hint = widget.text_list[13];
        field_4_hint = widget.text_list[14];
        break;
      case ResumeSectionFormType.education:
        field_1_hint = widget.text_list[10];
        field_2_hint = widget.text_list[11];
        field_3_hint = widget.text_list[12];
        break;
      case ResumeSectionFormType.custom:
        field_1_hint = widget.text_list[1];
        field_2_hint = widget.text_list[2];
        field_3_hint = widget.text_list[3];
        break;
    }

    return Container(
      alignment: Alignment.center,
      width: double.maxFinite,
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.text_color,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          SizedBox(
            height: sized_box_space,
          ),
          TextFormField(
            onChanged: (new_value) {
              update_item();
            },
            style: TextStyle(
              color: widget.text_color,
            ),
            decoration: InputDecoration(
              labelText: field_1_hint,
              labelStyle: TextStyle(
                color: widget.text_color,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: widget.text_color,
                ),
              ),
            ),
            controller: field_1_input_controller,
            validator: (value) => FormFieldValidators(
              value: value!,
              type: FormFieldValidatorsType.name,
            ).validate(),
          ),
          widget.resume_section_form_type != ResumeSectionFormType.skill
              ? Column(
                  children: [
                    TextFormField(
                      onChanged: (new_value) {
                        update_item();
                      },
                      style: TextStyle(
                        color: widget.text_color,
                      ),
                      decoration: InputDecoration(
                        labelText: field_2_hint,
                        labelStyle: TextStyle(
                          color: widget.text_color,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: widget.text_color,
                          ),
                        ),
                      ),
                      controller: field_2_input_controller,
                      validator: (value) => FormFieldValidators(
                        value: value!,
                        type: FormFieldValidatorsType.name,
                      ).validate(),
                    ),
                    TextFormField(
                      onChanged: (new_value) {
                        update_item();
                      },
                      style: TextStyle(
                        color: widget.text_color,
                      ),
                      decoration: InputDecoration(
                        labelText: field_3_hint,
                        labelStyle: TextStyle(
                          color: widget.text_color,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: widget.text_color,
                          ),
                        ),
                      ),
                      controller: field_3_input_controller,
                      validator: (value) => FormFieldValidators(
                        value: value!,
                        type: FormFieldValidatorsType.name,
                      ).validate(),
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                    ),
                    widget.resume_section_form_type == ResumeSectionFormType.employment_history
                        ? TextFormField(
                            onChanged: (new_value) {
                              update_item();
                            },
                            style: TextStyle(
                              color: widget.text_color,
                            ),
                            decoration: InputDecoration(
                              labelText: field_4_hint,
                              labelStyle: TextStyle(
                                color: widget.text_color,
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: widget.text_color,
                                ),
                              ),
                            ),
                            controller: field_4_input_controller,
                            validator: (value) => FormFieldValidators(
                              value: value!,
                              type: FormFieldValidatorsType.name,
                            ).validate(),
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                          )
                        : Container(),
                  ],
                )
              : Column(
                  children: [
                    Slider(
                      value: _current_slider_value,
                      min: 2,
                      max: 10,
                      divisions: 8,
                      label: _current_slider_value.round().toString(),
                      onChanged: (double value) {
                        _current_slider_value = value;
                        setState(() {});
                        update_item();
                      },
                    ),
                    SizedBox(
                      width: screen_width,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          elevation: MaterialStateProperty.all<double>(
                            0,
                          ),
                          backgroundColor: MaterialStateProperty.all<Color>(
                            current_color,
                          ),
                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width,
                              ),
                            ),
                          ),
                        ),
                        onPressed: () {
                          choose_color();
                        },
                        child: Text(
                          widget.text_list[13],
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          SizedBox(
            height: sized_box_space,
          ),
          widget.resume_section_form_type == ResumeSectionFormType.skill
              ? Container()
              : SizedBox(
                  width: screen_width,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      elevation: MaterialStateProperty.all<double>(
                        0,
                      ),
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Colors.transparent,
                      ),
                      overlayColor: MaterialStateProperty.all<Color>(
                        Colors.grey.withOpacity(0.2),
                      ),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width,
                          ),
                          side: BorderSide(
                            color: widget.text_color,
                          ),
                        ),
                      ),
                    ),
                    onPressed: () {
                      show_select_date_alert_dialog(widget.text_list[6]);
                    },
                    child: Text(
                      timeframe_text,
                      style: TextStyle(
                        color: widget.text_color,
                      ),
                    ),
                  ),
                ),
          widget.item_index != 0 || widget.resume_section_form_type == ResumeSectionFormType.custom
              ? Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () {
                      widget.remove_item(
                        widget.item_index,
                        widget.section_index,
                      );
                    },
                    icon: const Icon(
                      FontAwesomeIcons.trash,
                    ),
                    color: Colors.red,
                  ),
                )
              : Container(),
        ],
      ),
    );
  }

  Future _select_dates() async {
    DateTime now = DateTime.now();

    DateTime first_date = DateTime(
      now.year - 100,
      now.month,
      now.day,
    );

    DateTime initial_date = now;

    if (selected_date_index == 0) {
      if (selected_date_1 != null) {
        initial_date = selected_date_1!;
      }
    } else {
      if (selected_date_2 != null) {
        initial_date = selected_date_2!;
      }
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial_date,
      firstDate: first_date,
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.text_color,
              onPrimary: Colors.white,
              onSurface: widget.text_color,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: widget.text_color,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      switch (selected_date_index) {
        case 0:
          selected_date_1 = picked;
          break;
        case 1:
          if (picked.year == now.year && picked.month == now.month && picked.day == now.day) {
            picked = DateTime(
              picked.year,
              picked.month,
              picked.day,
              10,
              10,
              10,
            );
          }
          selected_date_2 = picked;
          break;
      }

      selected_date_index == 0 ? selected_date_index++ : selected_date_index = 0;

      if (selected_date_index != 0) {
        show_select_date_alert_dialog(widget.text_list[7]);
      }
      update_item();
      setState(() {});
    }
  }

  show_select_date_alert_dialog(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(msg),
          actions: <Widget>[
            TextButton(
              child: const Text("Ok"),
              onPressed: () async {
                Navigator.of(context).pop();
                _select_dates();
              },
            ),
          ],
        );
      },
    );
  }
}
