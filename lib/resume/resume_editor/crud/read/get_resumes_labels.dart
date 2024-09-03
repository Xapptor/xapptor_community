import 'package:intl/intl.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_alert.dart';

get_resumes_labels({
  required List<Resume> resumes,
  required String main_label,
  required String backup_label,
  required ResumeEditorAlertType resume_editor_alert_type,
}) {
  DateFormat date_format = DateFormat('yyyy/MM/dd, hh:mm a');
  List<String> labels = [];

  bool main_resume_exists = resumes.any((resume) => resume.slot_index == 0);

  if (main_resume_exists) {
    Resume main_resume = resumes.firstWhere((resume) => resume.slot_index == 0);

    String label = "";

    if (main_resume.creation_date == Resume.empty().creation_date) {
      label = main_label;
    } else {
      String main_date_String = date_format.format(main_resume.creation_date.toDate());
      label = "$main_label - $main_date_String";
    }

    labels.add(label);
  } else {
    if (resume_editor_alert_type != ResumeEditorAlertType.delete) {
      labels.add(main_label);
    }
  }
  int loop_limit = 3;

  for (int i = 1; i <= loop_limit; i++) {
    bool resume_exists = resumes.any((resume) => resume.slot_index == i);

    String label = "";

    if (resume_exists) {
      var current_resume = resumes.firstWhere((resume) => resume.slot_index == i);
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
