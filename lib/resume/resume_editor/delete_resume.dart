import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xapptor_community/resume/resume_editor/get_resume_ref.dart';
import 'package:xapptor_community/resume/resume_editor/load_resume.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:xapptor_community/resume/resume_editor/show_result_snack_bar.dart';

extension StateExtension on ResumeEditorState {
  delete_resume({
    required int slot_index,
  }) async {
    DocumentReference resume_doc_ref = get_resume_ref(
      slot_index: slot_index,
    );

    await resume_doc_ref.delete().then((value) {
      resumes.removeAt(slot_index);

      slot_index = resumes.first.slot_index;
      load_resume(
        slot_index: resumes.first.slot_index,
      );

      show_result_snack_bar(
        result_snack_bar_type: ResultSnackBarType.deleted,
        slot_index: slot_index,
      );
    });
  }
}
