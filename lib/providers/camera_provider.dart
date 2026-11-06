import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../services/camera_service.dart';

enum CameraState { uninitialized, initializing, ready, capturing, error }

/// Manages camera lifecycle, flash toggle, and image capture.
class CameraProvider extends ChangeNotifier {
  CameraController? _controller;
  CameraState _state = CameraState.uninitialized;
  FlashMode _flashMode = FlashMode.off;
  String? _error;
  String? _lastCapturedPath;

  // ─── Getters ────────────────────────────────────────────────────────────────

  CameraController? get controller => _controller;
  CameraState get state => _state;
  FlashMode get flashMode => _flashMode;
  String? get error => _error;
  String? get lastCapturedPath => _lastCapturedPath;
  bool get isReady => _state == CameraState.ready;
  bool get isCapturing => _state == CameraState.capturing;

  // ─── Init ────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_state == CameraState.initializing || _state == CameraState.ready) {
      return;
    }
    _setState(CameraState.initializing);
    try {
      await _controller?.dispose();
      _controller = await CameraService.createController();
      await _controller!.setFlashMode(_flashMode);
      _error = null;
      _setState(CameraState.ready);
    } catch (e) {
      _error = e.toString();
      _setState(CameraState.error);
    }
  }

  // ─── Flash ───────────────────────────────────────────────────────────────────

  Future<void> toggleFlash() async {
    if (_controller == null || !isReady) return;
    _flashMode =
        _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await _controller!.setFlashMode(_flashMode);
    notifyListeners();
  }

  // ─── Capture ─────────────────────────────────────────────────────────────────

  /// Captures an image, saves it to app documents directory, and returns the path.
  Future<String?> captureImage() async {
    if (_controller == null || !isReady) return null;
    _setState(CameraState.capturing);
    try {
      // Turn off torch before capture to avoid overexposure on some devices
      if (_flashMode == FlashMode.torch) {
        await _controller!.setFlashMode(FlashMode.always);
      }

      final xFile = await _controller!.takePicture();

      // Restore flash mode
      await _controller!.setFlashMode(_flashMode);

      // Save to permanent location
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          'parksnap_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = p.join(dir.path, 'snaps', fileName);
      await Directory(p.dirname(savedPath)).create(recursive: true);
      await File(xFile.path).copy(savedPath);

      _lastCapturedPath = savedPath;
      _setState(CameraState.ready);
      return savedPath;
    } catch (e) {
      _error = 'Capture failed: $e';
      _setState(CameraState.error);
      return null;
    }
  }

  // ─── Dispose ─────────────────────────────────────────────────────────────────

  void pauseCamera() {
    _controller?.pausePreview();
  }

  void resumeCamera() {
    _controller?.resumePreview();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _setState(CameraState s) {
    _state = s;
    notifyListeners();
  }
}
