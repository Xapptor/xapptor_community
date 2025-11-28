import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:xapptor_community/gender_reveal/event_view/charts/bar_chart_widget.dart';
import 'package:xapptor_community/gender_reveal/event_view/charts/pie_chart.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view_constants.dart';
import 'package:xapptor_community/gender_reveal/event_view/glowing_vote_button.dart';
import 'package:xapptor_logic/string/capitalize.dart';
import 'package:xapptor_ui/values/ui.dart';

/// Widget builder methods for EventView
mixin EventViewWidgetsMixin {
  // These getters must be implemented by the class that uses this mixin
  String get mother_name;
  String get father_name;
  double get boy_votes;
  double get girl_votes;
  String? get selected_vote;
  GlobalKey<TooltipState> get celebration_tooltip_key;
  Animation<double> get shake_animation;
  Animation<double> get glow_animation;

  Widget build_intro_section({
    required BuildContext context,
    required bool stacked,
    required BoxConstraints constraints,
    required Color boy_color,
    required Color girl_color,
    required VoidCallback on_celebration_pressed,
    required void Function(String vote) on_vote_selected,
    required Widget wishlist_button,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: stacked ? constraints.maxWidth : k_section_max_width_narrow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(outline_border_radius),
              ),
              child: Column(
                children: [
                  // Celebration icon with shake animation
                  AnimatedBuilder(
                    animation: shake_animation,
                    builder: (context, child) {
                      final t = shake_animation.value;
                      final dx = math.sin(t * math.pi * k_shake_frequency) * k_shake_delta_x;
                      final angle = math.sin(t * math.pi * k_shake_frequency) * k_shake_angle;

                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: Transform.rotate(
                          angle: angle,
                          child: child,
                        ),
                      );
                    },
                    child: Tooltip(
                      key: celebration_tooltip_key,
                      message: 'Click me',
                      child: IconButton(
                        iconSize: k_celebration_icon_size,
                        color: Theme.of(context).colorScheme.onPrimary,
                        onPressed: on_celebration_pressed,
                        icon: const Text(
                          "🎉",
                          style: TextStyle(
                            fontSize: k_celebration_icon_size,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: sized_box_space),

                  // Title
                  Text(
                    'Celebrate the Moment!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                  ),
                  const SizedBox(height: sized_box_space),

                  // Subtitle with parent names
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                      children: [
                        const TextSpan(text: 'Welcome to the '),
                        TextSpan(
                          text: mother_name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const TextSpan(text: ' & '),
                        TextSpan(
                          text: father_name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const TextSpan(
                          text: ' gender reveal celebration!',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: sized_box_space),

                  wishlist_button,
                ],
              ),
            ),
            const SizedBox(height: sized_box_space),

            // Vote buttons with glow animation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedBuilder(
                animation: glow_animation,
                builder: (context, _) {
                  final glow = glow_animation.value;
                  return Row(
                    children: [
                      Expanded(
                        child: GlowingVoteButton(
                          label: 'Boy',
                          icon: Icons.male,
                          color: boy_color,
                          is_selected: selected_vote == 'boy',
                          glow_strength: selected_vote == 'boy' ? glow : 0,
                          on_tap: () => on_vote_selected('boy'),
                        ),
                      ),
                      const SizedBox(width: sized_box_space),
                      Expanded(
                        child: GlowingVoteButton(
                          label: 'Girl',
                          icon: Icons.female,
                          color: girl_color,
                          is_selected: selected_vote == 'girl',
                          glow_strength: selected_vote == 'girl' ? glow : 0,
                          on_tap: () => on_vote_selected('girl'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: sized_box_space * 1.5),

            if (selected_vote != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'You voted for a ${selected_vote!.capitalize()}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: sized_box_space / 2),
                  Icon(
                    selected_vote == 'boy' ? Icons.male : Icons.female,
                    color: selected_vote == 'boy' ? Colors.blue : Colors.pink,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget build_charts_wrapper({
    required BuildContext context,
    required bool stacked,
    required BoxConstraints constraints,
    required bool portrait,
    required bool has_votes,
    required Color boy_color,
    required Color girl_color,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: stacked ? constraints.maxWidth : k_section_max_width_wide,
        ),
        child: AspectRatio(
          aspectRatio: stacked ? 0.9 : 1.35,
          child: !has_votes
              ? build_no_votes_message(
                  context: context,
                )
              : build_charts_section(
                  context: context,
                  portrait: portrait,
                  boy_color: boy_color,
                  girl_color: girl_color,
                ),
        ),
      ),
    );
  }

  Widget build_no_votes_message({
    required BuildContext context,
  }) {
    return Center(
      child: Text(
        'No votes yet',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
      ),
    );
  }

  Widget build_charts_section({
    required BuildContext context,
    required bool portrait,
    required Color boy_color,
    required Color girl_color,
  }) {
    return Flex(
      direction: portrait ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: BarChartWidget(
            girl_votes: girl_votes,
            boy_votes: boy_votes,
          ),
        ),
        if (portrait) const SizedBox(height: sized_box_space) else const SizedBox(width: sized_box_space),
        Expanded(
          child: VotePieChart(
            boy_votes: boy_votes,
            girl_votes: girl_votes,
            boy_color: boy_color,
            girl_color: girl_color,
          ),
        ),
      ],
    );
  }
}
