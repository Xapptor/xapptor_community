import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_alert.dart';

get_resumes_labels({
  required List<Resume> backup_resumes,
  required String backup_label,
  required ResumeEditorAlertType resume_editor_alert_type,
}) {
  List<String> labels = [];
  int loop_limit = resume_editor_alert_type == ResumeEditorAlertType.save ? 3 : backup_resumes.length;

  print("loop_limit: $loop_limit");

  for (int i = 1; i <= loop_limit; i++) {
    print("loop count");
    bool resume_exists = backup_resumes.any((resume) => resume.slot_index == i);
    var current_resume = backup_resumes[i - 1];

    String date_String = DateTime.parse(current_resume.creation_date.toDate().toString()).toString();

    String label = resume_exists ? "${current_resume.slot_index} - $date_String" : "$backup_label $i";

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
