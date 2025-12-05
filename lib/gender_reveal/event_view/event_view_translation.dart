import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view.dart';
import 'package:xapptor_community/ui/slideshow/slideshow.dart';
import 'package:xapptor_translation/translation_stream.dart';

/// Mixin for translation and FAB data handling in EventView.
mixin EventViewTranslationMixin on State<EventView> {
  int source_language_index = 0;
  TranslationStream? translation_stream_event;
  TranslationStream? translation_stream_wishlist;
  List<TranslationStream> translation_stream_list = [];

  SlideshowFabData? fab_data;
  VoidCallback? on_trigger_music_play;

  /// Update text list when translation changes.
  void update_text_list({
    required int index,
    required String new_text,
    required int list_index,
  }) {
    if (list_index == 0 && widget.event_text_list != null) {
      widget.event_text_list!.get(source_language_index)[index] = new_text;
    } else if (list_index == 1 && widget.wishlist_text_list != null) {
      widget.wishlist_text_list!.get(source_language_index)[index] = new_text;
    }
    setState(() {});
  }

  /// Update source language index.
  void update_source_language({required int new_source_language_index}) {
    source_language_index = new_source_language_index;
    setState(() {});
  }

  /// Load saved language preference.
  Future<void> load_saved_language() async {
    if (widget.event_text_list == null) return;

    final prefs = await SharedPreferences.getInstance();
    final target_language = prefs.getString('target_language');
    if (target_language == null) return;

    for (int i = 0; i < widget.event_text_list!.list.length; i++) {
      if (widget.event_text_list!.list[i].source_language == target_language) {
        if (i != source_language_index && mounted) {
          setState(() => source_language_index = i);
        }
        return;
      }
    }
  }

  /// Initialize translation streams.
  void init_translation_streams() {
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
  }

  /// Handle FAB data changes from slideshow.
  void on_fab_data_changed(SlideshowFabData data) {
    final bool should_update = fab_data == null ||
        fab_data!.is_playing != data.is_playing ||
        fab_data!.is_loading != data.is_loading ||
        fab_data!.sound_is_on != data.sound_is_on ||
        fab_data!.shuffle_is_on != data.shuffle_is_on ||
        fab_data!.loop_mode != data.loop_mode;

    if (!should_update) return;

    fab_data = data;
    on_trigger_music_play = () {
      if (!data.is_playing) data.on_play_pressed();
    };

    if (mounted) setState(() {});
  }
}
