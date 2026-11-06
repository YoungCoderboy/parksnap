import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/camera_provider.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import '../widgets/plate_viewfinder.dart';
import 'verify_confirm_screen.dart';

/// Screen 2: Full-screen camera viewfinder with plate guide and capture controls.
class CameraScannerScreen extends StatefulWidget {
  final String apiKey;

  const CameraScannerScreen({super.key, required this.apiKey});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraProvider>().initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camProvider = context.read<CameraProvider>();
    if (state == AppLifecycleState.paused) {
      camProvider.pauseCamera();
    } else if (state == AppLifecycleState.resumed) {
      camProvider.resumeCamera();
    }
  }

  Future<void> _capture() async {
    final camProvider = context.read<CameraProvider>();
    final imagePath = await camProvider.captureImage();

    if (imagePath == null || !mounted) return;

    // Show processing overlay and call Gemini
    _showProcessingOverlay();

    final gemini = GeminiService(widget.apiKey);
    String? errorMsg;
    dynamic result;

    try {
      result = await gemini.extractVehicleData(imagePath);
    } catch (e) {
      errorMsg = e.toString().replaceFirst('GeminiException: ', '');
    }

    if (!mounted) return;
    Navigator.of(context).pop(); // dismiss processing overlay

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerifyConfirmScreen(
          imagePath: imagePath,
          geminiResult: result,
          geminiError: errorMsg,
        ),
      ),
    );
  }

  void _showProcessingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 20),
              Text(
                'ANALYZING PLATE...',
                style: AppTheme.labelLg.copyWith(
                  color: AppTheme.primary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text('Gemini 2.5 Flash', style: AppTheme.bodyMd),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<CameraProvider>(
        builder: (ctx, camProvider, _) {
          if (camProvider.state == CameraState.initializing) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (camProvider.state == CameraState.error) {
            return _CameraErrorView(error: camProvider.error ?? 'Unknown error');
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // Camera preview
              if (camProvider.isReady && camProvider.controller != null)
                _buildCameraPreview(camProvider.controller!),

              // Viewfinder overlay
              const PlateViewfinder(),

              // Top bar
              _buildTopBar(camProvider),

              // Bottom controls
              _buildBottomBar(camProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCameraPreview(CameraController controller) {
    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildTopBar(CameraProvider camProvider) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Back
              _IconCircleButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
              // Flash toggle
              _IconCircleButton(
                icon: camProvider.flashMode == FlashMode.off
                    ? Icons.flash_off_rounded
                    : Icons.flash_on_rounded,
                onTap: camProvider.isReady
                    ? () => camProvider.toggleFlash()
                    : null,
                color: camProvider.flashMode == FlashMode.off
                    ? Colors.white
                    : AppTheme.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(CameraProvider camProvider) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.85),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TAP TO CAPTURE',
                style: AppTheme.labelSm.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              // Shutter button
              GestureDetector(
                onTap: camProvider.isReady && !camProvider.isCapturing
                    ? _capture
                    : null,
                child: _ShutterButton(isCapturing: camProvider.isCapturing),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final bool isCapturing;
  const _ShutterButton({required this.isCapturing});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCapturing
            ? AppTheme.primaryContainer.withValues(alpha: 0.7)
            : AppTheme.primaryContainer,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryContainer.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: isCapturing
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: AppTheme.primaryContainer,
                  strokeWidth: 2.5,
                ),
              )
            : null,
      ),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _IconCircleButton({
    required this.icon,
    this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  final String error;
  const _CameraErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.no_photography_rounded,
                  color: AppTheme.outline, size: 56),
              const SizedBox(height: 16),
              Text('Camera Unavailable', style: AppTheme.headlineSm),
              const SizedBox(height: 8),
              Text(
                error,
                style: AppTheme.bodyMd,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('GO BACK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
