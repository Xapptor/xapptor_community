import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xapptor_community/resume/models/resume_font.dart';
import 'package:xapptor_ui/utils/is_portrait.dart';
import 'package:xapptor_ui/values/ui.dart';

bool show_time_amount = true;
List<ResumeFont> font_families_value = [];
ResumeFont current_font_value = ResumeFont(
  name: 'Nunito',
  base: null,
  bold: null,
  google_font_family: GoogleFonts.nunito().fontFamily!,
);

class ResumeEditorAdditionalOptions extends StatefulWidget {
  final Function callback;

  const ResumeEditorAdditionalOptions({
    super.key,
    required this.callback,
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

  @override
  void initState() {
    super.initState();
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
                        child: Text(
                          font.name,
                          style: TextStyle(
                            fontFamily: font.google_font_family,
                          ),
                        ),
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
                      widget.callback();
                    },
                  ),
                ],
              ),
            ],
          );
  }
}
