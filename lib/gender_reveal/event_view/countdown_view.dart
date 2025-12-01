import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xapptor_ui/utils/is_portrait.dart';

const double main_alpha = 0.7;

/// Translation text indices for countdown labels
/// 7 = Day, 8 = Days, 9 = Hour, 10 = Hours, 11 = Minute, 12 = Minutes, 13 = Second, 14 = Seconds
class CountdownLabels {
  final String day;
  final String days;
  final String hour;
  final String hours;
  final String minute;
  final String minutes;
  final String second;
  final String seconds;

  const CountdownLabels({
    this.day = 'Day',
    this.days = 'Days',
    this.hour = 'Hour',
    this.hours = 'Hours',
    this.minute = 'Minute',
    this.minutes = 'Minutes',
    this.second = 'Second',
    this.seconds = 'Seconds',
  });

  factory CountdownLabels.fromTextList(List<String>? text) {
    if (text == null || text.length < 15) {
      return const CountdownLabels();
    }
    return CountdownLabels(
      day: text[7],
      days: text[8],
      hour: text[9],
      hours: text[10],
      minute: text[11],
      minutes: text[12],
      second: text[13],
      seconds: text[14],
    );
  }
}

class CountdownView extends StatefulWidget {
  final int milliseconds_sice_epoch;
  final CountdownLabels labels;

  const CountdownView({
    super.key,
    required this.milliseconds_sice_epoch,
    this.labels = const CountdownLabels(),
  });

  @override
  State<CountdownView> createState() => _CountdownViewState();
}

class _CountdownViewState extends State<CountdownView> {
  late final DateTime _target;
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _target = DateTime.fromMillisecondsSinceEpoch(widget.milliseconds_sice_epoch);
    _sync_remaining();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _sync_remaining());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _sync_remaining() {
    final now = DateTime.now();
    final diff = _target.isAfter(now) ? _target.difference(now) : Duration.zero;
    if (!mounted) {
      return;
    }
    setState(() => _remaining = diff);
  }

  String _two_digits(int value) => value == 0 ? '0' : value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    const bool seconds_test_mode = false;

    // ignore: dead_code
    final days = seconds_test_mode ? 0 : _remaining.inDays;
    // ignore: dead_code
    final hours = seconds_test_mode ? 0 : _remaining.inHours % 24;
    // ignore: dead_code
    final minutes = seconds_test_mode ? 0 : _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    final labels = widget.labels;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (days > 0)
          Expanded(
            flex: 1,
            child: _TimeBlock(
              label: days == 1 ? labels.day : labels.days,
              value: _two_digits(days),
            ),
          ),
        if (days > 0 || hours > 0)
          Expanded(
            flex: 1,
            child: _TimeBlock(
              label: hours == 1 ? labels.hour : labels.hours,
              value: _two_digits(hours),
            ),
          ),
        if (hours > 0 || minutes > 0)
          Expanded(
            flex: 1,
            child: _TimeBlock(
              label: minutes == 1 ? labels.minute : labels.minutes,
              value: _two_digits(minutes),
            ),
          ),
        Expanded(
          flex: 1,
          child: _TimeBlock(
            label: seconds == 1 ? labels.second : labels.seconds,
            value: _two_digits(seconds),
          ),
        ),
      ],
    );
  }
}

class _TimeBlock extends StatelessWidget {
  final String label;
  final String value;

  const _TimeBlock({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    bool portrait = is_portrait(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey<String>('$label$value'),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha((255 * main_alpha).round()),
                fontSize: portrait ? 20 : 40,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha((255 * main_alpha).round()),
                fontSize: portrait ? 12 : 32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
