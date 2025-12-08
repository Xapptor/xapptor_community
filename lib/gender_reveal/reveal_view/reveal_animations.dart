import 'dart:async';
import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/reveal_constants.dart';

/// Widget that displays the gender reveal celebration animations.
/// Includes confetti explosion and animated text reveal.
class RevealAnimations extends StatefulWidget {
  /// The gender to reveal: "boy" or "girl".
  final String gender;

  /// The baby's name to display (optional).
  final String? baby_name;

  /// Color for boy reveal (blue shades).
  final Color boy_color;

  /// Color for girl reveal (purple/pink shades).
  final Color girl_color;

  /// Callback when the animation sequence completes.
  final VoidCallback? on_animation_complete;

  /// Text to display for "It's a Boy!".
  final String boy_text;

  /// Text to display for "It's a Girl!".
  final String girl_text;

  const RevealAnimations({
    super.key,
    required this.gender,
    this.baby_name,
    required this.boy_color,
    required this.girl_color,
    this.on_animation_complete,
    this.boy_text = "It's a Boy!",
    this.girl_text = "It's a Girl!",
  });

  @override
  State<RevealAnimations> createState() => _RevealAnimationsState();
}

class _RevealAnimationsState extends State<RevealAnimations> with TickerProviderStateMixin {
  // Confetti controllers - using multiple for varied effects
  late ConfettiController _center_confetti_controller;
  late ConfettiController _left_confetti_controller;
  late ConfettiController _right_confetti_controller;

  // Animation controllers
  late AnimationController _pulse_controller;
  late AnimationController _text_scale_controller;
  late AnimationController _name_fade_controller;

  // Animations
  late Animation<double> _pulse_animation;
  late Animation<double> _text_scale_animation;
  late Animation<double> _name_fade_animation;

  // State
  bool _show_gender_text = false;
  bool _show_baby_name = false;
  Timer? _gender_reveal_timer;
  Timer? _name_reveal_timer;
  Timer? _confetti_stop_timer;
  Timer? _animation_complete_timer;

  bool get _is_boy => widget.gender.toLowerCase() == 'boy';
  Color get _reveal_color => _is_boy ? widget.boy_color : widget.girl_color;
  String get _reveal_text => _is_boy ? widget.boy_text : widget.girl_text;

  @override
  void initState() {
    super.initState();
    _initialize_controllers();
    _start_animation_sequence();
  }

  void _initialize_controllers() {
    // Confetti controllers with duration for memory management
    _center_confetti_controller = ConfettiController(
      duration: const Duration(seconds: k_confetti_emission_duration_seconds),
    );
    _left_confetti_controller = ConfettiController(
      duration: const Duration(seconds: k_confetti_emission_duration_seconds),
    );
    _right_confetti_controller = ConfettiController(
      duration: const Duration(seconds: k_confetti_emission_duration_seconds),
    );

    // Pulse animation for suspense building
    _pulse_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: k_pulse_animation_duration_ms),
    );
    _pulse_animation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulse_controller, curve: Curves.easeInOut),
    );

    // Text scale animation for dramatic reveal
    _text_scale_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: k_text_scale_animation_duration_ms),
    );
    _text_scale_animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _text_scale_controller, curve: Curves.elasticOut),
    );

    // Name fade animation
    _name_fade_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: k_fade_in_duration_ms),
    );
    _name_fade_animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _name_fade_controller, curve: Curves.easeIn),
    );
  }

  void _start_animation_sequence() {
    // Start pulse animation immediately
    _pulse_controller.repeat(reverse: true);

    // Schedule gender text reveal
    _gender_reveal_timer = Timer(
      const Duration(milliseconds: k_gender_text_reveal_delay_ms),
      () {
        if (!mounted) return;
        _reveal_gender();
      },
    );
  }

  void _reveal_gender() {
    // Stop pulse, start confetti and text animation
    _pulse_controller.stop();

    setState(() {
      _show_gender_text = true;
    });

    // Start text scale animation
    _text_scale_controller.forward();

    // Start confetti from multiple directions
    _center_confetti_controller.play();
    _left_confetti_controller.play();
    _right_confetti_controller.play();

    // Schedule baby name reveal if provided
    if (widget.baby_name != null && widget.baby_name!.isNotEmpty) {
      _name_reveal_timer = Timer(
        const Duration(
          milliseconds: k_baby_name_reveal_delay_ms - k_gender_text_reveal_delay_ms,
        ),
        () {
          if (!mounted) return;
          setState(() {
            _show_baby_name = true;
          });
          _name_fade_controller.forward();
        },
      );
    }

    // Schedule confetti stop
    _confetti_stop_timer = Timer(
      const Duration(seconds: k_confetti_emission_duration_seconds),
      () {
        if (!mounted) return;
        _center_confetti_controller.stop();
        _left_confetti_controller.stop();
        _right_confetti_controller.stop();
      },
    );

    // Schedule animation complete callback
    _animation_complete_timer = Timer(
      const Duration(seconds: k_reveal_animation_duration_seconds),
      () {
        if (!mounted) return;
        widget.on_animation_complete?.call();
      },
    );
  }

  @override
  void dispose() {
    // Cancel all timers
    _gender_reveal_timer?.cancel();
    _name_reveal_timer?.cancel();
    _confetti_stop_timer?.cancel();
    _animation_complete_timer?.cancel();

    // Dispose confetti controllers
    _center_confetti_controller.dispose();
    _left_confetti_controller.dispose();
    _right_confetti_controller.dispose();

    // Dispose animation controllers
    _pulse_controller.dispose();
    _text_scale_controller.dispose();
    _name_fade_controller.dispose();

    super.dispose();
  }

  /// Creates confetti colors based on gender.
  List<Color> _get_confetti_colors() {
    if (_is_boy) {
      return [
        widget.boy_color,
        widget.boy_color.withAlpha(200),
        HSLColor.fromColor(widget.boy_color).withLightness(0.7).toColor(),
        HSLColor.fromColor(widget.boy_color).withLightness(0.5).toColor(),
        Colors.white,
      ];
    } else {
      return [
        widget.girl_color,
        widget.girl_color.withAlpha(200),
        HSLColor.fromColor(widget.girl_color).withLightness(0.7).toColor(),
        HSLColor.fromColor(widget.girl_color).withLightness(0.5).toColor(),
        Colors.white,
      ];
    }
  }

  /// Creates varied confetti shapes for visual interest.
  Path _draw_confetti_shape(Size size) {
    final random = math.Random();
    final shape_type = random.nextInt(3);

    switch (shape_type) {
      case 0:
        // Circle
        return Path()
          ..addOval(Rect.fromCircle(
            center: Offset(size.width / 2, size.height / 2),
            radius: size.width / 2,
          ));
      case 1:
        // Square
        return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      default:
        // Star
        return _create_star_path(size);
    }
  }

  Path _create_star_path(Size size) {
    final path = Path();
    final center_x = size.width / 2;
    final center_y = size.height / 2;
    final outer_radius = size.width / 2;
    final inner_radius = size.width / 4;

    for (int i = 0; i < 5; i++) {
      final outer_angle = (i * 72 - 90) * math.pi / 180;
      final inner_angle = ((i * 72) + 36 - 90) * math.pi / 180;

      final outer_x = center_x + outer_radius * math.cos(outer_angle);
      final outer_y = center_y + outer_radius * math.sin(outer_angle);
      final inner_x = center_x + inner_radius * math.cos(inner_angle);
      final inner_y = center_y + inner_radius * math.sin(inner_angle);

      if (i == 0) {
        path.moveTo(outer_x, outer_y);
      } else {
        path.lineTo(outer_x, outer_y);
      }
      path.lineTo(inner_x, inner_y);
    }
    path.close();
    return path;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final portrait = size.height > size.width;
    final text_size = portrait ? k_gender_text_size_portrait : k_gender_text_size_landscape;
    final name_text_size = portrait ? k_baby_name_text_size_portrait : k_baby_name_text_size_landscape;

    return Stack(
      children: [
        // Animated gradient background
        _build_animated_background(),

        // Center content
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulse animation before reveal
              if (!_show_gender_text)
                AnimatedBuilder(
                  animation: _pulse_animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulse_animation.value,
                      child: Icon(
                        Icons.favorite,
                        size: 80,
                        color: Colors.white.withAlpha(180),
                      ),
                    );
                  },
                ),

              // Gender reveal text
              if (_show_gender_text)
                AnimatedBuilder(
                  animation: _text_scale_animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _text_scale_animation.value,
                      child: Text(
                        _reveal_text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: text_size,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 20,
                              color: _reveal_color.withAlpha(180),
                              offset: const Offset(0, 0),
                            ),
                            const Shadow(
                              blurRadius: 40,
                              color: Colors.black26,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 16),

              // Baby name
              if (_show_baby_name && widget.baby_name != null)
                FadeTransition(
                  opacity: _name_fade_animation,
                  child: Text(
                    widget.baby_name!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: name_text_size,
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          blurRadius: 15,
                          color: _reveal_color.withAlpha(150),
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Confetti - Center (top explosion)
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _center_confetti_controller,
            blastDirection: math.pi / 2, // Down
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: k_confetti_max_blast_force,
            minBlastForce: k_confetti_min_blast_force,
            emissionFrequency: 0.05,
            numberOfParticles: k_confetti_particle_count,
            gravity: 0.2,
            shouldLoop: false,
            colors: _get_confetti_colors(),
            createParticlePath: _draw_confetti_shape,
          ),
        ),

        // Confetti - Left side
        Align(
          alignment: Alignment.centerLeft,
          child: ConfettiWidget(
            confettiController: _left_confetti_controller,
            blastDirection: -math.pi / 4, // Diagonal right-down
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: k_confetti_max_blast_force * 0.8,
            minBlastForce: k_confetti_min_blast_force,
            emissionFrequency: 0.08,
            numberOfParticles: (k_confetti_particle_count * 0.6).round(),
            gravity: 0.15,
            shouldLoop: false,
            colors: _get_confetti_colors(),
            createParticlePath: _draw_confetti_shape,
          ),
        ),

        // Confetti - Right side
        Align(
          alignment: Alignment.centerRight,
          child: ConfettiWidget(
            confettiController: _right_confetti_controller,
            blastDirection: -3 * math.pi / 4, // Diagonal left-down
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: k_confetti_max_blast_force * 0.8,
            minBlastForce: k_confetti_min_blast_force,
            emissionFrequency: 0.08,
            numberOfParticles: (k_confetti_particle_count * 0.6).round(),
            gravity: 0.15,
            shouldLoop: false,
            colors: _get_confetti_colors(),
            createParticlePath: _draw_confetti_shape,
          ),
        ),
      ],
    );
  }

  Widget _build_animated_background() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: k_fade_in_duration_ms),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: _show_gender_text
              ? [
                  _reveal_color.withAlpha(100),
                  _reveal_color.withAlpha(50),
                  Colors.black.withAlpha(200),
                ]
              : [
                  Colors.white.withAlpha(30),
                  Colors.white.withAlpha(10),
                  Colors.black.withAlpha(200),
                ],
        ),
      ),
    );
  }
}
