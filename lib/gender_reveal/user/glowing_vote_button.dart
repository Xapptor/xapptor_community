import 'package:flutter/material.dart';

class GlowingVoteButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final double glowStrength;
  final Color color;
  final VoidCallback onTap;

  const GlowingVoteButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.glowStrength,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactiveForeground = theme.colorScheme.onSurface;
    final activeForeground = theme.colorScheme.onPrimary;

    return Transform.scale(
      scale: isSelected ? 1 + glowStrength * 0.04 : 1,
      child: AnimatedContainer(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: isSelected
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
            color: isSelected
                ? color.withAlpha((255 * 0.8).round())
                : theme.colorScheme.onSurface.withAlpha((255 * 0.12).round()),
          ),
          boxShadow: [
            if (glowStrength > 0)
              BoxShadow(
                color: color.withAlpha((255 * 0.45 * glowStrength).round()),
                blurRadius: 24 + (16 * glowStrength),
                spreadRadius: 2 + (4 * glowStrength),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              // 🔹 a bit less horizontal padding to help on tiny widths
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
                      color: isSelected ? activeForeground : inactiveForeground,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isSelected ? activeForeground : inactiveForeground,
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
