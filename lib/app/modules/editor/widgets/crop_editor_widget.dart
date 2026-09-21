import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/editor_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/outfit_painter.dart';
import '../../../../data/models/outfit_template.dart';

class CropEditorWidget extends StatefulWidget {
  const CropEditorWidget({super.key});

  @override
  State<CropEditorWidget> createState() => _CropEditorWidgetState();
}

class _CropEditorWidgetState extends State<CropEditorWidget> {
  final EditorController controller = Get.find<EditorController>();
  final TransformationController _transformController = TransformationController();
  double _viewportW = 0;
  double _viewportH = 0;
  double _frameW = 0;
  double _frameH = 0;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformationChanged);
  }

  void _onTransformationChanged() {
    final matrix = _transformController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final translation = matrix.getTranslation();

    controller.zoomScale.value = scale;
    controller.panOffsetX.value = translation.x;
    controller.panOffsetY.value = translation.y;

    _calculateNormalizedCrop();
  }

  void _calculateNormalizedCrop() {
    if (_viewportW <= 0 || _viewportH <= 0 || _frameW <= 0 || _frameH <= 0) return;

    final matrix = _transformController.value;
    final scale = matrix.getMaxScaleOnAxis().clamp(0.5, 6.0);
    final translation = matrix.getTranslation();

    final targetAspectRatio = controller.photoSize.aspectRatio;
    final containerAspect = _viewportW / _viewportH;
    double baseDisplayW;
    double baseDisplayH;

    if (targetAspectRatio > containerAspect) {
      baseDisplayW = _viewportW;
      baseDisplayH = _viewportW / targetAspectRatio;
    } else {
      baseDisplayH = _viewportH;
      baseDisplayW = _viewportH * targetAspectRatio;
    }

    final baseLeft = (_viewportW - baseDisplayW) / 2.0;
    final baseTop = (_viewportH - baseDisplayH) / 2.0;

    final frameLeft = (_viewportW - _frameW) / 2.0;
    final frameTop = (_viewportH - _frameH) / 2.0;
    final frameRight = frameLeft + _frameW;
    final frameBottom = frameTop + _frameH;

    final double normLeft = ((frameLeft - translation.x - baseLeft) / (baseDisplayW * scale)).clamp(0.0, 1.0);
    final double normTop = ((frameTop - translation.y - baseTop) / (baseDisplayH * scale)).clamp(0.0, 1.0);
    final double normRight = ((frameRight - translation.x - baseLeft) / (baseDisplayW * scale)).clamp(0.0, 1.0);
    final double normBottom = ((frameBottom - translation.y - baseTop) / (baseDisplayH * scale)).clamp(0.0, 1.0);

    final double normW = (normRight - normLeft).clamp(0.05, 1.0);
    final double normH = (normBottom - normTop).clamp(0.05, 1.0);

    controller.updateCropBounds(
      normX: normLeft,
      normY: normTop,
      normW: normW,
      normH: normH,
    );
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformationChanged);
    _transformController.dispose();
    super.dispose();
  }

  Widget _buildCustomOutfitOverlay(OutfitTemplate outfit) {
    final cfg = controller.outfitTransform.value;
    return Transform.translate(
      offset: Offset(cfg.panX, cfg.panY),
      child: Transform.scale(
        scale: cfg.scale,
        child: Transform.flip(
          flipX: cfg.flipHorizontal,
          child: Image.file(
            File(outfit.customImagePath!),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportW = constraints.maxWidth;
        _viewportH = constraints.maxHeight;

        final targetAspectRatio = controller.photoSize.aspectRatio;
        _frameW = _viewportW * 0.78;
        _frameH = _frameW / targetAspectRatio;

        if (_frameH > _viewportH * 0.85) {
          _frameH = _viewportH * 0.85;
          _frameW = _frameH * targetAspectRatio;
        }

        final frameW = _frameW;
        final frameH = _frameH;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _calculateNormalizedCrop();
        });

        return Stack(
          alignment: Alignment.center,
          children: [
            // Transformable Image Viewport
            Positioned.fill(
              child: Obx(
                () {
                  final isAuto = controller.isAutoResultMode.value;
                  final cutoutPath = controller.autoCutoutPath.value;
                  final displayFile = (isAuto && cutoutPath.isNotEmpty && File(cutoutPath).existsSync())
                      ? File(cutoutPath)
                      : File(controller.sourceImagePath);

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateZ(controller.rotationDegrees.value * 3.1415926535 / 180)
                      ..scale(controller.flipHorizontal.value ? -1.0 : 1.0, 1.0),
                    child: InteractiveViewer(
                      transformationController: _transformController,
                      minScale: 0.8,
                      maxScale: 4.0,
                      boundaryMargin: const EdgeInsets.all(200),
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.file(
                              displayFile,
                              fit: BoxFit.contain,
                            ),
                            // Outfit Overlay (Vector or Custom Extracted PNG)
                            if (controller.selectedOutfit.value != null)
                              Positioned.fill(
                                child: controller.selectedOutfit.value!.isCustomImage &&
                                        controller.selectedOutfit.value!.customImagePath != null
                                    ? _buildCustomOutfitOverlay(controller.selectedOutfit.value!)
                                    : CustomPaint(
                                        painter: OutfitPainter(
                                          outfit: controller.selectedOutfit.value!,
                                          config: controller.outfitTransform.value,
                                          faceRect: controller.segmentationResult.value?.primaryFaceRect,
                                        ),
                                      ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Semi-transparent cutout mask outside the crop frame
            IgnorePointer(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.6),
                  BlendMode.srcOut,
                ),
                child: Stack(
                  children: [
                    Container(decoration: const BoxDecoration(color: Colors.transparent)),
                    Center(
                      child: Container(
                        width: frameW,
                        height: frameH,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Biometric Crop Guide Frame
            IgnorePointer(
              child: SizedBox(
                width: frameW,
                height: frameH,
                child: Obx(
                  () => CustomPaint(
                    painter: BiometricEditorGuidePainter(
                      showGuidelines: controller.showGuidelines.value,
                    ),
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

class BiometricEditorGuidePainter extends CustomPainter {
  final bool showGuidelines;

  BiometricEditorGuidePainter({required this.showGuidelines});

  @override
  void paint(Canvas canvas, Size size) {
    // Outer border
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), borderPaint);

    // Corner guides
    final cornerPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const len = 20.0;
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), cornerPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, len), cornerPaint);

    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), cornerPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), cornerPaint);

    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), cornerPaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), cornerPaint);

    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - len, size.height), cornerPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - len), cornerPaint);

    if (!showGuidelines) return;

    final guidePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Face oval
    final faceOvalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.44),
      width: size.width * 0.58,
      height: size.height * 0.60,
    );
    canvas.drawOval(faceOvalRect, guidePaint);

    // Eye line (42%)
    final eyeY = size.height * 0.40;
    _drawDashedLine(canvas, Offset(size.width * 0.1, eyeY), Offset(size.width * 0.9, eyeY), guidePaint);

    // Chin line (74%)
    final chinY = size.height * 0.74;
    _drawDashedLine(canvas, Offset(size.width * 0.2, chinY), Offset(size.width * 0.8, chinY), guidePaint);

    // Center vertical line
    _drawDashedLine(canvas, Offset(size.width / 2, size.height * 0.08), Offset(size.width / 2, size.height * 0.92), guidePaint);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final dist = (Offset(dx, dy)).distance;
    final count = (dist / (dashWidth + dashSpace)).floor();
    final unitVector = Offset(dx / dist, dy / dist);

    for (int i = 0; i < count; i++) {
      final start = p1 + unitVector * (i * (dashWidth + dashSpace));
      final end = start + unitVector * dashWidth;
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
