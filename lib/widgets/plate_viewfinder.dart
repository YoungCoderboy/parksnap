import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Custom painter that draws the license-plate targeting reticle overlay.
class PlateViewfinder extends StatefulWidget {
  const PlateViewfinder({super.key});

  @override
  State<PlateViewfinder> createState() => _PlateViewfinderState();
}

class _PlateViewfinderState extends State<PlateViewfinder>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark scrim outside the viewfinder rectangle
        CustomPaint(
          painter: _ScrimpPainter(),
          size: Size.infinite,
        ),
        // Corner bracket overlay + scan bar
        AnimatedBuilder(
          animation: _scanAnimation,
          builder: (context, _) {
            return CustomPaint(
              painter: _ReticlePainter(scanProgress: _scanAnimation.value),
              size: Size.infinite,
            );
          },
        ),
        // Label text
        Align(
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset(
                0, MediaQuery.of(context).size.height * 0.18),
            child: Text(
              'ALIGN PLATE WITHIN GUIDE',
              style: AppTheme.labelSm.copyWith(
                color: AppTheme.primary.withValues(alpha: 0.85),
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints a semi-transparent scrim with a cutout rectangle for the plate area.
class _ScrimpPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final frameRect = _getFrameRect(size);

    // Draw four rects around the frame cutout
    canvas.drawRect(
        Rect.fromLTRB(0, 0, size.width, frameRect.top), paint);
    canvas.drawRect(
        Rect.fromLTRB(0, frameRect.bottom, size.width, size.height), paint);
    canvas.drawRect(
        Rect.fromLTRB(0, frameRect.top, frameRect.left, frameRect.bottom),
        paint);
    canvas.drawRect(
        Rect.fromLTRB(
            frameRect.right, frameRect.top, size.width, frameRect.bottom),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints the corner brackets and horizontal scan bar.
class _ReticlePainter extends CustomPainter {
  final double scanProgress;
  _ReticlePainter({required this.scanProgress});

  static const _bracketLength = 32.0;
  static const _bracketThickness = 3.0;
  static const _cornerRadius = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final frameRect = _getFrameRect(size);
    final bracketPaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = _bracketThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    // Draw four corner brackets
    _drawCorners(canvas, frameRect, bracketPaint);

    // Scan bar
    final scanY = frameRect.top + (frameRect.height * scanProgress);
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.primary.withValues(alpha: 0),
          AppTheme.primary.withValues(alpha: 0.85),
          AppTheme.primary.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(
          frameRect.left, scanY - 1, frameRect.width, 2));
    canvas.drawLine(
      Offset(frameRect.left + 8, scanY),
      Offset(frameRect.right - 8, scanY),
      scanPaint..strokeWidth = 2,
    );
  }

  void _drawCorners(Canvas canvas, Rect rect, Paint paint) {
    final corners = [
      // Top-left
      [
        Offset(rect.left, rect.top + _bracketLength),
        Offset(rect.left, rect.top),
        Offset(rect.left + _bracketLength, rect.top),
      ],
      // Top-right
      [
        Offset(rect.right - _bracketLength, rect.top),
        Offset(rect.right, rect.top),
        Offset(rect.right, rect.top + _bracketLength),
      ],
      // Bottom-left
      [
        Offset(rect.left, rect.bottom - _bracketLength),
        Offset(rect.left, rect.bottom),
        Offset(rect.left + _bracketLength, rect.bottom),
      ],
      // Bottom-right
      [
        Offset(rect.right - _bracketLength, rect.bottom),
        Offset(rect.right, rect.bottom),
        Offset(rect.right, rect.bottom - _bracketLength),
      ],
    ];

    for (final corner in corners) {
      final path = Path()
        ..moveTo(corner[0].dx, corner[0].dy)
        ..lineTo(corner[1].dx, corner[1].dy)
        ..lineTo(corner[2].dx, corner[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter oldDelegate) =>
      oldDelegate.scanProgress != scanProgress;
}

/// Returns the plate-sized targeting rectangle centered on screen.
Rect _getFrameRect(Size size) {
  const aspectRatio = 4.5; // typical license plate aspect ratio
  final frameWidth = size.width * 0.82;
  final frameHeight = frameWidth / aspectRatio;
  final left = (size.width - frameWidth) / 2;
  final top = (size.height - frameHeight) / 2 - size.height * 0.05;
  return Rect.fromLTWH(left, top, frameWidth, frameHeight);
}
