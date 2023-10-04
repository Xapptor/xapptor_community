import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:xapptor_community/resume/resume_editor/set_resume.dart';

extension SaveResume on ResumeEditorState {
  save_resume() async {
    if (chosen_image_src.isNotEmpty) {
      if (!chosen_image_src.contains("http")) {
        Reference profile_image_ref = FirebaseStorage.instance
            .ref()
            .child('users')
            .child('/${current_user.uid}')
            .child('/resumes')
            .child('/profile_image.$chosen_image_ext');

        await profile_image_ref.putData(base64Decode(chosen_image_src)).then((p0) async {
          chosen_image_src = await p0.ref.getDownloadURL();
          set_resume();
        });
      } else {
        set_resume();
      }
    } else {
      set_resume();
    }
  }
}
