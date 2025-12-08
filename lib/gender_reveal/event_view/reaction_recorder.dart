import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class ReactionRecorder extends StatefulWidget {
  final double border_radius;

  const ReactionRecorder({
    super.key,
    this.border_radius = 20,
  });

  @override
  State<ReactionRecorder> createState() => _ReactionRecorderState();
}

class _ReactionRecorderState extends State<ReactionRecorder> {
  List<CameraDescription> _cameras = [];
  CameraController? controller;

  bool camera_permission_granted = false;
  bool _camera_initialization_attempted = false;
  int countdown_seconds = 7;

  /// Initialize camera only once and only when first build occurs.
  /// Uses ResolutionPreset.low to minimize memory usage on web.
  /// CRITICAL: Camera uses 5-10MB on web - delay init to reduce memory pressure.
  Future<void> _initialize_camera_if_needed() async {
    if (_camera_initialization_attempted) return;
    _camera_initialization_attempted = true;

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty || !mounted) return;

      // Use LOW resolution to minimize memory on web
      // Medium resolution uses ~3x more GPU memory
      controller = CameraController(
        _cameras[0],
        ResolutionPreset.low,
      );

      await controller!.initialize();
      if (!mounted) return;
      setState(() {
        camera_permission_granted = true;
      });
    } on CameraException catch (e) {
      if (e.code == 'CameraAccessDenied') {
        // Handle access errors here.
      } else {
        // Handle other errors here.
      }
    } catch (e) {
      debugPrint('ReactionRecorder: Error initializing camera: $e');
    }
  }

  void update_countdown() {
    if (countdown_seconds > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() {
          countdown_seconds--;
        });
        update_countdown();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Delay camera initialization to first build
    // This allows widget to be constructed without immediately consuming memory
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Initialize camera only on first build (delayed initialization)
    // This prevents memory allocation until widget is actually visible
    if (!_camera_initialization_attempted) {
      _initialize_camera_if_needed();
    }

    if (!camera_permission_granted || controller == null || !controller!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.border_radius),
      child: CameraPreview(
        controller!,
        child: Stack(
          children: [
            if (countdown_seconds > 0 && countdown_seconds < 8)
              Align(
                alignment: Alignment.center,
                child: Text(
                  countdown_seconds.toString(),
                  style: TextStyle(
                    color: Colors.white.withAlpha(255 - (countdown_seconds * -32)),
                    fontSize: 150,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Container(
              alignment: Alignment.bottomCenter,
              margin: const EdgeInsets.only(bottom: 60),
              child: FilledButton(
                onPressed: () {
                  setState(() {
                    countdown_seconds = 7;
                  });
                  update_countdown();
                },
                child: const Text("Capture"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
