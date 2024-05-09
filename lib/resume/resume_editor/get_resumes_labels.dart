import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_alert.dart';

get_resumes_labels({
  required List<Resume> backup_resumes,
  required String backup_label,
  required ResumeEditorAlertType resume_editor_alert_type,
}) {
  List<String> labels = [];

  for (int i = 1; i <= 3; i++) {
    bool resume_exists = backup_resumes.any((resume) => resume.slot_index == i);
    String label = resume_exists ? backup_resumes[i - 1].creation_date.toString() : "$backup_label $i";

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
