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
  int countdown_seconds = 7;

  Future<void> get_cameras() async {
    _cameras = await availableCameras();

    controller = CameraController(
      _cameras[0],
      ResolutionPreset.medium,
    );

    try {
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
    get_cameras();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
