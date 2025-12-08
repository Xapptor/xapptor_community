import 'package:flutter/material.dart';
import 'package:xapptor_community/gender_reveal/models/event.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view_animations.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view_translation.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view_voting.dart';
import 'package:xapptor_db/xapptor_db.dart';
import 'package:xapptor_router/V2/get_last_path_segment_v2.dart';

/// Mixin containing state management logic for EventView.
mixin EventViewStateMixin
    on
        State<EventView>,
        TickerProviderStateMixin<EventView>,
        EventViewAnimationsMixin<EventView>,
        EventViewVotingMixin<EventView>,
        EventViewTranslationMixin {
  EventModel? event;

  void initialize_state() {
    on_voting_card_visibility_changed = (bool show, bool enable) {
      if (mounted)
        setState(() {
          show_voting_card = show;
          enable_voting_card = enable;
        });
    };
    get_event_from_path();
    check_if_user_voted();
    initialize_animations();
  }

  void get_event_from_path() async {
    event_id = get_last_path_segment_v2();
    try {
      final event_doc = await XapptorDB.instance.collection("events").doc(event_id).get();
      if (!event_doc.exists) {
        debugPrint('Event not found: $event_id');
        return;
      }
      event = EventModel.fromDoc(event_doc);
      listen_to_votes();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error getting event from path: $e');
      await _retry_get_event();
    }
  }

  Future<void> _retry_get_event() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    try {
      final event_doc = await XapptorDB.instance.collection("events").doc(event_id).get();
      if (event_doc.exists) {
        event = EventModel.fromDoc(event_doc);
        listen_to_votes();
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Retry failed - Error getting event: $e');
    }
  }

  void on_celebration_pressed() {
    handle_celebration_pressed(on_trigger_music_play: on_trigger_music_play);
  }

  void dispose_state() {
    cancel_votes_subscription();
    dispose_animations();
  }
}
