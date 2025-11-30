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
import 'package:xapptor_translation/language_picker.dart';
import 'package:xapptor_translation/model/text_list.dart';
import 'package:xapptor_translation/translation_stream.dart';

class EventView extends StatefulWidget {
  final String mother_name;
  final String father_name;
  final Widget Function(int source_language_index) wishlist_button_builder;
  final String share_url;
  final TranslationTextListArray? event_text_list;
  final TranslationTextListArray? wishlist_text_list;
  final TranslationTextListArray? slideshow_fab_text_list;
  final bool has_language_picker;

  const EventView({
    super.key,
    required this.mother_name,
    required this.father_name,
    required this.wishlist_button_builder,
    required this.share_url,
    this.event_text_list,
    this.wishlist_text_list,
    this.slideshow_fab_text_list,
    this.has_language_picker = false,
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

  // Translation state
  int source_language_index = 0;
  TranslationStream? translation_stream_event;
  TranslationStream? translation_stream_wishlist;
  TranslationStream? translation_stream_slideshow_fab;
  List<TranslationStream> translation_stream_list = [];

  void _on_fab_data_changed(SlideshowFabData data) {
    print('_on_fab_data_changed received! is_playing=${data.is_playing}, is_loading=${data.is_loading}');
    setState(() {
      _fab_data = data;
    });
  }

  update_text_list({
    required int index,
    required String new_text,
    required int list_index,
  }) {
    if (list_index == 0 && widget.event_text_list != null) {
      widget.event_text_list!.get(source_language_index)[index] = new_text;
    } else if (list_index == 1 && widget.wishlist_text_list != null) {
      widget.wishlist_text_list!.get(source_language_index)[index] = new_text;
    } else if (list_index == 2 && widget.slideshow_fab_text_list != null) {
      widget.slideshow_fab_text_list!.get(source_language_index)[index] = new_text;
    }
    setState(() {});
  }

  update_source_language({
    required int new_source_language_index,
  }) {
    source_language_index = new_source_language_index;
    setState(() {});
  }

  void _init_translation_streams() {
    if (widget.event_text_list != null) {
      translation_stream_event = TranslationStream(
        translation_text_list_array: widget.event_text_list!,
        update_text_list_function: update_text_list,
        list_index: 0,
        source_language_index: source_language_index,
      );
      translation_stream_list.add(translation_stream_event!);
    }

    if (widget.wishlist_text_list != null) {
      translation_stream_wishlist = TranslationStream(
        translation_text_list_array: widget.wishlist_text_list!,
        update_text_list_function: update_text_list,
        list_index: 1,
        source_language_index: source_language_index,
      );
      translation_stream_list.add(translation_stream_wishlist!);
    }

    if (widget.slideshow_fab_text_list != null) {
      translation_stream_slideshow_fab = TranslationStream(
        translation_text_list_array: widget.slideshow_fab_text_list!,
        update_text_list_function: update_text_list,
        list_index: 2,
        source_language_index: source_language_index,
      );
      translation_stream_list.add(translation_stream_slideshow_fab!);
    }
  }

  @override
  void initState() {
    super.initState();
    initialize_state();
    _init_translation_streams();
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
      body: event == null
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade200),
              ),
            )
          : SafeArea(
              child: Stack(
                children: [
                  // Main background container
                  Positioned.fill(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Builder(
                            builder: (context) {
                              // Get translated FAB labels from slideshow_fab_text_list
                              // Index: 0 = Music Menu, 1 = Close, 2 = Toggle Volume, 3 = Toggle Shuffle,
                              //        4 = Toggle Repeat, 5 = Previous Song, 6 = Play/Pause, 7 = Next Song, 8 = Share
                              final fab_text = widget.slideshow_fab_text_list?.get(source_language_index);

                              return Slideshow(
                                image_paths: const [],
                                use_examples: true,
                                onFabData: _on_fab_data_changed,
                                share_url: widget.share_url + event_id,
                                menu_label: fab_text?[0] ?? 'Music Menu',
                                close_label: fab_text?[1] ?? 'Close',
                                volume_label: fab_text?[2] ?? 'Toggle Volume',
                                shuffle_label: fab_text?[3] ?? 'Toggle Shuffle',
                                repeat_label: fab_text?[4] ?? 'Toggle Repeat',
                                back_label: fab_text?[5] ?? 'Previous Song',
                                play_label: fab_text?[6] ?? 'Play/Pause',
                                forward_label: fab_text?[7] ?? 'Next Song',
                                share_label: fab_text?[8] ?? 'Share',
                              );
                            },
                          ),
                        ),
                        if (event != null && enable_voting_card && !small_countdown_start)
                          Center(
                            child: AnimatedOpacity(
                              opacity: show_voting_card ? 1.0 : 0.0,
                              duration: const Duration(seconds: k_fade_animation_duration_seconds),
                              curve: Curves.easeOut,
                              child: Container(
                                height: screen_height * (portrait ? 0.75 : 0.8),
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
                                      labels: CountdownLabels.fromTextList(
                                        widget.event_text_list?.get(source_language_index),
                                      ),
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
                                            wishlist_button_builder: widget.wishlist_button_builder,
                                            source_language_index: source_language_index,
                                            event_text_list: widget.event_text_list,
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
                                            source_language_index: source_language_index,
                                            event_text_list: widget.event_text_list,
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

                  // Language Picker overlay
                  if (widget.has_language_picker && translation_stream_list.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: sized_box_space,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha((255 * 0.5).round()),
                          borderRadius: BorderRadius.circular(outline_border_radius),
                        ),
                        child: SizedBox(
                          width: 150,
                          child: LanguagePicker(
                            translation_stream_list: translation_stream_list,
                            language_picker_items_text_color: Colors.white,
                            update_source_language: update_source_language,
                            source_language_index: source_language_index,
                          ),
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
