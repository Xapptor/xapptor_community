import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/reveal_constants.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/video_recorder/video_recorder.dart' as video_recorder;

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

  /// Callback when recording completes with the file path and format.
  /// Returns null path if recording was not enabled or failed.
  /// Format is 'mp4' or 'webm' depending on what was actually recorded.
  final void Function(String? video_path, String format)? on_recording_complete;

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

/// Recording lifecycle states to prevent race conditions
enum _RecordingState {
  idle,
  initializing,
  ready,
  recording,
  stopping,
  completed,
  disposed,
}

class _RevealReactionRecorderState extends State<RevealReactionRecorder> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;

  bool _camera_initialized = false;
  bool _camera_initialization_attempted = false;

  // State machine for recording lifecycle - prevents race conditions
  _RecordingState _recording_state = _RecordingState.idle;

  // Legacy flags kept for UI (derived from state machine)
  bool get _is_recording => _recording_state == _RecordingState.recording;
  bool get _recording_complete =>
      _recording_state == _RecordingState.completed || _recording_state == _RecordingState.disposed;

  Timer? _recording_timer;
  Timer? _start_delay_timer;

  // Recording progress (0.0 to 1.0)
  double _recording_progress = 0.0;
  Timer? _progress_timer;

  // Web-specific: native MediaRecorder for MP4 support on Chrome
  dynamic _web_video_recorder;
  bool _use_native_video_recorder = false;

  // Track the actual format used for recording
  String _actual_recording_format = 'mp4'; // 'mp4' or 'webm'

  // Flag to track if callback was already fired (prevents double-callbacks)
  bool _callback_fired = false;

  @override
  void initState() {
    super.initState();
    // On web, check if MP4 recording is supported (Chrome 126+)
    // If so, we'll use native MediaRecorder for iOS-compatible videos
    if (kIsWeb) {
      _use_native_video_recorder = video_recorder.is_mp4_recording_supported();
      debugPrint(
        'RevealReactionRecorder: MP4 support=$_use_native_video_recorder, '
        'format=${video_recorder.get_preferred_extension()}, '
        'mimeType=${video_recorder.get_preferred_mime_type()}',
      );
      debugPrint('RevealReactionRecorder: Browser support: ${video_recorder.get_browser_support_info()}');
    }
    if (widget.show_preview) {
      _initialize_camera();
    }
  }

  /// Initialize camera with front-facing preference and low resolution.
  Future<void> _initialize_camera() async {
    if (_camera_initialization_attempted) return;
    if (_recording_state == _RecordingState.disposed) return;

    _camera_initialization_attempted = true;
    _recording_state = _RecordingState.initializing;

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty || !mounted || _recording_state == _RecordingState.disposed) return;

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

      if (!mounted || _recording_state == _RecordingState.disposed) return;

      setState(() {
        _camera_initialized = true;
        _recording_state = _RecordingState.ready;
      });

      debugPrint('RevealReactionRecorder: Camera initialized, state=$_recording_state');

      // Auto-start recording if enabled (with small delay for stability)
      if (widget.enable_recording) {
        _start_delay_timer = Timer(
          const Duration(milliseconds: k_recording_start_delay_ms),
          _start_recording,
        );
      }
    } on CameraException catch (e) {
      debugPrint('RevealReactionRecorder: Camera error: ${e.code} - ${e.description}');
      _recording_state = _RecordingState.idle;
    } catch (e) {
      debugPrint('RevealReactionRecorder: Error initializing camera: $e');
      _recording_state = _RecordingState.idle;
    }
  }

  /// Start video recording.
  /// On web with MP4 support (Chrome 126+), uses native MediaRecorder.
  /// Otherwise, uses the camera package's recorder.
  Future<void> _start_recording() async {
    // State machine guard - only start from ready state
    if (_recording_state != _RecordingState.ready) {
      debugPrint('RevealReactionRecorder: Cannot start recording, state=$_recording_state');
      return;
    }
    if (!mounted || !_camera_initialized || _controller == null) return;
    if (!widget.enable_recording) return;

    debugPrint('RevealReactionRecorder: Starting recording...');

    try {
      // On web with MP4 support, use native MediaRecorder for iOS-compatible videos
      if (kIsWeb && _use_native_video_recorder) {
        final success = await _start_web_native_recording();
        if (!success) {
          // Native recording failed, fall back to camera package (WebM)
          _actual_recording_format = 'webm';
          await _controller!.startVideoRecording();
        } else {
          // Native recording started, use its format
          _actual_recording_format = video_recorder.get_preferred_extension();
        }
      } else {
        // Camera package: WebM on web, MP4 on mobile
        _actual_recording_format = kIsWeb ? 'webm' : 'mp4';
        await _controller!.startVideoRecording();
      }

      if (!mounted || _recording_state == _RecordingState.disposed) return;

      setState(() {
        _recording_state = _RecordingState.recording;
        _recording_progress = 0.0;
      });

      debugPrint('RevealReactionRecorder: Recording started, format=$_actual_recording_format');
      widget.on_recording_started?.call();

      // Start progress timer - update less frequently to reduce CPU usage from setState
      final total_ms = widget.recording_duration.inMilliseconds;
      const update_interval = k_progress_update_interval_ms;
      _progress_timer = Timer.periodic(
        const Duration(milliseconds: update_interval),
        (timer) {
          if (!mounted || _recording_state == _RecordingState.disposed) {
            timer.cancel();
            return;
          }
          final elapsed = timer.tick * update_interval;
          setState(() {
            _recording_progress = (elapsed / total_ms).clamp(0.0, 1.0);
          });
        },
      );

      // Always set our own recording timer for consistent behavior
      // The web native recorder also has one, but we need ours as a backup
      // and to ensure _stop_recording is called even if web recorder fails
      _recording_timer = Timer(widget.recording_duration, _stop_recording);
    } catch (e) {
      debugPrint('RevealReactionRecorder: Error starting recording: $e');
      _recording_state = _RecordingState.ready;
      _fire_callback_once(null);
    }
  }

  /// Fire the completion callback exactly once to prevent double-callbacks
  void _fire_callback_once(String? video_path) {
    if (_callback_fired) {
      debugPrint('RevealReactionRecorder: Callback already fired, skipping');
      return;
    }
    _callback_fired = true;
    debugPrint('RevealReactionRecorder: Firing callback with path=$video_path, format=$_actual_recording_format');
    widget.on_recording_complete?.call(video_path, _actual_recording_format);
  }

  /// Start recording using native web MediaRecorder (for MP4 on Chrome).
  /// Returns true if native recording started successfully, false if it failed.
  Future<bool> _start_web_native_recording() async {
    if (!kIsWeb) return false;

    try {
      // Access the video element from the camera controller
      // The camera package exposes this through the preview widget
      final video_element = _get_web_video_element();
      if (video_element == null) {
        debugPrint('RevealReactionRecorder: Could not get video element for native recording');
        return false;
      }

      _web_video_recorder = video_recorder.WebVideoRecorder(
        video_element: video_element,
        recording_duration: widget.recording_duration,
      );

      await (_web_video_recorder as video_recorder.WebVideoRecorder).start_recording();
      debugPrint('RevealReactionRecorder: Started native web recording (${video_recorder.get_preferred_extension()})');
      return true;
    } catch (e) {
      debugPrint('RevealReactionRecorder: Native web recording failed: $e');
      _web_video_recorder = null;
      return false;
    }
  }

  /// Get the video element from the web camera implementation.
  dynamic _get_web_video_element() {
    if (!kIsWeb) return null;

    try {
      // The camera_web package uses an HtmlElementView with a video element
      // We need to find it in the DOM
      if (_controller?.value.previewSize == null) return null;

      // Use the web-specific helper to find the camera video element
      return video_recorder.find_camera_video_element();
    } catch (e) {
      debugPrint('RevealReactionRecorder: Error getting video element: $e');
      return null;
    }
  }

  /// Stop video recording and save the file.
  Future<void> _stop_recording() async {
    // State machine guard - only stop from recording state
    if (_recording_state != _RecordingState.recording) {
      debugPrint('RevealReactionRecorder: Cannot stop recording, state=$_recording_state');
      return;
    }

    debugPrint('RevealReactionRecorder: Stopping recording...');

    // Transition to stopping state to prevent re-entry
    _recording_state = _RecordingState.stopping;

    _progress_timer?.cancel();
    _recording_timer?.cancel();

    if (_controller == null) {
      _recording_state = _RecordingState.completed;
      _fire_callback_once(null);
      return;
    }

    try {
      String? video_path;

      // Check if we're using native web recorder
      if (kIsWeb && _web_video_recorder != null) {
        video_path = await _stop_web_native_recording();
      } else {
        final XFile video_file = await _controller!.stopVideoRecording();
        video_path = video_file.path;
      }

      debugPrint('RevealReactionRecorder: Recording stopped, path=$video_path');

      // Only update state if still mounted and not disposed
      if (mounted && _recording_state != _RecordingState.disposed) {
        setState(() {
          _recording_state = _RecordingState.completed;
          _recording_progress = 1.0;
        });
      } else {
        _recording_state = _RecordingState.completed;
      }

      _fire_callback_once(video_path);
    } catch (e) {
      debugPrint('RevealReactionRecorder: Error stopping recording: $e');

      if (mounted && _recording_state != _RecordingState.disposed) {
        setState(() {
          _recording_state = _RecordingState.completed;
        });
      } else {
        _recording_state = _RecordingState.completed;
      }

      _fire_callback_once(null);
    }
  }

  /// Stop native web recording and return the video URL.
  Future<String?> _stop_web_native_recording() async {
    if (_web_video_recorder == null) return null;

    try {
      final recorder = _web_video_recorder as video_recorder.WebVideoRecorder;
      final video_url = await recorder.stop_recording();

      if (video_url != null) {
        debugPrint(
          'RevealReactionRecorder: Native web recording complete '
          '(${recorder.file_extension}): $video_url',
        );
      }

      return video_url;
    } catch (e) {
      debugPrint('RevealReactionRecorder: Error stopping native web recording: $e');
      return null;
    }
  }

  @override
  void dispose() {
    debugPrint('RevealReactionRecorder: dispose() called, state=$_recording_state');

    // Cancel all timers first
    _recording_timer?.cancel();
    _start_delay_timer?.cancel();
    _progress_timer?.cancel();

    // Mark as disposed early to prevent any async operations from continuing
    final was_recording = _recording_state == _RecordingState.recording;
    final was_stopping = _recording_state == _RecordingState.stopping;
    _recording_state = _RecordingState.disposed;

    // If we were recording or stopping, we need to finalize synchronously
    if (was_recording || was_stopping) {
      debugPrint('RevealReactionRecorder: Finalizing recording during dispose...');
      _finalize_recording_on_dispose();
    }

    // Dispose video recorder
    _dispose_video_recorder();

    // Dispose camera controller
    _controller?.dispose();
    _controller = null;

    super.dispose();
  }

  /// Finalize recording during dispose - runs synchronously to ensure callback fires
  void _finalize_recording_on_dispose() {
    // Try to stop recording and get video synchronously if possible
    // For web native recorder, the data might already be available
    if (kIsWeb && _web_video_recorder != null) {
      try {
        final recorder = _web_video_recorder as video_recorder.WebVideoRecorder;
        // If recorder has already stopped and has a URL, use it
        if (recorder.recorded_video_url != null) {
          debugPrint('RevealReactionRecorder: Using existing video URL from web recorder');
          _fire_callback_once(recorder.recorded_video_url);
          return;
        }
        // Otherwise try to stop it (this might not work if already stopping)
        recorder.stop_recording().then((url) {
          _fire_callback_once(url);
        }).catchError((e) {
          debugPrint('RevealReactionRecorder: Error stopping web recorder during dispose: $e');
          _fire_callback_once(null);
        });
      } catch (e) {
        debugPrint('RevealReactionRecorder: Error accessing web recorder during dispose: $e');
        _fire_callback_once(null);
      }
    } else if (_controller != null) {
      // For camera package, try to stop recording
      try {
        _controller!.stopVideoRecording().then((file) {
          _fire_callback_once(file.path);
        }).catchError((e) {
          debugPrint('RevealReactionRecorder: Error stopping camera recording during dispose: $e');
          _fire_callback_once(null);
        });
      } catch (e) {
        debugPrint('RevealReactionRecorder: Error stopping recording during dispose: $e');
        _fire_callback_once(null);
      }
    } else {
      // No recorder available, just fire callback
      _fire_callback_once(null);
    }
  }

  void _dispose_video_recorder() {
    if (_web_video_recorder != null) {
      try {
        (_web_video_recorder as video_recorder.WebVideoRecorder).dispose();
      } catch (e) {
        // Ignore errors during cleanup
      }
      _web_video_recorder = null;
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
            // RepaintBoundary isolates the camera's frequent frame updates
            if (_camera_initialized && _controller != null)
              RepaintBoundary(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: CameraPreview(_controller!),
                ),
              )
            else
              _build_camera_placeholder(),

            // Recording indicator
            if (_is_recording) _build_recording_indicator(),

            // Recording complete indicator
            if (_recording_complete && !_is_recording) _build_recording_complete_indicator(),

            // Login prompt for non-authenticated users
            if (!widget.enable_recording && _camera_initialized) _build_login_prompt(),
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
                    // Pulsing red dot - uses RepaintBoundary to isolate repaints
                    RepaintBoundary(
                      child: _PulsingDot(
                        color: widget.accent_color,
                        isAnimating: _is_recording,
                      ),
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

/// Efficient pulsing dot widget that manages its own animation.
/// Uses SingleTickerProviderStateMixin to avoid rebuilding parent widget.
class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool isAnimating;

  const _PulsingDot({
    required this.color,
    required this.isAnimating,
  });

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_PulsingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isAnimating && oldWidget.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color.withAlpha((255 * _animation.value).round()),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
