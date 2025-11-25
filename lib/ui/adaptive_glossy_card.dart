import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';

class AdaptiveGlossyCard extends StatefulWidget {
  final Widget child;
  final double radius;
  final double scroll_factor;

  const AdaptiveGlossyCard({
    super.key,
    required this.child,
    this.radius = 22,
    this.scroll_factor = 0.0,
  });

  @override
  State<AdaptiveGlossyCard> createState() => _AdaptiveGlossyCardState();
}

class _AdaptiveGlossyCardState extends State<AdaptiveGlossyCard> {
  bool _hover = false;

  static const double _sigma_min = 1.5;
  static const double _sigma_max = 20;

  bool _hoverIsSupported() {
    final current_platform = Theme.of(context).platform;
    return kIsWeb ||
        current_platform == TargetPlatform.macOS ||
        current_platform == TargetPlatform.linux ||
        current_platform == TargetPlatform.windows;
  }

  @override
  Widget build(BuildContext context) {
    final media_query = MediaQuery.of(context);
    final bool is_portrait = media_query.orientation == Orientation.portrait;

    final bool hover_enabled = !is_portrait && _hoverIsSupported();

    final double frost_factor = hover_enabled ? (_hover ? 1.0 : 0.0) : widget.scroll_factor.clamp(0.0, 1.0);

    final double target_sigma = _sigma_min + (_sigma_max - _sigma_min) * frost_factor;
    final double target_scale = 1.0 + 0.03 * frost_factor;

    Widget card_widget = TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(
        begin: _sigma_min,
        end: target_sigma,
      ),
      builder: (build_context, animated_sigma, child_widget) {
        return AnimatedScale(
          scale: target_scale,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.radius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: animated_sigma,
                sigmaY: animated_sigma,
              ),
              child: child_widget,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((255 * 0.06).round()),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
        child: widget.child,
      ),
    );

    if (hover_enabled) {
      card_widget = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: card_widget,
      );
    }
    return card_widget;
  }
}
