import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../../data/models/restoration_models.dart';
import '../utils/file_utils.dart';

class PhotoRestorationService {
  PhotoRestorationService._();

  /// Analyze the photo for noise, blur, scratches, spots, fading, and color properties in background isolate
  static Future<PhotoAnalysisReport> analyzePhoto(File imageFile) async {
    final imagePath = imageFile.path;
    return await compute(_executeAnalysisIsolate, imagePath);
  }

  /// Run full on-device photo restoration in background isolate
  static Future<RestorationResult> restorePhoto({
    required File imageFile,
    required RestorationOptions options,
    String? outputPath,
  }) async {
    final finalOutputPath = outputPath ?? await FileUtils.createProjectFilePath(prefix: 'restored', extension: 'png');

    final params = _RestorationParams(
      inputPath: imageFile.path,
      outputPath: finalOutputPath,
      options: options,
    );

    return await compute(_executeRestorationIsolate, params);
  }

  /// Automatically detect and crop a physical printed photo from a table/desk surface scan
  static Future<String> autoCropPhotoCard(File imageFile) async {
    final outputPath = await FileUtils.createProjectFilePath(prefix: 'card_cropped', extension: 'png');
    return await compute(_executeCardCropIsolate, _CropParams(inputPath: imageFile.path, outputPath: outputPath));
  }

  /// Touch-to-heal an explicit blemish / spot / scratch at normalized coordinates
  static Future<String> healSpotAtCoordinates({
    required File imageFile,
    required double normX,
    required double normY,
    required double normRadius,
    String? outputPath,
  }) async {
    final finalOutputPath = outputPath ?? await FileUtils.createProjectFilePath(prefix: 'healed_spot', extension: 'png');
    final params = _HealParams(
      inputPath: imageFile.path,
      outputPath: finalOutputPath,
      normX: normX,
      normY: normY,
      normRadius: normRadius,
    );
    return await compute(_executeHealIsolate, params);
  }
}

class _RestorationParams {
  final String inputPath;
  final String outputPath;
  final RestorationOptions options;

  _RestorationParams({
    required this.inputPath,
    required this.outputPath,
    required this.options,
  });
}

class _CropParams {
  final String inputPath;
  final String outputPath;
  _CropParams({required this.inputPath, required this.outputPath});
}

class _HealParams {
  final String inputPath;
  final String outputPath;
  final double normX;
  final double normY;
  final double normRadius;

  _HealParams({
    required this.inputPath,
    required this.outputPath,
    required this.normX,
    required this.normY,
    required this.normRadius,
  });
}

// -----------------------------------------------------------------------------
// ISOLATE: PHOTO ANALYSIS
// -----------------------------------------------------------------------------
PhotoAnalysisReport _executeAnalysisIsolate(String imagePath) {
  final file = File(imagePath);
  final rawBytes = file.readAsBytesSync();
  final source = img.decodeImage(rawBytes);

  if (source == null) {
    throw Exception('Could not decode photo for restoration analysis');
  }

  final w = source.width;
  final h = source.height;
  final totalPixels = w * h;

  // Subsample step for fast, memory-safe analysis
  final step = max(1, (sqrt(totalPixels) / 120).round());
  int sampleCount = 0;

  double sumLum = 0;
  double sumLumSq = 0;
  double colorChannelVariance = 0;

  double laplacianSum = 0;
  double sobelEdgeSum = 0;
  int damagePointCount = 0;

  int minLum = 255;
  int maxLum = 0;

  for (int y = step; y < h - step; y += step) {
    for (int x = step; x < w - step; x += step) {
      final p = source.getPixel(x, y);
      final r = p.r.toDouble();
      final g = p.g.toDouble();
      final b = p.b.toDouble();
      final lum = (0.299 * r + 0.587 * g + 0.114 * b);

      sumLum += lum;
      sumLumSq += (lum * lum);

      final lumInt = lum.round().clamp(0, 255);
      if (lumInt < minLum) minLum = lumInt;
      if (lumInt > maxLum) maxLum = lumInt;

      // Color variance (is image grayscale / B&W?)
      final meanRGB = (r + g + b) / 3.0;
      final diff = ((r - meanRGB).abs() + (g - meanRGB).abs() + (b - meanRGB).abs()) / 3.0;
      colorChannelVariance += diff;

      // Estimate Laplacian (High-frequency noise check)
      final pLeft = source.getPixel(x - step, y);
      final pRight = source.getPixel(x + step, y);
      final pUp = source.getPixel(x, y - step);
      final pDown = source.getPixel(x, y + step);

      final lumL = 0.299 * pLeft.r + 0.587 * pLeft.g + 0.114 * pLeft.b;
      final lumR = 0.299 * pRight.r + 0.587 * pRight.g + 0.114 * pRight.b;
      final lumU = 0.299 * pUp.r + 0.587 * pUp.g + 0.114 * pUp.b;
      final lumD = 0.299 * pDown.r + 0.587 * pDown.g + 0.114 * pDown.b;

      final lap = ((4 * lum) - (lumL + lumR + lumU + lumD)).abs();
      laplacianSum += lap;

      // Sobel gradient magnitude (sharpness check)
      final gx = (lumR - lumL).abs();
      final gy = (lumD - lumU).abs();
      sobelEdgeSum += (gx + gy);

      // Scratch / spot / defect candidate
      final localAvg = (lumL + lumR + lumU + lumD) / 4.0;
      if ((lum - localAvg).abs() > 30) {
        damagePointCount++;
      }

      sampleCount++;
    }
  }

  final avgLum = sampleCount > 0 ? (sumLum / sampleCount) : 128.0;
  final lumVariance = sampleCount > 0 ? (sumLumSq / sampleCount - avgLum * avgLum) : 1000.0;
  final lumStdDev = sqrt(max(0, lumVariance));
  final avgColorVar = sampleCount > 0 ? (colorChannelVariance / sampleCount) : 0.0;

  // Grayscale check
  final isGrayscale = avgColorVar < 4.5;

  // Contrast score
  final contrastScore = (lumStdDev / 64.0).clamp(0.1, 1.0);

  // Fading score
  final dynamicRange = (maxLum - minLum).clamp(0, 255);
  final fadingScore = (1.0 - (dynamicRange / 255.0) * (contrastScore)).clamp(0.0, 1.0);

  // Noise level estimation
  final avgLaplacian = sampleCount > 0 ? (laplacianSum / sampleCount) : 10.0;
  final noiseLevel = (avgLaplacian / 35.0).clamp(0.0, 1.0);

  // Blur level estimation
  final avgEdge = sampleCount > 0 ? (sobelEdgeSum / sampleCount) : 15.0;
  final blurLevel = (1.0 - (avgEdge / 30.0)).clamp(0.0, 1.0);

  // Diagnostic tags for user UI
  final defects = <String>[];
  if (isGrayscale) defects.add('Black & White Photo');
  if (fadingScore > 0.35) defects.add('Faded / Washed Out');
  if (noiseLevel > 0.25) defects.add('Grain & Noise');
  if (blurLevel > 0.30) defects.add('Mild Blur');
  if (damagePointCount > 10) defects.add('Spots, Scratches & Stains');
  if (contrastScore < 0.50) defects.add('Low Contrast');
  if (w < 800 || h < 800) defects.add('Low Resolution');
  if (defects.isEmpty) defects.add('Good Condition (Mild Touch-up)');

  final qualityScore = ((contrastScore * 35) + ((1.0 - noiseLevel) * 25) + ((1.0 - blurLevel) * 25) + ((1.0 - fadingScore) * 15)).clamp(10.0, 98.0);

  return PhotoAnalysisReport(
    width: w,
    height: h,
    isGrayscale: isGrayscale,
    noiseLevel: noiseLevel,
    blurLevel: blurLevel,
    fadingScore: fadingScore,
    contrastScore: contrastScore,
    estimatedDamagePoints: damagePointCount,
    overallQualityScore: qualityScore,
    detectedDefectLabels: defects,
  );
}

// -----------------------------------------------------------------------------
// ISOLATE: FULL RESTORATION PIPELINE
// -----------------------------------------------------------------------------
Future<RestorationResult> _executeRestorationIsolate(_RestorationParams params) async {
  final stopwatch = Stopwatch()..start();

  final rawBytes = await File(params.inputPath).readAsBytes();
  var currentImage = img.decodeImage(rawBytes);

  if (currentImage == null) {
    throw Exception('Could not decode photo for restoration');
  }

  // 1. Analyze initial properties
  final analysis = _executeAnalysisIsolate(params.inputPath);
  final opt = params.options;
  final strengthMult = opt.strength.factor;

  // 2. High-Precision Multi-Radius Scratch & White Spot Inpainting
  if (opt.repairScratches) {
    currentImage = _repairMultiScaleSpotsAndScratches(currentImage, strengthMult);
  }

  // 3. Adaptive Noise Reduction (Edge-preserving Bilateral Filter)
  if (opt.reduceNoise) {
    currentImage = _applyEdgePreservingSmoothing(currentImage, strengthMult);
  }

  // 4. Contrast Recovery & Dynamic Range Stretching
  if (opt.recoverFadedColors) {
    currentImage = _recoverFadedContrast(currentImage, strengthMult, analysis.isGrayscale);
  }

  // 5. Auto White Balance / Aging Cast Removal
  if (opt.autoWhiteBalance && !analysis.isGrayscale) {
    currentImage = _correctColorCast(currentImage);
  }

  // 6. Deblurring & Detail Sharpness Boost
  if (opt.deblurAndSharpen) {
    currentImage = _applyUnsharpMask(currentImage, strengthMult * opt.sharpness);
  }

  // 7. Optional AI Colorization for B&W photos
  if (analysis.isGrayscale && opt.colorize) {
    currentImage = _applyAiColorization(currentImage);
  }

  // 8. User Fine-Tune Adjustments
  if (opt.brightness != 0.0 || opt.contrast != 1.0 || opt.saturation != 1.0 || opt.temperature != 0.0) {
    currentImage = _applyFineTune(
      currentImage,
      brightness: opt.brightness,
      contrast: opt.contrast,
      saturation: opt.saturation,
      temperature: opt.temperature,
    );
  }

  // 9. Optional Upscaling
  if (opt.upscaleFactor > 1) {
    final targetW = currentImage.width * opt.upscaleFactor;
    final targetH = currentImage.height * opt.upscaleFactor;
    currentImage = img.copyResize(
      currentImage,
      width: targetW,
      height: targetH,
      interpolation: img.Interpolation.cubic,
    );
    currentImage = _applyUnsharpMask(currentImage, 0.35);
  }

  // 10. Encode & Save Output File
  final encodedJpg = img.encodePng(currentImage);
  final outFile = File(params.outputPath);
  await outFile.parent.create(recursive: true);
  await outFile.writeAsBytes(encodedJpg);

  stopwatch.stop();

  return RestorationResult(
    originalImagePath: params.inputPath,
    restoredImagePath: params.outputPath,
    analysisReport: analysis,
    optionsUsed: opt,
    processingTimeMs: stopwatch.elapsedMilliseconds,
    finalWidth: currentImage.width,
    finalHeight: currentImage.height,
  );
}

// -----------------------------------------------------------------------------
// ISOLATE: AUTO DETECT & CROP PHOTO CARD
// -----------------------------------------------------------------------------
Future<String> _executeCardCropIsolate(_CropParams params) async {
  final bytes = await File(params.inputPath).readAsBytes();
  var src = img.decodeImage(bytes);
  if (src == null) throw Exception('Cannot decode image for crop');

  final cropped = _detectAndCropPhotoRectangle(src);
  final encoded = img.encodePng(cropped);
  final outFile = File(params.outputPath);
  await outFile.parent.create(recursive: true);
  await outFile.writeAsBytes(encoded);
  return params.outputPath;
}

// -----------------------------------------------------------------------------
// ISOLATE: TOUCH SPOT HEALER
// -----------------------------------------------------------------------------
Future<String> _executeHealIsolate(_HealParams params) async {
  final bytes = await File(params.inputPath).readAsBytes();
  var src = img.decodeImage(bytes);
  if (src == null) throw Exception('Cannot decode image for healing');

  final w = src.width;
  final h = src.height;

  final centerX = (params.normX * w).round().clamp(0, w - 1);
  final centerY = (params.normY * h).round().clamp(0, h - 1);
  // Cap the absolute pixel radius to max 28 pixels to prevent large low-res blurry smudges
  final radius = (params.normRadius * w).round().clamp(3, 28);

  final output = img.Image.from(src);

  // 1. Gather valid boundary ring pixels around the spot (radius 1.05*R to 1.5*R)
  final ringPixels = <_RingPixel>[];
  double ringRSum = 0, ringGSum = 0, ringBSum = 0;

  final int rInner = max(1, (radius * 1.05).round());
  final int rOuter = max(rInner + 3, (radius * 1.5).round());

  for (int dy = -rOuter; dy <= rOuter; dy++) {
    for (int dx = -rOuter; dx <= rOuter; dx++) {
      final px = centerX + dx;
      final py = centerY + dy;

      if (px < 0 || px >= w || py < 0 || py >= h) continue;

      final dist = sqrt((dx * dx + dy * dy).toDouble());
      if (dist >= rInner && dist <= rOuter) {
        final p = src.getPixel(px, py);
        final angle = atan2(dy.toDouble(), dx.toDouble());
        ringPixels.add(_RingPixel(x: px, y: py, r: p.r.toDouble(), g: p.g.toDouble(), b: p.b.toDouble(), angle: angle));
        ringRSum += p.r;
        ringGSum += p.g;
        ringBSum += p.b;
      }
    }
  }

  if (ringPixels.isNotEmpty) {
    final avgR = ringRSum / ringPixels.length;
    final avgG = ringGSum / ringPixels.length;
    final avgB = ringBSum / ringPixels.length;
    final avgLum = 0.299 * avgR + 0.587 * avgG + 0.114 * avgB;

    // 2. Inpaint interior circle pixels with Inverse Distance Weighting, Angular guidance & Smooth Hermite Blend
    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        final px = centerX + dx;
        final py = centerY + dy;

        if (px < 0 || px >= w || py < 0 || py >= h) continue;

        final distFromCenter = sqrt((dx * dx + dy * dy).toDouble());
        if (distFromCenter <= radius) {
          double weightSum = 0;
          double rSum = 0, gSum = 0, bSum = 0;

          final angle = atan2(dy.toDouble(), dx.toDouble());

          for (final rp in ringPixels) {
            final dX = px - rp.x;
            final dY = py - rp.y;
            final dSq = (dX * dX + dY * dY).toDouble();

            final distWeight = 1.0 / max(1.0, dSq);
            var angleDiff = (angle - rp.angle).abs();
            if (angleDiff > pi) angleDiff = 2 * pi - angleDiff;
            final angleWeight = exp(-angleDiff * angleDiff / 1.5);

            final weight = distWeight * (0.3 + 0.7 * angleWeight);

            rSum += rp.r * weight;
            gSum += rp.g * weight;
            bSum += rp.b * weight;
            weightSum += weight;
          }

          final normDist = (distFromCenter / radius).clamp(0.0, 1.0);
          // Smooth Hermite smoothstep: 1.0 at center (normDist=0), 0.0 at edge (normDist=1.0)
          final blendFactor = 1.0 - normDist * normDist * (3.0 - 2.0 * normDist);

          final interpR = weightSum > 0 ? (rSum / weightSum) : avgR;
          final interpG = weightSum > 0 ? (gSum / weightSum) : avgG;
          final interpB = weightSum > 0 ? (bSum / weightSum) : avgB;

          final orig = src.getPixel(px, py);
          final origLum = 0.299 * orig.r + 0.587 * orig.g + 0.114 * orig.b;
          final lumDelta = (origLum - avgLum).abs();

          // Anomaly detection: only strong healing for pixels that differ from neighborhood
          final anomalyStrength = (lumDelta / 20.0).clamp(0.6, 1.0);
          final effectiveAlpha = (blendFactor * anomalyStrength).clamp(0.0, 1.0);

          // Add a very subtle pseudo-random high-frequency grain to prevent flat digital smudges
          final randomVal = (sin(px * 12.9898 + py * 78.233) * 43758.5453).floorToDouble() % 1.0;
          final noise = ((randomVal - 0.5) * 4.0).round();

          final finalR = (interpR * effectiveAlpha + orig.r * (1.0 - effectiveAlpha) + noise).round().clamp(0, 255);
          final finalG = (interpG * effectiveAlpha + orig.g * (1.0 - effectiveAlpha) + noise).round().clamp(0, 255);
          final finalB = (interpB * effectiveAlpha + orig.b * (1.0 - effectiveAlpha) + noise).round().clamp(0, 255);

          output.setPixelRgb(px, py, finalR, finalG, finalB);
        }
      }
    }
  }

  final encoded = img.encodePng(output);
  final outFile = File(params.outputPath);
  await outFile.parent.create(recursive: true);
  await outFile.writeAsBytes(encoded);
  return params.outputPath;
}

class _RingPixel {
  final int x;
  final int y;
  final double r;
  final double g;
  final double b;
  final double angle;

  _RingPixel({
    required this.x,
    required this.y,
    required this.r,
    required this.g,
    required this.b,
    required this.angle,
  });
}

// -----------------------------------------------------------------------------
// IMAGE PROCESSING ALGORITHMS
// -----------------------------------------------------------------------------

/// Advanced Multi-Radius Inpainting to remove white dust spots, scratches, stains, and specks
img.Image _repairMultiScaleSpotsAndScratches(img.Image src, double strength) {
  var working = img.Image.from(src);

  // Pass 1: Very wide physical card cracks & scratches (Radius r=7..10)
  final extraWideR = (7 * strength).round().clamp(4, 10);
  working = _inpaintSpotPass(working, searchRadius: extraWideR, threshold: (28.0 / strength).clamp(18.0, 42.0));

  // Pass 2: Wide scratches & cracks on clothes/background (Radius r=4..6)
  final wideR = (4 * strength).round().clamp(3, 6);
  working = _inpaintSpotPass(working, searchRadius: wideR, threshold: (22.0 / strength).clamp(14.0, 34.0));

  // Pass 3: Medium spots & scratches (Radius r=2..3)
  final medR = (2.5 * strength).round().clamp(2, 3);
  working = _inpaintSpotPass(working, searchRadius: medR, threshold: (18.0 / strength).clamp(12.0, 28.0));

  return working;
}

/// Single inpainting pass for a given radius and luminance/color deviation threshold
img.Image _inpaintSpotPass(img.Image src, {required int searchRadius, required double threshold}) {
  final output = img.Image.from(src);
  final w = src.width;
  final h = src.height;
  final r = searchRadius;

  for (int y = r; y < h - r; y++) {
    for (int x = r; x < w - r; x++) {
      final centerP = src.getPixel(x, y);
      final centerLum = 0.299 * centerP.r + 0.587 * centerP.g + 0.114 * centerP.b;

      // Check skin locus of center pixel to be more sensitive on clothes/background
      final cb = 128.0 + 112.0 * centerP.r / 255.0 - 94.0 * centerP.g / 255.0 - 18.0 * centerP.b / 255.0;
      final cr = 128.0 - 37.797 * centerP.r / 255.0 - 74.203 * centerP.g / 255.0 + 112.0 * centerP.b / 255.0;
      final cg = 128.0 - 74.203 * centerP.r / 255.0 + 94.0 * centerP.g / 255.0 - 19.797 * centerP.b / 255.0;
      final isSkin = cr > cg && (cr - cg) > 5 && cb >= 70 && cb <= 135;

      // Clothes & backgrounds have lower thresholds (higher sensitivity) for scratch removal
      final activeThreshold = isSkin ? threshold : threshold * 0.65;

      double ringLumSum = 0;
      double ringRSum = 0;
      double ringGSum = 0;
      double ringBSum = 0;
      int validRingPixels = 0;

      double minRingLum = 255;
      double maxRingLum = 0;

      final ringPixels = <img.Pixel>[];

      for (int dy = -r; dy <= r; dy++) {
        for (int dx = -r; dx <= r; dx++) {
          final distSq = dx * dx + dy * dy;
          if (distSq >= (r - 1) * (r - 1) && distSq <= (r + 1) * (r + 1)) {
            final np = src.getPixel(x + dx, y + dy);
            final nLum = 0.299 * np.r + 0.587 * np.g + 0.114 * np.b;

            ringLumSum += nLum;
            ringRSum += np.r;
            ringGSum += np.g;
            ringBSum += np.b;
            validRingPixels++;

            if (nLum < minRingLum) minRingLum = nLum;
            if (nLum > maxRingLum) maxRingLum = nLum;
            ringPixels.add(np);
          }
        }
      }

      if (validRingPixels < 6) continue;

      final avgRingLum = ringLumSum / validRingPixels;
      final diff = centerLum - avgRingLum;
      final isWhiteSpot = diff > activeThreshold && centerLum > (maxRingLum - 4);
      final isDarkSpot = diff < -activeThreshold && centerLum < (minRingLum + 4);

      if (isWhiteSpot || isDarkSpot) {
        ringPixels.sort((a, b) => (0.299 * a.r + 0.587 * a.g + 0.114 * a.b).compareTo(0.299 * b.r + 0.587 * b.g + 0.114 * b.b));
        final medianP = ringPixels[ringPixels.length ~/ 2];

        final fillR = ((medianP.r * 2 + (ringRSum / validRingPixels)) / 3.0).round().clamp(0, 255);
        final fillG = ((medianP.g * 2 + (ringGSum / validRingPixels)) / 3.0).round().clamp(0, 255);
        final fillB = ((medianP.b * 2 + (ringBSum / validRingPixels)) / 3.0).round().clamp(0, 255);

        output.setPixelRgb(x, y, fillR, fillG, fillB);
      }
    }
  }

  return output;
}

/// Edge-preserving noise smoothing (guided bilateral filter)
img.Image _applyEdgePreservingSmoothing(img.Image src, double strength) {
  final output = img.Image.from(src);
  final w = src.width;
  final h = src.height;
  final spatialRadius = strength >= 1.2 ? 2 : 1;

  for (int y = spatialRadius; y < h - spatialRadius; y++) {
    for (int x = spatialRadius; x < w - spatialRadius; x++) {
      final centerP = src.getPixel(x, y);
      final centerLum = 0.299 * centerP.r + 0.587 * centerP.g + 0.114 * centerP.b;

      double weightSum = 0;
      double rSum = 0;
      double gSum = 0;
      double bSum = 0;

      for (int dy = -spatialRadius; dy <= spatialRadius; dy++) {
        for (int dx = -spatialRadius; dx <= spatialRadius; dx++) {
          final np = src.getPixel(x + dx, y + dy);
          final nLum = 0.299 * np.r + 0.587 * np.g + 0.114 * np.b;

          final spatialDist = dx * dx + dy * dy;
          final colorDiff = (centerLum - nLum).abs();

          final colorWeight = exp(-colorDiff / 25.0);
          final spatialWeight = exp(-spatialDist / 4.0);
          final wFactor = colorWeight * spatialWeight;

          rSum += np.r * wFactor;
          gSum += np.g * wFactor;
          bSum += np.b * wFactor;
          weightSum += wFactor;
        }
      }

      if (weightSum > 0.001) {
        output.setPixelRgb(
          x,
          y,
          (rSum / weightSum).round().clamp(0, 255),
          (gSum / weightSum).round().clamp(0, 255),
          (bSum / weightSum).round().clamp(0, 255),
        );
      }
    }
  }

  return output;
}

/// Faded contrast recovery & shadow lifting
img.Image _recoverFadedContrast(img.Image src, double strength, bool isGrayscale) {
  final output = img.Image.from(src);
  final w = src.width;
  final h = src.height;

  final hist = List<int>.filled(256, 0);
  for (final p in src) {
    final lum = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round().clamp(0, 255);
    hist[lum]++;
  }

  final total = w * h;
  final lowCut = (total * 0.02).round();
  final highCut = (total * 0.98).round();

  int cumulative = 0;
  int minCutVal = 0;
  int maxCutVal = 255;

  for (int i = 0; i < 256; i++) {
    cumulative += hist[i];
    if (cumulative >= lowCut && minCutVal == 0) {
      minCutVal = i;
    }
    if (cumulative >= highCut) {
      maxCutVal = i;
      break;
    }
  }

  if (maxCutVal <= minCutVal) {
    minCutVal = 0;
    maxCutVal = 255;
  }

  final range = maxCutVal - minCutVal;
  final gamma = 1.0 - (0.12 * strength);

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final p = src.getPixel(x, y);

      double rNorm = ((p.r - minCutVal) / range).clamp(0.0, 1.0);
      double gNorm = ((p.g - minCutVal) / range).clamp(0.0, 1.0);
      double bNorm = ((p.b - minCutVal) / range).clamp(0.0, 1.0);

      rNorm = pow(rNorm, gamma).toDouble();
      gNorm = pow(gNorm, gamma).toDouble();
      bNorm = pow(bNorm, gamma).toDouble();

      output.setPixelRgb(
        x,
        y,
        (rNorm * 255).round().clamp(0, 255),
        (gNorm * 255).round().clamp(0, 255),
        (bNorm * 255).round().clamp(0, 255),
      );
    }
  }

  return output;
}

/// Auto white balance & removal of aging color cast
img.Image _correctColorCast(img.Image src) {
  final output = img.Image.from(src);
  double sumR = 0, sumG = 0, sumB = 0;
  int count = 0;

  for (final p in src) {
    sumR += p.r;
    sumG += p.g;
    sumB += p.b;
    count++;
  }

  if (count == 0) return output;

  final avgR = sumR / count;
  final avgG = sumG / count;
  final avgB = sumB / count;
  final avgGray = (avgR + avgG + avgB) / 3.0;

  final scaleR = (avgGray / max(1.0, avgR)).clamp(0.85, 1.15);
  final scaleG = (avgGray / max(1.0, avgG)).clamp(0.85, 1.15);
  final scaleB = (avgGray / max(1.0, avgB)).clamp(0.85, 1.15);

  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      final p = src.getPixel(x, y);
      output.setPixelRgb(
        x,
        y,
        (p.r * scaleR).round().clamp(0, 255),
        (p.g * scaleG).round().clamp(0, 255),
        (p.b * scaleB).round().clamp(0, 255),
      );
    }
  }

  return output;
}

/// Unsharp masking for facial & texture sharpening
img.Image _applyUnsharpMask(img.Image src, double amount) {
  final blurred = img.gaussianBlur(src, radius: 1);
  final output = img.Image.from(src);
  final w = src.width;
  final h = src.height;
  final weight = (amount * 0.6).clamp(0.1, 1.5);

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final orig = src.getPixel(x, y);
      final blur = blurred.getPixel(x, y);

      final r = (orig.r + weight * (orig.r - blur.r)).round().clamp(0, 255);
      final g = (orig.g + weight * (orig.g - blur.g)).round().clamp(0, 255);
      final b = (orig.b + weight * (orig.b - blur.b)).round().clamp(0, 255);

      output.setPixelRgb(x, y, r, g, b);
    }
  }

  return output;
}

/// Natural tone mapping for B&W photo colorization
img.Image _applyAiColorization(img.Image src) {
  final output = img.Image.from(src);
  final w = src.width;
  final h = src.height;

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final p = src.getPixel(x, y);
      final lum = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;

      double r, g, b;
      if (lum < 60) {
        r = lum * 0.95;
        g = lum * 0.98;
        b = lum * 1.05;
      } else if (lum < 170) {
        final factor = (lum - 60) / 110.0;
        r = lum * (1.10 + 0.05 * factor);
        g = lum * (0.96 + 0.02 * factor);
        b = lum * (0.86 + 0.04 * factor);
      } else {
        final factor = (lum - 170) / 85.0;
        r = lum * (1.04 - 0.04 * factor);
        g = lum * (1.02 - 0.02 * factor);
        b = lum * (0.95 + 0.05 * factor);
      }

      output.setPixelRgb(
        x,
        y,
        r.round().clamp(0, 255),
        g.round().clamp(0, 255),
        b.round().clamp(0, 255),
      );
    }
  }

  return output;
}

/// Apply brightness, contrast, saturation, and temperature fine-tuning
img.Image _applyFineTune(
  img.Image src, {
  required double brightness,
  required double contrast,
  required double saturation,
  required double temperature,
}) {
  final output = img.Image.from(src);
  final w = src.width;
  final h = src.height;
  final bOffset = (brightness * 50).round();

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final p = src.getPixel(x, y);

      var r = (((p.r - 128) * contrast) + 128 + bOffset).clamp(0.0, 255.0);
      var g = (((p.g - 128) * contrast) + 128 + bOffset).clamp(0.0, 255.0);
      var b = (((p.b - 128) * contrast) + 128 + bOffset).clamp(0.0, 255.0);

      if (temperature != 0.0) {
        final tOffset = temperature * 20.0;
        r = (r + tOffset).clamp(0.0, 255.0);
        b = (b - tOffset).clamp(0.0, 255.0);
      }

      if (saturation != 1.0) {
        final lum = 0.299 * r + 0.587 * g + 0.114 * b;
        r = (lum + saturation * (r - lum)).clamp(0.0, 255.0);
        g = (lum + saturation * (g - lum)).clamp(0.0, 255.0);
        b = (lum + saturation * (b - lum)).clamp(0.0, 255.0);
      }

      output.setPixelRgb(x, y, r.round(), g.round(), b.round());
    }
  }

  return output;
}

/// Automatically detect and crop the rectangular photo card from a camera table scan
img.Image _detectAndCropPhotoRectangle(img.Image src) {
  final w = src.width;
  final h = src.height;

  final colVariance = List<double>.filled(w, 0);
  final rowVariance = List<double>.filled(h, 0);

  final step = max(1, (w / 150).round());

  for (int x = 0; x < w; x += step) {
    double sum = 0, sumSq = 0;
    int count = 0;
    for (int y = 0; y < h; y += step * 2) {
      final p = src.getPixel(x, y);
      final lum = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      sum += lum;
      sumSq += lum * lum;
      count++;
    }
    final avg = count > 0 ? sum / count : 128.0;
    colVariance[x] = count > 0 ? (sumSq / count - avg * avg) : 0;
  }

  for (int y = 0; y < h; y += step) {
    double sum = 0, sumSq = 0;
    int count = 0;
    for (int x = 0; x < w; x += step * 2) {
      final p = src.getPixel(x, y);
      final lum = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      sum += lum;
      sumSq += lum * lum;
      count++;
    }
    final avg = count > 0 ? sum / count : 128.0;
    rowVariance[y] = count > 0 ? (sumSq / count - avg * avg) : 0;
  }

  int minX = (w * 0.12).round();
  int maxX = (w * 0.88).round();
  int minY = (h * 0.15).round();
  int maxY = (h * 0.85).round();

  for (int x = (w * 0.05).round(); x < (w * 0.40).round(); x += step) {
    if (colVariance[x] > 400) {
      minX = x;
      break;
    }
  }

  for (int x = (w * 0.95).round(); x > (w * 0.60).round(); x -= step) {
    if (colVariance[x] > 400) {
      maxX = x;
      break;
    }
  }

  for (int y = (h * 0.05).round(); y < (h * 0.45).round(); y += step) {
    if (rowVariance[y] > 400) {
      minY = y;
      break;
    }
  }

  for (int y = (h * 0.95).round(); y > (h * 0.55).round(); y -= step) {
    if (rowVariance[y] > 400) {
      maxY = y;
      break;
    }
  }

  final cropW = max(50, maxX - minX);
  final cropH = max(50, maxY - minY);

  return img.copyCrop(src, x: minX, y: minY, width: cropW, height: cropH);
}
