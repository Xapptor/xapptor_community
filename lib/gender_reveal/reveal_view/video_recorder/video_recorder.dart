/// Conditional export for video recorder.
/// Uses web implementation on web, stub on other platforms.
export 'video_recorder_stub.dart'
    if (dart.library.html) 'video_recorder_web.dart';
