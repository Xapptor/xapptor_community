// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/models/resume.dart';
import 'package:xapptor_community/resume/resume_editor/crud/delete/delete_resume.dart';
import 'package:xapptor_community/resume/resume_editor/crud/read/get_resumes.dart';
import 'package:xapptor_community/resume/resume_editor/crud/read/get_resumes_labels.dart';
import 'package:xapptor_community/resume/resume_editor/load_resume.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:xapptor_community/resume/resume_editor/crud/create/save_resume.dart';
import 'dart:async';

enum ResumeEditorAlertType {
  save,
  load,
  delete,
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

  _asking_for_deletion_alert() {
    String no_label = alert_text_list.get(source_language_index)[5];
    String yes_label = alert_text_list.get(source_language_index)[6];

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
                    no_label,
                    style: const TextStyle(
                      color: Colors.black,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    delete_resume(
                      slot_index: slot_index,
                    );
                  },
                  child: Text(
                    yes_label,
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

  _asking_for_backup_alert({
    required Resume resume,
  }) {
    String no_label = alert_text_list.get(source_language_index)[5];
    String yes_label = alert_text_list.get(source_language_index)[6];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text(
                alert_text_list.get(source_language_index)[4],
                style: const TextStyle(
                  color: Colors.black,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    asked_for_backup_alert = false;
                    Navigator.pop(context);
                  },
                  child: Text(
                    no_label,
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
                      resume_editor_alert_type: ResumeEditorAlertType.save,
                    );
                  },
                  child: Text(
                    yes_label,
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

    resumes = await get_resumes(
      user_id: current_user!.uid,
    );

    List<String> resumes_labels = get_resumes_labels(
      resumes: resumes,
      main_label: main_label,
      backup_label: backup_label,
      resume_editor_alert_type: resume_editor_alert_type,
    );

    if (resumes_labels.isNotEmpty) {
      slot_value = resumes_labels[slot_index];
    }

    set_slot_index() {
      if (slot_value.contains(backup_label)) {
        slot_index = resumes_labels.indexOf(slot_value);
      } else if (slot_value.contains(main_label)) {
        slot_index = 0;
      }
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
                        ? 3
                        : resume_editor_alert_type == ResumeEditorAlertType.delete
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
                      isExpanded: true,
                      onChanged: (String? value) {
                        slot_value = value!;
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
                      alert_text_list.get(source_language_index)[7],
                      style: const TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (expandable_fab_key.currentState!.isOpen) {
                      expandable_fab_key.currentState!.toggle();
                    }

                    if (resumes_labels.isNotEmpty) {
                      switch (resume_editor_alert_type) {
                        case ResumeEditorAlertType.save:
                          set_slot_index();

                          save_resume(
                            resume: resume,
                            callback: () {
                              if (!asked_for_backup_alert) {
                                asked_for_backup_alert = true;

                                Timer(const Duration(milliseconds: 2000), () {
                                  _asking_for_backup_alert(
                                    resume: resume,
                                  );
                                });
                              } else {
                                asked_for_backup_alert = false;
                              }
                            },
                          );
                          break;
                        case ResumeEditorAlertType.load:
                          set_slot_index();

                          load_resume(
                            load_example: false,
                            new_slot_index: slot_index,
                          );
                          break;
                        case ResumeEditorAlertType.delete:
                          _asking_for_deletion_alert();
                          break;
                      }
                    }
                  },
                  child: Text(
                    alert_text_list.get(source_language_index)[resumes_labels.isEmpty
                        ? 12
                        : resume_editor_alert_type == ResumeEditorAlertType.delete
                            ? 19
                            : resume_editor_alert_type == ResumeEditorAlertType.save
                                ? 18
                                : 17],
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
