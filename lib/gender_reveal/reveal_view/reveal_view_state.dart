import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xapptor_community/gender_reveal/models/event.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/reveal_view.dart';
import 'package:xapptor_db/xapptor_db.dart';
import 'package:xapptor_router/V2/get_last_path_segment_v2.dart';

/// Mixin containing state management logic for RevealView.
/// Handles event loading, reaction video upload, and reveal state.
mixin RevealViewStateMixin on State<RevealView> {
  // Event data
  EventModel? event;
  String event_id = '';
  String? baby_gender;
  bool _event_loaded = false;
  bool _event_load_error = false;

  // Animation state
  bool animation_complete = false;
  bool show_share_options = false;

  // Reaction recording state
  String? reaction_video_path;
  String reaction_video_format = 'mp4'; // 'mp4' or 'webm'
  bool is_uploading_reaction = false;
  bool reaction_uploaded = false;
  String? reaction_upload_error;
  bool reaction_recording_complete = false;

  // Existing reaction state - tracks if user already has a reaction for this event
  bool user_has_existing_reaction = false;
  String? existing_reaction_url;

  // User state - using Firebase Auth directly
  User? get _firebase_user => FirebaseAuth.instance.currentUser;
  bool get is_user_logged_in => _firebase_user != null;
  String? get current_user_id => _firebase_user?.uid;

  /// Whether camera should be shown (user logged in and no existing reaction)
  bool get should_show_camera => is_user_logged_in && !user_has_existing_reaction;

  /// Initialize the reveal view state.
  void initialize_reveal_state() {
    _load_event_data();
  }

  /// Load event data from Firestore.
  Future<void> _load_event_data() async {
    event_id = get_last_path_segment_v2();

    if (event_id.isEmpty) {
      setState(() {
        _event_load_error = true;
      });
      return;
    }

    try {
      final event_doc = await XapptorDB.instance.collection("events").doc(event_id).get();

      if (!event_doc.exists) {
        debugPrint('RevealView: Event not found: $event_id');
        setState(() {
          _event_load_error = true;
        });
        return;
      }

      final Map<String, dynamic>? event_data = event_doc.data();

      if (!mounted) return;

      setState(() {
        event = EventModel.fromDoc(event_doc);
        baby_gender = event_data?['baby_gender'] as String? ?? 'boy';
        _event_loaded = true;
      });

      // Check if user already has a reaction for this event
      await _check_existing_reaction();
    } catch (e) {
      debugPrint('RevealView: Error loading event: $e');
      if (mounted) {
        setState(() {
          _event_load_error = true;
        });
      }
    }
  }

  /// Generate the reaction document ID (composite key: event_id + user_id).
  String _get_reaction_doc_id() => '${event_id}_$current_user_id';

  /// Check if the current user already has a reaction video for this event.
  Future<void> _check_existing_reaction() async {
    if (!is_user_logged_in || current_user_id == null || event_id.isEmpty) {
      return;
    }

    try {
      // Use top-level reactions collection with composite document ID
      final reaction_doc = await XapptorDB.instance
          .collection("reactions")
          .doc(_get_reaction_doc_id())
          .get();

      if (!mounted) return;

      if (reaction_doc.exists) {
        final data = reaction_doc.data();
        setState(() {
          user_has_existing_reaction = true;
          existing_reaction_url = data?['video_url'] as String?;
          reaction_video_format = data?['format'] as String? ?? 'mp4';
          // Mark as already recorded so UI shows appropriate state
          reaction_recording_complete = true;
          reaction_uploaded = true;
        });
        debugPrint('RevealView: User already has reaction for this event');
      }
    } catch (e) {
      debugPrint('RevealView: Error checking existing reaction: $e');
      // Don't fail the whole flow if this check fails
    }
  }

  /// Called when the reveal animation completes.
  void on_animation_complete() {
    if (!mounted) return;
    setState(() {
      animation_complete = true;
    });

    // Show share options after a brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        show_share_options = true;
      });
    });
  }

  /// Called when reaction recording completes.
  /// The format parameter indicates what format was actually recorded ('mp4' or 'webm').
  void on_reaction_recording_complete(String? video_path, String format) {
    if (!mounted) return;

    setState(() {
      reaction_video_path = video_path;
      reaction_video_format = format;
      reaction_recording_complete = true;
    });

    debugPrint('RevealViewState: Recording complete - path: $video_path, format: $format');

    // Auto-upload if user is logged in and video was recorded
    if (video_path != null && is_user_logged_in) {
      _upload_reaction_video(video_path);
    }
  }

  /// Upload reaction video to Firebase Storage and save metadata to Firestore.
  Future<void> _upload_reaction_video(String video_path) async {
    if (!is_user_logged_in || current_user_id == null) return;

    setState(() {
      is_uploading_reaction = true;
      reaction_upload_error = null;
    });

    try {
      // Use correct file extension and MIME type based on format
      final file_extension = reaction_video_format;
      final content_type = reaction_video_format == 'webm' ? 'video/webm' : 'video/mp4';

      final storage_path = 'events/$event_id/reactions/$current_user_id.$file_extension';
      final ref = FirebaseStorage.instance.ref().child(storage_path);

      // Upload the file
      if (kIsWeb) {
        // For web, read file as bytes using camera XFile
        final x_file = XFile(video_path);
        final bytes = await x_file.readAsBytes();
        await ref.putData(
          bytes,
          SettableMetadata(contentType: content_type),
        );
      } else {
        // For mobile, use File directly
        final file = File(video_path);
        await ref.putFile(
          file,
          SettableMetadata(contentType: content_type),
        );
      }

      // Get the download URL
      final download_url = await ref.getDownloadURL();

      // Save reaction metadata to Firestore
      await _save_reaction_metadata(download_url);

      if (!mounted) return;

      setState(() {
        is_uploading_reaction = false;
        reaction_uploaded = true;
        user_has_existing_reaction = true;
        existing_reaction_url = download_url;
      });

      debugPrint('RevealView: Reaction video uploaded successfully');
    } catch (e) {
      debugPrint('RevealView: Error uploading reaction: $e');
      if (mounted) {
        setState(() {
          is_uploading_reaction = false;
          reaction_upload_error = e.toString();
        });
      }
    }
  }

  /// Save reaction metadata to Firestore for future reference.
  /// Uses top-level 'reactions' collection with composite document ID.
  Future<void> _save_reaction_metadata(String video_url) async {
    if (!is_user_logged_in || current_user_id == null || event_id.isEmpty) {
      return;
    }

    try {
      // Use top-level reactions collection with composite document ID
      await XapptorDB.instance
          .collection("reactions")
          .doc(_get_reaction_doc_id())
          .set({
        'event_id': event_id,
        'user_id': current_user_id,
        'video_url': video_url,
        'format': reaction_video_format,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('RevealView: Reaction metadata saved to Firestore');
    } catch (e) {
      debugPrint('RevealView: Error saving reaction metadata: $e');
      // Don't fail the upload if metadata save fails
    }
  }

  /// Replay the reveal animation.
  void replay_reveal() {
    if (!mounted) return;
    setState(() {
      animation_complete = false;
      show_share_options = false;
      reaction_recording_complete = false;
    });
  }

  /// Check if event data is loaded.
  bool get is_event_loaded => _event_loaded;

  /// Check if there was an error loading the event.
  bool get has_load_error => _event_load_error;

  /// Get the display name for the gender.
  String get_gender_display_name({
    String boy_text = 'Boy',
    String girl_text = 'Girl',
  }) {
    return baby_gender?.toLowerCase() == 'boy' ? boy_text : girl_text;
  }

  /// Dispose resources.
  void dispose_reveal_state() {
    // Clean up any resources if needed
  }
}
