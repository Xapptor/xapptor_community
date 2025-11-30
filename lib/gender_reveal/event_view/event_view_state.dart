import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:xapptor_auth/model/xapptor_user.dart';
import 'package:xapptor_community/gender_reveal/models/event.dart';
import 'package:xapptor_community/gender_reveal/models/vote.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view_constants.dart';
import 'package:xapptor_db/xapptor_db.dart';
import 'package:xapptor_router/get_last_path_segment.dart';
import 'package:confetti/confetti.dart';

/// Mixin containing state management logic for EventView
mixin EventViewStateMixin on State<EventView>, TickerProviderStateMixin<EventView> {
  final GlobalKey<TooltipState> celebration_tooltip_key = GlobalKey<TooltipState>();

  // State variables
  double boy_votes = 10;
  double girl_votes = 62;
  String? selected_vote;
  bool confirmed = false;
  bool show_voting_card = false;
  bool enable_voting_card = false;
  final bool show_countdown = false;
  bool tooltip_shown = false;

  // Animation controllers
  late AnimationController glow_controller;
  late Animation<double> glow_animation;
  late AnimationController shake_controller;
  late Animation<double> shake_animation;

  // Timers
  Timer? shake_timer;
  Timer? voting_card_hide_timer;
  Timer? voting_card_show_timer;
  Timer? audio_play_timer;

  // Media
  late AudioPlayer player;
  late ConfettiController controller_top_center;

  String event_id = "";
  EventModel? event;
  XapptorUser? current_user;
  bool is_loading_vote_status = true;

  void initialize_state() {
    get_event_from_path();
    check_if_user_voted();
    // Show the celebration tooltip once after first build to avoid layout mutations.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || tooltip_shown) return;
      celebration_tooltip_key.currentState?.ensureTooltipVisible();
      tooltip_shown = true;
    });

    // Initialize audio player and confetti
    player = AudioPlayer();
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
          if (mounted) {
            setState(() {});
          }
        }
      } catch (retry_error) {
        debugPrint('Retry failed - Error getting event: $retry_error');
      }
    }
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
    audio_play_timer?.cancel();
  }

  void dispose_state() {
    cancel_all_timers();
    glow_controller.dispose();
    shake_controller.removeStatusListener(on_shake_status_changed);
    shake_controller.dispose();
    player.dispose();
    controller_top_center.dispose();
  }

  Future<void> on_vote_selected(String vote) async {
    if (vote == selected_vote || confirmed) return;

    // Check if user is authenticated
    if (current_user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to vote'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialog_context) => AlertDialog(
        title: const Text('Confirm your vote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to vote for ${vote == 'boy' ? 'Boy' : 'Girl'}?'),
            const SizedBox(height: 8),
            const Text(
              'Your vote is final.',
              style: TextStyle(
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog_context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialog_context).pop(true),
            child: const Text('Confirm'),
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

      await Future.wait([
        XapptorDB.instance.collection("votes").add(new_vote.toMap()),
      ]);

      if (!mounted) return;

      setState(() {
        // Remove previous vote if exists
        if (selected_vote == 'boy') {
          boy_votes = (boy_votes - 1).clamp(0.0, double.infinity);
        } else if (selected_vote == 'girl') {
          girl_votes = (girl_votes - 1).clamp(0.0, double.infinity);
        }

        // Add new vote
        if (vote == 'boy') {
          boy_votes += 1;
        } else if (vote == 'girl') {
          girl_votes += 1;
        }

        selected_vote = vote;
        confirmed = true;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vote for ${vote == 'boy' ? 'Boy' : 'Girl'} saved successfully!'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error saving vote: $e');
      if (!mounted) return;

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving vote: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void on_celebration_pressed() async {
    // Cancel any existing timers to avoid conflicts
    voting_card_hide_timer?.cancel();
    voting_card_show_timer?.cancel();
    audio_play_timer?.cancel();

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

    // Schedule voting card to reappear
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

    // Play confetti animation
    controller_top_center.play();

    // Play audio after delay
    audio_play_timer = Timer(
      const Duration(seconds: k_audio_play_delay_seconds),
      () async {
        if (!mounted || player.playing) return;
        try {
          await player.setAsset("assets/example_song/song.mp3");
          await player.play();
        } catch (e) {
          debugPrint('Error playing audio: $e');
        }
      },
    );
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
