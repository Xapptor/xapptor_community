import 'package:intl/intl.dart';
import 'package:xapptor_community/resume/resume_editor/resume_editor_additional_options.dart';

String get_timeframe_text({
  required DateTime begin,
  required DateTime end,
  required String language_code,
  required String present_text,
  required List<String> text_list,
}) {
  String timeframe_text = "";
  String begin_text = DateFormat.yMMMM(language_code).format(begin);

  bool end_verification_code = end.hour == 10 && end.minute == 10 && end.second == 10;

  String end_text = (end.difference(DateTime.now()).inDays == 0 || end_verification_code
      ? present_text
      : DateFormat.yMMMM(language_code).format(end));

  String timeframe_text_1 = begin_text.substring(0, 1).toUpperCase() + begin_text.substring(1);
  String timeframe_text_2 = end_text.substring(0, 1).toUpperCase() + end_text.substring(1);

  timeframe_text = "$timeframe_text_1 - $timeframe_text_2";

  if (show_time_amount) {
    int months_difference = (begin.month - end.month + 12 * (begin.year - end.year)).abs();

    if (begin.month != end.month) {
      months_difference += 1;
    }

    if (months_difference > 12) {
      int years = months_difference ~/ 12;

      String years_label = get_year_label(
        count: years,
        text_list: text_list,
      );

      timeframe_text += " . $years $years_label";

      int remainder_months = months_difference % 12;

      if (remainder_months > 0) {
        String months_label = get_month_label(
          count: remainder_months,
          text_list: text_list,
        );

        timeframe_text += " $remainder_months $months_label";
      }
    } else {
      String months_label = get_month_label(
        count: months_difference,
        text_list: text_list,
      );

      timeframe_text += " . $months_difference $months_label";
    }
  }
  return timeframe_text;
}

String get_year_label({
  required int count,
  required List<String> text_list,
}) {
  return text_list[count > 1 ? 1 : 0];
}

String get_month_label({
  required int count,
  required List<String> text_list,
}) {
  return text_list[count > 1 ? 3 : 2];
}
