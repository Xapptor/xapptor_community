// ignore_for_file: invalid_use_of_protected_member

import 'package:file_picker/file_picker.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';

extension StateExtension on ResumeEditorState {
  choose_profile_image() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      chosen_image_path = 'users/${current_user!.uid}/resumes/resume_profile_image.${result.files.single.extension}';
      chosen_image_bytes = result.files.single.bytes!;
      setState(() {});
    }
  }
}
