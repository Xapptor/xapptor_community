import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/models/save_resume.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:xapptor_community/resume/resume_visualizer/download_resume_pdf.dart';

extension StateExtension on ResumeEditorState {
  resume_editor_fab(Resume resume) {
    String download_label = text_list.get(source_language_index)[text_list.get(source_language_index).length - 2];
    String save_label = text_list.get(source_language_index).last;

    return ExpandableFab(
      children: [
        FloatingActionButton.extended(
          heroTag: null,
          onPressed: () => download_resume_pdf(
            resume: resume,
            text_bottom_margin_for_section: widget.text_bottom_margin_for_section,
            resume_link: "${widget.base_url}/resumes/${resume.id}",
            context: context,
            language_code: text_list.list[source_language_index].source_language,
          ),
          backgroundColor: Colors.lightBlue,
          tooltip: download_label,
          label: Row(
            children: [
              Text(
                download_label,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                FontAwesomeIcons.fileArrowDown,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
        FloatingActionButton.extended(
          heroTag: null,
          onPressed: () => save_resume(),
          backgroundColor: Colors.green,
          tooltip: save_label,
          label: Row(
            children: [
              Text(
                save_label,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                FontAwesomeIcons.cloudArrowUp,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ].reversed.toList(),
    );
  }
}
