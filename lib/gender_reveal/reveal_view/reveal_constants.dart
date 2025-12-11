import 'package:flutter/foundation.dart';

// Constants for the gender reveal animation screen.
// These values are tuned for optimal UX and memory performance on iOS Safari.

// =============================================================================
// TIMING CONSTANTS
// =============================================================================

/// Total duration of the reveal animation sequence (in seconds).
/// This matches the reaction recording duration.
const int k_reveal_animation_duration_seconds = 10;

/// Duration of the fake countdown for late arrivals (in seconds).
/// 2 minutes in release mode, 20 seconds in debug mode for faster testing.
const int k_fake_countdown_duration_seconds = kDebugMode ? 20 : 120;

/// Delay before the gender text appears (in milliseconds).
/// Allows suspense to build with pulse animation first.
const int k_gender_text_reveal_delay_ms = 2000;

/// Delay before the baby name appears (in milliseconds).
/// Appears after the gender reveal text has settled.
const int k_baby_name_reveal_delay_ms = 4000;

/// Duration of the fade in animation (in milliseconds).
const int k_fade_in_duration_ms = 500;

/// Duration of the pulse animation cycle (in milliseconds).
const int k_pulse_animation_duration_ms = 1000;

/// Duration of confetti emission (in seconds).
/// Slightly longer than reveal to maintain celebration feel.
const int k_confetti_emission_duration_seconds = 8;

// =============================================================================
// REACTION RECORDER CONSTANTS
// =============================================================================

/// Duration of reaction video recording (in seconds).
const int k_reaction_recording_duration_seconds = 10;

/// Delay before starting recording to allow camera initialization (in milliseconds).
const int k_recording_start_delay_ms = 500;

// =============================================================================
// CONFETTI CONSTANTS
// =============================================================================

/// Number of confetti particles to emit per burst.
/// Kept low for memory efficiency on iOS Safari.
const int k_confetti_particle_count = 50;

/// Minimum confetti blast force.
const double k_confetti_min_blast_force = 10;

/// Maximum confetti blast force.
const double k_confetti_max_blast_force = 30;

// =============================================================================
// UI SIZE CONSTANTS
// =============================================================================

/// Camera preview size as fraction of screen width (portrait mode).
const double k_camera_preview_size_portrait = 0.35;

/// Camera preview size as fraction of screen width (landscape mode).
const double k_camera_preview_size_landscape = 0.22;

/// Camera preview border radius.
const double k_camera_preview_border_radius = 16.0;

/// Maximum width for share options container.
const double k_share_options_max_width = 400.0;

/// Padding around the reveal content.
const double k_reveal_content_padding = 24.0;

// =============================================================================
// TEXT SIZE CONSTANTS
// =============================================================================

/// Font size for the main gender reveal text (portrait).
const double k_gender_text_size_portrait = 56.0;

/// Font size for the main gender reveal text (landscape).
const double k_gender_text_size_landscape = 120.0;

/// Font size for the baby name text (portrait).
const double k_baby_name_text_size_portrait = 28.0;

/// Font size for the baby name text (landscape).
const double k_baby_name_text_size_landscape = 40.0;

/// Font size for the delivery date text (portrait).
const double k_delivery_date_text_size_portrait = 20.0;

/// Font size for the delivery date text (landscape).
const double k_delivery_date_text_size_landscape = 24.0;

// =============================================================================
// POST-REVEAL CONSTANTS
// =============================================================================

/// Delay before showing share options after reveal animation (in milliseconds).
const int k_share_options_delay_ms = 500;

/// Duration of share options fade in (in milliseconds).
const int k_share_options_fade_duration_ms = 800;
