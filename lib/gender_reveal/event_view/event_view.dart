import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:xapptor_community/gender_reveal/event_view/countdown_view.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view_animations.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view_constants.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view_state.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view_translation.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view_voting.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view_widgets.dart';
import 'package:xapptor_community/ui/slideshow/slideshow.dart';
import 'package:xapptor_ui/utils/is_portrait.dart';
import 'package:xapptor_ui/values/ui.dart';
import 'package:xapptor_translation/language_picker.dart';
import 'package:xapptor_translation/model/text_list.dart';

class EventView extends StatefulWidget {
  final String mother_name;
  final String father_name;
  final Widget Function(int source_language_index) wishlist_button_builder;
  final String share_url;
  final TranslationTextListArray? event_text_list;
  final TranslationTextListArray? wishlist_text_list;
  final TranslationTextListArray? slideshow_fab_text_list;
  final bool has_language_picker;
  final Color? card_overlay_color;
  final Color? boy_color;
  final Color? girl_color;
  final Color? language_picker_background_color;
  final Color? language_picker_text_color;
  final Color? boy_gradient_start;
  final Color? boy_gradient_end;
  final Color? girl_gradient_start;
  final Color? girl_gradient_end;
  final Color? fab_primary_color;
  final Color? fab_secondary_color;
  final TextStyle? title_style;
  final TextStyle? subtitle_style;
  final TextStyle? body_style;
  final bool language_picker_show_icon;
  final Color? language_picker_icon_color;

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
    this.card_overlay_color,
    this.boy_color,
    this.girl_color,
    this.boy_gradient_start,
    this.boy_gradient_end,
    this.girl_gradient_start,
    this.girl_gradient_end,
    this.fab_primary_color,
    this.fab_secondary_color,
    this.language_picker_background_color,
    this.language_picker_text_color,
    this.title_style,
    this.subtitle_style,
    this.body_style,
    this.language_picker_show_icon = false,
    this.language_picker_icon_color,
  });

  @override
  State<EventView> createState() => _EventViewState();
}

class _EventViewState extends State<EventView>
    with
        TickerProviderStateMixin,
        EventViewAnimationsMixin,
        EventViewVotingMixin,
        EventViewTranslationMixin,
        EventViewStateMixin,
        EventViewWidgetsMixin {
  @override
  String get mother_name => widget.mother_name;
  @override
  String get father_name => widget.father_name;
  @override
  List<String>? get dialog_text_list => widget.event_text_list?.get(source_language_index);

  final GlobalKey<ExpandableFabState> _fab_key = GlobalKey<ExpandableFabState>();

  @override
  void initState() {
    super.initState();
    initialize_state();
    init_translation_streams();
    load_saved_language();
  }

  @override
  void dispose() {
    dispose_state();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final portrait = is_portrait(context);
    final has_votes = (boy_votes + girl_votes) > 0;
    final boy_color = widget.boy_color ?? Colors.blueAccent.shade200;
    final girl_color = widget.girl_color ?? Colors.pinkAccent.shade200;
    final card_overlay = widget.card_overlay_color ?? Colors.black.withAlpha((255 * 0.6).round());
    final lang_bg = widget.language_picker_background_color ?? Colors.black.withAlpha((255 * 0.5).round());
    final lang_text = widget.language_picker_text_color ?? Colors.white;

    bool small_countdown = false;
    if (event != null) {
      small_countdown = (event!.reveal_date.millisecondsSinceEpoch - 7000) <= DateTime.now().millisecondsSinceEpoch;
    }

    return Scaffold(
      body: event == null
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade200)))
          : SafeArea(
              child: Stack(children: [
                _build_main_content(
                  size.width,
                  size.height,
                  portrait,
                  has_votes,
                  boy_color,
                  girl_color,
                  card_overlay,
                  small_countdown,
                ),
                if (widget.has_language_picker && translation_stream_list.isNotEmpty)
                  _build_language_picker(lang_bg, lang_text),
              ]),
            ),
      floatingActionButton: fab_data?.build_fab(_fab_key),
      floatingActionButtonLocation: ExpandableFab.location,
    );
  }

  Widget _build_main_content(
    double w,
    double h,
    bool portrait,
    bool has_votes,
    Color boy,
    Color girl,
    Color overlay,
    bool small,
  ) {
    return Positioned.fill(
      child: Stack(children: [
        Positioned.fill(child: _build_slideshow()),
        if (event != null && enable_voting_card && !small)
          _build_voting_card(w, h, portrait, has_votes, boy, girl, overlay),
      ]),
    );
  }

  Widget _build_slideshow() {
    final fab_text = widget.slideshow_fab_text_list?.get(source_language_index);
    return Slideshow(
      key: const ValueKey('event_view_slideshow'),
      image_paths: const [],
      use_examples: true,
      on_fab_data: on_fab_data_changed,
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
      primary_color: widget.fab_primary_color ?? const Color(0xFFD9C7FF),
      secondary_color: widget.fab_secondary_color ?? const Color(0xFFFFC2E0),
      title_style: widget.title_style,
      subtitle_style: widget.subtitle_style,
      body_style: widget.body_style,
    );
  }

  Widget _build_voting_card(double w, double h, bool portrait, bool has_votes, Color boy, Color girl, Color overlay) {
    return Center(
      child: AnimatedOpacity(
        opacity: show_voting_card ? 1.0 : 0.0,
        duration: const Duration(seconds: k_fade_animation_duration_seconds),
        curve: Curves.easeOut,
        child: Container(
          height: h * (portrait ? 0.75 : 0.8),
          width: w * (portrait ? 0.85 : 0.7),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: overlay, borderRadius: BorderRadius.circular(outline_border_radius)),
          child: Column(mainAxisSize: MainAxisSize.max, children: [
            CountdownView(
              milliseconds_sice_epoch: event!.reveal_date.millisecondsSinceEpoch,
              labels: CountdownLabels.fromTextList(widget.event_text_list?.get(source_language_index)),
            ),
            Expanded(child: _build_voting_content(portrait, has_votes, boy, girl)),
          ]),
        ),
      ),
    );
  }

  Widget _build_voting_content(bool portrait, bool has_votes, Color boy, Color girl) {
    return LayoutBuilder(builder: (context, constraints) {
      final stacked = portrait || constraints.maxWidth < 760;
      final intro = build_intro_section(
        context: context,
        stacked: stacked,
        constraints: constraints,
        boy_color: boy,
        girl_color: girl,
        on_celebration_pressed: on_celebration_pressed,
        on_vote_selected: (vote) => on_vote_selected(vote, context),
        wishlist_button_builder: widget.wishlist_button_builder,
        source_language_index: source_language_index,
        event_text_list: widget.event_text_list,
        title_style: widget.title_style,
        subtitle_style: widget.subtitle_style,
      );
      final charts = build_charts_wrapper(
        context: context,
        stacked: stacked,
        constraints: constraints,
        portrait: portrait,
        has_votes: has_votes,
        boy_color: boy,
        girl_color: girl,
        source_language_index: source_language_index,
        event_text_list: widget.event_text_list,
        boy_gradient_start: widget.boy_gradient_start,
        boy_gradient_end: widget.boy_gradient_end,
        girl_gradient_start: widget.girl_gradient_start,
        girl_gradient_end: widget.girl_gradient_end,
      );
      final content = stacked
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                intro,
                const SizedBox(height: sized_box_space * 4),
                charts,
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(flex: 48, child: intro),
                const SizedBox(width: sized_box_space),
                Flexible(flex: 52, child: charts)
              ],
            );
      return Scrollbar(
        thumbVisibility: portrait ? true : false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: stacked ? 40 : 56),
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: portrait ? constraints.maxHeight : 0,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: content,
            ),
          ),
        ),
      );
    });
  }

  Widget _build_language_picker(Color bg, Color text) {
    return Positioned(
      top: 8,
      right: sized_box_space,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(outline_border_radius)),
        child: SizedBox(
          width: widget.language_picker_show_icon ? 170 : 150,
          child: LanguagePicker(
            translation_stream_list: translation_stream_list,
            language_picker_items_text_color: text,
            update_source_language: update_source_language,
            source_language_index: source_language_index,
            show_icon: widget.language_picker_show_icon,
            icon_color: widget.language_picker_icon_color ?? text,
          ),
        ),
      ),
    );
  }
}
