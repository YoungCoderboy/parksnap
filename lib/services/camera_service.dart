import 'package:camera/camera.dart';

/// Manages camera initialization and lifecycle.
class CameraService {
  static List<CameraDescription>? _cameras;

  /// Returns available cameras, cached after first call.
  static Future<List<CameraDescription>> getAvailableCameras() async {
    _cameras ??= await availableCameras();
    return _cameras!;
  }

  /// Returns the first back camera, or first available camera.
  static Future<CameraDescription> getPrimaryCamera() async {
    final cameras = await getAvailableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras available on this device.');
    }
    return cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
  }

  /// Creates and initializes a CameraController.
  /// Caller is responsible for disposing the controller.
  static Future<CameraController> createController({
    CameraDescription? camera,
    ResolutionPreset preset = ResolutionPreset.high,
    bool enableAudio = false,
  }) async {
    final cam = camera ?? await getPrimaryCamera();
    final controller = CameraController(
      cam,
      preset,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller.initialize();
    return controller;
  }
}
