import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:xapptor_community/resume/resume_editor/update_text_list.dart';
import 'package:xapptor_translation/translation_stream.dart';

extension StateExtension on ResumeEditorState {
  resume_editor_init_state() {
    initializeDateFormatting();

    translation_stream = TranslationStream(
      translation_text_list_array: text_list,
      update_text_list_function: update_text_list,
      list_index: 0,
      source_language_index: source_language_index,
    );

    skill_translation_stream = TranslationStream(
      translation_text_list_array: skill_text_list,
      update_text_list_function: update_text_list,
      list_index: 1,
      source_language_index: source_language_index,
    );

    employment_translation_stream = TranslationStream(
      translation_text_list_array: employment_text_list,
      update_text_list_function: update_text_list,
      list_index: 2,
      source_language_index: source_language_index,
    );

    education_translation_stream = TranslationStream(
      translation_text_list_array: education_text_list,
      update_text_list_function: update_text_list,
      list_index: 3,
      source_language_index: source_language_index,
    );

    picker_translation_stream = TranslationStream(
      translation_text_list_array: picker_text_list,
      update_text_list_function: update_text_list,
      list_index: 4,
      source_language_index: source_language_index,
    );

    sections_by_page_translation_stream = TranslationStream(
      translation_text_list_array: sections_by_page_text_list,
      update_text_list_function: update_text_list,
      list_index: 5,
      source_language_index: source_language_index,
    );

    translation_stream_list = [
      translation_stream,
      skill_translation_stream,
      employment_translation_stream,
      education_translation_stream,
      picker_translation_stream,
      sections_by_page_translation_stream,
    ];
  }
}
