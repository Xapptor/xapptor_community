import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/resume_editor/check_for_remote_resume.dart';
import 'package:xapptor_community/resume/resume_editor/choose_color.dart';
import 'package:xapptor_community/resume/resume_editor/choose_profile_image.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor.dart';
import 'package:xapptor_ui/values/ui.dart';

extension ResumeEditorStateExtension on ResumeEditorState {
  resume_editor_top_option_buttons() => Column(
        children: [
          SizedBox(
            height: sized_box_space * 4,
          ),
          SizedBox(
            width: screen_width,
            child: ElevatedButton(
              style: ButtonStyle(
                elevation: MaterialStateProperty.all<double>(
                  0,
                ),
                backgroundColor: MaterialStateProperty.all<Color>(
                  Colors.transparent,
                ),
                overlayColor: MaterialStateProperty.all<Color>(
                  Colors.grey.withOpacity(0.2),
                ),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
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
                check_for_remote_resume(load_example: true);
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
                      elevation: MaterialStateProperty.all<double>(
                        0,
                      ),
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Colors.transparent,
                      ),
                      overlayColor: MaterialStateProperty.all<Color>(
                        Colors.grey.withOpacity(0.2),
                      ),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
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
                      elevation: MaterialStateProperty.all<double>(
                        0,
                      ),
                      backgroundColor: MaterialStateProperty.all<Color>(
                        current_color,
                      ),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
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
