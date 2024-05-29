import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/get_timeframe_text.dart';
import 'package:xapptor_community/resume/resume_editor/resume_section_form.dart';
import 'package:xapptor_community/resume/resume_editor/resume_section_form_item/choose_color.dart';
import 'package:xapptor_community/resume/resume_editor/resume_section_form_item/populate_fields.dart';
import 'package:xapptor_community/resume/resume_editor/resume_section_form_item/show_select_date_alert_dialog.dart';
import 'package:xapptor_community/resume/resume_editor/resume_section_form_item/update_item.dart';
import 'package:xapptor_community/resume/resume_editor/update_item.dart';
import 'package:xapptor_ui/values/ui.dart';
import 'package:xapptor_logic/form_field_validators.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ResumeSectionFormItem extends StatefulWidget {
  final ResumeSectionFormType resume_section_form_type;
  final List<String> text_list;
  final Color text_color;
  final String language_code;
  final int item_index;
  final int section_index;

  final Function({
    required int item_index,
    required int section_index,
    required dynamic section,
    ChangeItemPositionType change_item_position_type,
  }) update_item;

  final Function({
    required int item_index,
    required int section_index,
  }) remove_item;

  final dynamic section;

  final bool show_up_arrow;
  final bool show_down_arrow;

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
    required this.show_up_arrow,
    required this.show_down_arrow,
  });

  @override
  State<ResumeSectionFormItem> createState() => ResumeSectionFormItemState();
}

class ResumeSectionFormItemState extends State<ResumeSectionFormItem> {
  TextEditingController field_1_input_controller = TextEditingController();
  TextEditingController field_2_input_controller = TextEditingController();
  TextEditingController field_3_input_controller = TextEditingController();
  TextEditingController field_4_input_controller = TextEditingController();

  DateTime? selected_date_1;
  DateTime? selected_date_2;
  int selected_date_index = 0;
  String timeframe_text = "";

  @override
  void initState() {
    super.initState();
  }

  double current_slider_value = 2;

  Color picker_color = Colors.blue;
  Color current_color = Colors.blue;

  @override
  Widget build(BuildContext context) {
    populate_fields();

    double screen_width = MediaQuery.of(context).size.width;

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
                      value: current_slider_value,
                      min: 2,
                      max: 10,
                      divisions: 8,
                      label: current_slider_value.round().toString(),
                      onChanged: (double value) {
                        current_slider_value = value;
                        setState(() {});
                        update_item();
                      },
                    ),
                    SizedBox(
                      width: screen_width,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          elevation: WidgetStateProperty.all<double>(
                            0,
                          ),
                          backgroundColor: WidgetStateProperty.all<Color>(
                            current_color,
                          ),
                          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
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
                      elevation: WidgetStateProperty.all<double>(
                        0,
                      ),
                      backgroundColor: WidgetStateProperty.all<Color>(
                        Colors.transparent,
                      ),
                      overlayColor: WidgetStateProperty.all<Color>(
                        Colors.grey.withOpacity(0.2),
                      ),
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              widget.item_index != 0 || widget.resume_section_form_type == ResumeSectionFormType.custom
                  ? IconButton(
                      onPressed: () {
                        widget.remove_item(
                          item_index: widget.item_index,
                          section_index: widget.section_index,
                        );
                      },
                      icon: const Icon(
                        FontAwesomeIcons.trash,
                      ),
                      color: Colors.red,
                    )
                  : Container(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.show_up_arrow)
                    IconButton(
                      onPressed: () {
                        widget.update_item(
                          item_index: widget.item_index,
                          section_index: widget.section_index,
                          section: widget.section,
                          change_item_position_type: ChangeItemPositionType.move_up,
                        );
                      },
                      icon: const Icon(
                        FontAwesomeIcons.arrowUp,
                      ),
                      color: widget.text_color,
                    ),
                  !widget.show_down_arrow
                      ? const SizedBox(
                          height: 40,
                          width: 40,
                        )
                      : IconButton(
                          onPressed: () {
                            widget.update_item(
                              item_index: widget.item_index,
                              section_index: widget.section_index,
                              section: widget.section,
                              change_item_position_type: ChangeItemPositionType.move_down,
                            );
                          },
                          icon: const Icon(
                            FontAwesomeIcons.arrowDown,
                          ),
                          color: widget.text_color,
                        ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
