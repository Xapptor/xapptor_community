import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/get_timeframe_text.dart';
import 'package:xapptor_ui/values/ui.dart';
import 'package:xapptor_logic/form_field_validators.dart';

class ResumeSectionForm extends StatefulWidget {
  ResumeSectionForm({
    required this.text_list,
    required this.text_color,
    required this.language_code,
  });

  final List<String> text_list;
  final Color text_color;
  final String language_code;

  @override
  _ResumeSectionFormState createState() => _ResumeSectionFormState();
}

class _ResumeSectionFormState extends State<ResumeSectionForm> {
  TextEditingController title_input_controller = TextEditingController();
  TextEditingController subtitle_input_controller = TextEditingController();
  TextEditingController description_input_controller = TextEditingController();

  late DateTime? begin;
  late DateTime? end;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screen_height = MediaQuery.of(context).size.height;
    double screen_width = MediaQuery.of(context).size.width;
    bool portrait = screen_height > screen_width;

    String timeframe_text = "";
    if (begin != null && end != null) {
      timeframe_text = get_timeframe_text(
        begin: begin!,
        end: end!,
        language_code: widget.language_code,
        present_text: widget.text_list[0],
      );
    }

    return FractionallySizedBox(
      widthFactor: portrait ? 0.9 : 0.5,
      child: Container(
        child: Column(
          children: [
            SizedBox(
              height: sized_box_space,
            ),
            TextFormField(
              style: TextStyle(
                color: widget.text_color,
              ),
              decoration: InputDecoration(
                labelText: widget.text_list[5],
                labelStyle: TextStyle(
                  color: widget.text_color,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: widget.text_color,
                  ),
                ),
              ),
              controller: title_input_controller,
              validator: (value) => FormFieldValidators(
                value: value!,
                type: FormFieldValidatorsType.name,
              ).validate(),
            ),
            TextFormField(
              style: TextStyle(
                color: widget.text_color,
              ),
              decoration: InputDecoration(
                labelText: widget.text_list[5],
                labelStyle: TextStyle(
                  color: widget.text_color,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: widget.text_color,
                  ),
                ),
              ),
              controller: subtitle_input_controller,
              validator: (value) => FormFieldValidators(
                value: value!,
                type: FormFieldValidatorsType.name,
              ).validate(),
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text(
                timeframe_text,
              ),
            ),
            TextFormField(
              style: TextStyle(
                color: widget.text_color,
              ),
              decoration: InputDecoration(
                labelText: widget.text_list[5],
                labelStyle: TextStyle(
                  color: widget.text_color,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: widget.text_color,
                  ),
                ),
              ),
              controller: description_input_controller,
              validator: (value) => FormFieldValidators(
                value: value!,
                type: FormFieldValidatorsType.name,
              ).validate(),
            ),
          ],
        ),
      ),
    );
  }
}
