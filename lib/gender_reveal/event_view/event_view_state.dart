import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:xapptor_auth/model/xapptor_user.dart';
import 'package:xapptor_community/gender_reveal/models/event.dart';
import 'package:xapptor_community/gender_reveal/models/vote.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view_constants.dart';
import 'package:xapptor_db/xapptor_db.dart';
import 'package:xapptor_router/get_last_path_segment.dart';
import 'package:xapptor_router/app_screens.dart';
import 'package:confetti/confetti.dart';

/// Mixin containing state management logic for EventView
mixin EventViewStateMixin on State<EventView>, TickerProviderStateMixin<EventView> {
  final GlobalKey<TooltipState> celebration_tooltip_key = GlobalKey<TooltipState>();

  // State variables
  double boy_votes = 0;
  double girl_votes = 0;
  String? selected_vote;
  bool confirmed = false;
  bool show_voting_card = false;
  bool enable_voting_card = false;
  final bool show_countdown = false;
  bool tooltip_shown = false;

  // Callback to trigger slideshow music play (set by EventView)
  VoidCallback? on_trigger_music_play;

  // Getter for translated dialog text (to be set by implementing class)
  // Returns list of strings for dialog text, or null if not available
  // Index: 17 = Login Required, 18 = Login message, 19 = Cancel, 20 = Log In,
  //        21 = Confirm your vote, 22 = Vote confirmation message, 23 = Vote is final, 24 = Confirm
  List<String>? get dialog_text_list;

  // Animation controllers
  late AnimationController glow_controller;
  late Animation<double> glow_animation;
  late AnimationController shake_controller;
  late Animation<double> shake_animation;

  // Timers
  Timer? shake_timer;
  Timer? voting_card_hide_timer;
  Timer? voting_card_show_timer;

  // Confetti controller
  late ConfettiController controller_top_center;

  String event_id = "";
  EventModel? event;
  XapptorUser? current_user;
  bool is_loading_vote_status = true;

  // Real-time votes subscription
  StreamSubscription<QuerySnapshot>? votes_subscription;

  void initialize_state() {
    get_event_from_path();
    check_if_user_voted();
    // Show the celebration tooltip once after first build to avoid layout mutations.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || tooltip_shown) return;
      celebration_tooltip_key.currentState?.ensureTooltipVisible();
      tooltip_shown = true;
    });

    // Initialize confetti controller
    controller_top_center = ConfettiController(
      duration: const Duration(seconds: k_confetti_duration_seconds),
    );

    // Initialize glow animation for vote buttons
    glow_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: k_glow_animation_duration_ms),
    )..repeat(reverse: true);

    glow_animation = CurvedAnimation(
      parent: glow_controller,
      curve: Curves.easeInOut,
    );

    // Initialize shake animation for celebration icon
    shake_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: k_shake_animation_duration_ms),
    );

    shake_animation = CurvedAnimation(
      parent: shake_controller,
      curve: Curves.easeOut,
    );

    shake_controller.addStatusListener(on_shake_status_changed);
    schedule_next_shake();
  }

  void on_shake_status_changed(AnimationStatus status) {
    if (!mounted) return;

    if (status == AnimationStatus.forward) {
      // Show tooltip when shake animation starts
      celebration_tooltip_key.currentState?.ensureTooltipVisible();
    } else if (status == AnimationStatus.completed) {
      shake_controller.reset();
      schedule_next_shake();
      tooltip_shown = true;
    }
  }

  void get_event_from_path() async {
    event_id = get_last_path_segment();

    try {
      final event_doc = await XapptorDB.instance.collection("events").doc(event_id).get();

      if (!event_doc.exists) {
        debugPrint('Event not found: $event_id');
        return;
      }

      event = EventModel.fromDoc(event_doc);

      // Start listening to votes after event is loaded
      listen_to_votes();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error getting event from path: $e');
      // Retry once after a short delay (Firestore might still be initializing)
      await Future.delayed(const Duration(milliseconds: 1500));
      try {
        final event_doc = await XapptorDB.instance.collection("events").doc(event_id).get();
        if (event_doc.exists) {
          event = EventModel.fromDoc(event_doc);

          // Start listening to votes after event is loaded
          listen_to_votes();

          if (mounted) {
            setState(() {});
          }
        }
      } catch (retry_error) {
        debugPrint('Retry failed - Error getting event: $retry_error');
      }
    }
  }

  /// Listen to votes collection in real-time for this event
  void listen_to_votes() {
    // Cancel any existing subscription
    votes_subscription?.cancel();

    if (event_id.isEmpty) {
      debugPrint('Cannot listen to votes: event_id is empty');
      return;
    }

    debugPrint('Starting real-time votes listener for event: $event_id');

    // Subscribe to votes collection filtered by event_id
    votes_subscription = XapptorDB.instance
        .collection("votes")
        .where("event_id", isEqualTo: event_id)
        .snapshots()
        .listen(
      (QuerySnapshot snapshot) {
        if (!mounted) return;

        // Count votes by choice
        int boy_count = 0;
        int girl_count = 0;

        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final choice = data['choice'] as String?;

          if (choice == 'boy') {
            boy_count++;
          } else if (choice == 'girl') {
            girl_count++;
          }
        }

        debugPrint('Votes updated - Boy: $boy_count, Girl: $girl_count');

        setState(() {
          boy_votes = boy_count.toDouble();
          girl_votes = girl_count.toDouble();
        });
      },
      onError: (error) {
        debugPrint('Error listening to votes: $error');
      },
    );
  }

  void schedule_next_shake() {
    shake_timer?.cancel();

    // Random interval between min and max seconds
    const range = k_max_shake_interval_seconds - k_min_shake_interval_seconds;
    final seconds = k_min_shake_interval_seconds + math.Random().nextInt(range);

    shake_timer = Timer(Duration(seconds: seconds), () {
      if (!mounted) return;
      shake_controller.forward();
    });
  }

  void cancel_all_timers() {
    shake_timer?.cancel();
    voting_card_hide_timer?.cancel();
    voting_card_show_timer?.cancel();
  }

  void dispose_state() {
    cancel_all_timers();
    votes_subscription?.cancel();
    glow_controller.dispose();
    shake_controller.removeStatusListener(on_shake_status_changed);
    shake_controller.dispose();
    controller_top_center.dispose();
  }

  Future<void> on_vote_selected(String vote) async {
    if (vote == selected_vote || confirmed) return;

    // Get translated text or use defaults
    final text = dialog_text_list;
    final login_required_title = text?[17] ?? 'Login Required';
    final login_required_message = text?[18] ?? 'You need to log in to vote. Would you like to log in now?';
    final cancel_text = text?[19] ?? 'Cancel';
    final login_text = text?[20] ?? 'Log In';
    final confirm_vote_title = text?[21] ?? 'Confirm your vote';
    final vote_confirmation_template = text?[22] ?? 'Are you sure you want to vote for {choice}?';
    final vote_is_final_text = text?[23] ?? 'Your vote is final.';
    final confirm_text = text?[24] ?? 'Confirm';
    final vote_success_template = text?[25] ?? 'Vote for {choice} saved successfully!';
    final vote_error_text = text?[26] ?? 'Error saving vote';
    final boy_text = text?[3] ?? 'Boy';
    final girl_text = text?[4] ?? 'Girl';

    // Check if user is authenticated - redirect to login if not
    if (current_user == null) {
      if (!mounted) return;

      final should_login = await showDialog<bool>(
        context: context,
        builder: (dialog_context) => AlertDialog(
          title: Text(login_required_title),
          content: Text(login_required_message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog_context).pop(false),
              child: Text(cancel_text),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialog_context).pop(true),
              child: Text(login_text),
            ),
          ],
        ),
      );

      if (should_login == true) {
        open_login();
      }
      return;
    }

    // Get choice text for confirmation message
    final choice_text = vote == 'boy' ? boy_text : girl_text;
    final confirmation_message = vote_confirmation_template.replaceAll('{choice}', choice_text);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialog_context) => AlertDialog(
        title: Text(confirm_vote_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(confirmation_message),
            const SizedBox(height: 8),
            Text(
              vote_is_final_text,
              style: const TextStyle(
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog_context).pop(false),
            child: Text(cancel_text),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialog_context).pop(true),
            child: Text(confirm_text),
          ),
        ],
      ),
    );

    if (result != true || !mounted) return;

    try {
      // Prepare vote data
      Vote new_vote = Vote(
        id: "",
        choice: vote,
        event_id: event_id,
        user_id: current_user!.id,
      );

      await XapptorDB.instance.collection("votes").add(new_vote.toMap());

      if (!mounted) return;

      // Update local state - votes count will be updated by real-time listener
      setState(() {
        selected_vote = vote;
        confirmed = true;
      });

      // Show success message with translated text
      final success_message = vote_success_template.replaceAll('{choice}', choice_text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success_message),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error saving vote: $e');
      if (!mounted) return;

      // Show error message with translated text
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$vote_error_text: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void on_celebration_pressed() {
    // Cancel any existing timers to avoid conflicts
    voting_card_hide_timer?.cancel();
    voting_card_show_timer?.cancel();

    // Hide voting card with fade out
    setState(() {
      show_voting_card = false;
    });

    // Disable voting card after fade completes
    voting_card_hide_timer = Timer(
      const Duration(milliseconds: k_voting_card_hide_delay_ms),
      () {
        if (!mounted) return;
        setState(() {
          enable_voting_card = false;
        });
      },
    );

    // Schedule voting card to reappear after 10 seconds
    voting_card_show_timer = Timer(
      const Duration(seconds: k_voting_card_show_delay_seconds),
      () {
        if (!mounted) return;
        setState(() {
          enable_voting_card = true;
          show_voting_card = true;
        });
      },
    );

    // Trigger slideshow music play via callback (if set)
    on_trigger_music_play?.call();
  }

  // Do a query to check if the user already vote for this event
  Future<void> check_if_user_voted() async {
    try {
      // Get current user
      current_user = await get_xapptor_user();

      if (current_user == null) {
        debugPrint('User not authenticated');
        if (mounted) {
          setState(() {
            is_loading_vote_status = false;
          });
        }
        return;
      }

      // Get event_id first if not set yet
      if (event_id.isEmpty) {
        event_id = get_last_path_segment();
      }

      // Validate event_id is not empty
      if (event_id.isEmpty) {
        debugPrint('Error: event_id is empty');
        if (mounted) {
          setState(() {
            is_loading_vote_status = false;
          });
        }
        return;
      }

      // Query the votes collection to check if this user has already voted for this specific event
      // Filter by both user_id AND event_id to ensure we're checking the correct event
      final vote_query = await XapptorDB.instance
          .collection("votes")
          .where("user_id", isEqualTo: current_user!.id)
          .where("event_id", isEqualTo: event_id)
          .limit(1)
          .get();

      if (vote_query.docs.isNotEmpty) {
        // User has already voted for this event - HIDE voting card
        final vote_data = vote_query.docs.first.data();
        final user_vote = vote_data['choice'] as String?;
        final vote_event_id = vote_data['event_id'] as String?;

        // Double check that the event_id matches (extra validation)
        if (vote_event_id != event_id) {
          debugPrint('Warning: Vote event_id mismatch. Expected: $event_id, Got: $vote_event_id');
        }

        if (mounted) {
          setState(() {
            selected_vote = user_vote;
            confirmed = true;
            is_loading_vote_status = false;
            // Hide voting card since user already voted
            show_voting_card = true;
            enable_voting_card = true;
          });
        }

        debugPrint('User has already voted for event $event_id: $user_vote');
      } else {
        // User hasn't voted yet for this event - SHOW voting card
        if (mounted) {
          setState(() {
            is_loading_vote_status = false;
            // Show voting card since user hasn't voted
            show_voting_card = true;
            enable_voting_card = true;
          });
        }
        debugPrint('User has not voted yet for event: $event_id - Showing voting card');
      }
    } catch (e) {
      debugPrint('Error checking if user voted: $e');
      // Retry once after a short delay (Firestore might still be initializing)
      await Future.delayed(const Duration(milliseconds: 1500));
      try {
        final vote_query_retry = await XapptorDB.instance
            .collection("votes")
            .where("user_id", isEqualTo: current_user!.id)
            .where("event_id", isEqualTo: event_id)
            .limit(1)
            .get();

        if (vote_query_retry.docs.isNotEmpty) {
          final vote_data = vote_query_retry.docs.first.data();
          final user_vote = vote_data['choice'] as String?;
          if (mounted) {
            setState(() {
              selected_vote = user_vote;
              confirmed = true;
              is_loading_vote_status = false;
              show_voting_card = true;
              enable_voting_card = true;
            });
          }
          debugPrint('Retry succeeded - User has already voted: $user_vote');
        } else {
          if (mounted) {
            setState(() {
              is_loading_vote_status = false;
              show_voting_card = true;
              enable_voting_card = true;
            });
          }
          debugPrint('Retry succeeded - User has not voted yet');
        }
      } catch (retry_error) {
        debugPrint('Retry failed - Error checking if user voted: $retry_error');
        if (mounted) {
          setState(() {
            is_loading_vote_status = false;
            // Show voting card on error (offline or network issues)
            // User can still vote and it will sync when back online
            show_voting_card = true;
            enable_voting_card = true;
          });
        }
      }
    }
  }
}
