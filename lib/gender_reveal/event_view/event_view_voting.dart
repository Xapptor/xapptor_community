// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:xapptor_auth/model/xapptor_user.dart';
import 'package:xapptor_community/gender_reveal/models/vote.dart';
import 'package:xapptor_community/gender_reveal/services/pending_vote_intent_service.dart';
import 'package:xapptor_db/xapptor_db.dart';
import 'package:xapptor_router/V2/get_last_path_segment_v2.dart';
import 'package:xapptor_router/V2/app_screens_v2.dart';

/// Mixin containing voting logic for EventView.
mixin EventViewVotingMixin<T extends StatefulWidget> on State<T> {
  // Vote counts
  double boy_votes = 0;
  double girl_votes = 0;

  // Vote state
  String? selected_vote;
  bool confirmed = false;
  bool is_loading_vote_status = true;

  // User and event info
  String event_id = "";
  XapptorUser? current_user;

  // Real-time votes subscription
  StreamSubscription<QuerySnapshot>? votes_subscription;

  /// Get translated dialog text list from implementing class.
  List<String>? get dialog_text_list;

  /// Callback to notify when voting card should be shown.
  void Function(bool show, bool enable)? on_voting_card_visibility_changed;

  /// Callback to trigger vote confirmation dialog from pending intent.
  /// The implementing class should call show_vote_confirmation_dialog when invoked.
  void Function(String vote_choice)? on_pending_vote_ready;

  /// Start listening to votes collection in real-time.
  void listen_to_votes() {
    votes_subscription?.cancel();

    if (event_id.isEmpty) {
      debugPrint('Cannot listen to votes: event_id is empty');
      return;
    }

    debugPrint('Starting real-time votes listener for event: $event_id');

    votes_subscription =
        XapptorDB.instance.collection("votes").where("event_id", isEqualTo: event_id).snapshots().listen(
      (QuerySnapshot snapshot) {
        if (!mounted) return;

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

  /// Cancel votes subscription.
  void cancel_votes_subscription() {
    votes_subscription?.cancel();
  }

  /// Check if the current user has already voted for this event.
  Future<void> check_if_user_voted() async {
    try {
      current_user = await get_xapptor_user();

      if (current_user == null) {
        debugPrint('User not authenticated');
        _update_loading_state(false, show_card: true);
        return;
      }

      if (event_id.isEmpty) {
        event_id = get_last_path_segment_v2();
      }

      if (event_id.isEmpty) {
        debugPrint('Error: event_id is empty');
        _update_loading_state(false, show_card: true);
        return;
      }

      final vote_query = await XapptorDB.instance
          .collection("votes")
          .where("user_id", isEqualTo: current_user!.id)
          .where("event_id", isEqualTo: event_id)
          .limit(1)
          .get();

      if (vote_query.docs.isNotEmpty) {
        final vote_data = vote_query.docs.first.data();
        final user_vote = vote_data['choice'] as String?;

        if (mounted) {
          setState(() {
            selected_vote = user_vote;
            confirmed = true;
            is_loading_vote_status = false;
          });
          on_voting_card_visibility_changed?.call(true, true);
        }

        debugPrint('User has already voted for event $event_id: $user_vote');
      } else {
        _update_loading_state(false, show_card: true);
        debugPrint('User has not voted yet for event: $event_id');
      }
    } catch (e) {
      debugPrint('Error checking if user voted: $e');
      await _retry_check_vote();
    }
  }

  Future<void> _retry_check_vote() async {
    if (current_user == null || event_id.isEmpty) {
      _update_loading_state(false, show_card: true);
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1500));

    if (current_user == null || event_id.isEmpty) {
      _update_loading_state(false, show_card: true);
      return;
    }

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
          });
          on_voting_card_visibility_changed?.call(true, true);
        }
        debugPrint('Retry succeeded - User has already voted: $user_vote');
      } else {
        _update_loading_state(false, show_card: true);
        debugPrint('Retry succeeded - User has not voted yet');
      }
    } catch (retry_error) {
      debugPrint('Retry failed - Error checking if user voted: $retry_error');
      _update_loading_state(false, show_card: true);
    }
  }

  void _update_loading_state(bool is_loading, {bool show_card = false}) {
    if (mounted) {
      setState(() {
        is_loading_vote_status = is_loading;
      });
      if (show_card) {
        on_voting_card_visibility_changed?.call(true, true);
      }
    }
  }

  /// Handle vote selection.
  Future<void> on_vote_selected(String vote, BuildContext context) async {
    if (vote == selected_vote || confirmed) return;

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
        // Save pending vote intent before redirecting to login
        await PendingVoteIntentService.save(
          event_id: event_id,
          vote_choice: vote,
        );
        open_login_v2();
      }
      return;
    }

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
      Vote new_vote = Vote(
        id: "",
        choice: vote,
        event_id: event_id,
        user_id: current_user!.id,
      );

      await XapptorDB.instance.collection("votes").add(new_vote.toMap());

      if (!mounted) return;

      setState(() {
        selected_vote = vote;
        confirmed = true;
      });

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$vote_error_text: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Check for pending vote intent and trigger vote confirmation if valid.
  /// Should be called after user authentication is confirmed.
  /// Returns true if a pending vote was found and processed.
  Future<bool> check_pending_vote_intent() async {
    if (current_user == null || event_id.isEmpty) {
      debugPrint('PendingVote: Cannot check - user or event_id missing');
      return false;
    }

    // User has already voted - don't process pending intent
    if (confirmed) {
      debugPrint('PendingVote: User already voted, clearing any pending intent');
      await PendingVoteIntentService.clear();
      return false;
    }

    final intent = await PendingVoteIntentService.load_for_event(event_id);
    if (intent == null) {
      debugPrint('PendingVote: No valid pending intent for this event');
      return false;
    }

    // Validate the vote choice is still valid (boy or girl)
    if (intent.vote_choice != 'boy' && intent.vote_choice != 'girl') {
      debugPrint('PendingVote: Invalid vote choice: ${intent.vote_choice}');
      await PendingVoteIntentService.clear();
      return false;
    }

    debugPrint('PendingVote: Found valid intent - choice: ${intent.vote_choice}');

    // Clear the intent first to prevent duplicate processing
    await PendingVoteIntentService.clear();

    // Trigger the callback to show vote confirmation dialog
    // Small delay to ensure UI is ready
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return false;

    on_pending_vote_ready?.call(intent.vote_choice);
    return true;
  }

  /// Show vote confirmation dialog for a pending vote intent.
  /// This is called by the implementing class when on_pending_vote_ready is triggered.
  Future<void> show_vote_confirmation_dialog(
    String vote,
    BuildContext context,
  ) async {
    if (current_user == null) {
      debugPrint('PendingVote: User not authenticated, cannot show dialog');
      return;
    }

    if (confirmed) {
      debugPrint('PendingVote: User already voted');
      // Show message that user already voted
      final text = dialog_text_list;
      final already_voted_text = text?[30] ?? 'You have already voted in this event';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(already_voted_text),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final text = dialog_text_list;
    final cancel_text = text?[19] ?? 'Cancel';
    final confirm_vote_title = text?[21] ?? 'Confirm your vote';
    final vote_confirmation_template = text?[22] ?? 'Are you sure you want to vote for {choice}?';
    final vote_is_final_text = text?[23] ?? 'Your vote is final.';
    final confirm_text = text?[24] ?? 'Confirm';
    final vote_success_template = text?[25] ?? 'Vote for {choice} saved successfully!';
    final vote_error_text = text?[26] ?? 'Error saving vote';
    final boy_text = text?[3] ?? 'Boy';
    final girl_text = text?[4] ?? 'Girl';

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
      Vote new_vote = Vote(
        id: "",
        choice: vote,
        event_id: event_id,
        user_id: current_user!.id,
      );

      await XapptorDB.instance.collection("votes").add(new_vote.toMap());

      if (!mounted) return;

      setState(() {
        selected_vote = vote;
        confirmed = true;
      });

      final success_message = vote_success_template.replaceAll('{choice}', choice_text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success_message),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error saving vote from pending intent: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$vote_error_text: $e'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
