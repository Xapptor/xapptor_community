// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
// ignore: deprecated_member_use
import 'dart:html' as html;

/// Find the first video element in the DOM that is playing (camera preview).
html.VideoElement? findCameraVideoElement() {
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
const bool _forceMP4 = true;

/// Check if MP4 recording is supported by the browser.
/// Uses MediaRecorder.isTypeSupported() static method.
bool isMP4RecordingSupported() {
  // If forcing MP4, always return true to attempt MP4 recording
  if (_forceMP4) return true;

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

/// Check if browser actually reports MP4 support (for logging).
bool _browserReportsMP4Support() {
  try {
    if (html.MediaRecorder.isTypeSupported('video/mp4;codecs=h264')) {
      return true;
    }
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
String getPreferredMimeType() {
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
    if (_forceMP4) {
      return 'video/mp4';
    }
  } catch (_) {
    // If forcing MP4, return it even on error
    if (_forceMP4) {
      return 'video/mp4';
    }
  }
  // Fall back to WebM
  return 'video/webm;codecs=vp8,opus';
}

/// Get the file extension for the preferred format.
String getPreferredExtension() {
  return isMP4RecordingSupported() ? 'mp4' : 'webm';
}

/// Get debug info about browser support.
String getBrowserSupportInfo() {
  final mp4H264 = _safeIsTypeSupported('video/mp4;codecs=h264');
  final mp4Basic = _safeIsTypeSupported('video/mp4');
  final webmVp8 = _safeIsTypeSupported('video/webm;codecs=vp8,opus');
  final webmBasic = _safeIsTypeSupported('video/webm');

  return 'MP4+H264: $mp4H264, MP4: $mp4Basic, WebM+VP8: $webmVp8, WebM: $webmBasic, ForceMP4: $_forceMP4';
}

bool _safeIsTypeSupported(String mimeType) {
  try {
    return html.MediaRecorder.isTypeSupported(mimeType);
  } catch (e) {
    return false;
  }
}

/// Web-specific video recorder using native MediaRecorder API.
/// Supports MP4 on Chrome 126+ and falls back to WebM on other browsers.
class WebVideoRecorder {
  final html.VideoElement _videoElement;
  final Duration _recordingDuration;

  html.MediaRecorder? _mediaRecorder;
  List<html.Blob> _recordedChunks = [];
  String? _recordedVideoUrl;
  bool _isRecording = false;
  late String _mimeType;
  late String _fileExtension;
  Completer<String?>? _stopCompleter;
  Timer? _durationTimer;

  WebVideoRecorder({
    required html.VideoElement videoElement,
    Duration? recordingDuration,
  })  : _videoElement = videoElement,
        _recordingDuration = recordingDuration ?? const Duration(seconds: 10) {
    _mimeType = getPreferredMimeType();
    _fileExtension = getPreferredExtension();
  }

  bool get isRecording => _isRecording;
  String? get recordedVideoUrl => _recordedVideoUrl;
  String get mimeType => _mimeType;
  String get fileExtension => _fileExtension;

  /// Start recording video from the video element's stream.
  Future<void> startRecording() async {
    if (_isRecording) return;

    try {
      // Get the stream from the video element
      final stream = _videoElement.captureStream();

      _recordedChunks = [];
      _recordedVideoUrl = null;

      // Create MediaRecorder with preferred MIME type
      _mediaRecorder = html.MediaRecorder(stream, {'mimeType': _mimeType});

      // Handle data available event
      _mediaRecorder!.addEventListener('dataavailable', (event) {
        final blobEvent = event as html.BlobEvent;
        if (blobEvent.data != null && blobEvent.data!.size > 0) {
          _recordedChunks.add(blobEvent.data!);
        }
      });

      // Handle stop event
      _mediaRecorder!.addEventListener('stop', (_) {
        _finishRecording();
      });

      // Handle error event
      _mediaRecorder!.addEventListener('error', (event) {
        _isRecording = false;
        _stopCompleter?.complete(null);
        _stopCompleter = null;
      });

      // Start recording
      _mediaRecorder!.start();
      _isRecording = true;

      // Auto-stop after duration
      _durationTimer = Timer(_recordingDuration, () {
        stopRecording();
      });
    } catch (e) {
      _isRecording = false;
      rethrow;
    }
  }

  /// Stop recording and return the blob URL of the recorded video.
  Future<String?> stopRecording() async {
    if (!_isRecording || _mediaRecorder == null) {
      return _recordedVideoUrl;
    }

    _durationTimer?.cancel();
    _stopCompleter = Completer<String?>();

    try {
      _mediaRecorder!.stop();
      _isRecording = false;
    } catch (e) {
      _isRecording = false;
      _stopCompleter?.complete(null);
    }

    return _stopCompleter?.future;
  }

  void _finishRecording() {
    if (_recordedChunks.isEmpty) {
      _stopCompleter?.complete(null);
      _stopCompleter = null;
      return;
    }

    // Create blob from recorded chunks
    final blob = html.Blob(_recordedChunks, _mimeType);
    _recordedVideoUrl = html.Url.createObjectUrlFromBlob(blob);
    _stopCompleter?.complete(_recordedVideoUrl);
    _stopCompleter = null;
  }

  /// Dispose resources.
  void dispose() {
    _durationTimer?.cancel();
    if (_isRecording && _mediaRecorder != null) {
      try {
        _mediaRecorder!.stop();
      } catch (_) {}
    }
    _mediaRecorder = null;
    _recordedChunks = [];
    // Note: Don't revoke URL here as it may still be needed
  }
}
