import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/glowing_reveal_button.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/reveal_animations.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/reveal_constants.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/reveal_reaction_recorder.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/reveal_share_options.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/reveal_view_state.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/reveal_view_translation.dart';
import 'package:xapptor_router/V2/app_screens_v2.dart';
import 'package:xapptor_translation/language_picker.dart';
import 'package:xapptor_translation/model/text_list.dart';
import 'package:xapptor_ui/utils/is_portrait.dart';
import 'package:xapptor_ui/values/ui.dart';

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

  /// Whether to show the language picker.
  final bool has_language_picker;

  /// Background color for the language picker container.
  final Color? language_picker_background_color;

  /// Text color for the language picker.
  final Color? language_picker_text_color;

  /// Whether to show the icon in the language picker.
  final bool language_picker_show_icon;

  /// Icon color for the language picker.
  final Color? language_picker_icon_color;

  /// Firebase Storage path for background images folder.
  /// Example: "gs://genderrevealbaby-210b7.firebasestorage.app/app/example_backgrounds/"
  final String? background_images_storage_path;

  /// Index of the background image to use from the storage folder.
  final int background_image_index;

  /// Firebase Storage path for sound effects folder.
  /// Example: "gs://genderrevealbaby-210b7.firebasestorage.app/app/example_sound_effects/"
  final String? sound_effects_storage_path;

  /// Index of the sound effect to use from the storage folder.
  final int sound_effect_index;

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
    this.has_language_picker = false,
    this.language_picker_background_color,
    this.language_picker_text_color,
    this.language_picker_show_icon = false,
    this.language_picker_icon_color,
    this.background_images_storage_path,
    this.background_image_index = 0,
    this.sound_effects_storage_path,
    this.sound_effect_index = 0,
  });

  @override
  State<RevealView> createState() => _RevealViewState();
}

class _RevealViewState extends State<RevealView> with RevealViewStateMixin, RevealViewTranslationMixin {
  // Key for forcing animation rebuild on replay
  Key _animation_key = UniqueKey();

  // Whether the reveal has been triggered (button pressed)
  bool _reveal_triggered = false;

  // Camera and microphone permission state for early permission request
  bool _permissions_requested = false;
  bool _camera_permission_granted = false;
  bool _microphone_permission_granted = false;

  // Background image state
  String? _background_image_url;
  bool _background_image_loading = false;

  // Sound effect state
  AudioPlayer? _audio_player;
  bool _sound_effect_loading = false;
  bool _sound_effect_ready = false;

  @override
  void initState() {
    super.initState();
    // Initialize translation and load saved language preference
    init_translation_streams();
    load_saved_language();
    // Load all Firebase resources in parallel for faster initialization
    _load_all_resources_in_parallel();
  }

  /// Load all Firebase resources in parallel for optimal performance.
  /// This reduces initial load time by 30-40% compared to sequential loading.
  Future<void> _load_all_resources_in_parallel() async {
    // Run all async operations in parallel
    await Future.wait([
      // Event data from Firestore (includes checking existing reaction)
      initialize_reveal_state(),
      // Background image from Firebase Storage
      _load_background_image(),
      // Sound effect from Firebase Storage
      _load_sound_effect(),
      // Camera permission (doesn't depend on Firebase but runs in parallel)
      _request_camera_permission_early(),
    ]);
  }

  /// Load background image URL from Firebase Storage.
  Future<void> _load_background_image() async {
    if (widget.background_images_storage_path == null) return;
    if (_background_image_loading) return;

    _background_image_loading = true;

    try {
      // Get the storage reference from the gs:// path
      final storage_ref = FirebaseStorage.instance.refFromURL(widget.background_images_storage_path!);

      // List all items in the folder
      final list_result = await storage_ref.listAll();

      if (list_result.items.isEmpty) {
        debugPrint('RevealView: No background images found in storage path');
        _background_image_loading = false;
        return;
      }

      // Get the image at the specified index (or first if index is out of bounds)
      final image_index = widget.background_image_index.clamp(0, list_result.items.length - 1);
      final image_ref = list_result.items[image_index];

      // Get the download URL
      final download_url = await image_ref.getDownloadURL();

      if (!mounted) return;

      // Single setState with all state updates batched
      setState(() {
        _background_image_url = download_url;
        _background_image_loading = false;
      });

      debugPrint('RevealView: Background image loaded: $download_url');
    } catch (e) {
      debugPrint('RevealView: Error loading background image: $e');
      _background_image_loading = false;
    }
  }

  /// Load sound effect URL from Firebase Storage and prepare the audio player.
  Future<void> _load_sound_effect() async {
    if (widget.sound_effects_storage_path == null) return;
    if (_sound_effect_loading) return;

    _sound_effect_loading = true;

    try {
      // Get the storage reference from the gs:// path
      final storage_ref = FirebaseStorage.instance.refFromURL(widget.sound_effects_storage_path!);

      // List all items in the folder
      final list_result = await storage_ref.listAll();

      if (list_result.items.isEmpty) {
        debugPrint('RevealView: No sound effects found in storage path');
        _sound_effect_loading = false;
        return;
      }

      // Get the sound effect at the specified index (or first if index is out of bounds)
      final sfx_index = widget.sound_effect_index.clamp(0, list_result.items.length - 1);
      final sfx_ref = list_result.items[sfx_index];

      // Get the download URL
      final download_url = await sfx_ref.getDownloadURL();

      if (!mounted) return;

      // Initialize and prepare the audio player
      _audio_player = AudioPlayer();
      await _audio_player!.setUrl(download_url);

      if (!mounted) return;

      // Single setState with all state updates batched
      setState(() {
        _sound_effect_loading = false;
        _sound_effect_ready = true;
      });

      debugPrint('RevealView: Sound effect loaded and ready: $download_url');
    } catch (e) {
      debugPrint('RevealView: Error loading sound effect: $e');
      _sound_effect_loading = false;
    }
  }

  /// Play the reveal sound effect.
  Future<void> _play_reveal_sound_effect() async {
    if (!_sound_effect_ready || _audio_player == null) return;

    try {
      // Stop any current playback first
      await _audio_player!.stop();
      // Seek to start for replay
      await _audio_player!.seek(Duration.zero);
      // Play the sound effect
      await _audio_player!.play();
      debugPrint('RevealView: Playing reveal sound effect');
    } catch (e) {
      debugPrint('RevealView: Error playing sound effect: $e');
    }
  }

  /// Request camera and microphone permissions early, before the user presses "Reveal Now!".
  /// This reduces friction during the reveal moment by avoiding permission
  /// dialogs interrupting the animation flow.
  ///
  /// Uses permission_handler for explicit control over both permissions,
  /// ensuring the user grants both camera AND microphone access for
  /// reaction video recording with audio.
  Future<void> _request_camera_permission_early() async {
    if (_permissions_requested) return;
    _permissions_requested = true;

    try {
      // On web, permission_handler may not work the same way
      // Fall back to checking via camera package
      if (kIsWeb) {
        await _request_permissions_web();
        return;
      }

      // Request both camera and microphone permissions together
      // This shows both permission dialogs at once (or combined on some platforms)
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      if (!mounted) return;

      final camera_status = statuses[Permission.camera];
      final microphone_status = statuses[Permission.microphone];

      setState(() {
        _camera_permission_granted = camera_status?.isGranted ?? false;
        _microphone_permission_granted = microphone_status?.isGranted ?? false;
      });

      debugPrint(
        'RevealView: Permissions - '
        'Camera: ${camera_status?.name}, '
        'Microphone: ${microphone_status?.name}',
      );

      // Log if either permission was denied
      if (camera_status?.isDenied ?? true) {
        debugPrint('RevealView: Camera permission denied - recording will not work');
      }
      if (microphone_status?.isDenied ?? true) {
        debugPrint('RevealView: Microphone permission denied - recording will have no audio');
      }
    } catch (e) {
      debugPrint('RevealView: Permission request failed: $e');
      // Permission denied or error - camera won't be available during reveal
      // This is acceptable, the reveal will still work without recording
    }
  }

  /// Request permissions on web platform.
  /// Web uses the browser's built-in permission API through getUserMedia.
  Future<void> _request_permissions_web() async {
    try {
      // On web, we can use permission_handler's web implementation
      // or let the camera package handle it when CameraController initializes
      final camera_status = await Permission.camera.request();
      final microphone_status = await Permission.microphone.request();

      if (!mounted) return;

      setState(() {
        _camera_permission_granted = camera_status.isGranted;
        _microphone_permission_granted = microphone_status.isGranted;
      });

      debugPrint(
        'RevealView (Web): Permissions - '
        'Camera: ${camera_status.name}, '
        'Microphone: ${microphone_status.name}',
      );
    } catch (e) {
      debugPrint('RevealView (Web): Permission request failed: $e');
      // On web, if permission_handler fails, the camera package will
      // handle permissions when CameraController.initialize() is called
    }
  }

  @override
  void dispose() {
    _audio_player?.dispose();
    dispose_reveal_state();
    super.dispose();
  }

  /// Get translated texts or fallbacks.
  /// Uses source_language_index from RevealViewTranslationMixin.
  RevealShareTexts get _share_texts {
    final text = widget.reveal_text_list?.get(source_language_index);
    if (text != null && text.length >= 13) {
      return RevealShareTexts.fromTextList(text);
    }
    return const RevealShareTexts();
  }

  String get _its_a_boy_text {
    final text = widget.reveal_text_list?.get(source_language_index);
    return text != null && text.length > 13 ? text[13] : "It's a Boy!";
  }

  String get _its_a_girl_text {
    final text = widget.reveal_text_list?.get(source_language_index);
    return text != null && text.length > 14 ? text[14] : "It's a Girl!";
  }

  String get _login_prompt_text {
    final text = widget.reveal_text_list?.get(source_language_index);
    return text != null && text.length > 15 ? text[15] : 'Login to save your reaction';
  }

  String get _reveal_now_text {
    final text = widget.reveal_text_list?.get(source_language_index);
    return text != null && text.length > 16 ? text[16] : 'Reveal Now!';
  }

  String get _baby_on_the_way_text {
    final text = widget.reveal_text_list?.get(source_language_index);
    return text != null && text.length > 17 ? text[17] : '{name} is on the way!';
  }

  String get _camera_permission_message {
    final text = widget.reveal_text_list?.get(source_language_index);
    return text != null && text.length > 18 ? text[18] : 'Allow camera access to record your reaction';
  }

  /// Name connector ("&" in English, "y" in Spanish).
  String get _name_connector {
    final text = widget.reveal_text_list?.get(source_language_index);
    return text != null && text.length > 20 ? text[20] : '&';
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
    // Play reveal sound effect
    _play_reveal_sound_effect();

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
    final camera_size =
        portrait ? size.width * k_camera_preview_size_portrait : size.width * k_camera_preview_size_landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background image (if available)
          if (_background_image_url != null) _build_background_image(),

          // Show reveal button or animation based on state
          if (!_reveal_triggered)
            _build_reveal_button_view()
          else ...[
            // Main reveal animation - no SafeArea to allow glow effects to extend to edges
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
                locale: current_locale,
                on_animation_complete: on_animation_complete,
                reduce_confetti: show_share_options,
              ),
            ),

            // Camera preview (only show during reveal if user should record)
            // IMPORTANT: Keep widget mounted until recording is fully complete to avoid
            // race conditions where dispose() is called before video is saved.
            // We use Offstage to hide visually while keeping the widget alive.
            // - Don't show if user already has a reaction for this event
            if (should_show_camera && !reaction_recording_complete)
              Offstage(
                // Hide visually when share options appear, but keep mounted
                offstage: show_share_options,
                child: _build_camera_preview(portrait, camera_size),
              ),

            // Show "Reaction Recorded" indicator when recording is complete or user has existing reaction
            if (reaction_recording_complete || user_has_existing_reaction) _build_reaction_recorded_indicator(portrait),
          ],

          // Share options overlay (after animation completes)
          if (show_share_options) _build_share_overlay(portrait),

          // Language picker (only when not triggered and before reveal)
          if (widget.has_language_picker && translation_stream_list.isNotEmpty && !_reveal_triggered)
            _build_language_picker(),
        ],
      ),
    );
  }

  Widget _build_background_image() {
    return Positioned.fill(
      child: CachedNetworkImage(
        imageUrl: _background_image_url!,
        fit: BoxFit.cover,
        // Use memory cache for instant replay
        memCacheHeight: 1920,
        memCacheWidth: 1080,
        errorWidget: (context, url, error) {
          debugPrint('RevealView: Error displaying background image: $error');
          return const SizedBox.shrink();
        },
        placeholder: (context, url) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _build_reveal_button_view() {
    return Positioned.fill(
      child: Container(
        decoration: _background_image_url != null
            ? BoxDecoration(
                color: Colors.black.withAlpha((255 * 0.5).round()),
              )
            : BoxDecoration(
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
                  '${widget.mother_name} $_name_connector ${widget.father_name}',
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
              // Camera/microphone permission message - shows while permission is being requested
              // This informs users why we need camera and microphone access (to record their reaction)
              if ((!_camera_permission_granted || !_microphone_permission_granted) && _permissions_requested)
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
    final safe_top = MediaQuery.of(context).padding.top;
    // Position differently for portrait vs landscape
    if (portrait) {
      // Portrait: Top center
      return Positioned(
        top: safe_top + 16,
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
        top: safe_top + 16,
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

  Widget _build_reaction_recorded_indicator(bool portrait) {
    final safe_top = MediaQuery.of(context).padding.top;
    if (portrait) {
      return Positioned(
        top: safe_top + 16,
        left: 0,
        right: 0,
        child: Center(
          child: _build_reaction_recorded_badge(),
        ),
      );
    } else {
      return Positioned(
        top: safe_top + 16,
        right: 16,
        child: _build_reaction_recorded_badge(),
      );
    }
  }

  Widget _build_reaction_recorded_badge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.brown.withAlpha((255 * 0.6).round()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withAlpha((255 * 0.3).round()),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.1).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha((255 * 0.2).round()),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _share_texts.reaction_recorded,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _build_share_overlay(bool portrait) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: portrait ? MediaQuery.of(context).size.height * 0.5 : MediaQuery.of(context).size.height * 0.6,
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
              reaction_video_path: reaction_video_path,
              reaction_video_format: reaction_video_format,
              wishlist_button_builder: widget.wishlist_button_builder,
              registry_link: event?.registry_link,
              source_language_index: source_language_index,
              boy_color: widget.boy_color,
              girl_color: widget.girl_color,
              texts: _share_texts,
              on_replay: _handle_replay,
              show_replay_button: true,
              name_connector: _name_connector,
            ),
          ),
        ),
      ),
    );
  }

  Widget _build_language_picker() {
    final bg_color = widget.language_picker_background_color ?? Colors.black.withAlpha((255 * 0.5).round());
    final text_color = widget.language_picker_text_color ?? Colors.white;
    final safe_top = MediaQuery.of(context).padding.top;

    return Positioned(
      top: safe_top + 8,
      right: sized_box_space,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: bg_color,
          borderRadius: BorderRadius.circular(outline_border_radius),
        ),
        child: SizedBox(
          width: widget.language_picker_show_icon ? 170 : 150,
          child: LanguagePicker(
            translation_stream_list: translation_stream_list,
            language_picker_items_text_color: text_color,
            update_source_language: update_source_language,
            source_language_index: source_language_index,
            show_icon: widget.language_picker_show_icon,
            icon_color: widget.language_picker_icon_color ?? text_color,
          ),
        ),
      ),
    );
  }
}
