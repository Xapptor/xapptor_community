import 'package:xapptor_community/resume/resume_editor/crud/read/get_slot_label.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:xapptor_ui/utils/show_alert.dart';

enum ResultSnackBarType {
  loaded,
  saved,
  deleted,
}

extension StateExtension on ResumeEditorState {
  show_result_snack_bar({
    required ResultSnackBarType result_snack_bar_type,
    required int slot_index,
  }) {
    String message = "";
    String slot_label = get_slot_label(
      slot_index: slot_index,
    );
    int textIndex = 0;

    switch (result_snack_bar_type) {
      case ResultSnackBarType.loaded:
        textIndex = 14;
        break;
      case ResultSnackBarType.saved:
        textIndex = 15;
        break;
      case ResultSnackBarType.deleted:
        textIndex = 16;
        break;
    }
    message = "${alert_text_list.get(source_language_index)[textIndex]}: $slot_label";
    show_success_alert(
      context: context,
      message: message,
    );
  }
}
