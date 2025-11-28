import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xapptor_ui/utils/is_portrait.dart';
import 'package:xapptor_ui/values/ui.dart';

const double main_alpha = 0.7;

class CountdownView extends StatefulWidget {
  final int milliseconds_sice_epoch;

  const CountdownView({
    super.key,
    required this.milliseconds_sice_epoch,
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (days > 0)
          Expanded(
            flex: 1,
            child: _TimeBlock(
              label: days == 1 ? 'Day' : 'Days',
              value: _two_digits(days),
            ),
          ),
        if (days > 0 || hours > 0)
          Expanded(
            flex: 1,
            child: _TimeBlock(
              label: hours == 1 ? 'Hour' : 'Hours',
              value: _two_digits(hours),
            ),
          ),
        if (hours > 0 || minutes > 0)
          Expanded(
            flex: 1,
            child: _TimeBlock(
              label: minutes == 1 ? 'Minute' : 'Minutes',
              value: _two_digits(minutes),
            ),
          ),
        Expanded(
          flex: 1,
          child: _TimeBlock(
            label: seconds == 1 ? 'Second' : 'Seconds',
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
            const SizedBox(height: sized_box_space),
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
