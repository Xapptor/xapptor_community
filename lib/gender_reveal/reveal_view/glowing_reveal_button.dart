import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:xapptor_ui/values/ui.dart';

/// Constants for reveal button animations.
const int k_reveal_glow_duration_ms = 1600;
const int k_reveal_shake_duration_ms = 450;
const int k_reveal_first_shake_delay_seconds = 3;
const int k_reveal_min_shake_interval_seconds = 4;
const int k_reveal_max_shake_interval_seconds = 8;
const double k_reveal_shake_delta_x = 4.0;
const double k_reveal_shake_angle = 0.04;
const double k_reveal_shake_frequency = 6.0;

/// A magical glowing button for triggering the gender reveal.
/// Design inspired by ExternalLinkButton with hover animations, gradient,
/// and shadows. Includes shake animation similar to the celebration icon.
class GlowingRevealButton extends StatefulWidget {
  /// The button label text.
  final String label;

  /// The boy color for the gradient.
  final Color boy_color;

  /// The girl color for the gradient.
  final Color girl_color;

  /// Callback when the button is pressed.
  final VoidCallback on_pressed;

  /// Border radius of the button.
  final double border_radius;

  /// Duration of hover animation.
  final Duration animation_duration;

  const GlowingRevealButton({
    super.key,
    required this.label,
    required this.boy_color,
    required this.girl_color,
    required this.on_pressed,
    this.border_radius = 30,
    this.animation_duration = const Duration(milliseconds: 200),
  });

  @override
  State<GlowingRevealButton> createState() => _GlowingRevealButtonState();
}

class _GlowingRevealButtonState extends State<GlowingRevealButton>
    with TickerProviderStateMixin {
  // Hover animation controller (similar to ExternalLinkButton)
  late AnimationController _hover_controller;
  late Animation<double> _scale_animation;
  late Animation<double> _elevation_animation;
  late Animation<double> _glow_animation;
  late Animation<double> _icon_rotation_animation;

  // Continuous glow pulsing animation
  late AnimationController _pulse_controller;
  late Animation<double> _pulse_animation;

  // Shake animation (similar to celebration icon)
  late AnimationController _shake_controller;
  late Animation<double> _shake_animation;
  Timer? _shake_timer;

  bool _is_pressed = false;

  @override
  void initState() {
    super.initState();

    // Hover animation controller
    _hover_controller = AnimationController(
      duration: widget.animation_duration,
      vsync: this,
    );

    _scale_animation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hover_controller, curve: Curves.easeOutCubic),
    );

    _elevation_animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hover_controller, curve: Curves.easeOutCubic),
    );

    _glow_animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hover_controller, curve: Curves.easeOutCubic),
    );

    _icon_rotation_animation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _hover_controller, curve: Curves.easeInOutCubic),
    );

    // Continuous glow pulsing animation
    _pulse_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: k_reveal_glow_duration_ms),
    )..repeat(reverse: true);

    _pulse_animation = CurvedAnimation(
      parent: _pulse_controller,
      curve: Curves.easeInOut,
    );

    // Shake animation controller
    _shake_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: k_reveal_shake_duration_ms),
    );

    _shake_animation = CurvedAnimation(
      parent: _shake_controller,
      curve: Curves.easeOut,
    );

    _shake_controller.addStatusListener(_on_shake_status_changed);
    _schedule_next_shake(is_first_shake: true);
  }

  @override
  void dispose() {
    _shake_timer?.cancel();
    _hover_controller.dispose();
    _pulse_controller.dispose();
    _shake_controller.removeStatusListener(_on_shake_status_changed);
    _shake_controller.dispose();
    super.dispose();
  }

  void _on_shake_status_changed(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.completed) {
      _shake_controller.reset();
      _schedule_next_shake(is_first_shake: false);
    }
  }

  void _schedule_next_shake({bool is_first_shake = false}) {
    _shake_timer?.cancel();

    final int seconds;
    if (is_first_shake) {
      seconds = k_reveal_first_shake_delay_seconds;
    } else {
      const range =
          k_reveal_max_shake_interval_seconds - k_reveal_min_shake_interval_seconds;
      seconds =
          k_reveal_min_shake_interval_seconds + math.Random().nextInt(range + 1);
    }

    _shake_timer = Timer(Duration(seconds: seconds), () {
      if (!mounted) return;
      _shake_controller.forward();
    });
  }

  void _on_hover(bool hovering) {
    if (hovering) {
      _hover_controller.forward();
    } else {
      _hover_controller.reverse();
    }
  }

  void _on_tap_down(TapDownDetails details) {
    _on_hover(false);
    setState(() => _is_pressed = true);
  }

  void _on_tap_up(TapUpDetails details) {
    _on_hover(true);
    setState(() => _is_pressed = false);
  }

  void _on_tap_cancel() {
    _on_hover(true);
    setState(() => _is_pressed = false);
  }

  void _on_tap() {
    // TODO: Add sound effect here
    // This is where you can trigger a VFX/reveal sound.
    // Example: audio_player.play('reveal_sound.mp3');
    widget.on_pressed();
  }

  @override
  Widget build(BuildContext context) {
    // Blend boy and girl colors for gradient
    final gradient_start = widget.boy_color;
    final gradient_end = widget.girl_color;
    final border_color = Color.lerp(widget.boy_color, widget.girl_color, 0.5)!;
    final shadow_color = Color.lerp(widget.boy_color, widget.girl_color, 0.5)!;

    return MouseRegion(
      onEnter: (_) => _on_hover(true),
      onExit: (_) => _on_hover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: _on_tap_down,
        onTapUp: _on_tap_up,
        onTapCancel: _on_tap_cancel,
        onTap: _on_tap,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _hover_controller,
            _pulse_animation,
            _shake_animation,
          ]),
          builder: (context, child) {
            final press_scale = _is_pressed ? 0.97 : 1.0;
            final pulse = _pulse_animation.value;
            final glow = _glow_animation.value;

            // Shake transform
            final shake_t = _shake_animation.value;
            final shake_dx =
                math.sin(shake_t * math.pi * k_reveal_shake_frequency) *
                    k_reveal_shake_delta_x;
            final shake_angle =
                math.sin(shake_t * math.pi * k_reveal_shake_frequency) *
                    k_reveal_shake_angle;

            return Transform.translate(
              offset: Offset(shake_dx, 0),
              child: Transform.rotate(
                angle: shake_angle,
                child: Transform.scale(
                  scale: _scale_animation.value * press_scale,
                  child: Transform.translate(
                    offset: Offset(0, -2 * _elevation_animation.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.border_radius),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.lerp(
                              gradient_start.withAlpha((255 * 0.7).round()),
                              gradient_start,
                              (glow * 0.5) + (pulse * 0.3),
                            )!,
                            Color.lerp(
                              gradient_end.withAlpha((255 * 0.7).round()),
                              gradient_end,
                              (glow * 0.5) + (pulse * 0.3),
                            )!,
                          ],
                        ),
                        border: Border.all(
                          color: Color.lerp(
                            border_color.withAlpha((255 * 0.5).round()),
                            border_color,
                            glow + (pulse * 0.3),
                          )!,
                          width: 1 + (glow * 0.5),
                        ),
                        boxShadow: [
                          // Base shadow
                          BoxShadow(
                            color: Color.lerp(
                              shadow_color.withAlpha((255 * 0.2).round()),
                              shadow_color.withAlpha((255 * 0.4).round()),
                              glow,
                            )!,
                            blurRadius: 8 + (12 * _elevation_animation.value),
                            offset: Offset(
                              0,
                              2 + (4 * _elevation_animation.value),
                            ),
                          ),
                          // Boy color glow (left side)
                          BoxShadow(
                            color: widget.boy_color.withAlpha(
                              (255 * (0.15 + (0.25 * pulse) + (0.2 * glow))).round(),
                            ),
                            blurRadius: 16 + (12 * pulse) + (8 * glow),
                            spreadRadius: 1 + (2 * pulse),
                            offset: const Offset(-4, 0),
                          ),
                          // Girl color glow (right side)
                          BoxShadow(
                            color: widget.girl_color.withAlpha(
                              (255 * (0.15 + (0.25 * pulse) + (0.2 * glow))).round(),
                            ),
                            blurRadius: 16 + (12 * pulse) + (8 * glow),
                            spreadRadius: 1 + (2 * pulse),
                            offset: const Offset(4, 0),
                          ),
                          // Center glow on hover
                          if (glow > 0)
                            BoxShadow(
                              color: shadow_color.withAlpha(
                                (255 * 0.3 * glow).round(),
                              ),
                              blurRadius: 20 * glow,
                              spreadRadius: 2 * glow,
                            ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Left icon with rotation on hover
                          Transform.rotate(
                            angle: _icon_rotation_animation.value * math.pi,
                            child: Icon(
                              Icons.auto_awesome,
                              size: 22,
                              color: Color.lerp(
                                Colors.white.withAlpha((255 * 0.9).round()),
                                Colors.white,
                                glow,
                              ),
                            ),
                          ),
                          const SizedBox(width: sized_box_space),
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5 + (glow * 0.3),
                              color: Color.lerp(
                                Colors.white.withAlpha((255 * 0.95).round()),
                                Colors.white,
                                glow,
                              ),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withAlpha((255 * 0.3).round()),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: sized_box_space),
                          // Right icon with rotation on hover (opposite direction)
                          Transform.rotate(
                            angle: -_icon_rotation_animation.value * math.pi,
                            child: Icon(
                              Icons.auto_awesome,
                              size: 22,
                              color: Color.lerp(
                                Colors.white.withAlpha((255 * 0.9).round()),
                                Colors.white,
                                glow,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
