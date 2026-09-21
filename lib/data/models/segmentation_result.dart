import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class SegmentationMaskData {
  final int width;
  final int height;
  final Float32List confidences;

  SegmentationMaskData({
    required this.width,
    required this.height,
    required this.confidences,
  });

  double getConfidence(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0.0;
    return confidences[y * width + x];
  }

  /// Photoshop-style Subpixel Bilinear Mask Sampling
  double getBilinearConfidence(double normX, double normY) {
    final fx = (normX.clamp(0.0, 1.0) * (width - 1));
    final fy = (normY.clamp(0.0, 1.0) * (height - 1));

    final x0 = fx.floor();
    final y0 = fy.floor();
    final x1 = min(width - 1, x0 + 1);
    final y1 = min(height - 1, y0 + 1);

    final dx = fx - x0;
    final dy = fy - y0;

    final c00 = getConfidence(x0, y0);
    final c10 = getConfidence(x1, y0);
    final c01 = getConfidence(x0, y1);
    final c11 = getConfidence(x1, y1);

    final top = c00 * (1.0 - dx) + c10 * dx;
    final bottom = c01 * (1.0 - dx) + c11 * dx;

    return top * (1.0 - dy) + bottom * dy;
  }

  /// Multi-tap Gaussian Edge Feather Sampling
  double getFeatheredConfidence(double normX, double normY, double radiusNorm) {
    if (radiusNorm <= 0.001) {
      return getBilinearConfidence(normX, normY);
    }

    // 5-tap separable gaussian kernel weights [0.06, 0.24, 0.40, 0.24, 0.06]
    const weights = [0.06, 0.24, 0.40, 0.24, 0.06];
    const offsets = [-2.0, -1.0, 0.0, 1.0, 2.0];

    double totalConfidence = 0.0;

    for (int y = 0; y < 5; y++) {
      for (int x = 0; x < 5; x++) {
        final sampleX = normX + (offsets[x] * radiusNorm);
        final sampleY = normY + (offsets[y] * radiusNorm * (width / height));
        final conf = getBilinearConfidence(sampleX, sampleY);
        final weight = weights[x] * weights[y];
        totalConfidence += conf * weight;
      }
    }

    return totalConfidence.clamp(0.0, 1.0);
  }

  void setConfidence(int x, int y, double value) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      confidences[y * width + x] = value.clamp(0.0, 1.0);
    }
  }

  /// Create a deep clone of this mask
  SegmentationMaskData clone() {
    return SegmentationMaskData(
      width: width,
      height: height,
      confidences: Float32List.fromList(confidences),
    );
  }

  /// Create an empty mask with 0.0 confidence
  static SegmentationMaskData empty(int width, int height) {
    return SegmentationMaskData(
      width: width,
      height: height,
      confidences: Float32List(width * height),
    );
  }

  /// Apply brush stroke at normalized position (0.0 .. 1.0)
  void applyBrushStroke({
    required double normX,
    required double normY,
    required double normRadius,
    required bool isAdd,
    double feather = 0.25,
  }) {
    final centerX = normX * width;
    final centerY = normY * height;
    final radiusPx = normRadius * width;
    final radiusSq = radiusPx * radiusPx;

    final minX = max(0, (centerX - radiusPx).floor());
    final maxX = min(width - 1, (centerX + radiusPx).ceil());
    final minY = max(0, (centerY - radiusPx).floor());
    final maxY = min(height - 1, (centerY + radiusPx).ceil());

    for (int y = minY; y <= maxY; y++) {
      for (int x = minX; x <= maxX; x++) {
        final dx = x - centerX;
        final dy = y - centerY;
        final distSq = dx * dx + dy * dy;

        if (distSq <= radiusSq) {
          final dist = sqrt(distSq);
          final innerRadius = radiusPx * (1.0 - feather);

          double factor = 1.0;
          if (dist > innerRadius && radiusPx > innerRadius) {
            factor = 1.0 - ((dist - innerRadius) / (radiusPx - innerRadius));
            factor = factor * factor * (3.0 - 2.0 * factor); // smoothstep
          }

          final currentIndex = y * width + x;
          final currentVal = confidences[currentIndex];

          if (isAdd) {
            final targetVal = currentVal + (1.0 - currentVal) * factor;
            confidences[currentIndex] = max(currentVal, targetVal).clamp(0.0, 1.0);
          } else {
            final targetVal = currentVal * (1.0 - factor);
            confidences[currentIndex] = min(currentVal, targetVal).clamp(0.0, 1.0);
          }
        }
      }
    }
  }
}

class SegmentationResult {
  final bool isPersonDetected;
  final Rect? primaryPersonRect;
  final Rect? primaryFaceRect;
  final List<Rect> detectedFaces;
  final double confidence;
  final SegmentationMaskData? mask;
  final String? errorMessage;
  final bool isLowQuality;
  final String? warningMessage;

  const SegmentationResult({
    required this.isPersonDetected,
    this.primaryPersonRect,
    this.primaryFaceRect,
    this.detectedFaces = const [],
    this.confidence = 0.0,
    this.mask,
    this.errorMessage,
    this.isLowQuality = false,
    this.warningMessage,
  });

  bool get hasMultiplePeople => detectedFaces.length > 1;

  SegmentationResult copyWith({
    bool? isPersonDetected,
    Rect? primaryPersonRect,
    Rect? primaryFaceRect,
    List<Rect>? detectedFaces,
    double? confidence,
    SegmentationMaskData? mask,
    String? errorMessage,
    bool? isLowQuality,
    String? warningMessage,
  }) {
    return SegmentationResult(
      isPersonDetected: isPersonDetected ?? this.isPersonDetected,
      primaryPersonRect: primaryPersonRect ?? this.primaryPersonRect,
      primaryFaceRect: primaryFaceRect ?? this.primaryFaceRect,
      detectedFaces: detectedFaces ?? this.detectedFaces,
      confidence: confidence ?? this.confidence,
      mask: mask ?? this.mask,
      errorMessage: errorMessage ?? this.errorMessage,
      isLowQuality: isLowQuality ?? this.isLowQuality,
      warningMessage: warningMessage ?? this.warningMessage,
    );
  }

  factory SegmentationResult.failure(String message) {
    return SegmentationResult(
      isPersonDetected: false,
      errorMessage: message,
    );
  }
}

class PortraitCropConfig {
  final double chestBoundaryRatio; // 0.65 .. 1.0 (cutoff from head top down to chest/bust)
  final double headroomRatio; // 0.05 .. 0.20
  final double edgeFeatherRadius; // 0.5 .. 5.0 px (Photoshop edge smoothing)
  final double panX;
  final double panY;
  final double zoomScale;
  final int rotationDegrees;
  final bool flipHorizontal;
  final Color backgroundColor;
  final Rect? customCropRect; // Normalized 0..1 crop box from on-screen guide frame

  const PortraitCropConfig({
    this.chestBoundaryRatio = 0.85,
    this.headroomRatio = 0.10,
    this.edgeFeatherRadius = 2.0,
    this.panX = 0.0,
    this.panY = 0.0,
    this.zoomScale = 1.0,
    this.rotationDegrees = 0,
    this.flipHorizontal = false,
    this.backgroundColor = Colors.white,
    this.customCropRect,
  });

  PortraitCropConfig copyWith({
    double? chestBoundaryRatio,
    double? headroomRatio,
    double? edgeFeatherRadius,
    double? panX,
    double? panY,
    double? zoomScale,
    int? rotationDegrees,
    bool? flipHorizontal,
    Color? backgroundColor,
    Rect? customCropRect,
  }) {
    return PortraitCropConfig(
      chestBoundaryRatio: chestBoundaryRatio ?? this.chestBoundaryRatio,
      headroomRatio: headroomRatio ?? this.headroomRatio,
      edgeFeatherRadius: edgeFeatherRadius ?? this.edgeFeatherRadius,
      panX: panX ?? this.panX,
      panY: panY ?? this.panY,
      zoomScale: zoomScale ?? this.zoomScale,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      customCropRect: customCropRect ?? this.customCropRect,
    );
  }
}
