import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';

extension StateExtension on ResumeEditorState {
  String get_slot_label({
    required int slot_index,
  }) {
    return slot_index == 0
        ? alert_text_list.get(source_language_index)[9]
        : "${alert_text_list.get(source_language_index)[8]} $slot_index";
  }
}
