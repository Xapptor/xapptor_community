import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:xapptor_community/gender_reveal/models/event.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view_animations.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view_translation.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view_voting.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/reveal_constants.dart';
import 'package:xapptor_db/xapptor_db.dart';
import 'package:xapptor_router/V2/get_last_path_segment_v2.dart';
import 'package:xapptor_router/V2/app_screens_v2.dart';

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

  // ==========================================================================
  // FAKE COUNTDOWN STATE
  // ==========================================================================

  /// Whether to use a fake countdown (for users arriving after reveal time).
  bool use_fake_countdown = false;

  /// The end time for the fake countdown.
  DateTime? fake_countdown_end;

  /// Whether the wishlist button should be enabled.
  /// Enabled when: real countdown reached OR using fake countdown.
  bool wishlist_enabled = false;

  /// Whether navigation to reveal screen has been triggered.
  bool _reveal_navigation_triggered = false;

  void initialize_state() {
    on_voting_card_visibility_changed = (bool show, bool enable) {
      if (mounted) {
        setState(() {
          show_voting_card = show;
          enable_voting_card = enable;
        });
      }
    };

    // Set up callback for pending vote intent
    on_pending_vote_ready = (String vote_choice) {
      if (mounted) {
        show_vote_confirmation_dialog(vote_choice, context);
      }
    };

    _listen_to_event();
    _check_user_vote_and_pending_intent();
    initialize_animations();
  }

  /// Check if user has voted, then check for pending vote intent.
  Future<void> _check_user_vote_and_pending_intent() async {
    await check_if_user_voted();

    // After checking vote status, check for pending vote intent
    // Only if user is authenticated and hasn't voted yet
    if (current_user != null && !confirmed) {
      await check_pending_vote_intent();
    }
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
          // Check if we need fake countdown (user arrived after reveal time)
          _check_countdown_status();
        }

        if (reveal_date_changed) {
          debugPrint('Event reveal_date changed, updating countdown...');
          // Re-check countdown status when reveal date changes
          _check_countdown_status();
        }

        if (mounted) setState(() {});
      },
      onError: (e) {
        debugPrint('Error listening to event: $e');
        _retry_listen_to_event();
      },
    );
  }

  /// Check if user arrived after reveal time and needs fake countdown.
  void _check_countdown_status() {
    if (event == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final reveal_time = event!.reveal_date.millisecondsSinceEpoch;

    if (now >= reveal_time) {
      // User arrived AFTER reveal time - start fake countdown
      _start_fake_countdown();
    } else {
      // Real countdown is still active
      use_fake_countdown = false;
      wishlist_enabled = false;
    }
  }

  /// Start a fake countdown for users who arrived late.
  /// This creates anticipation even for latecomers.
  void _start_fake_countdown() {
    if (use_fake_countdown) return; // Already started

    debugPrint('EventView: Starting fake countdown (user arrived late)');

    use_fake_countdown = true;
    wishlist_enabled = true; // Enable wishlist for late arrivals
    fake_countdown_end = DateTime.now().add(
      const Duration(seconds: k_fake_countdown_duration_seconds),
    );

    if (mounted) setState(() {});
  }

  /// Get the countdown target time (real or fake).
  int get countdown_target_milliseconds {
    if (use_fake_countdown && fake_countdown_end != null) {
      return fake_countdown_end!.millisecondsSinceEpoch;
    }
    return event?.reveal_date.millisecondsSinceEpoch ?? 0;
  }

  /// Called when countdown (real or fake) reaches zero.
  void on_countdown_complete() {
    if (_reveal_navigation_triggered) return;
    _reveal_navigation_triggered = true;

    debugPrint('EventView: Countdown complete, navigating to reveal screen');

    // Enable wishlist before navigation
    wishlist_enabled = true;

    // Navigate to reveal screen
    open_screen_v2('reveal/$event_id');
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
