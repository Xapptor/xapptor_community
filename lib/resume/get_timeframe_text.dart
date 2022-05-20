import 'package:intl/intl.dart';

get_timeframe_text({
  required DateTime begin,
  required DateTime end,
  required String language_code,
  required String present_text,
}) {
  String timeframe_text = "";
  String begin_text = DateFormat.yMMMM(language_code).format(begin);

  bool end_verification_code =
      end.hour == 10 && end.minute == 10 && end.second == 10;

  String end_text =
      (end.difference(DateTime.now()).inDays == 0 || end_verification_code
          ? present_text
          : DateFormat.yMMMM(language_code).format(end));

  return timeframe_text = begin_text.substring(0, 1).toUpperCase() +
      begin_text.substring(1) +
      " - " +
      end_text.substring(0, 1).toUpperCase() +
      end_text.substring(1);
}
