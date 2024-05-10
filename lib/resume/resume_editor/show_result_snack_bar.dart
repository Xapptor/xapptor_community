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
    switch (result_snack_bar_type) {
      case ResultSnackBarType.loaded:
        message = "${alert_text_list.get(source_language_index)[14]}: $slot_index";
        break;
      case ResultSnackBarType.saved:
        message = "${alert_text_list.get(source_language_index)[15]}: $slot_index";
        break;
      case ResultSnackBarType.deleted:
        message = "${alert_text_list.get(source_language_index)[16]}: $slot_index";
        break;
    }
    show_success_alert(
      context: context,
      message: message,
    );
  }
}
