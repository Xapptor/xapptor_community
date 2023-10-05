import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:xapptor_community/resume/resume_editor/check_for_remote_resume.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:xapptor_logic/check_browser_type.dart';

extension ApplyTimer on ResumeEditorState {
  apply_timer() async {
    BrowserType browser_type = await check_browser_type();
    int timer_duration = browser_type == BrowserType.mobile ? 3000 : 1200;

    Timer(Duration(milliseconds: timer_duration), () {
      current_user = FirebaseAuth.instance.currentUser!;
      check_for_remote_resume();
    });
  }
}
