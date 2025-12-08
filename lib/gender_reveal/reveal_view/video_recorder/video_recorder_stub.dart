/// Stub implementation for non-web platforms.
/// This file is used when the app runs on mobile/desktop platforms.

/// Find the camera video element (stub - always returns null on non-web).
dynamic find_camera_video_element() => null;

/// Check if MP4 recording is supported (always false on non-web, mobile uses native MP4).
bool is_mp4_recording_supported() => false;

/// Get the preferred MIME type for recording (not used on non-web).
String get_preferred_mime_type() => 'video/mp4';

/// Get the file extension for the preferred format.
String get_preferred_extension() => 'mp4';

/// Get debug info about browser support (stub).
String get_browser_support_info() => 'Non-web platform (native MP4)';

/// Web video recorder stub - does nothing on non-web platforms.
class WebVideoRecorder {
  WebVideoRecorder({
    required dynamic video_element,
    Duration? recording_duration,
  });

  bool get is_recording => false;
  String? get recorded_video_url => null;
  String get mime_type => 'video/mp4';
  String get file_extension => 'mp4';

  Future<void> start_recording() async {}
  Future<String?> stop_recording() async => null;
  void dispose() {}
}
