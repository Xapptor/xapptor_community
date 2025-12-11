import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model class representing a pending vote intent.
/// Stores the user's intention to vote after completing login.
class PendingVoteIntent {
  final String event_id;
  final String vote_choice;
  final DateTime created_at;

  PendingVoteIntent({
    required this.event_id,
    required this.vote_choice,
    required this.created_at,
  });

  /// Maximum age for a pending intent before it expires.
  /// After 10 minutes, the intent is considered stale.
  static const Duration expiration_duration = Duration(minutes: 10);

  /// Check if this intent has expired.
  bool get is_expired => DateTime.now().difference(created_at) > expiration_duration;

  /// Convert to JSON for storage.
  Map<String, dynamic> toJson() => {
        'event_id': event_id,
        'vote_choice': vote_choice,
        'created_at': created_at.toIso8601String(),
      };

  /// Create from JSON.
  factory PendingVoteIntent.fromJson(Map<String, dynamic> json) {
    return PendingVoteIntent(
      event_id: json['event_id'] as String,
      vote_choice: json['vote_choice'] as String,
      created_at: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Service for managing pending vote intents.
///
/// When a user tries to vote without being logged in:
/// 1. Save the intent (event_id + vote_choice + timestamp)
/// 2. User goes through login flow
/// 3. On return to app, check for pending intent
/// 4. If valid (not expired, same event), show vote confirmation dialog
class PendingVoteIntentService {
  static const String _storage_key = 'pending_vote_intent';

  /// Save a pending vote intent to SharedPreferences.
  static Future<void> save({
    required String event_id,
    required String vote_choice,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final intent = PendingVoteIntent(
        event_id: event_id,
        vote_choice: vote_choice,
        created_at: DateTime.now(),
      );
      await prefs.setString(_storage_key, jsonEncode(intent.toJson()));
      debugPrint('PendingVoteIntent: Saved intent for event $event_id, choice: $vote_choice');
    } catch (e) {
      debugPrint('PendingVoteIntent: Error saving intent: $e');
    }
  }

  /// Load the pending vote intent from SharedPreferences.
  /// Returns null if no intent exists or if it has expired.
  static Future<PendingVoteIntent?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json_string = prefs.getString(_storage_key);

      if (json_string == null) {
        debugPrint('PendingVoteIntent: No pending intent found');
        return null;
      }

      final intent = PendingVoteIntent.fromJson(
        jsonDecode(json_string) as Map<String, dynamic>,
      );

      if (intent.is_expired) {
        debugPrint('PendingVoteIntent: Intent expired, clearing...');
        await clear();
        return null;
      }

      debugPrint('PendingVoteIntent: Loaded valid intent for event ${intent.event_id}');
      return intent;
    } catch (e) {
      debugPrint('PendingVoteIntent: Error loading intent: $e');
      await clear();
      return null;
    }
  }

  /// Clear the pending vote intent from SharedPreferences.
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storage_key);
      debugPrint('PendingVoteIntent: Cleared pending intent');
    } catch (e) {
      debugPrint('PendingVoteIntent: Error clearing intent: $e');
    }
  }

  /// Check if a pending intent exists without loading the full data.
  /// Useful for quick checks before navigation decisions.
  static Future<bool> has_pending_intent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_storage_key);
    } catch (e) {
      return false;
    }
  }

  /// Load pending intent only if it matches the given event_id.
  /// Clears the intent if it exists but doesn't match.
  /// Returns null if no matching intent.
  static Future<PendingVoteIntent?> load_for_event(String event_id) async {
    final intent = await load();

    if (intent == null) return null;

    if (intent.event_id != event_id) {
      debugPrint('PendingVoteIntent: Intent is for different event '
          '(${intent.event_id} != $event_id), ignoring');
      // Don't clear - user might navigate to the correct event later
      return null;
    }

    return intent;
  }
}
