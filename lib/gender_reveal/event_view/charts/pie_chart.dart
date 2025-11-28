import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:xapptor_ui/values/ui.dart';

class VotePieChart extends StatelessWidget {
  final double boy_votes;
  final double girl_votes;
  final Color boy_color;
  final Color girl_color;

  const VotePieChart({
    super.key,
    required this.boy_votes,
    required this.girl_votes,
    required this.boy_color,
    required this.girl_color,
  });

  @override
  Widget build(BuildContext context) {
    final double total_votes = boy_votes + girl_votes;
    final double boy_percentage = total_votes == 0 ? 0 : boy_votes / total_votes;
    final double girl_percentage = total_votes == 0 ? 0 : girl_votes / total_votes;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, box_constraints) {
              final double chart_size = math.min(box_constraints.maxWidth, box_constraints.maxHeight);
              return Center(
                child: SizedBox(
                  width: chart_size,
                  height: chart_size,
                  child: CustomPaint(
                    painter: PieChartPainter(
                      boy_percentage: boy_percentage,
                      girl_percentage: girl_percentage,
                      boy_color: boy_color,
                      girl_color: girl_color,
                    ),
                    child: Center(
                      child: Text(
                        '${(boy_percentage * 100).toStringAsFixed(0)}% / ${(girl_percentage * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: sized_box_space),
        PieLegendEntry(
          color: boy_color,
          label: 'Boy',
          percentage: boy_percentage,
        ),
        const SizedBox(height: 6),
        PieLegendEntry(
          color: girl_color,
          label: 'Girl',
          percentage: girl_percentage,
        ),
      ],
    );
  }
}

class PieChartPainter extends CustomPainter {
  final double boy_percentage;
  final double girl_percentage;
  final Color boy_color;
  final Color girl_color;

  PieChartPainter({
    required this.boy_percentage,
    required this.girl_percentage,
    required this.boy_color,
    required this.girl_color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double stroke_width = size.width * 0.2;
    final Rect chart_rect = Offset.zero & size;
    final Paint background_paint = Paint()
      ..color = Colors.white.withAlpha((255 * 0.15).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke_width;

    canvas.drawArc(chart_rect.deflate(stroke_width / 2), 0, 2 * math.pi, false, background_paint);

    double start_angle = -math.pi / 2;
    final Paint boy_paint = Paint()
      ..color = boy_color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke_width
      ..strokeCap = StrokeCap.round;

    final Paint girl_paint = Paint()
      ..color = girl_color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke_width
      ..strokeCap = StrokeCap.round;

    final double boy_sweep = 2 * math.pi * boy_percentage;
    final double girl_sweep = 2 * math.pi * girl_percentage;

    if (boy_sweep > 0) {
      canvas.drawArc(chart_rect.deflate(stroke_width / 2), start_angle, boy_sweep, false, boy_paint);
      start_angle += boy_sweep;
    }
    if (girl_sweep > 0) {
      canvas.drawArc(chart_rect.deflate(stroke_width / 2), start_angle, girl_sweep, false, girl_paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PieLegendEntry extends StatelessWidget {
  final Color color;
  final String label;
  final double percentage;

  const PieLegendEntry({
    super.key,
    required this.color,
    required this.label,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
        ),
        Text(
          '${(percentage * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
        ),
      ],
    );
  }
}
