import 'package:intl/intl.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_alert.dart';

get_resumes_labels({
  required List<Resume> backup_resumes,
  required String main_label,
  required String backup_label,
  required ResumeEditorAlertType resume_editor_alert_type,
}) {
  DateFormat date_format = DateFormat('yyyy/MM/dd, hh:mm a');
  List<String> labels = [];

  Resume main_resume = backup_resumes.firstWhere((resume) => resume.slot_index == 0);
  String main_date_String = date_format.format(main_resume.creation_date.toDate());
  String label = "$main_label - $main_date_String";
  labels.add(label);

  int loop_limit = 3;

  for (int i = 1; i <= loop_limit; i++) {
    bool resume_exists = backup_resumes.any((resume) => resume.slot_index == i);

    String label = "";

    if (resume_exists) {
      var current_resume = backup_resumes.firstWhere((resume) => resume.slot_index == i);
      String backup_date_String = date_format.format(current_resume.creation_date.toDate());

      label = "$backup_label ${current_resume.slot_index} - $backup_date_String";
    } else {
      label = "$backup_label $i";
    }

    if (resume_editor_alert_type == ResumeEditorAlertType.save) {
      labels.add(label);
    } else {
      if (resume_exists) {
        labels.add(label);
      }
    }
  }
  return labels;
}
