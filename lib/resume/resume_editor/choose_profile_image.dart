// ignore_for_file: invalid_use_of_protected_member

import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';

extension ChooseProfileImage on ResumeEditorState {
  choose_profile_image() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      chosen_image_src = base64Encode(result.files.single.bytes!);
      chosen_image_ext = result.files.single.extension!;
      setState(() {});
    }
  }
}
