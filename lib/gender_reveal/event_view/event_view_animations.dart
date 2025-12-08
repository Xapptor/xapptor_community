import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:xapptor_community/gender_reveal/event_view/event_view_constants.dart';

/// Mixin containing animation logic for EventView.
/// This includes glow animation for vote buttons and shake animation
/// for the celebration icon.
mixin EventViewAnimationsMixin<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  // Animation controllers
  late AnimationController glow_controller;
  late Animation<double> glow_animation;
  late AnimationController shake_controller;
  late Animation<double> shake_animation;

  // Timers
  Timer? shake_timer;
  Timer? voting_card_hide_timer;
  Timer? voting_card_show_timer;

  // Tooltip state
  final GlobalKey<TooltipState> celebration_tooltip_key =
      GlobalKey<TooltipState>();
  bool tooltip_shown = false;

  // Voting card visibility state
  bool show_voting_card = false;
  bool enable_voting_card = false;

  /// Initialize all animations.
  void initialize_animations() {
    // Show tooltip once after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || tooltip_shown) return;
      celebration_tooltip_key.currentState?.ensureTooltipVisible();
      tooltip_shown = true;
    });

    // Initialize glow animation for vote buttons
    glow_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: k_glow_animation_duration_ms),
    )..repeat(reverse: true);

    glow_animation = CurvedAnimation(
      parent: glow_controller,
      curve: Curves.easeInOut,
    );

    // Initialize shake animation for celebration icon
    shake_controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: k_shake_animation_duration_ms),
    );

    shake_animation = CurvedAnimation(
      parent: shake_controller,
      curve: Curves.easeOut,
    );

    shake_controller.addStatusListener(on_shake_status_changed);
    schedule_next_shake();
  }

  /// Handle shake animation status changes.
  void on_shake_status_changed(AnimationStatus status) {
    if (!mounted) return;

    if (status == AnimationStatus.forward) {
      celebration_tooltip_key.currentState?.ensureTooltipVisible();
    } else if (status == AnimationStatus.completed) {
      shake_controller.reset();
      schedule_next_shake();
      tooltip_shown = true;
    }
  }

  /// Schedule the next shake animation at a random interval.
  void schedule_next_shake() {
    shake_timer?.cancel();

    const range = k_max_shake_interval_seconds - k_min_shake_interval_seconds;
    final seconds = k_min_shake_interval_seconds + math.Random().nextInt(range);

    shake_timer = Timer(Duration(seconds: seconds), () {
      if (!mounted) return;
      shake_controller.forward();
    });
  }

  /// Cancel all animation timers and null them to prevent reuse.
  /// CRITICAL: Setting to null prevents memory leaks from lingering references.
  void cancel_all_animation_timers() {
    shake_timer?.cancel();
    shake_timer = null;
    voting_card_hide_timer?.cancel();
    voting_card_hide_timer = null;
    voting_card_show_timer?.cancel();
    voting_card_show_timer = null;
  }

  /// Dispose all animation resources.
  void dispose_animations() {
    cancel_all_animation_timers();
    glow_controller.dispose();
    shake_controller.removeStatusListener(on_shake_status_changed);
    shake_controller.dispose();
  }

  /// Handle celebration button press - triggers confetti and hides voting card.
  ///
  /// Parameters:
  /// - [on_trigger_music_play]: Callback to trigger music playback.
  void handle_celebration_pressed({VoidCallback? on_trigger_music_play}) {
    // Cancel any existing timers
    voting_card_hide_timer?.cancel();
    voting_card_show_timer?.cancel();

    // Hide voting card with fade out
    show_voting_card = false;
    if (mounted) setState(() {});

    // Disable voting card after fade completes
    voting_card_hide_timer = Timer(
      const Duration(milliseconds: k_voting_card_hide_delay_ms),
      () {
        if (!mounted) return;
        enable_voting_card = false;
        setState(() {});
      },
    );

    // Schedule voting card to reappear
    voting_card_show_timer = Timer(
      const Duration(seconds: k_voting_card_show_delay_seconds),
      () {
        if (!mounted) return;
        enable_voting_card = true;
        show_voting_card = true;
        setState(() {});
      },
    );

    // Trigger music playback (directly, not async - required for iOS Safari)
    on_trigger_music_play?.call();
  }
}
