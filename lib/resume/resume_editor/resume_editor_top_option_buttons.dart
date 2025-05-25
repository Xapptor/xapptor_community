import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/resume_editor/load_resume.dart';
import 'package:xapptor_community/resume/resume_editor/crud/update/choose_color.dart';
import 'package:xapptor_community/resume/resume_editor/crud/update/choose_profile_image.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:xapptor_ui/values/ui.dart';

extension StateExtension on ResumeEditorState {
  resume_editor_top_option_buttons() => Column(
        children: [
          SizedBox(
            height: sized_box_space * 4,
          ),
          SizedBox(
            width: screen_width,
            child: ElevatedButton(
              style: ButtonStyle(
                elevation: WidgetStateProperty.all<double>(
                  0,
                ),
                backgroundColor: WidgetStateProperty.all<Color>(
                  Colors.transparent,
                ),
                overlayColor: WidgetStateProperty.all<Color>(
                  Colors.grey.withValues(alpha: 0.2),
                ),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width,
                    ),
                    side: BorderSide(
                      color: widget.color_topbar,
                    ),
                  ),
                ),
              ),
              onPressed: () {
                load_resume(
                  load_example: true,
                  new_slot_index: 0,
                );
              },
              child: Text(
                text_list.get(source_language_index)[20],
                style: TextStyle(
                  color: widget.color_topbar,
                ),
              ),
            ),
          ),
          SizedBox(
            height: sized_box_space,
          ),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.only(right: 5),
                  child: ElevatedButton(
                    style: ButtonStyle(
                      elevation: WidgetStateProperty.all<double>(
                        0,
                      ),
                      backgroundColor: WidgetStateProperty.all<Color>(
                        Colors.transparent,
                      ),
                      overlayColor: WidgetStateProperty.all<Color>(
                        Colors.grey.withValues(alpha: 0.2),
                      ),
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width,
                          ),
                          side: BorderSide(
                            color: widget.color_topbar,
                          ),
                        ),
                      ),
                    ),
                    onPressed: () {
                      choose_profile_image();
                    },
                    child: Text(
                      picker_text_list.get(source_language_index)[0],
                      style: TextStyle(
                        color: widget.color_topbar,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.only(left: 5),
                  child: ElevatedButton(
                    style: ButtonStyle(
                      elevation: WidgetStateProperty.all<double>(
                        0,
                      ),
                      backgroundColor: WidgetStateProperty.all<Color>(
                        current_color,
                      ),
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            MediaQuery.of(context).size.width,
                          ),
                        ),
                      ),
                    ),
                    onPressed: () {
                      choose_color();
                    },
                    child: Text(
                      picker_text_list.get(source_language_index)[1],
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
}
