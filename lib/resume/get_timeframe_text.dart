import 'package:intl/intl.dart';

get_timeframe_text({
  required DateTime begin,
  required DateTime end,
  required String language_code,
  required String present_text,
}) {
  String timeframe_text = "";
  String begin_text = DateFormat.yMMMM(language_code).format(begin);

  String end_text = (end.difference(DateTime.now()).inDays == 0
      ? present_text
      : DateFormat.yMMMM(language_code).format(end));

  return timeframe_text = begin_text.substring(0, 1).toUpperCase() +
      begin_text.substring(1) +
      " - " +
      end_text.substring(0, 1).toUpperCase() +
      end_text.substring(1);
}
