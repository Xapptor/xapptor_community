import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Real-time subscription to event document changes.
  /// This allows the countdown and other event data to update automatically
  /// when the event creator modifies the event (e.g., changes reveal_date).
  StreamSubscription<DocumentSnapshot>? _event_subscription;

  void initialize_state() {
    on_voting_card_visibility_changed = (bool show, bool enable) {
      if (mounted) {
        setState(() {
          show_voting_card = show;
          enable_voting_card = enable;
        });
      }
    };
    _listen_to_event();
    check_if_user_voted();
    initialize_animations();
  }

  /// Listen to real-time changes on the event document.
  /// If the creator changes the reveal_date or any other field,
  /// all users viewing the event will see the update immediately.
  void _listen_to_event() {
    event_id = get_last_path_segment_v2();

    _event_subscription?.cancel();
    _event_subscription = XapptorDB.instance.collection("events").doc(event_id).snapshots().listen(
      (event_doc) {
        if (!event_doc.exists) {
          debugPrint('Event not found: $event_id');
          return;
        }

        final new_event = EventModel.fromDoc(event_doc);

        // Check if this is the first load or if data changed
        final bool is_first_load = event == null;
        final bool reveal_date_changed = event != null && event!.reveal_date != new_event.reveal_date;

        event = new_event;

        // Start listening to votes on first load
        if (is_first_load) {
          listen_to_votes();
        }

        if (reveal_date_changed) {
          debugPrint('Event reveal_date changed, updating countdown...');
        }

        if (mounted) setState(() {});
      },
      onError: (e) {
        debugPrint('Error listening to event: $e');
        _retry_listen_to_event();
      },
    );
  }

  Future<void> _retry_listen_to_event() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      _listen_to_event();
    }
  }

  void on_celebration_pressed() {
    handle_celebration_pressed(on_trigger_music_play: on_trigger_music_play);
  }

  void dispose_state() {
    _event_subscription?.cancel();
    _event_subscription = null;
    cancel_votes_subscription();
    dispose_animations();
  }
}
