import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/resume_visualizer/resume_visualizer.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:xapptor_ui/values/ui.dart';

extension StateExtension on ResumeEditorState {
  resume_editor_preview({
    required BuildContext context,
    required bool portrait,
    required Resume resume,
    required String base_url,
  }) =>
      Container(
        margin: EdgeInsets.all(portrait ? 6 : 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.deepOrangeAccent,
            width: 6,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            SizedBox(
              height: sized_box_space * 2,
            ),
            Container(
              alignment: Alignment.center,
              width: double.maxFinite,
              padding: const EdgeInsets.only(bottom: 20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.deepOrangeAccent,
                    width: 6,
                  ),
                ),
              ),
              child: Text(
                text_list.get(source_language_index)[6],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ResumeVisualizer(
              resume: resume,
              language_code: text_list.list[source_language_index].source_language,
              base_url: widget.base_url,
            ),
          ],
        ),
      );
}
