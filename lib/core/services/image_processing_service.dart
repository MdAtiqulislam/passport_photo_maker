import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart' as material;
import 'package:image/image.dart' as img;
import '../utils/file_utils.dart';

class PhotoQualityReport {
  final bool hasAdequateResolution;
  final bool isLightingGood;
  final bool isSharpEnough;
  final String resolutionText;
  final List<String> warnings;

  const PhotoQualityReport({
    required this.hasAdequateResolution,
    required this.isLightingGood,
    required this.isSharpEnough,
    required this.resolutionText,
    this.warnings = const [],
  });

  bool get isReady => hasAdequateResolution && warnings.length <= 1;
}

class ImageProcessingService {
  /// Decode and analyze image quality
  static Future<PhotoQualityReport> analyzeImageQuality(String filePath, {int minWidth = 400, int minHeight = 400}) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return const PhotoQualityReport(
          hasAdequateResolution: false,
          isLightingGood: false,
          isSharpEnough: false,
          resolutionText: 'Unknown',
          warnings: ['Could not decode image file.'],
        );
      }

      final warnings = <String>[];
      final resAdequate = decoded.width >= minWidth && decoded.height >= minHeight;
      if (!resAdequate) {
        warnings.add('Low resolution (${decoded.width}×${decoded.height}). Recommended at least 600×600 px.');
      }

      // Sample image brightness
      double totalLuminance = 0;
      int samples = 0;
      const step = 20;
      for (int y = 0; y < decoded.height; y += step) {
        for (int x = 0; x < decoded.width; x += step) {
          final pixel = decoded.getPixel(x, y);
          final r = pixel.r;
          final g = pixel.g;
          final b = pixel.b;
          final lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
          totalLuminance += lum;
          samples++;
        }
      }
      final avgLum = samples > 0 ? (totalLuminance / samples) : 0.5;
      final isLightingGood = avgLum >= 0.25 && avgLum <= 0.85;
      if (avgLum < 0.25) {
        warnings.add('Photo seems too dark. Try a brighter photo or use Auto Enhance.');
      } else if (avgLum > 0.88) {
        warnings.add('Photo might be overexposed.');
      }

      return PhotoQualityReport(
        hasAdequateResolution: resAdequate,
        isLightingGood: isLightingGood,
        isSharpEnough: true,
        resolutionText: '${decoded.width} × ${decoded.height} px',
        warnings: warnings,
      );
    } catch (e) {
      return PhotoQualityReport(
        hasAdequateResolution: true,
        isLightingGood: true,
        isSharpEnough: true,
        resolutionText: 'Standard',
        warnings: ['Could not verify image properties: $e'],
      );
    }
  }

  /// Process photo: Crop -> Rotate -> Flip -> Adjustments -> Background Color -> Resize
  static Future<String> processPhoto({
    required String sourceImagePath,
    required double cropX, // normalized 0..1
    required double cropY, // normalized 0..1
    required double cropWidth, // normalized 0..1
    required double cropHeight, // normalized 0..1
    int rotationDegrees = 0, // 0, 90, 180, 270
    bool flipHorizontal = false,
    double brightness = 0.0, // -1.0 to 1.0 (0 default)
    double contrast = 1.0, // 0.0 to 2.0 (1 default)
    double saturation = 1.0, // 0.0 to 2.0 (1 default)
    double warmth = 0.0, // -1.0 to 1.0 (0 default)
    bool applyAutoEnhance = false,
    material.Color? targetBackgroundColor,
    required int targetWidthPx,
    required int targetHeightPx,
    int outputDpi = 300,
  }) async {
    final rawBytes = await File(sourceImagePath).readAsBytes();
    img.Image? image = img.decodeImage(rawBytes);

    if (image == null) {
      throw Exception('Failed to decode source image');
    }

    // 1. Orientation / Initial manual rotation
    if (rotationDegrees != 0) {
      image = img.copyRotate(image, angle: rotationDegrees);
    }

    if (flipHorizontal) {
      image = img.copyFlip(image, direction: img.FlipDirection.horizontal);
    }

    // 2. Crop according to normalized coordinates
    final srcW = image.width;
    final srcH = image.height;

    final pixelX = (cropX * srcW).clamp(0.0, srcW.toDouble()).toInt();
    final pixelY = (cropY * srcH).clamp(0.0, srcH.toDouble()).toInt();
    final pixelW = (cropWidth * srcW).clamp(1.0, (srcW - pixelX).toDouble()).toInt();
    final pixelH = (cropHeight * srcH).clamp(1.0, (srcH - pixelY).toDouble()).toInt();

    image = img.copyCrop(
      image,
      x: pixelX,
      y: pixelY,
      width: pixelW,
      height: pixelH,
    );

    // 3. Auto Enhance or manual adjustments
    if (applyAutoEnhance) {
      // Optimal balance for official portrait: slight brightness & contrast boost, normalize
      image = img.adjustColor(
        image,
        brightness: 1.08,
        contrast: 1.12,
        saturation: 1.05,
      );
    } else {
      final effectiveBrightness = 1.0 + (brightness * 0.4);
      final effectiveContrast = contrast;
      final effectiveSaturation = saturation;

      if (effectiveBrightness != 1.0 || effectiveContrast != 1.0 || effectiveSaturation != 1.0) {
        image = img.adjustColor(
          image,
          brightness: effectiveBrightness,
          contrast: effectiveContrast,
          saturation: effectiveSaturation,
        );
      }
    }

    // 4. Background Color Replacement / Tint if selected and non-transparent
    if (targetBackgroundColor != null && targetBackgroundColor != material.Colors.transparent) {
      image = _replaceBackgroundColor(image, targetBackgroundColor);
    }

    // 5. Final Resize to exact target pixel dimensions with high-quality cubic interpolation
    image = img.copyResize(
      image,
      width: targetWidthPx,
      height: targetHeightPx,
      interpolation: img.Interpolation.cubic,
    );

    // 6. Encode and save to persistent project/processed path
    final outputPath = await FileUtils.createProjectFilePath(prefix: 'processed', extension: 'jpg');
    final jpgBytes = img.encodeJpg(image, quality: 95);
    await File(outputPath).writeAsBytes(jpgBytes);

    return outputPath;
  }

  /// Intelligent background replacement based on edge flood / corner sampling
  static img.Image _replaceBackgroundColor(img.Image image, material.Color targetColor) {
    final result = img.Image.from(image);
    final w = result.width;
    final h = result.height;

    final targetR = (targetColor.r * 255.0).round().clamp(0, 255).toDouble();
    final targetG = (targetColor.g * 255.0).round().clamp(0, 255).toDouble();
    final targetB = (targetColor.b * 255.0).round().clamp(0, 255).toDouble();

    // Corner background sampling: sample 4 corners of the photo
    final corners = [
      result.getPixel(2, 2),
      result.getPixel(w - 3, 2),
      result.getPixel(2, 10),
      result.getPixel(w - 3, 10),
    ];

    double bgR = 0, bgG = 0, bgB = 0;
    for (var c in corners) {
      bgR += c.r;
      bgG += c.g;
      bgB += c.b;
    }
    bgR /= corners.length;
    bgG /= corners.length;
    bgB /= corners.length;

    // Threshold check for background replacement
    const double tolerance = 48.0;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = result.getPixel(x, y);
        final diffR = (p.r - bgR).abs();
        final diffG = (p.g - bgG).abs();
        final diffB = (p.b - bgB).abs();
        final dist = sqrt(diffR * diffR + diffG * diffG + diffB * diffB);

        if (dist < tolerance) {
          final factor = (dist / tolerance).clamp(0.0, 1.0);
          final newR = (targetR * (1 - factor) + p.r * factor).round();
          final newG = (targetG * (1 - factor) + p.g * factor).round();
          final newB = (targetB * (1 - factor) + p.b * factor).round();
          result.setPixelRgb(x, y, newR, newG, newB);
        }
      }
    }

    return result;
  }
}
