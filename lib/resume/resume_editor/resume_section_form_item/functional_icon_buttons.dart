import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:xapptor_community/resume/resume_editor/crud/update/update_section.dart';
import 'package:xapptor_community/resume/resume_editor/resume_section_form.dart';
import 'package:xapptor_community/resume/resume_editor/resume_section_form_item/resume_section_form_item.dart';

extension StateExtension on ResumeSectionFormItemState {
  Widget functional_icon_buttons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (widget.item_index != 0 || widget.resume_section_form_type == ResumeSectionFormType.custom)
              IconButton(
                onPressed: () {
                  widget.remove_item(
                    item_index: widget.item_index,
                    section_index: widget.section_index,
                  );
                },
                icon: const Icon(
                  FontAwesomeIcons.trash,
                ),
                color: Colors.red,
              ),
            IconButton(
              onPressed: () {
                widget.clone_item(
                  item_index: widget.item_index,
                  section_index: widget.section_index,
                );
              },
              icon: const Icon(
                FontAwesomeIcons.clone,
              ),
              color: Colors.blueGrey,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.show_up_arrow)
              IconButton(
                onPressed: () {
                  widget.update_item(
                    item_index: widget.item_index,
                    section_index: widget.section_index,
                    section: widget.section,
                    change_item_position_type: ChangeItemPositionType.move_up,
                  );
                },
                icon: const Icon(
                  FontAwesomeIcons.arrowUp,
                ),
                color: widget.text_color,
              ),
            !widget.show_down_arrow
                ? const SizedBox(
                    height: 40,
                    width: 40,
                  )
                : IconButton(
                    onPressed: () {
                      widget.update_item(
                        item_index: widget.item_index,
                        section_index: widget.section_index,
                        section: widget.section,
                        change_item_position_type: ChangeItemPositionType.move_down,
                      );
                    },
                    icon: const Icon(
                      FontAwesomeIcons.arrowDown,
                    ),
                    color: widget.text_color,
                  ),
          ],
        ),
      ],
    );
  }
}
