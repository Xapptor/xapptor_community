import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_text_field.dart';
import 'package:xapptor_logic/form_field_validators.dart';
import 'package:xapptor_ui/values/ui.dart';
import 'package:xapptor_ui/widgets/text_field/custom_text_field.dart';
import 'package:xapptor_ui/widgets/text_field/custom_text_field_model.dart';

extension StateExtension on ResumeEditorState {
  resume_editor_text_fields() => Column(
        children: [
          SizedBox(height: sized_box_space),
          CustomTextField(
            model: CustomTextFieldModel(
              title: text_list.get(source_language_index)[0],
              hint: text_list.get(source_language_index)[0],
              focus_node: focus_node_1,
              on_field_submitted: (fieldValue) => focus_node_2.requestFocus(),
              controller: name_input_controller,
              validator: (value) => FormFieldValidators(
                value: value!,
                type: FormFieldValidatorsType.name,
              ).validate(),
            ),
          ),
          SizedBox(height: sized_box_space),
          resume_editor_text_field(
            label_text: text_list.get(source_language_index)[1],
            controller: job_title_input_controller,
            validator: (value) => FormFieldValidators(
              value: value!,
              type: FormFieldValidatorsType.name,
            ).validate(),
          ),
          SizedBox(height: sized_box_space),
          resume_editor_text_field(
            label_text: text_list.get(source_language_index)[2],
            controller: email_input_controller,
            validator: (value) => FormFieldValidators(
              value: value!,
              type: FormFieldValidatorsType.email,
            ).validate(),
          ),
          SizedBox(height: sized_box_space),
          resume_editor_text_field(
            label_text: text_list.get(source_language_index)[3],
            controller: website_input_controller,
            validator: (value) => FormFieldValidators(
              value: value!,
              type: FormFieldValidatorsType.email,
            ).validate(),
          ),
          SizedBox(height: sized_box_space),
          resume_editor_text_field(
            label_text: text_list.get(source_language_index)[5],
            controller: profile_input_controller,
            validator: (value) => FormFieldValidators(
              value: value!,
              type: FormFieldValidatorsType.email,
            ).validate(),
            keyboardType: TextInputType.multiline,
            maxLines: null,
          ),
        ],
      );
}
