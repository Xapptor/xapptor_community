import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/font_configuration.dart';
import 'package:xapptor_community/resume/models/resume_font.dart';
import 'package:xapptor_ui/utils/is_portrait.dart';
import 'package:xapptor_ui/values/ui.dart';

bool show_time_amount = true;

class ResumeEditorAdditionalOptions extends StatefulWidget {
  const ResumeEditorAdditionalOptions({
    super.key,
  });

  @override
  State<ResumeEditorAdditionalOptions> createState() => ResumeEditorAdditionalOptionsState();
}

class ResumeEditorAdditionalOptionsState extends State<ResumeEditorAdditionalOptions> {
  String font_family_title = """
Select the Font Family for the PDF Resume:
Note: Only for PDF File not for Web version.
""";

  String checkbox_label = 'Show the amount of time at\nthe side of the timeframe';

  List<ResumeFont> font_families_value = [];
  late ResumeFont current_font_value;

  @override
  void initState() {
    super.initState();
    get_values();
  }

  get_values() async {
    font_families_value = await font_families();
    current_font_value = await current_font();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool portrait = is_portrait(context);

    return font_families_value.isEmpty
        ? Container()
        : Column(
            children: [
              SizedBox(height: sized_box_space * 2),
              Flex(
                direction: portrait ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: portrait ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  Text(
                    font_family_title,
                  ),
                  if (!portrait) SizedBox(width: sized_box_space),
                  DropdownButton<String>(
                    value: current_font_value.name,
                    items: font_families_value.map((ResumeFont font) {
                      return DropdownMenuItem<String>(
                        value: font.name,
                        child: Text(font.name),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      current_font_value = font_families_value.firstWhere(
                        (ResumeFont font) => font.name == value,
                      );
                      setState(() {});
                    },
                  ),
                ],
              ),
              if (portrait) SizedBox(height: sized_box_space),
              Row(
                children: [
                  Text(
                    checkbox_label,
                  ),
                  SizedBox(width: sized_box_space),
                  Checkbox(
                    value: show_time_amount,
                    onChanged: (bool? value) {
                      show_time_amount = value!;
                      setState(() {});
                    },
                  ),
                ],
              ),
            ],
          );
  }
}
