import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:xapptor_community/gender_reveal/event_view/charts/bar_chart_widget.dart';
import 'package:xapptor_community/gender_reveal/event_view/charts/pie_chart.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view_constants.dart';
import 'package:xapptor_ui/widgets/buttons/glowing_vote_button.dart';
import 'package:xapptor_ui/values/ui.dart';
import 'package:xapptor_translation/model/text_list.dart';

/// Widget builder methods for EventView
mixin EventViewWidgetsMixin {
  // These getters must be implemented by the class that uses this mixin
  String get mother_name;
  String get father_name;
  double get boy_votes;
  double get girl_votes;
  String? get selected_vote;
  Animation<double> get shake_animation;
  Animation<double> get glow_animation;

  /// Whether the wishlist button should be enabled.
  /// Override in implementing class to control wishlist visibility.
  bool get wishlist_enabled => false;

  Widget build_intro_section({
    required BuildContext context,
    required bool stacked,
    required BoxConstraints constraints,
    required Color boy_color,
    required Color girl_color,
    required VoidCallback on_celebration_pressed,
    required void Function(String vote) on_vote_selected,
    required Widget Function(
      int source_language_index,
      String? registry_link,
    ) wishlist_button_builder,
    String? registry_link,
    int source_language_index = 0,
    TranslationTextListArray? event_text_list,
    TextStyle? title_style,
    TextStyle? subtitle_style,
  }) {
    // Get translated text or fallback to defaults
    // Index: 1 = Celebrate the Moment!,
    //        2 = Welcome message template (with {mother} and {father} placeholders),
    //        3 = Boy, 4 = Girl, 5 = You voted for a,
    //        27 = Wishlist available after reveal (tooltip)
    final text = event_text_list?.get(source_language_index);
    final celebrate_text = text?[1] ?? 'Celebrate the Moment!';
    final welcome_template = text?[2] ?? 'Welcome to the {mother} & {father} gender reveal celebration!';
    final boy_text = text?[3] ?? 'Boy';
    final girl_text = text?[4] ?? 'Girl';
    final voted_for_text = text?[5] ?? 'You voted for a ';
    final wishlist_tooltip_text = text != null && text.length > 27 ? text[27] : 'Available after the gender reveal';

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
                  // Note: No Tooltip here to avoid "mutated during performLayout" errors
                  // when orientation changes. Tooltips use Overlay which conflicts with
                  // LayoutBuilder during relayout.
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
                    child: GestureDetector(
                      onTap: on_celebration_pressed,
                      child: const Text(
                        "🎉",
                        style: TextStyle(
                          fontSize: k_celebration_icon_size,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: sized_box_space),

                  // Title - use custom style or fallback to theme
                  Text(
                    celebrate_text,
                    textAlign: TextAlign.center,
                    style: title_style ??
                        Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 2.0,
                            ),
                  ),
                  const SizedBox(height: sized_box_space),

                  // Subtitle with parent names (using template with placeholders)
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: subtitle_style ??
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 1.0,
                              ),
                      children: _build_welcome_text_spans(
                        template: welcome_template,
                        mother_name: mother_name,
                        father_name: father_name,
                      ),
                    ),
                  ),

                  const SizedBox(height: sized_box_space),

                  // Wishlist button - disabled until countdown complete or fake countdown
                  // Shows tooltip when disabled (tap on mobile, hover on desktop)
                  AnimatedOpacity(
                    opacity: wishlist_enabled ? 1.0 : 0.5,
                    duration: const Duration(milliseconds: 300),
                    child: wishlist_enabled
                        ? wishlist_button_builder(
                            source_language_index,
                            registry_link,
                          )
                        : Tooltip(
                            message: wishlist_tooltip_text,
                            triggerMode: TooltipTriggerMode.tap,
                            showDuration: const Duration(seconds: 3),
                            child: IgnorePointer(
                              ignoring: true,
                              child: wishlist_button_builder(
                                source_language_index,
                                registry_link,
                              ),
                            ),
                          ),
                  ),
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
                          label: boy_text,
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
                          label: girl_text,
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
                    '$voted_for_text${selected_vote == 'boy' ? boy_text : girl_text}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: sized_box_space / 2),
                  Icon(
                    selected_vote == 'boy' ? Icons.male : Icons.female,
                    color: selected_vote == 'boy' ? boy_color : girl_color,
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
    int source_language_index = 0,
    TranslationTextListArray? event_text_list,
    Color? boy_gradient_start,
    Color? boy_gradient_end,
    Color? girl_gradient_start,
    Color? girl_gradient_end,
  }) {
    // Get translated text for charts
    // Index: 6 = No votes yet (after template consolidation)
    final text = event_text_list?.get(source_language_index);
    final no_votes_text = text?[6] ?? 'No votes yet';

    // Create labels for charts
    final bar_chart_labels = BarChartLabels.fromTextList(text);
    final pie_chart_labels = PieChartLabels.fromTextList(text);

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
                  no_votes_text: no_votes_text,
                )
              : build_charts_section(
                  context: context,
                  portrait: portrait,
                  boy_color: boy_color,
                  girl_color: girl_color,
                  bar_chart_labels: bar_chart_labels,
                  pie_chart_labels: pie_chart_labels,
                  boy_gradient_start: boy_gradient_start,
                  boy_gradient_end: boy_gradient_end,
                  girl_gradient_start: girl_gradient_start,
                  girl_gradient_end: girl_gradient_end,
                ),
        ),
      ),
    );
  }

  Widget build_no_votes_message({
    required BuildContext context,
    String no_votes_text = 'No votes yet',
  }) {
    return Center(
      child: Text(
        no_votes_text,
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
    BarChartLabels bar_chart_labels = const BarChartLabels(),
    PieChartLabels pie_chart_labels = const PieChartLabels(),
    Color? boy_gradient_start,
    Color? boy_gradient_end,
    Color? girl_gradient_start,
    Color? girl_gradient_end,
  }) {
    return Flex(
      direction: portrait ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: BarChartWidget(
            girl_votes: girl_votes,
            boy_votes: boy_votes,
            labels: bar_chart_labels,
            boy_gradient_start: boy_gradient_start,
            boy_gradient_end: boy_gradient_end,
            girl_gradient_start: girl_gradient_start,
            girl_gradient_end: girl_gradient_end,
          ),
        ),
        if (portrait) const SizedBox(height: sized_box_space) else const SizedBox(width: sized_box_space),
        Expanded(
          child: VotePieChart(
            boy_votes: boy_votes,
            girl_votes: girl_votes,
            boy_color: boy_color,
            girl_color: girl_color,
            labels: pie_chart_labels,
          ),
        ),
      ],
    );
  }

  /// Builds a list of TextSpans from a template string with placeholders.
  /// Placeholders: {mother} and {father} will be replaced with the actual names
  /// and styled with bold font weight.
  List<TextSpan> _build_welcome_text_spans({
    required String template,
    required String mother_name,
    required String father_name,
  }) {
    final List<TextSpan> spans = [];
    const bold_style = TextStyle(fontWeight: FontWeight.w800);

    // Regular expression to find {mother} and {father} placeholders
    final regex = RegExp(r'\{(mother|father)\}');
    int last_end = 0;

    for (final match in regex.allMatches(template)) {
      // Add text before the placeholder
      if (match.start > last_end) {
        spans.add(TextSpan(text: template.substring(last_end, match.start)));
      }

      // Add the name with bold styling
      final placeholder = match.group(1);
      if (placeholder == 'mother') {
        spans.add(TextSpan(text: mother_name, style: bold_style));
      } else if (placeholder == 'father') {
        spans.add(TextSpan(text: father_name, style: bold_style));
      }

      last_end = match.end;
    }

    // Add any remaining text after the last placeholder
    if (last_end < template.length) {
      spans.add(TextSpan(text: template.substring(last_end)));
    }

    return spans;
  }
}
