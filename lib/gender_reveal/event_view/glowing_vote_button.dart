import 'package:flutter/material.dart';

class GlowingVoteButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool is_selected;
  final double glow_strength;
  final Color color;
  final VoidCallback on_tap;

  const GlowingVoteButton({
    super.key,
    required this.label,
    required this.icon,
    required this.is_selected,
    required this.glow_strength,
    required this.color,
    required this.on_tap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactive_foreground = theme.colorScheme.onSurface;
    final active_foreground = theme.colorScheme.onPrimary;

    return Transform.scale(
      scale: is_selected ? 1 + glow_strength * 0.1 : 1,
      child: AnimatedContainer(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: is_selected
              ? LinearGradient(
                  colors: [
                    color.withAlpha((255 * 0.95).round()),
                    color.withAlpha((255 * 0.70).round()),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    theme.colorScheme.surface.withAlpha((255 * 0.95).round()),
                    theme.colorScheme.surface.withAlpha((255 * 0.78).round()),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: is_selected
                ? color.withAlpha((255 * 0.8).round())
                : theme.colorScheme.onSurface.withAlpha((255 * 0.12).round()),
          ),
          boxShadow: [
            if (glow_strength > 0)
              BoxShadow(
                color: color.withAlpha((255 * 0.45 * glow_strength).round()),
                blurRadius: 24 + (16 * glow_strength),
                spreadRadius: 2 + (4 * glow_strength),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: on_tap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              // 🔹 this makes the row shrink instead of overflow
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: is_selected ? active_foreground : inactive_foreground,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: is_selected ? active_foreground : inactive_foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
