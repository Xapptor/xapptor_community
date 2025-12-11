import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/reveal_constants.dart';
import 'package:xapptor_ui/values/ui.dart';

/// Widget that displays the gender reveal celebration animations.
/// Includes confetti explosion and animated text reveal.
class RevealAnimations extends StatefulWidget {
  /// The gender to reveal: "boy" or "girl".
  final String gender;

  /// The baby's name to display (optional).
  final String? baby_name;

  /// The expected delivery date (optional).
  final Timestamp? baby_delivery_date;

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

  /// Text template for baby name section (e.g., "{name} is on the way!").
  /// Use {name} as placeholder for the baby's name.
  final String baby_on_the_way_text;

  /// Locale code for date formatting (e.g., "en", "es").
  final String locale;

  /// Whether to reduce confetti intensity (e.g., after share options are shown).
  final bool reduce_confetti;

  const RevealAnimations({
    super.key,
    required this.gender,
    this.baby_name,
    this.baby_delivery_date,
    required this.boy_color,
    required this.girl_color,
    this.on_animation_complete,
    this.boy_text = "It's a Boy!",
    this.girl_text = "It's a Girl!",
    this.baby_on_the_way_text = "{name} is on the way!",
    this.locale = 'en',
    this.reduce_confetti = false,
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
  late AnimationController _bounce_controller;
  late AnimationController _name_fade_controller;

  // Animations
  late Animation<double> _pulse_animation;
  late Animation<double> _text_scale_animation;
  late Animation<double> _bounce_animation;
  late Animation<double> _name_fade_animation;

  // State
  bool _show_gender_text = false;
  bool _show_baby_name = false;
  Timer? _gender_reveal_timer;
  Timer? _name_reveal_timer;
  Timer? _animation_complete_timer;

  // Cached values to avoid recalculation on every build
  late final bool _is_boy;
  late final Color _reveal_color;
  late final String _reveal_text;
  late final List<Color> _confetti_colors;
  String? _cached_formatted_date;
  String? _cached_on_the_way_text;

  /// Formats the delivery date as "Month Year" (e.g., "January 2026" / "Enero 2026").
  /// Cached to avoid repeated DateFormat parsing.
  String? get _formatted_delivery_date {
    if (_cached_formatted_date != null) return _cached_formatted_date;
    if (widget.baby_delivery_date == null) return null;
    final date = widget.baby_delivery_date!.toDate();
    final formatted = DateFormat.yMMMM(widget.locale).format(date);
    if (formatted.isEmpty) {
      _cached_formatted_date = formatted;
      return formatted;
    }
    _cached_formatted_date = formatted[0].toUpperCase() + formatted.substring(1);
    return _cached_formatted_date;
  }

  /// Gets the "on the way" text with the baby name replaced.
  /// Cached to avoid repeated string operations.
  String get _on_the_way_text {
    if (_cached_on_the_way_text != null) return _cached_on_the_way_text!;
    if (widget.baby_name == null || widget.baby_name!.isEmpty) {
      _cached_on_the_way_text = '';
      return '';
    }
    _cached_on_the_way_text = widget.baby_on_the_way_text.replaceAll('{name}', widget.baby_name!);
    return _cached_on_the_way_text!;
  }

  @override
  void initState() {
    super.initState();

    // Initialize cached values once to avoid recalculation on every build
    _is_boy = widget.gender.toLowerCase() == 'boy';
    _reveal_color = _is_boy ? widget.boy_color : widget.girl_color;
    _reveal_text = _is_boy ? widget.boy_text : widget.girl_text;
    _confetti_colors = _build_confetti_colors();

    initializeDateFormatting(widget.locale);
    _initialize_controllers();
    _start_animation_sequence();
  }

  /// Build confetti colors once during initialization.
  /// This avoids expensive HSLColor conversions on every build.
  List<Color> _build_confetti_colors() {
    final base_color = _is_boy ? widget.boy_color : widget.girl_color;
    return [
      base_color,
      base_color.withAlpha(200),
      HSLColor.fromColor(base_color).withLightness(0.7).toColor(),
      HSLColor.fromColor(base_color).withLightness(0.5).toColor(),
      Colors.white,
    ];
  }

  void _initialize_controllers() {
    // Confetti controllers
    _center_confetti_controller = ConfettiController(
      duration: const Duration(seconds: k_confetti_emission_duration_seconds),
    );
    _left_confetti_controller = ConfettiController(
      duration: const Duration(seconds: k_confetti_emission_duration_seconds),
    );
    _right_confetti_controller = ConfettiController(
      duration: const Duration(seconds: k_confetti_emission_duration_seconds),
    );

    // Pulse animation for suspense
    _pulse_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: k_pulse_animation_duration_ms),
    );
    _pulse_animation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulse_controller, curve: Curves.easeInOut),
    );

    // Text scale - explosive entrance
    _text_scale_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _text_scale_animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.4).chain(
          CurveTween(curve: Curves.easeOutBack),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.4, end: 1.0).chain(
          CurveTween(curve: Curves.elasticOut),
        ),
        weight: 50,
      ),
    ]).animate(_text_scale_controller);

    // Bounce - heartbeat effect
    _bounce_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _bounce_animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.06).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 0.97).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.97, end: 1.04).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.04, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(_bounce_controller);

    // Name fade
    _name_fade_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: k_fade_in_duration_ms),
    );
    _name_fade_animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _name_fade_controller, curve: Curves.easeIn),
    );
  }

  void _start_animation_sequence() {
    _pulse_controller.repeat(reverse: true);

    _gender_reveal_timer = Timer(
      const Duration(milliseconds: k_gender_text_reveal_delay_ms),
      () {
        if (!mounted) return;
        _reveal_gender();
      },
    );
  }

  void _reveal_gender() {
    _pulse_controller.stop();

    setState(() {
      _show_gender_text = true;
    });

    // Start all reveal animations
    _text_scale_controller.forward().then((_) {
      if (!mounted) return;
      _bounce_controller.repeat();
    });

    // Start confetti
    _center_confetti_controller.play();
    _left_confetti_controller.play();
    _right_confetti_controller.play();

    // Schedule baby name reveal
    if (widget.baby_name != null && widget.baby_name!.isNotEmpty) {
      _name_reveal_timer = Timer(
        const Duration(milliseconds: k_baby_name_reveal_delay_ms - k_gender_text_reveal_delay_ms),
        () {
          if (!mounted) return;
          setState(() {
            _show_baby_name = true;
          });
          _name_fade_controller.forward();
        },
      );
    }

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
  void didUpdateWidget(RevealAnimations oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Performance optimization: Stop animations when share options appear
    if (widget.reduce_confetti && !oldWidget.reduce_confetti) {
      // Stop bounce animation to save CPU immediately
      _bounce_controller.stop();

      // Stagger side confetti stops to spread out resource release
      // This prevents a sudden GPU/memory spike from releasing all at once
      Future.delayed(const Duration(milliseconds: k_confetti_reduction_delay_ms), () {
        if (!mounted) return;
        _left_confetti_controller.stop();
      });
      Future.delayed(const Duration(milliseconds: k_confetti_reduction_delay_ms * 2), () {
        if (!mounted) return;
        _right_confetti_controller.stop();
      });
    }
  }

  @override
  void dispose() {
    _gender_reveal_timer?.cancel();
    _name_reveal_timer?.cancel();
    _animation_complete_timer?.cancel();

    _center_confetti_controller.dispose();
    _left_confetti_controller.dispose();
    _right_confetti_controller.dispose();

    _pulse_controller.dispose();
    _text_scale_controller.dispose();
    _bounce_controller.dispose();
    _name_fade_controller.dispose();

    super.dispose();
  }


  // Reusable random instance for confetti shape generation
  // Creating Random() for every particle is expensive
  static final math.Random _confetti_random = math.Random();

  Path _draw_confetti_shape(Size size) {
    final shape_type = _confetti_random.nextInt(3);

    switch (shape_type) {
      case 0:
        return Path()
          ..addOval(Rect.fromCircle(
            center: Offset(size.width / 2, size.height / 2),
            radius: size.width / 2,
          ));
      case 1:
        return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      default:
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
    final date_text_size = portrait ? k_delivery_date_text_size_portrait : k_delivery_date_text_size_landscape;

    final int particle_count_top = portrait ? 14 : 34;
    final int particle_count_side = portrait ? 10 : 26;

    return Stack(
      children: [
        // Animated gradient background
        _build_animated_background(),

        // Center content
        Positioned.fill(
          child: Center(
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

                // Main gender reveal title with glow effect
                if (_show_gender_text) _buildGlowingTitle(text_size, portrait),

                const SizedBox(height: 24),

                // Baby name and delivery date section
                if (_show_baby_name && widget.baby_name != null)
                  FadeTransition(
                    opacity: _name_fade_animation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _on_the_way_text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: name_text_size,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                blurRadius: 20,
                                color: _reveal_color,
                                offset: const Offset(0, 0),
                              ),
                              const Shadow(
                                blurRadius: 10,
                                color: Colors.white54,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                        if (_formatted_delivery_date != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _formatted_delivery_date!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: date_text_size,
                              fontWeight: FontWeight.w300,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withAlpha(220),
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
                        ],
                      ],
                    ),
                  ),
                SizedBox(height: sized_box_space * (portrait ? 6 : 4)),
              ],
            ),
          ),
        ),

        // Confetti - Center (wrapped in RepaintBoundary to isolate GPU repaints)
        RepaintBoundary(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _center_confetti_controller,
              blastDirection: math.pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              maxBlastForce: k_confetti_max_blast_force,
              minBlastForce: k_confetti_min_blast_force,
              emissionFrequency: widget.reduce_confetti ? 0.06 : 0.03,
              numberOfParticles:
                  widget.reduce_confetti ? (particle_count_top * 0.4).round() : (particle_count_top * 0.7).round(),
              gravity: 0.15,
              shouldLoop: true,
              colors: _confetti_colors,
              createParticlePath: _draw_confetti_shape,
            ),
          ),
        ),

        // Confetti - Left (wrapped in RepaintBoundary to isolate GPU repaints)
        RepaintBoundary(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConfettiWidget(
              confettiController: _left_confetti_controller,
              blastDirection: -math.pi / 4,
              blastDirectionality: BlastDirectionality.explosive,
              maxBlastForce: k_confetti_max_blast_force * 0.8,
              minBlastForce: k_confetti_min_blast_force,
              emissionFrequency: widget.reduce_confetti ? 0.10 : 0.05,
              numberOfParticles:
                  widget.reduce_confetti ? (particle_count_side * 0.2).round() : (particle_count_side * 0.35).round(),
              gravity: 0.12,
              shouldLoop: true,
              colors: _confetti_colors,
              createParticlePath: _draw_confetti_shape,
            ),
          ),
        ),

        // Confetti - Right (wrapped in RepaintBoundary to isolate GPU repaints)
        RepaintBoundary(
          child: Align(
            alignment: Alignment.centerRight,
            child: ConfettiWidget(
              confettiController: _right_confetti_controller,
              blastDirection: -3 * math.pi / 4,
              blastDirectionality: BlastDirectionality.explosive,
              maxBlastForce: k_confetti_max_blast_force * 0.8,
              minBlastForce: k_confetti_min_blast_force,
              emissionFrequency: widget.reduce_confetti ? 0.10 : 0.05,
              numberOfParticles:
                  widget.reduce_confetti ? (particle_count_side * 0.2).round() : (particle_count_side * 0.35).round(),
              gravity: 0.12,
              shouldLoop: true,
              colors: _confetti_colors,
              createParticlePath: _draw_confetti_shape,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the title with scale and bounce animations, solid white color
  Widget _buildGlowingTitle(double text_size, bool portrait) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _text_scale_animation,
        _bounce_animation,
      ]),
      builder: (context, child) {
        final scale =
            _text_scale_animation.value * (_text_scale_controller.isCompleted ? _bounce_animation.value : 1.0);

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: portrait ? null : MediaQuery.of(context).size.width * 0.8,
            child: Text(
              _reveal_text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: text_size,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2.0,
                shadows: [
                  // Dark shadow for readability on any background
                  Shadow(
                    blurRadius: 15,
                    color: Colors.black.withAlpha(180),
                    offset: const Offset(0, 3),
                  ),
                  // Subtle glow in reveal color
                  Shadow(
                    blurRadius: 30,
                    color: _reveal_color.withAlpha(150),
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
