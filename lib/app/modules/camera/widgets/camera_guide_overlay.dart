import 'package:flutter/material.dart';

class CameraGuideOverlay extends StatelessWidget {
  final double aspectRatio;
  final bool showGuidelines;

  const CameraGuideOverlay({
    super.key,
    this.aspectRatio = 35 / 45,
    this.showGuidelines = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;
        final screenH = constraints.maxHeight;

        // Frame width is ~75% of screen width
        final frameW = screenW * 0.72;
        final frameH = frameW / aspectRatio;

        final left = (screenW - frameW) / 2;
        final top = (screenH - frameH) / 2 - 30;

        return Stack(
          children: [
            // Darkened vignette around crop area
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.55),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    width: frameW,
                    height: frameH,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Frame Outline and Biometric Lines
            Positioned(
              left: left,
              top: top,
              width: frameW,
              height: frameH,
              child: CustomPaint(
                painter: BiometricGuidePainter(showGuidelines: showGuidelines),
              ),
            ),

            // Help instructions overlay
            Positioned(
              top: top - 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Position eyes & chin on guideline markers',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class BiometricGuidePainter extends CustomPainter {
  final bool showGuidelines;

  BiometricGuidePainter({required this.showGuidelines});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Outer Crop Border with rounded corners
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rrect, borderPaint);

    // Corner L-shapes
    final cornerPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const cornerLen = 22.0;
    // Top-Left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLen, 0), cornerPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLen), cornerPaint);
    // Top-Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLen, 0), cornerPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLen), cornerPaint);
    // Bottom-Left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLen, size.height), cornerPaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLen), cornerPaint);
    // Bottom-Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLen, size.height), cornerPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLen), cornerPaint);

    if (!showGuidelines) return;

    final dashedPaint = Paint()
      ..color = Colors.white.withOpacity(0.65)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Face Oval outline
    final faceOvalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.44),
      width: size.width * 0.58,
      height: size.height * 0.60,
    );
    canvas.drawOval(faceOvalRect, dashedPaint);

    // Eye Line (around 42% height)
    final eyeY = size.height * 0.40;
    _drawDashedLine(canvas, Offset(size.width * 0.15, eyeY), Offset(size.width * 0.85, eyeY), dashedPaint);

    // Chin Line (around 72% height)
    final chinY = size.height * 0.74;
    _drawDashedLine(canvas, Offset(size.width * 0.25, chinY), Offset(size.width * 0.75, chinY), dashedPaint);

    // Center Vertical Line
    _drawDashedLine(canvas, Offset(size.width / 2, size.height * 0.1), Offset(size.width / 2, size.height * 0.9), dashedPaint);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = (Offset(dx, dy)).distance;
    final count = (distance / (dashWidth + dashSpace)).floor();
    final unitVector = Offset(dx / distance, dy / distance);

    for (int i = 0; i < count; i++) {
      final start = p1 + unitVector * (i * (dashWidth + dashSpace));
      final end = start + unitVector * dashWidth;
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
