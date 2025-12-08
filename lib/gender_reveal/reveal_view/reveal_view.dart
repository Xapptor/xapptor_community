import 'package:flutter/material.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/reveal_animations.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/reveal_constants.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/reveal_reaction_recorder.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/reveal_share_options.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/reveal_view_state.dart';
import 'package:xapptor_router/V2/app_screens_v2.dart';
import 'package:xapptor_translation/model/text_list.dart';
import 'package:xapptor_ui/utils/is_portrait.dart';

/// The gender reveal animation screen.
/// Displays a beautiful reveal animation with confetti and optional reaction recording.
///
/// Route: reveal/<event_id>
///
/// Features:
/// - Gender reveal animation with confetti
/// - Reaction video recording (for logged-in users)
/// - Post-reveal share options
/// - Amazon wishlist integration
class RevealView extends StatefulWidget {
  /// The mother's name for share messages.
  final String mother_name;

  /// The father's name for share messages.
  final String father_name;

  /// Builder for the Amazon wishlist button.
  final Widget Function(int source_language_index) wishlist_button_builder;

  /// Base URL for event sharing.
  final String share_url;

  /// Translation text list for the reveal screen.
  final TranslationTextListArray? reveal_text_list;

  /// Color for boy reveal (blue).
  final Color boy_color;

  /// Color for girl reveal (purple/pink).
  final Color girl_color;

  /// Background color for overlays.
  final Color? overlay_color;

  /// Current language index.
  final int source_language_index;

  const RevealView({
    super.key,
    required this.mother_name,
    required this.father_name,
    required this.wishlist_button_builder,
    required this.share_url,
    this.reveal_text_list,
    this.boy_color = const Color(0xFF5DADE2),
    this.girl_color = const Color(0xFFAF7AC5),
    this.overlay_color,
    this.source_language_index = 0,
  });

  @override
  State<RevealView> createState() => _RevealViewState();
}

class _RevealViewState extends State<RevealView> with RevealViewStateMixin {
  // Key for forcing animation rebuild on replay
  Key _animation_key = UniqueKey();

  @override
  void initState() {
    super.initState();
    initialize_reveal_state();
  }

  @override
  void dispose() {
    dispose_reveal_state();
    super.dispose();
  }

  /// Get translated texts or fallbacks.
  RevealShareTexts get _share_texts {
    final text = widget.reveal_text_list?.get(widget.source_language_index);
    if (text != null && text.length >= 13) {
      return RevealShareTexts.fromTextList(text);
    }
    return const RevealShareTexts();
  }

  String get _boy_text {
    final text = widget.reveal_text_list?.get(widget.source_language_index);
    return text != null && text.length > 11 ? text[11] : 'Boy';
  }

  String get _girl_text {
    final text = widget.reveal_text_list?.get(widget.source_language_index);
    return text != null && text.length > 12 ? text[12] : 'Girl';
  }

  String get _its_a_boy_text {
    final text = widget.reveal_text_list?.get(widget.source_language_index);
    return text != null && text.length > 13 ? text[13] : "It's a Boy!";
  }

  String get _its_a_girl_text {
    final text = widget.reveal_text_list?.get(widget.source_language_index);
    return text != null && text.length > 14 ? text[14] : "It's a Girl!";
  }

  String get _login_prompt_text {
    final text = widget.reveal_text_list?.get(widget.source_language_index);
    return text != null && text.length > 15 ? text[15] : 'Login to save your reaction';
  }

  void _handle_replay() {
    setState(() {
      animation_complete = false;
      show_share_options = false;
      _animation_key = UniqueKey();
    });
  }

  void _navigate_to_login() {
    open_login_v2();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (!is_event_loaded) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: has_load_error
              ? _build_error_view()
              : const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                ),
        ),
      );
    }

    final portrait = is_portrait(context);
    final size = MediaQuery.of(context).size;
    final camera_size = portrait
        ? size.width * k_camera_preview_size_portrait
        : size.width * k_camera_preview_size_landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main reveal animation
            Positioned.fill(
              child: RevealAnimations(
                key: _animation_key,
                gender: baby_gender ?? 'boy',
                baby_name: event?.baby_name,
                boy_color: widget.boy_color,
                girl_color: widget.girl_color,
                boy_text: _its_a_boy_text,
                girl_text: _its_a_girl_text,
                on_animation_complete: on_animation_complete,
              ),
            ),

            // Camera preview
            _build_camera_preview(portrait, camera_size),

            // Share options overlay (after animation completes)
            if (show_share_options) _build_share_overlay(portrait),
          ],
        ),
      ),
    );
  }

  Widget _build_error_view() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline,
          color: Colors.white54,
          size: 48,
        ),
        const SizedBox(height: 16),
        const Text(
          'Event not found',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => open_screen_v2('home'),
          child: const Text(
            'Go Home',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _build_camera_preview(bool portrait, double size) {
    // Position differently for portrait vs landscape
    if (portrait) {
      // Portrait: Top center
      return Positioned(
        top: 16,
        left: 0,
        right: 0,
        child: Center(
          child: SizedBox(
            width: size,
            child: RevealReactionRecorder(
              enable_recording: is_user_logged_in,
              show_preview: true,
              accent_color: baby_gender == 'boy' ? widget.boy_color : widget.girl_color,
              login_prompt_text: _login_prompt_text,
              on_login_prompt: _navigate_to_login,
              on_recording_complete: on_reaction_recording_complete,
            ),
          ),
        ),
      );
    } else {
      // Landscape: Top right corner
      return Positioned(
        top: 16,
        right: 16,
        child: SizedBox(
          width: size,
          child: RevealReactionRecorder(
            enable_recording: is_user_logged_in,
            show_preview: true,
            accent_color: baby_gender == 'boy' ? widget.boy_color : widget.girl_color,
            login_prompt_text: _login_prompt_text,
            on_login_prompt: _navigate_to_login,
            on_recording_complete: on_reaction_recording_complete,
          ),
        ),
      );
    }
  }

  Widget _build_share_overlay(bool portrait) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: portrait
              ? MediaQuery.of(context).size.height * 0.5
              : MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withAlpha(200),
              Colors.black.withAlpha(230),
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: 40,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Center(
            child: RevealShareOptions(
              gender: baby_gender ?? 'boy',
              baby_name: event?.baby_name,
              mother_name: widget.mother_name,
              father_name: widget.father_name,
              event_url: '${widget.share_url}$event_id',
              reaction_video_path: reaction_uploaded ? reaction_video_path : null,
              reaction_video_format: reaction_video_format,
              wishlist_button_builder: widget.wishlist_button_builder,
              source_language_index: widget.source_language_index,
              boy_color: widget.boy_color,
              girl_color: widget.girl_color,
              texts: _share_texts,
              on_replay: _handle_replay,
              show_replay_button: true,
            ),
          ),
        ),
      ),
    );
  }
}
