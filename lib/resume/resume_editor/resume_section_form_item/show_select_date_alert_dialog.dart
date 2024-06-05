// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:xapptor_community/resume/resume_editor/resume_section_form_item/resume_section_form_item.dart';
import 'package:xapptor_community/resume/resume_editor/resume_section_form_item/update_item.dart';

extension StateExtension on ResumeSectionFormItemState {
  show_select_date_alert_dialog(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(msg),
          actions: [
            TextButton(
              child: const Text("Ok"),
              onPressed: () async {
                Navigator.of(context).pop();
                _select_dates();
              },
            ),
          ],
        );
      },
    );
  }

  Future _select_dates() async {
    DateTime now = DateTime.now();

    DateTime first_date = DateTime(
      now.year - 100,
      now.month,
      now.day,
    );

    DateTime initial_date = now;

    if (selected_date_index == 0) {
      if (selected_date_1 != null) {
        initial_date = selected_date_1!;
      }
    } else {
      if (selected_date_2 != null) {
        initial_date = selected_date_2!;
      }
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial_date,
      firstDate: first_date,
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.text_color,
              onPrimary: Colors.white,
              onSurface: widget.text_color,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: widget.text_color,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      switch (selected_date_index) {
        case 0:
          selected_date_1 = picked;
          break;
        case 1:
          if (picked.year == now.year && picked.month == now.month && picked.day == now.day) {
            picked = DateTime(
              picked.year,
              picked.month,
              picked.day,
              10,
              10,
              10,
            );
          }
          selected_date_2 = picked;
          break;
      }

      selected_date_index == 0 ? selected_date_index++ : selected_date_index = 0;

      if (selected_date_index != 0) {
        show_select_date_alert_dialog(widget.text_list[7]);
      }
      update_item();
      setState(() {});
    }
  }
}
