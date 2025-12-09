import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/glowing_reveal_button.dart';
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
  /// The registry_link parameter comes from the event's Firestore document.
  final Widget Function(int source_language_index, String? registry_link) wishlist_button_builder;

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

  // Whether the reveal has been triggered (button pressed)
  bool _reveal_triggered = false;

  // Camera permission state for early permission request
  bool _camera_permission_requested = false;
  bool _camera_permission_granted = false;

  @override
  void initState() {
    super.initState();
    initialize_reveal_state();
    // Request camera permission early to reduce friction during reveal
    _request_camera_permission_early();
  }

  /// Request camera permission early, before the user presses "Reveal Now!".
  /// This reduces friction during the reveal moment by avoiding permission
  /// dialogs interrupting the animation flow.
  Future<void> _request_camera_permission_early() async {
    if (_camera_permission_requested) return;
    _camera_permission_requested = true;

    try {
      // Simply calling availableCameras triggers the permission request
      final cameras = await availableCameras();
      if (!mounted) return;

      setState(() {
        _camera_permission_granted = cameras.isNotEmpty;
      });

      if (cameras.isNotEmpty) {
        debugPrint('RevealView: Camera permission granted early');
      }
    } catch (e) {
      debugPrint('RevealView: Camera permission request failed: $e');
      // Permission denied or error - camera won't be available during reveal
      // This is acceptable, the reveal will still work without recording
    }
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

  String get _reveal_now_text {
    final text = widget.reveal_text_list?.get(widget.source_language_index);
    return text != null && text.length > 16 ? text[16] : 'Reveal Now!';
  }

  String get _baby_on_the_way_text {
    final text = widget.reveal_text_list?.get(widget.source_language_index);
    return text != null && text.length > 17 ? text[17] : '{name} is on the way!';
  }

  String get _camera_permission_message {
    final text = widget.reveal_text_list?.get(widget.source_language_index);
    return text != null && text.length > 18
        ? text[18]
        : 'Allow camera access to record your reaction';
  }

  void _handle_replay() {
    setState(() {
      _reveal_triggered = false;
      animation_complete = false;
      show_share_options = false;
      _animation_key = UniqueKey();
    });
  }

  void _handle_reveal_button_pressed() {
    // TODO: Add sound effect here
    // This is where you can trigger a VFX/reveal sound.
    // Example: audio_player.play('reveal_sound.mp3');
    setState(() {
      _reveal_triggered = true;
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
            // Show reveal button or animation based on state
            if (!_reveal_triggered)
              _build_reveal_button_view()
            else ...[
              // Main reveal animation
              Positioned.fill(
                child: RevealAnimations(
                  key: _animation_key,
                  gender: baby_gender ?? 'boy',
                  baby_name: event?.baby_name,
                  baby_delivery_date: event?.baby_delivery_date,
                  boy_color: widget.boy_color,
                  girl_color: widget.girl_color,
                  boy_text: _its_a_boy_text,
                  girl_text: _its_a_girl_text,
                  baby_on_the_way_text: _baby_on_the_way_text,
                  on_animation_complete: on_animation_complete,
                ),
              ),

              // Camera preview (only show during/after reveal)
              _build_camera_preview(portrait, camera_size),
            ],

            // Share options overlay (after animation completes)
            if (show_share_options) _build_share_overlay(portrait),
          ],
        ),
      ),
    );
  }

  Widget _build_reveal_button_view() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.grey.shade900,
              Colors.black,
            ],
            radius: 1.2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Teaser text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  '${widget.mother_name} & ${widget.father_name}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withAlpha((255 * 0.9).round()),
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              // Reveal button
              GlowingRevealButton(
                label: _reveal_now_text,
                boy_color: widget.boy_color,
                girl_color: widget.girl_color,
                on_pressed: _handle_reveal_button_pressed,
              ),
              const SizedBox(height: 32),
              // Camera permission message - shows while permission is being requested
              // This informs users why we need camera access (to record their reaction)
              if (!_camera_permission_granted && _camera_permission_requested)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_outlined,
                        size: 18,
                        color: Colors.white.withAlpha((255 * 0.5).round()),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _camera_permission_message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withAlpha((255 * 0.5).round()),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Hint sparkle emoji when permission is granted or not needed
                Text(
                  '✨',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white.withAlpha((255 * 0.6).round()),
                  ),
                ),
            ],
          ),
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
              registry_link: event?.registry_link,
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
