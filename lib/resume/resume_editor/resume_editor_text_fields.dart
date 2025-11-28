import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:xapptor_logic/form_field_validators.dart';
import 'package:xapptor_ui/values/ui.dart';
import 'package:xapptor_ui/widgets/text_field/custom_text_field.dart';
import 'package:xapptor_ui/widgets/text_field/custom_text_field_model.dart';

extension StateExtension on ResumeEditorState {
  resume_editor_text_fields() => Column(
        children: [
          const SizedBox(height: sized_box_space),
          CustomTextField(
            model: CustomTextFieldModel(
              title: text_list.get(source_language_index)[0],
              hint: text_list.get(source_language_index)[0],
              focus_node: focus_node_1,
              on_field_submitted: (fieldValue) => focus_node_2.requestFocus(),
              controller: name_input_controller,
              length_limit: FormFieldValidatorsType.name.get_Length(),
              validator: (value) => FormFieldValidators(
                value: value!,
                type: FormFieldValidatorsType.name,
              ).validate(),
            ),
          ),
          const SizedBox(height: sized_box_space),
          CustomTextField(
            model: CustomTextFieldModel(
              title: text_list.get(source_language_index)[1],
              hint: text_list.get(source_language_index)[1],
              focus_node: focus_node_2,
              on_field_submitted: (fieldValue) => focus_node_3.requestFocus(),
              controller: job_title_input_controller,
              length_limit: FormFieldValidatorsType.name.get_Length(),
              validator: (value) => FormFieldValidators(
                value: value!,
                type: FormFieldValidatorsType.name,
              ).validate(),
            ),
          ),
          const SizedBox(height: sized_box_space),
          CustomTextField(
            model: CustomTextFieldModel(
              title: text_list.get(source_language_index)[2],
              hint: text_list.get(source_language_index)[2],
              focus_node: focus_node_3,
              on_field_submitted: (fieldValue) => focus_node_4.requestFocus(),
              controller: email_input_controller,
              length_limit: FormFieldValidatorsType.email.get_Length(),
              validator: (value) => FormFieldValidators(
                value: value!,
                type: FormFieldValidatorsType.email,
              ).validate(),
            ),
          ),
          const SizedBox(height: sized_box_space),
          CustomTextField(
            model: CustomTextFieldModel(
              title: text_list.get(source_language_index)[3],
              hint: text_list.get(source_language_index)[3],
              focus_node: focus_node_4,
              on_field_submitted: (fieldValue) => focus_node_5.requestFocus(),
              controller: website_input_controller,
              length_limit: FormFieldValidatorsType.website.get_Length(),
              validator: (value) => FormFieldValidators(
                value: value!,
                type: FormFieldValidatorsType.website,
              ).validate(),
            ),
          ),
          const SizedBox(height: sized_box_space),
          CustomTextField(
            model: CustomTextFieldModel(
              title: text_list.get(source_language_index)[5],
              hint: text_list.get(source_language_index)[5],
              focus_node: focus_node_5,
              on_field_submitted: (fieldValue) => null,
              controller: profile_input_controller,
              length_limit: FormFieldValidatorsType.multiline_long.get_Length(),
              validator: (value) => FormFieldValidators(
                value: value!,
                type: FormFieldValidatorsType.multiline_long,
              ).validate(),
              keyboard_type: TextInputType.multiline,
              max_lines: null,
            ),
          ),
        ],
      );
}
