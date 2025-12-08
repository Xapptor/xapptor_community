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

  // User state - using Firebase Auth directly
  User? get _firebase_user => FirebaseAuth.instance.currentUser;
  bool get is_user_logged_in => _firebase_user != null;
  String? get current_user_id => _firebase_user?.uid;

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
      final event_doc = await XapptorDB.instance
          .collection("events")
          .doc(event_id)
          .get();

      if (!event_doc.exists) {
        debugPrint('RevealView: Event not found: $event_id');
        setState(() {
          _event_load_error = true;
        });
        return;
      }

      final event_data = event_doc.data() as Map<String, dynamic>?;

      if (!mounted) return;

      setState(() {
        event = EventModel.fromDoc(event_doc);
        baby_gender = event_data?['baby_gender'] as String? ?? 'boy';
        _event_loaded = true;
      });
    } catch (e) {
      debugPrint('RevealView: Error loading event: $e');
      if (mounted) {
        setState(() {
          _event_load_error = true;
        });
      }
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
    });

    debugPrint('RevealViewState: Recording complete - path: $video_path, format: $format');

    // Auto-upload if user is logged in and video was recorded
    if (video_path != null && is_user_logged_in) {
      _upload_reaction_video(video_path);
    }
  }

  /// Upload reaction video to Firebase Storage.
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

      if (!mounted) return;

      setState(() {
        is_uploading_reaction = false;
        reaction_uploaded = true;
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

  /// Replay the reveal animation.
  void replay_reveal() {
    if (!mounted) return;
    setState(() {
      animation_complete = false;
      show_share_options = false;
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
