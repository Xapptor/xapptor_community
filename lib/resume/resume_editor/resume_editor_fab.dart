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
    String language_code = text_list.list[source_language_index].source_language;
    List alert_text_array = alert_text_list.get(source_language_index);

    String load_label = alert_text_array[17];
    String save_label = alert_text_array[18];
    String delete_label = alert_text_array[19];
    String download_label = alert_text_array[20];
    String menu_label = alert_text_array[21];
    String close_label = alert_text_array[22];

    return ExpandableFab(
      key: expandable_fab_key,
      distance: 200,
      duration: const Duration(milliseconds: 150),
      overlayStyle: const ExpandableFabOverlayStyle(
        blur: 5,
      ),
      openButtonBuilder: FloatingActionButtonBuilder(
        size: 20,
        builder: (context, onPressed, progress) {
          return FloatingActionButton(
            heroTag: null,
            onPressed: onPressed,
            tooltip: menu_label,
            child: const Icon(
              Icons.menu,
              color: Colors.white,
            ),
          );
        },
      ),
      closeButtonBuilder: FloatingActionButtonBuilder(
        size: 20,
        builder: (context, onPressed, progress) {
          return FloatingActionButton(
            heroTag: null,
            onPressed: onPressed,
            tooltip: close_label,
            child: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          );
        },
      ),
      children: [
        // LOAD

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

        // SAVE

        FloatingActionButton.extended(
          heroTag: null,
          onPressed: () {
            Resume resume = generate_resume(slot_index: slot_index);
            resume.id = "${resume.user_id}_$language_code";
            current_resume_id = resume.id;

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

        // DELETE

        FloatingActionButton.extended(
          heroTag: null,
          onPressed: () {
            Resume resume = generate_resume(slot_index: slot_index);

            resume_editor_alert(
              resume: resume,
              resume_editor_alert_type: ResumeEditorAlertType.delete,
            );
          },
          backgroundColor: Colors.red,
          tooltip: delete_label,
          label: Row(
            children: [
              Text(
                delete_label,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                FontAwesomeIcons.trash,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),

        // DOWNLOAD

        FloatingActionButton.extended(
          heroTag: null,
          onPressed: () {
            Resume resume = generate_resume(slot_index: slot_index);
            resume.id = "${resume.user_id}_$language_code";

            String resume_link = "${widget.base_url}/resumes/${resume.id}";

            // var encoder = const JsonEncoder.withIndent('  ');
            // String pretty_json = encoder.convert(resume.to_json_2());
            // print(pretty_json);

            download_resume_pdf(
              resume: resume,
              text_bottom_margin_for_section: widget.text_bottom_margin_for_section,
              resume_link: resume_link,
              context: context,
              language_code: language_code,
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
      ].reversed.toList(),
    );
  }
}
