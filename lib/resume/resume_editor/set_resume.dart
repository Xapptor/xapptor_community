import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:xapptor_community/resume/resume_editor/show_saved_snack_bar.dart';

extension StateExtension on ResumeEditorState {
  set_resume({
    required Resume resume,
  }) async {
    String resume_doc_id = "${current_user!.uid}_${text_list.list[source_language_index].source_language}";

    if (resume.slot_index != null) {
      resume_doc_id += "_bu_${resume.slot_index}";
    }

    DocumentReference resume_doc_ref = FirebaseFirestore.instance.collection("resumes").doc(resume_doc_id);

    Map resume_json = resume.to_json();

    await resume_doc_ref
        .set(
      resume_json,
      SetOptions(merge: true),
    )
        .then((value) {
      show_saved_snack_bar();
    });
  }
}
