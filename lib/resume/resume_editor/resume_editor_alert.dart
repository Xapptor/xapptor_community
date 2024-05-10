// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/resume_editor/get_resumes_slots.dart';
import 'package:xapptor_community/resume/resume_editor/get_resumes_labels.dart';
import 'package:xapptor_community/resume/resume_editor/load_resume.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:xapptor_community/resume/resume_editor/save_resume.dart';

enum ResumeEditorAlertType {
  save,
  load,
}

extension StateExtension on ResumeEditorState {
  resume_editor_alert({
    required Resume resume,
    required ResumeEditorAlertType resume_editor_alert_type,
  }) {
    _main_alert(
      resume: resume,
      resume_editor_alert_type: resume_editor_alert_type,
    );
  }

  _asking_for_backup_alert({
    required Resume resume,
    required ResumeEditorAlertType resume_editor_alert_type,
  }) {
    save_resume(resume: resume);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(
                alert_text_list.get(source_language_index)[2],
                style: const TextStyle(
                  color: Colors.black,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    alert_text_list.get(source_language_index)[3],
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _main_alert(
                      resume: resume,
                      resume_editor_alert_type: resume_editor_alert_type,
                    );
                  },
                  child: Text(
                    alert_text_list.get(source_language_index)[4],
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  _main_alert({
    required Resume resume,
    required ResumeEditorAlertType resume_editor_alert_type,
  }) async {
    String main_label = alert_text_list.get(source_language_index)[9];
    String backup_label = alert_text_list.get(source_language_index)[8];

    List<Resume> resumes = await get_resumes_slots(
      resume_doc_id: resume.id,
      user_id: current_user!.uid,
    );

    List<String> resumes_labels = get_resumes_labels(
      resumes: resumes,
      main_label: alert_text_list.get(source_language_index)[9],
      backup_label: backup_label,
      resume_editor_alert_type: resume_editor_alert_type,
    );

    if (resumes_labels.isNotEmpty) {
      slot_value = resumes_labels[slot_index];
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(
                alert_text_list.get(source_language_index)[resumes_labels.isEmpty
                    ? 9
                    : resume_editor_alert_type == ResumeEditorAlertType.save
                        ? 1
                        : 0],
                style: const TextStyle(
                  color: Colors.black,
                ),
              ),
              content: resumes_labels.isEmpty
                  ? Text(
                      alert_text_list.get(source_language_index)[10],
                      style: const TextStyle(
                        color: Colors.black,
                      ),
                    )
                  : DropdownButton<String>(
                      value: slot_value,
                      onChanged: (String? value) {
                        if (value!.contains(backup_label)) {
                          slot_index = resumes_labels.indexOf(value);
                        } else if (value.contains(main_label)) {
                          slot_index = 0;
                        }

                        resume.slot_index = slot_index;
                        slot_value = value;
                        setState(() {});
                      },
                      items: resumes_labels
                          .map<DropdownMenuItem<String>>(
                            (String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                    ),
              actions: [
                if (resumes_labels.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      alert_text_list.get(source_language_index)[5],
                      style: const TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    expandable_fab_key.currentState!.toggle();

                    if (resumes_labels.isNotEmpty) {
                      switch (resume_editor_alert_type) {
                        case ResumeEditorAlertType.save:
                          save_resume(
                            resume: resume,
                          );
                          break;
                        case ResumeEditorAlertType.load:
                          load_resume(
                            load_example: false,
                            slot_index: slot_index,
                          );
                          break;
                      }
                    }
                  },
                  child: Text(
                    alert_text_list.get(source_language_index)[resumes_labels.isEmpty
                        ? 11
                        : resume_editor_alert_type == ResumeEditorAlertType.save
                            ? 7
                            : 6],
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
