import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xapptor_community/resume/resume_editor/generate_resume.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:xapptor_community/resume/resume_editor/show_saved_snack_bar.dart';

extension SetResume on ResumeEditorState {
  set_resume() async {
    String resume_doc_id = "${current_user.uid}_${text_list.list[source_language_index].source_language}";

    DocumentReference resume_doc = FirebaseFirestore.instance.collection("resumes").doc(resume_doc_id);

    await resume_doc
        .set(
      generate_resume().to_json(),
      SetOptions(merge: true),
    )
        .then((value) {
      show_saved_snack_bar();
    });
  }
}
