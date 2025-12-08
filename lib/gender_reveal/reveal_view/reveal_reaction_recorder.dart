import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/reveal_constants.dart';

/// Enhanced reaction recorder widget for the gender reveal screen.
/// Records the user's reaction during the reveal animation.
///
/// Features:
/// - Auto-start recording when mounted (if enabled)
/// - Fixed duration recording (10 seconds)
/// - Low resolution for web memory efficiency
/// - Responsive sizing for portrait/landscape
/// - Hybrid approach: shows preview for all, records for logged-in users only
class RevealReactionRecorder extends StatefulWidget {
  /// Whether recording is enabled (requires logged-in user).
  final bool enable_recording;

  /// Whether to show the camera preview (for all users).
  final bool show_preview;

  /// Border radius for the camera preview.
  final double border_radius;

  /// Duration of the recording.
  final Duration recording_duration;

  /// Callback when recording completes with the file path.
  /// Returns null if recording was not enabled or failed.
  final void Function(String? video_path)? on_recording_complete;

  /// Callback when recording starts.
  final VoidCallback? on_recording_started;

  /// Callback to prompt user to login.
  final VoidCallback? on_login_prompt;

  /// Accent color for the recording indicator.
  final Color accent_color;

  /// Text to show when prompting login.
  final String login_prompt_text;

  const RevealReactionRecorder({
    super.key,
    this.enable_recording = true,
    this.show_preview = true,
    this.border_radius = k_camera_preview_border_radius,
    this.recording_duration = const Duration(
      seconds: k_reaction_recording_duration_seconds,
    ),
    this.on_recording_complete,
    this.on_recording_started,
    this.on_login_prompt,
    this.accent_color = Colors.red,
    this.login_prompt_text = 'Login to save your reaction',
  });

  @override
  State<RevealReactionRecorder> createState() => _RevealReactionRecorderState();
}

class _RevealReactionRecorderState extends State<RevealReactionRecorder> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;

  bool _camera_initialized = false;
  bool _camera_initialization_attempted = false;
  bool _is_recording = false;
  bool _recording_complete = false;
  String? _video_path;

  Timer? _recording_timer;
  Timer? _start_delay_timer;

  // Recording progress (0.0 to 1.0)
  double _recording_progress = 0.0;
  Timer? _progress_timer;

  @override
  void initState() {
    super.initState();
    if (widget.show_preview) {
      _initialize_camera();
    }
  }

  /// Initialize camera with front-facing preference and low resolution.
  Future<void> _initialize_camera() async {
    if (_camera_initialization_attempted) return;
    _camera_initialization_attempted = true;

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty || !mounted) return;

      // Prefer front camera for selfie-style reaction
      CameraDescription selected_camera = _cameras.first;
      for (final camera in _cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          selected_camera = camera;
          break;
        }
      }

      // Use LOW resolution to minimize memory on web
      // This is CRITICAL for iOS Safari stability
      _controller = CameraController(
        selected_camera,
        ResolutionPreset.low,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() {
        _camera_initialized = true;
      });

      // Auto-start recording if enabled (with small delay for stability)
      if (widget.enable_recording) {
        _start_delay_timer = Timer(
          const Duration(milliseconds: k_recording_start_delay_ms),
          _start_recording,
        );
      }
    } on CameraException catch (e) {
      debugPrint('RevealReactionRecorder: Camera error: ${e.code} - ${e.description}');
    } catch (e) {
      debugPrint('RevealReactionRecorder: Error initializing camera: $e');
    }
  }

  /// Start video recording.
  Future<void> _start_recording() async {
    if (!mounted || !_camera_initialized || _controller == null) return;
    if (_is_recording || _recording_complete) return;
    if (!widget.enable_recording) return;

    try {
      await _controller!.startVideoRecording();

      if (!mounted) return;

      setState(() {
        _is_recording = true;
        _recording_progress = 0.0;
      });

      widget.on_recording_started?.call();

      // Start progress timer
      final total_ms = widget.recording_duration.inMilliseconds;
      const update_interval = 100; // Update every 100ms
      _progress_timer = Timer.periodic(
        const Duration(milliseconds: update_interval),
        (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          final elapsed = timer.tick * update_interval;
          setState(() {
            _recording_progress = (elapsed / total_ms).clamp(0.0, 1.0);
          });
        },
      );

      // Schedule recording stop
      _recording_timer = Timer(widget.recording_duration, _stop_recording);
    } catch (e) {
      debugPrint('RevealReactionRecorder: Error starting recording: $e');
      widget.on_recording_complete?.call(null);
    }
  }

  /// Stop video recording and save the file.
  Future<void> _stop_recording() async {
    _progress_timer?.cancel();
    _recording_timer?.cancel();

    if (!mounted || _controller == null || !_is_recording) return;

    try {
      final XFile video_file = await _controller!.stopVideoRecording();

      if (!mounted) return;

      setState(() {
        _is_recording = false;
        _recording_complete = true;
        _video_path = video_file.path;
        _recording_progress = 1.0;
      });

      widget.on_recording_complete?.call(video_file.path);
    } catch (e) {
      debugPrint('RevealReactionRecorder: Error stopping recording: $e');
      setState(() {
        _is_recording = false;
        _recording_complete = true;
      });
      widget.on_recording_complete?.call(null);
    }
  }

  @override
  void dispose() {
    _recording_timer?.cancel();
    _start_delay_timer?.cancel();
    _progress_timer?.cancel();
    _stop_recording_if_needed();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _stop_recording_if_needed() async {
    if (_is_recording && _controller != null) {
      try {
        await _controller!.stopVideoRecording();
      } catch (e) {
        // Ignore errors during cleanup
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show_preview) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.border_radius),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(widget.border_radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Camera preview or placeholder
            if (_camera_initialized && _controller != null)
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              )
            else
              _build_camera_placeholder(),

            // Recording indicator
            if (_is_recording) _build_recording_indicator(),

            // Recording complete indicator
            if (_recording_complete && !_is_recording)
              _build_recording_complete_indicator(),

            // Login prompt for non-authenticated users
            if (!widget.enable_recording && _camera_initialized)
              _build_login_prompt(),
          ],
        ),
      ),
    );
  }

  Widget _build_camera_placeholder() {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _build_recording_indicator() {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Column(
        children: [
          // Recording badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pulsing red dot
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.5, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, child) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.accent_color.withAlpha((255 * value).round()),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                      onEnd: () {
                        // Restart animation
                        if (mounted && _is_recording) {
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'REC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _recording_progress,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(widget.accent_color),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _build_recording_complete_indicator() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, color: Colors.white, size: 12),
            SizedBox(width: 4),
            Text(
              'Saved',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build_login_prompt() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(150),
          borderRadius: BorderRadius.circular(widget.border_radius),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.videocam_off,
                  color: Colors.white70,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.login_prompt_text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.on_login_prompt != null)
                  TextButton(
                    onPressed: widget.on_login_prompt,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
