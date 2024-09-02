import 'package:xapptor_db/xapptor_db.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';

extension StateExtension on ResumeEditorState {
  get_resume_ref({
    required int slot_index,
  }) {
    String resume_doc_id = "${current_user!.uid}_${text_list.list[source_language_index].source_language}";

    if (slot_index != 0) {
      resume_doc_id += "_bu_$slot_index";
    }
    return XapptorDB.instance.collection("resumes").doc(resume_doc_id);
  }
}
