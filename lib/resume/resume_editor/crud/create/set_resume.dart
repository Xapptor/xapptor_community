// ignore_for_file: invalid_use_of_protected_member

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/resume_editor/crud/read/get_resume_ref.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:xapptor_community/resume/resume_editor/show_result_snack_bar.dart';

extension StateExtension on ResumeEditorState {
  set_resume({
    required int new_slot_index,
    required Resume resume,
  }) async {
    resume.slot_index = new_slot_index;
    DocumentReference resume_doc_ref = get_resume_ref(
      slot_index: new_slot_index,
    );

    Map resume_json = resume.to_json();

    slot_index = new_slot_index;
    setState(() {});

    await resume_doc_ref
        .set(
      resume_json,
      SetOptions(merge: true),
    )
        .then((value) {
      show_result_snack_bar(
        result_snack_bar_type: ResultSnackBarType.saved,
        slot_index: new_slot_index,
      );
    });
  }
}
