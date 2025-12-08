import 'package:flutter/material.dart';
import 'package:xapptor_ui/values/ui.dart';

/// A magical glowing button for triggering the gender reveal.
/// Features a pulsing dual-color gradient animation using both boy and girl colors.
class GlowingRevealButton extends StatefulWidget {
  /// The button label text.
  final String label;

  /// The boy color for the gradient.
  final Color boy_color;

  /// The girl color for the gradient.
  final Color girl_color;

  /// Callback when the button is pressed.
  final VoidCallback on_pressed;

  const GlowingRevealButton({
    super.key,
    required this.label,
    required this.boy_color,
    required this.girl_color,
    required this.on_pressed,
  });

  @override
  State<GlowingRevealButton> createState() => _GlowingRevealButtonState();
}

class _GlowingRevealButtonState extends State<GlowingRevealButton>
    with TickerProviderStateMixin {
  late AnimationController _glow_controller;
  late Animation<double> _glow_animation;
  late AnimationController _shimmer_controller;
  late Animation<double> _shimmer_animation;

  @override
  void initState() {
    super.initState();

    // Glow pulsing animation (breathing effect)
    _glow_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glow_animation = CurvedAnimation(
      parent: _glow_controller,
      curve: Curves.easeInOut,
    );

    // Shimmer animation for gradient movement
    _shimmer_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _shimmer_animation = CurvedAnimation(
      parent: _shimmer_controller,
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    _glow_controller.dispose();
    _shimmer_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_glow_animation, _shimmer_animation]),
      builder: (context, child) {
        final glow = _glow_animation.value;
        final shimmer = _shimmer_animation.value;

        // Calculate dynamic gradient stops based on shimmer
        final gradient_offset = shimmer * 0.5;

        return Transform.scale(
          scale: 1.0 + glow * 0.05,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(outline_border_radius),
              gradient: LinearGradient(
                colors: [
                  widget.boy_color.withAlpha((255 * 0.9).round()),
                  widget.girl_color.withAlpha((255 * 0.9).round()),
                  widget.boy_color.withAlpha((255 * 0.9).round()),
                ],
                stops: [
                  0.0 + gradient_offset,
                  0.5,
                  1.0 - gradient_offset * 0.5,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                // Boy color glow
                BoxShadow(
                  color: widget.boy_color.withAlpha((255 * 0.4 * glow).round()),
                  blurRadius: 20 + (15 * glow),
                  spreadRadius: 2 + (3 * glow),
                  offset: const Offset(-8, 0),
                ),
                // Girl color glow
                BoxShadow(
                  color: widget.girl_color.withAlpha((255 * 0.4 * glow).round()),
                  blurRadius: 20 + (15 * glow),
                  spreadRadius: 2 + (3 * glow),
                  offset: const Offset(8, 0),
                ),
                // Combined center glow
                BoxShadow(
                  color: Color.lerp(
                    widget.boy_color,
                    widget.girl_color,
                    shimmer,
                  )!
                      .withAlpha((255 * 0.35 * glow).round()),
                  blurRadius: 30 + (20 * glow),
                  spreadRadius: 4 + (6 * glow),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(outline_border_radius),
                onTap: () {
                  // TODO: Add sound effect here
                  // This is where you can trigger a VFX/reveal sound.
                  // Example: audio_player.play('reveal_sound.mp3');
                  widget.on_pressed();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 48,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Sparkle icon
                      Icon(
                        Icons.auto_awesome,
                        color: theme.colorScheme.onPrimary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.label,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: theme.colorScheme.onPrimary,
                          shadows: [
                            Shadow(
                              color: Colors.black.withAlpha((255 * 0.3).round()),
                              blurRadius: 4,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Sparkle icon
                      Icon(
                        Icons.auto_awesome,
                        color: theme.colorScheme.onPrimary,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
