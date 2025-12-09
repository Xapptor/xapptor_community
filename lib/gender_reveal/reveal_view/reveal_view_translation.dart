import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/reveal_view.dart';
import 'package:xapptor_translation/translation_stream.dart';

/// Mixin for translation handling in RevealView.
/// Manages language selection and persists user preference.
mixin RevealViewTranslationMixin on State<RevealView> {
  int source_language_index = 0;
  TranslationStream? translation_stream_reveal;
  List<TranslationStream> translation_stream_list = [];

  /// Gets the current locale code (e.g., "en", "es") based on selected language.
  String get current_locale {
    if (widget.reveal_text_list != null && source_language_index < widget.reveal_text_list!.list.length) {
      return widget.reveal_text_list!.list[source_language_index].source_language;
    }
    return 'en';
  }

  /// Update text list when translation changes.
  void update_text_list({
    required int index,
    required String new_text,
    required int list_index,
  }) {
    if (list_index == 0 && widget.reveal_text_list != null) {
      widget.reveal_text_list!.get(source_language_index)[index] = new_text;
    }
    setState(() {});
  }

  /// Update source language index and persist preference.
  Future<void> update_source_language({required int new_source_language_index}) async {
    source_language_index = new_source_language_index;
    setState(() {});

    // Persist the language preference
    if (widget.reveal_text_list != null && new_source_language_index < widget.reveal_text_list!.list.length) {
      final target_language = widget.reveal_text_list!.list[new_source_language_index].source_language;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('target_language', target_language);
    }
  }

  /// Load saved language preference.
  Future<void> load_saved_language() async {
    if (widget.reveal_text_list == null) return;

    final prefs = await SharedPreferences.getInstance();
    final target_language = prefs.getString('target_language');
    if (target_language == null) return;

    for (int i = 0; i < widget.reveal_text_list!.list.length; i++) {
      if (widget.reveal_text_list!.list[i].source_language == target_language) {
        if (i != source_language_index && mounted) {
          setState(() => source_language_index = i);
        }
        return;
      }
    }
  }

  /// Initialize translation streams.
  void init_translation_streams() {
    if (widget.reveal_text_list != null) {
      translation_stream_reveal = TranslationStream(
        translation_text_list_array: widget.reveal_text_list!,
        update_text_list_function: update_text_list,
        list_index: 0,
        source_language_index: source_language_index,
      );
      translation_stream_list.add(translation_stream_reveal!);
    }
  }
}
