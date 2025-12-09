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
  late AnimationController _glow_controller;
  late AnimationController _shimmer_controller;

  // Animations
  late Animation<double> _pulse_animation;
  late Animation<double> _text_scale_animation;
  late Animation<double> _bounce_animation;
  late Animation<double> _name_fade_animation;
  late Animation<double> _glow_animation;
  late Animation<double> _shimmer_animation;

  // State
  bool _show_gender_text = false;
  bool _show_baby_name = false;
  Timer? _gender_reveal_timer;
  Timer? _name_reveal_timer;
  Timer? _animation_complete_timer;

  bool get _is_boy => widget.gender.toLowerCase() == 'boy';
  Color get _reveal_color => _is_boy ? widget.boy_color : widget.girl_color;
  String get _reveal_text => _is_boy ? widget.boy_text : widget.girl_text;

  /// Formats the delivery date as "Month Year" (e.g., "January 2026" / "Enero 2026").
  /// Uses the locale passed from the parent widget for proper translation.
  /// Capitalizes the first character for proper display.
  String? get _formatted_delivery_date {
    if (widget.baby_delivery_date == null) return null;
    final date = widget.baby_delivery_date!.toDate();
    final formatted = DateFormat.yMMMM(widget.locale).format(date);
    // Capitalize first character
    if (formatted.isEmpty) return formatted;
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  /// Gets the "on the way" text with the baby name replaced.
  String get _on_the_way_text {
    if (widget.baby_name == null || widget.baby_name!.isEmpty) return '';
    return widget.baby_on_the_way_text.replaceAll('{name}', widget.baby_name!);
  }

  @override
  void initState() {
    super.initState();
    // Initialize locale data for date formatting
    initializeDateFormatting(widget.locale);
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

    // Text scale animation for dramatic reveal (explosive entrance)
    _text_scale_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _text_scale_animation = TweenSequence<double>([
      // Start from tiny
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.3).chain(
          CurveTween(curve: Curves.easeOutBack),
        ),
        weight: 60,
      ),
      // Overshoot and settle
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0).chain(
          CurveTween(curve: Curves.elasticOut),
        ),
        weight: 40,
      ),
    ]).animate(_text_scale_controller);

    // Bounce animation for continuous "heartbeat" effect after reveal
    _bounce_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _bounce_animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 0.98).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.98, end: 1.03).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.03, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 25,
      ),
    ]).animate(_bounce_controller);

    // Glow animation for burst effect on reveal
    _glow_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glow_animation = TweenSequence<double>([
      // Initial burst
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 30,
      ),
      // Fade down
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.3).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 70,
      ),
    ]).animate(_glow_controller);

    // Shimmer animation for sparkle effect
    _shimmer_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _shimmer_animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmer_controller, curve: Curves.linear),
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

    // Start all reveal animations
    _text_scale_controller.forward().then((_) {
      if (!mounted) return;
      // Start continuous bounce after initial reveal
      _bounce_controller.repeat();
    });

    // Start glow burst
    _glow_controller.forward();

    // Start shimmer effect (repeating)
    _shimmer_controller.repeat();

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

    // Confetti now runs continuously (shouldLoop: true), no stop timer needed

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
    _animation_complete_timer?.cancel();

    // Dispose confetti controllers
    _center_confetti_controller.dispose();
    _left_confetti_controller.dispose();
    _right_confetti_controller.dispose();

    // Dispose animation controllers
    _pulse_controller.dispose();
    _text_scale_controller.dispose();
    _bounce_controller.dispose();
    _name_fade_controller.dispose();
    _glow_controller.dispose();
    _shimmer_controller.dispose();

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
    final date_text_size = portrait ? k_delivery_date_text_size_portrait : k_delivery_date_text_size_landscape;

    return Stack(
      children: [
        // Animated gradient background
        _build_animated_background(),

        // Center content
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100),
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

                // Gender reveal text with dramatic glow, scale and shimmer effects
                // Using UnconstrainedBox to allow glow shadows to extend beyond parent bounds
                if (_show_gender_text)
                  UnconstrainedBox(
                    clipBehavior: Clip.none,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _text_scale_animation,
                        _bounce_animation,
                        _glow_animation,
                        _shimmer_animation,
                      ]),
                      builder: (context, child) {
                        // Combine initial scale with continuous bounce
                        final scale = _text_scale_animation.value *
                            (_text_scale_controller.isCompleted ? _bounce_animation.value : 1.0);

                        // Dynamic glow intensity based on animation
                        final glow_intensity = _glow_animation.value;
                        final base_glow_radius = 30.0 + (glow_intensity * 50.0);

                        // Shimmer offset for sparkle sweep effect
                        final shimmer_offset = _shimmer_animation.value;

                        return Transform.scale(
                          scale: scale,
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // Outer glow layer (burst effect)
                              if (glow_intensity > 0.1)
                                Text(
                                  _reveal_text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: text_size,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.transparent,
                                    shadows: [
                                      Shadow(
                                        blurRadius: base_glow_radius * 2,
                                        color: _reveal_color.withAlpha((150 * glow_intensity).round()),
                                        offset: const Offset(0, 0),
                                      ),
                                      Shadow(
                                        blurRadius: base_glow_radius * 3,
                                        color: Colors.white.withAlpha((100 * glow_intensity).round()),
                                        offset: const Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                ),
                              // Main text with shimmer gradient
                              ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Colors.white.withAlpha(200),
                                      Colors.white,
                                      Colors.white.withAlpha(220),
                                      Colors.white,
                                    ],
                                    stops: [
                                      (shimmer_offset - 0.3).clamp(0.0, 1.0),
                                      (shimmer_offset - 0.1).clamp(0.0, 1.0),
                                      shimmer_offset.clamp(0.0, 1.0),
                                      (shimmer_offset + 0.1).clamp(0.0, 1.0),
                                      (shimmer_offset + 0.3).clamp(0.0, 1.0),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds);
                                },
                                blendMode: BlendMode.srcIn,
                                child: Text(
                                  _reveal_text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: text_size,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                    shadows: [
                                      Shadow(
                                        blurRadius: base_glow_radius,
                                        color: _reveal_color.withAlpha(200),
                                        offset: const Offset(0, 0),
                                      ),
                                      Shadow(
                                        blurRadius: base_glow_radius / 2,
                                        color: Colors.white.withAlpha(150),
                                        offset: const Offset(0, 0),
                                      ),
                                      const Shadow(
                                        blurRadius: 40,
                                        color: Colors.black38,
                                        offset: Offset(3, 3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                // Baby name and delivery date section
                if (_show_baby_name && widget.baby_name != null)
                  FadeTransition(
                    opacity: _name_fade_animation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "{name} is on the way!" text
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
                                blurRadius: 15,
                                color: _reveal_color.withAlpha(150),
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                        // Delivery date if available
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
                                  blurRadius: 10,
                                  color: _reveal_color.withAlpha(100),
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

        // Confetti - Center (top explosion) - continuous celebration
        // Initial: 70% of base count, Reduced: 40% of base count
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _center_confetti_controller,
            blastDirection: math.pi / 2, // Down
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: k_confetti_max_blast_force,
            minBlastForce: k_confetti_min_blast_force,
            emissionFrequency: widget.reduce_confetti ? 0.06 : 0.03,
            numberOfParticles: widget.reduce_confetti
                ? (k_confetti_particle_count * 0.4).round()
                : (k_confetti_particle_count * 0.7).round(),
            gravity: 0.15,
            shouldLoop: true,
            colors: _get_confetti_colors(),
            createParticlePath: _draw_confetti_shape,
          ),
        ),

        // Confetti - Left side - continuous celebration
        // Initial: 35% of base count, Reduced: 20% of base count
        Align(
          alignment: Alignment.centerLeft,
          child: ConfettiWidget(
            confettiController: _left_confetti_controller,
            blastDirection: -math.pi / 4, // Diagonal right-down
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: k_confetti_max_blast_force * 0.8,
            minBlastForce: k_confetti_min_blast_force,
            emissionFrequency: widget.reduce_confetti ? 0.10 : 0.05,
            numberOfParticles: widget.reduce_confetti
                ? (k_confetti_particle_count * 0.2).round()
                : (k_confetti_particle_count * 0.35).round(),
            gravity: 0.12,
            shouldLoop: true,
            colors: _get_confetti_colors(),
            createParticlePath: _draw_confetti_shape,
          ),
        ),

        // Confetti - Right side - continuous celebration
        // Initial: 35% of base count, Reduced: 20% of base count
        Align(
          alignment: Alignment.centerRight,
          child: ConfettiWidget(
            confettiController: _right_confetti_controller,
            blastDirection: -3 * math.pi / 4, // Diagonal left-down
            blastDirectionality: BlastDirectionality.explosive,
            maxBlastForce: k_confetti_max_blast_force * 0.8,
            minBlastForce: k_confetti_min_blast_force,
            emissionFrequency: widget.reduce_confetti ? 0.10 : 0.05,
            numberOfParticles: widget.reduce_confetti
                ? (k_confetti_particle_count * 0.2).round()
                : (k_confetti_particle_count * 0.35).round(),
            gravity: 0.12,
            shouldLoop: true,
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
