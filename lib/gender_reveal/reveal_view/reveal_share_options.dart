import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/reveal_constants.dart';

/// Unified border radius for all share options elements
const double _k_share_border_radius = 16.0;

/// Widget displaying share options after the gender reveal animation.
/// Includes social sharing, event link copy, and wishlist button.
class RevealShareOptions extends StatefulWidget {
  /// The gender that was revealed: "boy" or "girl".
  final String gender;

  /// The baby's name (optional).
  final String? baby_name;

  /// The parents' names for the share message.
  final String mother_name;
  final String father_name;

  /// The event URL to share.
  final String event_url;

  /// The path to the recorded reaction video (if any).
  final String? reaction_video_path;

  /// The format of the reaction video ('mp4' or 'webm').
  final String reaction_video_format;

  /// Builder for the Amazon wishlist button.
  /// The registry_link parameter comes from the event's Firestore document.
  final Widget Function(
    int source_language_index,
    String? registry_link,
  ) wishlist_button_builder;

  /// The Amazon registry link from Firestore (optional).
  final String? registry_link;

  /// Current language index for translations.
  final int source_language_index;

  /// Color for boy theme.
  final Color boy_color;

  /// Color for girl theme.
  final Color girl_color;

  /// Translated text values.
  final RevealShareTexts texts;

  /// Callback when user wants to replay the reveal.
  final VoidCallback? on_replay;

  /// Whether to show the replay button.
  final bool show_replay_button;

  /// Name connector ("&" in English, "y" in Spanish).
  final String name_connector;

  const RevealShareOptions({
    super.key,
    required this.gender,
    this.baby_name,
    required this.mother_name,
    required this.father_name,
    required this.event_url,
    this.reaction_video_path,
    this.reaction_video_format = 'mp4',
    required this.wishlist_button_builder,
    this.registry_link,
    this.source_language_index = 0,
    required this.boy_color,
    required this.girl_color,
    this.texts = const RevealShareTexts(),
    this.on_replay,
    this.show_replay_button = true,
    this.name_connector = '&',
  });

  @override
  State<RevealShareOptions> createState() => _RevealShareOptionsState();
}

class _RevealShareOptionsState extends State<RevealShareOptions> with SingleTickerProviderStateMixin {
  late AnimationController _fade_controller;
  late Animation<double> _fade_animation;
  bool _link_copied = false;

  bool get _is_boy => widget.gender.toLowerCase() == 'boy';

  @override
  void initState() {
    super.initState();
    _fade_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: k_share_options_fade_duration_ms),
    );
    _fade_animation = CurvedAnimation(
      parent: _fade_controller,
      curve: Curves.easeOut,
    );

    // Start fade in after delay
    Future.delayed(
      const Duration(milliseconds: k_share_options_delay_ms),
      () {
        if (mounted) {
          _fade_controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _fade_controller.dispose();
    super.dispose();
  }

  String get _share_message {
    final gender_text = _is_boy ? widget.texts.boy : widget.texts.girl;
    final name_part = widget.baby_name != null && widget.baby_name!.isNotEmpty ? ' ${widget.baby_name}' : '';
    return "${widget.texts.share_message_prefix} $gender_text!$name_part\n\n"
        "${widget.texts.celebrate_with} ${widget.mother_name} ${widget.name_connector} ${widget.father_name}!\n\n"
        "${widget.event_url}";
  }

  void _share_to_social() {
    SharePlus.instance.share(
      ShareParams(
        text: _share_message,
        subject: widget.texts.share_subject,
      ),
    );
  }

  void _copy_event_link() {
    Clipboard.setData(ClipboardData(text: widget.event_url));
    setState(() {
      _link_copied = true;
    });

    // Reset after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _link_copied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade_animation,
      child: Container(
        constraints: const BoxConstraints(maxWidth: k_share_options_max_width),
        padding: const EdgeInsets.all(k_reveal_content_padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Share buttons row - uses same width as other elements
            Row(
              children: [
                // Share to social
                Expanded(
                  child: _build_share_button(
                    icon: Icons.share,
                    label: widget.texts.share,
                    on_pressed: _share_to_social,
                  ),
                ),
                const SizedBox(width: 12),

                // Copy link
                Expanded(
                  child: _build_share_button(
                    icon: _link_copied ? Icons.check : Icons.link,
                    label: _link_copied ? widget.texts.copied : widget.texts.copy_link,
                    on_pressed: _copy_event_link,
                    is_highlighted: _link_copied,
                  ),
                ),

                // Replay button
                if (widget.show_replay_button && widget.on_replay != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _build_share_button(
                      icon: Icons.replay,
                      label: widget.texts.replay,
                      on_pressed: widget.on_replay!,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Amazon wishlist button
            widget.wishlist_button_builder(
              widget.source_language_index,
              widget.registry_link,
            ),

            // Reaction video preview (if available)
            if (widget.reaction_video_path != null) ...[
              const SizedBox(height: 16),
              _build_reaction_preview(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _build_share_button({
    required IconData icon,
    required String label,
    required VoidCallback on_pressed,
    bool is_highlighted = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: on_pressed,
        borderRadius: BorderRadius.circular(_k_share_border_radius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            // Dark semi-transparent background for better visibility on light backgrounds
            color: is_highlighted
                ? Colors.green.withAlpha((255 * 0.3).round())
                : Colors.brown.withAlpha((255 * 0.6).round()),
            borderRadius: BorderRadius.circular(_k_share_border_radius),
            border: Border.all(
              color: is_highlighted
                  ? Colors.green.withAlpha((255 * 0.5).round())
                  : Colors.brown.withAlpha((255 * 0.3).round()),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: is_highlighted ? Colors.green : Colors.white,
                size: 24,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: is_highlighted ? Colors.green : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _build_reaction_preview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.brown.withAlpha((255 * 0.6).round()),
        borderRadius: BorderRadius.circular(_k_share_border_radius),
        border: Border.all(
          color: Colors.brown.withAlpha((255 * 0.3).round()),
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
        children: [
          // Video thumbnail placeholder
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((255 * 0.15).round()),
              borderRadius: BorderRadius.circular(_k_share_border_radius / 2),
              border: Border.all(
                color: Colors.white.withAlpha((255 * 0.3).round()),
              ),
            ),
            child: const Icon(
              Icons.videocam,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Info text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.texts.your_reaction,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.texts.reaction_saved,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Share reaction button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((255 * 0.15).round()),
              borderRadius: BorderRadius.circular(_k_share_border_radius / 2),
            ),
            child: IconButton(
              onPressed: () {
                if (widget.reaction_video_path != null) {
                  // Use the format passed from the recorder
                  final extension = widget.reaction_video_format;
                  final mime_type = extension == 'webm' ? 'video/webm' : 'video/mp4';

                  // Generate filename: baby_name + date + extension
                  final safe_name = widget.baby_name != null && widget.baby_name!.isNotEmpty
                      ? widget.baby_name!.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase()
                      : 'baby';
                  final date = DateTime.now();
                  final date_str =
                      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
                  final file_name = '${safe_name}_reveal_$date_str.$extension';

                  final reaction_file = XFile(
                    widget.reaction_video_path!,
                    mimeType: mime_type,
                    name: file_name,
                  );

                  SharePlus.instance.share(
                    ShareParams(
                      files: [reaction_file],
                      subject: widget.texts.share_subject,
                      text: _share_message,
                    ),
                  );
                }
              },
              icon: const Icon(
                Icons.share,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Translation texts for the reveal share options.
class RevealShareTexts {
  final String share_the_joy;
  final String share;
  final String copy_link;
  final String copied;
  final String replay;
  final String help_parents_prepare;
  final String your_reaction;
  final String reaction_saved;
  final String share_message_prefix;
  final String celebrate_with;
  final String share_subject;
  final String boy;
  final String girl;
  final String reaction_recorded;

  const RevealShareTexts({
    this.share_the_joy = 'Share the Joy',
    this.share = 'Share',
    this.copy_link = 'Copy Link',
    this.copied = 'Copied!',
    this.replay = 'Replay',
    this.help_parents_prepare = 'Help the parents prepare for their little one!',
    this.your_reaction = 'Your Reaction',
    this.reaction_saved = 'Saved to your account',
    this.share_message_prefix = "It's a",
    this.celebrate_with = 'Celebrate with',
    this.share_subject = 'Gender Reveal Celebration!',
    this.boy = 'Boy',
    this.girl = 'Girl',
    this.reaction_recorded = 'Reaction Recorded',
  });

  factory RevealShareTexts.fromTextList(List<String>? text) {
    if (text == null || text.length < 13) {
      return const RevealShareTexts();
    }
    return RevealShareTexts(
      share_the_joy: text[0],
      share: text[1],
      copy_link: text[2],
      copied: text[3],
      replay: text[4],
      help_parents_prepare: text[5],
      your_reaction: text[6],
      reaction_saved: text[7],
      share_message_prefix: text[8],
      celebrate_with: text[9],
      share_subject: text[10],
      boy: text[11],
      girl: text[12],
      // Index 13: boy_text, 14: girl_text, 15: login_prompt_text
      // Index 16: reveal_now_text, 17: baby_on_the_way_text, 18: camera_permission_message
      // Index 19: reaction_recorded
      reaction_recorded: text.length > 19 ? text[19] : 'Reaction Recorded',
    );
  }
}
