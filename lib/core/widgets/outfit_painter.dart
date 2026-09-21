import 'package:flutter/material.dart';
import '../../data/models/outfit_template.dart';
import '../services/outfit_renderer_service.dart';

class OutfitPainter extends CustomPainter {
  final OutfitTemplate outfit;
  final OutfitTransformConfig config;
  final Rect? faceRect;

  OutfitPainter({
    required this.outfit,
    required this.config,
    this.faceRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    OutfitRendererService.drawOutfit(
      canvas,
      size,
      outfit,
      config,
      faceRect: faceRect,
    );
  }

  @override
  bool shouldRepaint(covariant OutfitPainter oldDelegate) {
    return oldDelegate.outfit != outfit ||
        oldDelegate.config.scale != config.scale ||
        oldDelegate.config.panX != config.panX ||
        oldDelegate.config.panY != config.panY ||
        oldDelegate.config.rotationDegrees != config.rotationDegrees ||
        oldDelegate.config.shoulderWidthScale != config.shoulderWidthScale ||
        oldDelegate.config.neckDepthScale != config.neckDepthScale ||
        oldDelegate.config.flipHorizontal != config.flipHorizontal;
  }
}
