import 'dart:async';
import 'package:flutter/material.dart';
import 'package:xapptor_ui/utils/is_portrait.dart';

const double main_alpha = 0.75;
const double background_alpha = 0.5;

class CountdownView extends StatefulWidget {
  final int epoch;

  const CountdownView({
    super.key,
    required this.epoch,
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
    _target = DateTime.fromMillisecondsSinceEpoch(widget.epoch * 1000);
    _syncRemaining();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _syncRemaining());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncRemaining() {
    final now = DateTime.now();
    final diff = _target.isAfter(now) ? _target.difference(now) : Duration.zero;
    if (!mounted) {
      return;
    }
    setState(() => _remaining = diff);
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

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

    final revealReached = _remaining == Duration.zero;

    double screen_height = MediaQuery.of(context).size.height;
    double screen_width = MediaQuery.of(context).size.width;
    bool portrait = screen_height > screen_width;

    double main_container_screen_width = screen_width * (portrait ? 0.9 : 0.6);

    return Container(
      alignment: Alignment.center,
      color: Colors.black.withAlpha((255 * background_alpha).round()),
      child: SizedBox(
        height: screen_height,
        width: screen_width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: main_container_screen_width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey.withAlpha((255 * background_alpha).round()),
              ),
              child: Text(
                'Gender Reveal In:',
                style: TextStyle(
                  color: Colors.white.withAlpha((255 * 0.8).round()),
                  fontSize: portrait ? 32 : 60,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: main_container_screen_width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey.withAlpha((255 * background_alpha).round()),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (days > 0)
                    Expanded(
                      flex: 1,
                      child: _TimeBlock(
                        label: 'Days',
                        value: _twoDigits(days),
                      ),
                    ),
                  if (days > 0 || hours > 0)
                    Expanded(
                      flex: 1,
                      child: _TimeBlock(
                        label: 'Hours',
                        value: _twoDigits(hours),
                      ),
                    ),
                  if (hours > 0 || minutes > 0)
                    Expanded(
                      flex: 1,
                      child: _TimeBlock(
                        label: 'Minutes',
                        value: _twoDigits(minutes),
                      ),
                    ),
                  Expanded(
                    flex: 1,
                    child: _TimeBlock(
                      label: 'Seconds',
                      value: _twoDigits(seconds),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: revealReached
                  ? Text(
                      'It\'s time! 💖💙',
                      key: const ValueKey('reveal'),
                      style: TextStyle(
                        color: Colors.white.withAlpha((255 * main_alpha).round()),
                        fontSize: portrait ? 20 : 30,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    )
                  : Text(
                      'Get ready for the big moment!',
                      key: const ValueKey('waiting'),
                      style: TextStyle(
                        color: Colors.white.withAlpha((255 * main_alpha).round()),
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
            ),
          ],
        ),
      ),
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
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: Colors.white.withAlpha((255 * main_alpha).round()),
                fontSize: portrait ? 20 : 54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withAlpha((255 * main_alpha).round()),
                fontSize: portrait ? 12 : 34,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
