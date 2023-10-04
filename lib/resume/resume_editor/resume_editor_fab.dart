import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/models/save_resume.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:xapptor_community/resume/resume_visualizer/download_resume_pdf.dart';

extension ResumeEditorFab on ResumeEditorState {
  resume_editor_fab(Resume resume) => ExpandableFab(
        children: [
          FloatingActionButton.small(
            heroTag: null,
            onPressed: () {
              download_resume_pdf(
                resume: resume,
                text_bottom_margin_for_section: widget.text_bottom_margin_for_section,
                resume_link: "${widget.base_url}/resumes/${resume.id}",
                context: context,
                language_code: text_list.list[source_language_index].source_language,
              );
            },
            backgroundColor: Colors.lightBlue,
            tooltip: text_list.get(source_language_index)[22],
            child: const Icon(
              FontAwesomeIcons.fileArrowDown,
              color: Colors.white,
              size: 16,
            ),
          ),
          FloatingActionButton.small(
            heroTag: null,
            onPressed: () => save_resume(),
            backgroundColor: Colors.green,
            tooltip: text_list.get(source_language_index).last,
            child: const Icon(
              FontAwesomeIcons.fileArrowDown,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      );
}
