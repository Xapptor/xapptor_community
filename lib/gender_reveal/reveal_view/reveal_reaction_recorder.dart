import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/reveal_constants.dart';
import 'package:xapptor_community/gender_reveal/reveal_view/video_recorder/video_recorder.dart'
    as video_recorder;

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

  // Web-specific: native MediaRecorder for MP4 support on Chrome
  dynamic _web_video_recorder;
  bool _use_native_video_recorder = false;

  // Track the actual format used for recording
  String _actual_recording_format = 'mp4'; // 'mp4' or 'webm'

  @override
  void initState() {
    super.initState();
    // On web, check if MP4 recording is supported (Chrome 126+)
    // If so, we'll use native MediaRecorder for iOS-compatible videos
    if (kIsWeb) {
      _use_native_video_recorder = video_recorder.isMP4RecordingSupported();
      debugPrint(
        'RevealReactionRecorder: MP4 support=$_use_native_video_recorder, '
        'format=${video_recorder.getPreferredExtension()}, '
        'mimeType=${video_recorder.getPreferredMimeType()}',
      );
      debugPrint('RevealReactionRecorder: Browser support: ${video_recorder.getBrowserSupportInfo()}');
    }
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
  /// On web with MP4 support (Chrome 126+), uses native MediaRecorder.
  /// Otherwise, uses the camera package's recorder.
  Future<void> _start_recording() async {
    if (!mounted || !_camera_initialized || _controller == null) return;
    if (_is_recording || _recording_complete) return;
    if (!widget.enable_recording) return;

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
          _actual_recording_format = video_recorder.getPreferredExtension();
        }
      } else {
        // Camera package: WebM on web, MP4 on mobile
        _actual_recording_format = kIsWeb ? 'webm' : 'mp4';
        await _controller!.startVideoRecording();
      }

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

      // Schedule recording stop (only if not using web native recorder, which handles its own duration)
      if (!kIsWeb || !_use_native_video_recorder || _web_video_recorder == null) {
        _recording_timer = Timer(widget.recording_duration, _stop_recording);
      }
    } catch (e) {
      debugPrint('RevealReactionRecorder: Error starting recording: $e');
      widget.on_recording_complete?.call(null, _actual_recording_format);
    }
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
        videoElement: video_element,
        recordingDuration: widget.recording_duration,
      );

      await (_web_video_recorder as video_recorder.WebVideoRecorder).startRecording();
      debugPrint('RevealReactionRecorder: Started native web recording (${video_recorder.getPreferredExtension()})');
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
      return video_recorder.findCameraVideoElement();
    } catch (e) {
      debugPrint('RevealReactionRecorder: Error getting video element: $e');
      return null;
    }
  }

  /// Stop video recording and save the file.
  Future<void> _stop_recording() async {
    _progress_timer?.cancel();
    _recording_timer?.cancel();

    if (!mounted || _controller == null || !_is_recording) return;

    try {
      String? video_path;

      // Check if we're using native web recorder
      if (kIsWeb && _web_video_recorder != null) {
        video_path = await _stop_web_native_recording();
      } else {
        final XFile video_file = await _controller!.stopVideoRecording();
        video_path = video_file.path;
      }

      if (!mounted) return;

      setState(() {
        _is_recording = false;
        _recording_complete = true;
        _video_path = video_path;
        _recording_progress = 1.0;
      });

      widget.on_recording_complete?.call(video_path, _actual_recording_format);
    } catch (e) {
      debugPrint('RevealReactionRecorder: Error stopping recording: $e');
      setState(() {
        _is_recording = false;
        _recording_complete = true;
      });
      widget.on_recording_complete?.call(null, _actual_recording_format);
    }
  }

  /// Stop native web recording and return the video URL.
  Future<String?> _stop_web_native_recording() async {
    if (_web_video_recorder == null) return null;

    try {
      final recorder = _web_video_recorder as video_recorder.WebVideoRecorder;
      final video_url = await recorder.stopRecording();

      if (video_url != null) {
        debugPrint(
          'RevealReactionRecorder: Native web recording complete '
          '(${recorder.fileExtension}): $video_url',
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
    _recording_timer?.cancel();
    _start_delay_timer?.cancel();
    _progress_timer?.cancel();
    _stop_recording_if_needed();
    _dispose_video_recorder();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _stop_recording_if_needed() async {
    if (_is_recording && _controller != null) {
      try {
        if (kIsWeb && _web_video_recorder != null) {
          await (_web_video_recorder as video_recorder.WebVideoRecorder).stopRecording();
        } else {
          await _controller!.stopVideoRecording();
        }
      } catch (e) {
        // Ignore errors during cleanup
      }
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
