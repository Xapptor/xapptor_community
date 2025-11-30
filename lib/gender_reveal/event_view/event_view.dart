import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:xapptor_community/gender_reveal/event_view/countdown_view.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view_constants.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view_state.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view_widgets.dart';
import 'package:xapptor_community/gender_reveal/event_view/reaction_recorder.dart';
import 'package:xapptor_community/ui/slideshow/slideshow.dart';
import 'package:xapptor_ui/utils/is_portrait.dart';
import 'package:confetti/confetti.dart';
import 'package:xapptor_ui/values/ui.dart';

class EventView extends StatefulWidget {
  final String mother_name;
  final String father_name;
  final Widget wishlist_button;

  const EventView({
    super.key,
    required this.mother_name,
    required this.father_name,
    required this.wishlist_button,
  });

  @override
  State<EventView> createState() => _EventViewState();
}

class _EventViewState extends State<EventView>
    with TickerProviderStateMixin, EventViewStateMixin, EventViewWidgetsMixin {
  // Implement getters required by EventViewWidgetsMixin
  @override
  String get mother_name => widget.mother_name;

  @override
  String get father_name => widget.father_name;

  // FAB key - owned by this widget, persists across rebuilds
  final GlobalKey<ExpandableFabState> _fab_key = GlobalKey<ExpandableFabState>();

  // FAB data from Slideshow
  SlideshowFabData? _fab_data;

  void _on_fab_data_changed(SlideshowFabData data) {
    print('_on_fab_data_changed received! is_playing=${data.is_playing}, is_loading=${data.is_loading}');
    setState(() {
      _fab_data = data;
    });
  }

  @override
  void initState() {
    super.initState();
    initialize_state();
  }

  @override
  void dispose() {
    dispose_state();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screen_width = size.width;
    final screen_height = size.height;
    final portrait = is_portrait(context);

    final total_votes = boy_votes + girl_votes;
    final has_votes = total_votes > 0;
    final boy_color = Colors.blueAccent.shade200;
    final girl_color = Colors.pinkAccent.shade200;

    bool small_countdown_start = false;
    if (event != null) {
      small_countdown_start =
          (event!.reveal_date.millisecondsSinceEpoch - 7000) <= DateTime.now().millisecondsSinceEpoch;
    }

    print('small_countdown_start=$small_countdown_start');

    final fab = _fab_data?.build_fab(_fab_key);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main background container
            Positioned.fill(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Slideshow(
                      image_paths: [],
                      use_examples: true,
                      onFabData: _on_fab_data_changed,
                    ),
                  ),
                  if (event != null && enable_voting_card && !small_countdown_start)
                    Center(
                      child: AnimatedOpacity(
                        opacity: show_voting_card ? 1.0 : 0.0,
                        duration: const Duration(seconds: k_fade_animation_duration_seconds),
                        curve: Curves.easeOut,
                        child: Container(
                          height: screen_height * (portrait ? 0.75 : 0.70),
                          width: screen_width * (portrait ? 0.85 : 0.7),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha((255 * 0.6).round()),
                            borderRadius: BorderRadius.circular(outline_border_radius),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              CountdownView(
                                milliseconds_sice_epoch: (event!.reveal_date).millisecondsSinceEpoch,
                              ),
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final stacked = portrait || constraints.maxWidth < 760;

                                    // ───────────────── intro section ─────────────────
                                    final intro_section = build_intro_section(
                                      context: context,
                                      stacked: stacked,
                                      constraints: constraints,
                                      boy_color: boy_color,
                                      girl_color: girl_color,
                                      on_celebration_pressed: on_celebration_pressed,
                                      on_vote_selected: on_vote_selected,
                                      wishlist_button: widget.wishlist_button,
                                    );

                                    // ───────────────── charts section ─────────────────
                                    final charts_section = build_charts_wrapper(
                                      context: context,
                                      stacked: stacked,
                                      constraints: constraints,
                                      portrait: portrait,
                                      has_votes: has_votes,
                                      boy_color: boy_color,
                                      girl_color: girl_color,
                                    );

                                    final content = stacked
                                        ? Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              intro_section,
                                              const SizedBox(height: sized_box_space * 4),
                                              charts_section,
                                            ],
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Flexible(
                                                flex: 48,
                                                child: intro_section,
                                              ),
                                              const SizedBox(width: sized_box_space),
                                              Flexible(
                                                flex: 52,
                                                child: charts_section,
                                              ),
                                            ],
                                          );

                                    // ⭐ This scrolls INSIDE the card when content > card height.
                                    return SingleChildScrollView(
                                      padding: EdgeInsets.only(
                                        bottom: stacked ? 40 : 56,
                                      ),
                                      physics: const BouncingScrollPhysics(
                                        parent: AlwaysScrollableScrollPhysics(),
                                      ),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: portrait ? constraints.maxHeight : 0,
                                        ),
                                        child: Align(
                                          alignment: Alignment.topCenter,
                                          child: content,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (small_countdown_start)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: SizedBox(
                        height: screen_height / 4,
                        width: screen_width / 4,
                        child: const ReactionRecorder(),
                      ),
                    ),
                ],
              ),
            ),

            // Confetti overlay
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: ConfettiWidget(
                  confettiController: controller_top_center,
                  blastDirectionality: BlastDirectionality.explosive,
                  blastDirection: math.pi / 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 12,
                  gravity: 0.2,
                  maxBlastForce: 20,
                  minBlastForce: 5,
                  shouldLoop: false,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: fab,
      floatingActionButtonLocation: ExpandableFab.location,
    );
  }
}
