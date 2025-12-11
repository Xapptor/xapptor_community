// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
// ignore: deprecated_member_use
import 'dart:html' as html;

/// Find the first video element in the DOM that is playing (camera preview).
html.VideoElement? find_camera_video_element() {
  try {
    // Query all video elements in the document
    final videos = html.document.querySelectorAll('video');
    for (final element in videos) {
      if (element is html.VideoElement) {
        // Check if this video is playing and has a stream (likely the camera)
        if (!element.paused && element.srcObject != null) {
          return element;
        }
      }
    }
    // If no playing video found, return the first video with a stream
    for (final element in videos) {
      if (element is html.VideoElement && element.srcObject != null) {
        return element;
      }
    }
  } catch (e) {
    // Return null on error
  }
  return null;
}

/// Force MP4 recording even if isTypeSupported returns false.
/// Set to true to test MP4 on Safari/iOS.
const bool _force_mp4 = true;

/// Check if MP4 recording is supported by the browser.
/// Uses MediaRecorder.isTypeSupported() static method.
bool is_mp4_recording_supported() {
  // If forcing MP4, always return true to attempt MP4 recording
  if (_force_mp4) return true;

  try {
    // Check for MP4 with H264 codec support
    if (html.MediaRecorder.isTypeSupported('video/mp4;codecs=h264')) {
      return true;
    }
    // Check for basic MP4 support
    if (html.MediaRecorder.isTypeSupported('video/mp4')) {
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}

/// Get the preferred MIME type for recording.
/// Returns MP4 if supported (Chrome 126+) or forced, otherwise WebM.
String get_preferred_mime_type() {
  try {
    // Try MP4 with H264 codec first (best for iOS compatibility)
    if (html.MediaRecorder.isTypeSupported('video/mp4;codecs=h264')) {
      return 'video/mp4;codecs=h264';
    }
    // Try basic MP4
    if (html.MediaRecorder.isTypeSupported('video/mp4')) {
      return 'video/mp4';
    }
    // If forcing MP4, try it anyway (for Safari/iOS testing)
    if (_force_mp4) {
      return 'video/mp4';
    }
  } catch (_) {
    // If forcing MP4, return it even on error
    if (_force_mp4) {
      return 'video/mp4';
    }
  }
  // Fall back to WebM
  return 'video/webm;codecs=vp8,opus';
}

/// Get the file extension for the preferred format.
String get_preferred_extension() {
  return is_mp4_recording_supported() ? 'mp4' : 'webm';
}

/// Get debug info about browser support.
String get_browser_support_info() {
  final mp4_h264 = _safe_is_type_supported('video/mp4;codecs=h264');
  final mp4_basic = _safe_is_type_supported('video/mp4');
  final webm_vp8 = _safe_is_type_supported('video/webm;codecs=vp8,opus');
  final webm_basic = _safe_is_type_supported('video/webm');

  return 'MP4+H264: $mp4_h264, MP4: $mp4_basic, WebM+VP8: $webm_vp8, WebM: $webm_basic, ForceMP4: $_force_mp4';
}

bool _safe_is_type_supported(String mime_type) {
  try {
    return html.MediaRecorder.isTypeSupported(mime_type);
  } catch (e) {
    return false;
  }
}

/// Web-specific video recorder using native MediaRecorder API.
/// Supports MP4 on Chrome 126+ and falls back to WebM on other browsers.
class WebVideoRecorder {
  final html.VideoElement _video_element;
  final Duration _recording_duration;

  html.MediaRecorder? _media_recorder;
  List<html.Blob> _recorded_chunks = [];
  String? _recorded_video_url;
  bool _is_recording = false;
  late String _mime_type;
  late String _file_extension;
  Completer<String?>? _stop_completer;
  Timer? _duration_timer;

  WebVideoRecorder({
    required html.VideoElement video_element,
    Duration? recording_duration,
  })  : _video_element = video_element,
        _recording_duration = recording_duration ?? const Duration(seconds: 10) {
    _mime_type = get_preferred_mime_type();
    _file_extension = get_preferred_extension();
  }

  bool get is_recording => _is_recording;
  String? get recorded_video_url => _recorded_video_url;
  String get mime_type => _mime_type;
  String get file_extension => _file_extension;

  /// Start recording video from the video element's stream.
  Future<void> start_recording() async {
    if (_is_recording) return;

    try {
      // Get the stream from the video element
      final stream = _video_element.captureStream();

      _recorded_chunks = [];
      _recorded_video_url = null;

      // Create MediaRecorder with preferred MIME type
      _media_recorder = html.MediaRecorder(stream, {'mimeType': _mime_type});

      // Handle data available event
      _media_recorder!.addEventListener('dataavailable', (event) {
        final blob_event = event as html.BlobEvent;
        if (blob_event.data != null && blob_event.data!.size > 0) {
          _recorded_chunks.add(blob_event.data!);
        }
      });

      // Handle stop event
      _media_recorder!.addEventListener('stop', (_) {
        _finish_recording();
      });

      // Handle error event
      _media_recorder!.addEventListener('error', (event) {
        _is_recording = false;
        _stop_completer?.complete(null);
        _stop_completer = null;
      });

      // Start recording
      _media_recorder!.start();
      _is_recording = true;

      // Auto-stop after duration
      _duration_timer = Timer(_recording_duration, () {
        stop_recording();
      });
    } catch (e) {
      _is_recording = false;
      rethrow;
    }
  }

  /// Stop recording and return the blob URL of the recorded video.
  /// If already stopped, returns the existing video URL.
  /// If a stop is already in progress, waits for that to complete.
  Future<String?> stop_recording() async {
    // If we already have a recorded URL, return it immediately
    if (_recorded_video_url != null) {
      return _recorded_video_url;
    }

    // If a stop is already in progress, wait for it
    if (_stop_completer != null && !_stop_completer!.isCompleted) {
      return _stop_completer!.future;
    }

    // If not recording, nothing to do
    if (!_is_recording || _media_recorder == null) {
      return _recorded_video_url;
    }

    _duration_timer?.cancel();
    _stop_completer = Completer<String?>();

    try {
      _media_recorder!.stop();
      _is_recording = false;
    } catch (e) {
      _is_recording = false;
      if (!_stop_completer!.isCompleted) {
        _stop_completer!.complete(null);
      }
    }

    return _stop_completer?.future;
  }

  void _finish_recording() {
    if (_recorded_chunks.isEmpty) {
      if (_stop_completer != null && !_stop_completer!.isCompleted) {
        _stop_completer!.complete(null);
      }
      _stop_completer = null;
      return;
    }

    // Create blob from recorded chunks
    final blob = html.Blob(_recorded_chunks, _mime_type);
    _recorded_video_url = html.Url.createObjectUrlFromBlob(blob);

    if (_stop_completer != null && !_stop_completer!.isCompleted) {
      _stop_completer!.complete(_recorded_video_url);
    }
    _stop_completer = null;
  }

  /// Dispose resources.
  void dispose() {
    _duration_timer?.cancel();
    if (_is_recording && _media_recorder != null) {
      try {
        _media_recorder!.stop();
      } catch (_) {}
    }
    _media_recorder = null;
    _recorded_chunks = [];
    // Note: Don't revoke URL here as it may still be needed
  }
}
