// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/resume_editor/generate_resume.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_alert.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:xapptor_community/resume/resume_visualizer/download_resume_pdf.dart';

extension StateExtension on ResumeEditorState {
  resume_editor_fab() {
    String download_label = text_list.get(source_language_index)[text_list.get(source_language_index).length - 3];
    String load_label = text_list.get(source_language_index)[text_list.get(source_language_index).length - 1];
    String save_label = text_list.get(source_language_index)[text_list.get(source_language_index).length - 2];

    return ExpandableFab(
      key: expandable_fab_key,
      distance: 200,
      duration: const Duration(milliseconds: 150),
      overlayStyle: ExpandableFabOverlayStyle(
        blur: 5,
      ),
      children: [
        FloatingActionButton.extended(
          heroTag: null,
          onPressed: () {
            Resume resume = generate_resume(slot_index: slot_index);

            download_resume_pdf(
              resume: resume,
              text_bottom_margin_for_section: widget.text_bottom_margin_for_section,
              resume_link: "${widget.base_url}/resumes/${resume.id}",
              context: context,
              language_code: text_list.list[source_language_index].source_language,
            );
          },
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
          onPressed: () {
            Resume resume = generate_resume(slot_index: slot_index);

            resume_editor_alert(
              resume: resume,
              resume_editor_alert_type: ResumeEditorAlertType.load,
            );
          },
          backgroundColor: Colors.pink,
          tooltip: load_label,
          label: Row(
            children: [
              Text(
                load_label,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                FontAwesomeIcons.server,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
        FloatingActionButton.extended(
          heroTag: null,
          onPressed: () {
            Resume resume = generate_resume(slot_index: slot_index);

            resume_editor_alert(
              resume: resume,
              resume_editor_alert_type: ResumeEditorAlertType.save,
            );
          },
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
