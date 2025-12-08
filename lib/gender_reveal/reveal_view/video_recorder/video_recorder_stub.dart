/// Stub implementation for non-web platforms.
/// This file is used when the app runs on mobile/desktop platforms.

/// Find the camera video element (stub - always returns null on non-web).
dynamic findCameraVideoElement() => null;

/// Check if MP4 recording is supported (always false on non-web, mobile uses native MP4).
bool isMP4RecordingSupported() => false;

/// Get the preferred MIME type for recording (not used on non-web).
String getPreferredMimeType() => 'video/mp4';

/// Get the file extension for the preferred format.
String getPreferredExtension() => 'mp4';

/// Get debug info about browser support (stub).
String getBrowserSupportInfo() => 'Non-web platform (native MP4)';

/// Web video recorder stub - does nothing on non-web platforms.
class WebVideoRecorder {
  WebVideoRecorder({
    required dynamic videoElement,
    Duration? recordingDuration,
  });

  bool get isRecording => false;
  String? get recordedVideoUrl => null;
  String get mimeType => 'video/mp4';
  String get fileExtension => 'mp4';

  Future<void> startRecording() async {}
  Future<String?> stopRecording() async => null;
  void dispose() {}
}
