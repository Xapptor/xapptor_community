import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:xapptor_ui/values/ui.dart';

/// Labels for bar chart translations
/// Uses indices 3 = Boy, 4 = Girl, 15 = votes, 16 = vote from event_text_list
class BarChartLabels {
  final String boy;
  final String girl;
  final String votes;
  final String vote;

  const BarChartLabels({
    this.boy = 'Boy',
    this.girl = 'Girl',
    this.votes = 'votes',
    this.vote = 'vote',
  });

  factory BarChartLabels.fromTextList(List<String>? text) {
    if (text == null || text.length < 17) {
      return const BarChartLabels();
    }
    return BarChartLabels(
      boy: text[3],
      girl: text[4],
      votes: text[15],
      vote: text[16],
    );
  }
}

class BarChartWidget extends StatelessWidget {
  final double boy_votes;
  final double girl_votes;
  final BarChartLabels labels;

  // Customizable gradient colors
  final Color? boy_gradient_start;
  final Color? boy_gradient_end;
  final Color? girl_gradient_start;
  final Color? girl_gradient_end;

  const BarChartWidget({
    super.key,
    required this.boy_votes,
    required this.girl_votes,
    this.labels = const BarChartLabels(),
    this.boy_gradient_start,
    this.boy_gradient_end,
    this.girl_gradient_start,
    this.girl_gradient_end,
  });

  @override
  Widget build(BuildContext context) {
    final double max_votes = boy_votes > girl_votes ? boy_votes : girl_votes;
    final double max_y = max_votes == 0 ? 1 : max_votes * 1.2;
    final double interval = max_y <= 4 ? 1 : max_y / 4;

    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: BarChart(
        BarChartData(
          maxY: max_y,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = group.x == 0 ? labels.boy : labels.girl;
                final vote_count = rod.toY.toStringAsFixed(0);
                final vote_label = rod.toY == 1 ? labels.vote : labels.votes;
                return BarTooltipItem(
                  '$label\n$vote_count $vote_label',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  Widget child = const SizedBox.shrink();
                  switch (value.toInt()) {
                    case 0:
                      child = Text(
                        labels.boy,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                      break;
                    case 1:
                      child = Text(
                        labels.girl,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                      break;
                  }
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: child,
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(
                      value.toInt().toString(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withAlpha((255 * 0.5).round()),
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: boy_votes,
                  width: 42,
                  borderRadius: BorderRadius.circular(outline_border_radius),
                  gradient: LinearGradient(
                    colors: [
                      boy_gradient_start ?? const Color(0xFF85C1E9), // Lighter blue
                      boy_gradient_end ?? const Color(0xFF3498DB), // Deeper blue
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
              showingTooltipIndicators: boy_votes == 0 ? [] : [0],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: girl_votes,
                  width: 42,
                  borderRadius: BorderRadius.circular(outline_border_radius),
                  gradient: LinearGradient(
                    colors: [
                      girl_gradient_start ?? const Color(0xFFF5B7B1), // Lighter pink
                      girl_gradient_end ?? const Color(0xFFE74C3C), // Deeper pink/coral
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
              showingTooltipIndicators: girl_votes == 0 ? [] : [0],
            ),
          ],
        ),
      ),
    );
  }
}
