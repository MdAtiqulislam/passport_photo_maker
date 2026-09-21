import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../../data/models/ai_enhance_result.dart';
import '../utils/file_utils.dart';

class AiEnhanceService {
  AiEnhanceService._();

  /// Enhance photo on-device with smart exposure, beauty skin smoothing, and detail clarity
  static Future<AiEnhanceResult> enhancePhoto({
    required String imagePath,
    AiEnhanceProfile profile = AiEnhanceProfile.balanced,
    String? outputPath,
  }) async {
    final finalOutputPath = outputPath ?? await FileUtils.createProjectFilePath(prefix: 'enhanced', extension: 'jpg');

    final params = _AiEnhanceParams(
      inputPath: imagePath,
      outputPath: finalOutputPath,
      profileIndex: profile.index,
    );

    return await compute(_executeAiEnhanceIsolate, params);
  }
}

class _AiEnhanceParams {
  final String inputPath;
  final String outputPath;
  final int profileIndex;

  _AiEnhanceParams({
    required this.inputPath,
    required this.outputPath,
    required this.profileIndex,
  });
}

Future<AiEnhanceResult> _executeAiEnhanceIsolate(_AiEnhanceParams params) async {
  final rawBytes = await File(params.inputPath).readAsBytes();
  var source = img.decodeImage(rawBytes);

  if (source == null) {
    throw Exception('Could not decode input photo for enhancement');
  }

  // OPTIMIZATION: Prevent CPU freeze by capping extreme resolution inputs
  // Passport photos only need to be 600x600 for printing. 800x800 gives perfect headroom.
  if (source.width > 800 || source.height > 800) {
    final scale = 800.0 / (source.width > source.height ? source.width : source.height);
    source = img.copyResize(
      source,
      width: (source.width * scale).round(),
      height: (source.height * scale).round(),
      interpolation: img.Interpolation.linear,
    );
  }

  final profile = AiEnhanceProfile.values[params.profileIndex];

  // 1. Analyze Luminance & Color Channels
  final w = source.width;
  final h = source.height;
  final totalPixels = w * h;

  double sumR = 0, sumG = 0, sumB = 0;
  double sumLum = 0;

  final step = max(1, (sqrt(totalPixels) / 100).round());
  int sampleCount = 0;

  for (int y = 0; y < h; y += step) {
    for (int x = 0; x < w; x += step) {
      final p = source.getPixel(x, y);
      sumR += p.r;
      sumG += p.g;
      sumB += p.b;
      sumLum += (0.299 * p.r + 0.587 * p.g + 0.114 * p.b);
      sampleCount++;
    }
  }

  final avgR = sampleCount > 0 ? (sumR / sampleCount) : 128.0;
  final avgG = sampleCount > 0 ? (sumG / sampleCount) : 128.0;
  final avgB = sampleCount > 0 ? (sumB / sampleCount) : 128.0;
  final avgLum = sampleCount > 0 ? (sumLum / sampleCount) : 128.0;
  final avgGray = (avgR + avgG + avgB) / 3.0;

  // 2. Configure Profile Weights
  double exposureMultiplier = 1.0;
  double contrastFactor = 1.08;
  double sharpenFactor = 0.15;
  double skinSmoothingStrength = 0.0;
  double skinWhiteningFactor = 1.0;

  switch (profile) {
    case AiEnhanceProfile.subtle:
      contrastFactor = 1.04;
      sharpenFactor = 0.10;
      skinSmoothingStrength = 0.2;
      skinWhiteningFactor = 1.02;
      break;
    case AiEnhanceProfile.balanced:
      contrastFactor = 1.09;
      sharpenFactor = 0.18;
      skinSmoothingStrength = 0.45;
      skinWhiteningFactor = 1.04;
      break;
    case AiEnhanceProfile.beautySmooth:
      contrastFactor = 1.06;
      sharpenFactor = 0.14;
      skinSmoothingStrength = 0.85;
      skinWhiteningFactor = 1.08;
      break;
    case AiEnhanceProfile.glamRadiance:
      contrastFactor = 1.12;
      sharpenFactor = 0.22;
      skinSmoothingStrength = 0.70;
      skinWhiteningFactor = 1.12;
      break;
    case AiEnhanceProfile.studioPro:
      contrastFactor = 1.14;
      sharpenFactor = 0.26;
      skinSmoothingStrength = 0.35;
      skinWhiteningFactor = 1.03;
      break;
  }

  // Exposure correction
  if (avgLum < 125) {
    exposureMultiplier = (138.0 / max(60.0, avgLum)).clamp(1.02, 1.35);
  } else if (avgLum > 165) {
    exposureMultiplier = (155.0 / avgLum).clamp(0.85, 0.98);
  }

  // White balance gain
  final gainR = avgR > 10 ? (avgGray / avgR).clamp(0.90, 1.12) : 1.0;
  final gainG = avgG > 10 ? (avgGray / avgG).clamp(0.92, 1.08) : 1.0;
  final gainB = avgB > 10 ? (avgGray / avgB).clamp(0.90, 1.15) : 1.0;

  // 3. Stage 1: Color, Exposure & Tone Curve
  final processed = img.Image(width: w, height: h, numChannels: source.numChannels);

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final p = source.getPixel(x, y);

      double r = p.r * gainR * exposureMultiplier;
      double g = p.g * gainG * exposureMultiplier;
      double b = p.b * gainB * exposureMultiplier;

      // S-curve contrast boost around midtones (128)
      r = ((r - 128.0) * contrastFactor + 128.0).clamp(0.0, 255.0);
      g = ((g - 128.0) * contrastFactor + 128.0).clamp(0.0, 255.0);
      b = ((b - 128.0) * contrastFactor + 128.0).clamp(0.0, 255.0);

      processed.setPixelRgb(x, y, r.round(), g.round(), b.round());
    }
  }

  // 4. Stage 2: Beauty Camera Skin Smoothing & Skin Glow
  var smoothed = processed;
  if (skinSmoothingStrength > 0.05) {
    smoothed = _applyBeautySkinSmoothing(
      processed,
      strength: skinSmoothingStrength,
      whitening: skinWhiteningFactor,
    );
  }

  // 5. Stage 3: Detail & Eye Clarity (Unsharp Mask)
  final enhanced = img.Image(width: w, height: h, numChannels: source.numChannels);
  final k = sharpenFactor;

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      if (x == 0 || x == w - 1 || y == 0 || y == h - 1) {
        final p = smoothed.getPixel(x, y);
        enhanced.setPixelRgb(x, y, p.r, p.g, p.b);
        continue;
      }

      final center = smoothed.getPixel(x, y);
      final top = smoothed.getPixel(x, y - 1);
      final bottom = smoothed.getPixel(x, y + 1);
      final left = smoothed.getPixel(x - 1, y);
      final right = smoothed.getPixel(x + 1, y);

      final sharpR = (center.r * (1.0 + 4.0 * k) - k * (top.r + bottom.r + left.r + right.r)).clamp(0.0, 255.0);
      final sharpG = (center.g * (1.0 + 4.0 * k) - k * (top.g + bottom.g + left.g + right.g)).clamp(0.0, 255.0);
      final sharpB = (center.b * (1.0 + 4.0 * k) - k * (top.b + bottom.b + left.b + right.b)).clamp(0.0, 255.0);

      enhanced.setPixelRgb(x, y, sharpR.round(), sharpG.round(), sharpB.round());
    }
  }

  // Save enhanced photo
  final jpgBytes = img.encodeJpg(enhanced, quality: 96);
  await File(params.outputPath).writeAsBytes(jpgBytes);

  return AiEnhanceResult(
    originalImagePath: params.inputPath,
    enhancedImagePath: params.outputPath,
    profile: profile,
    exposureAdjustment: exposureMultiplier,
    contrastMultiplier: contrastFactor,
    sharpnessFactor: sharpenFactor,
    noiseReduced: true,
    whiteBalanceCorrected: true,
    summary: 'Skin smoothed with ${profile.title}, blemish reduction active, exposure balanced.',
  );
}

/// Beauty Camera Bilateral Filter: Smooths skin pores & blemishes while preserving eyes, hair, beard, and edges
img.Image _applyBeautySkinSmoothing(
  img.Image src, {
  required double strength,
  required double whitening,
}) {
  final output = img.Image.from(src);
  final w = src.width;
  final h = src.height;

  final radius = (strength >= 0.6 ? 2 : 1);
  final spatialSigmaSq = 2.0 * radius * radius;
  final colorSigmaSq = 24.0 * 24.0 * (1.0 + strength * 0.5) * (1.0 + strength * 0.5);

  // Pre-calculate spatial weights to avoid doing exp() millions of times
  final spatialWeights = List<double>.filled((2 * radius + 1) * (2 * radius + 1), 0.0);
  for (int dy = -radius; dy <= radius; dy++) {
    for (int dx = -radius; dx <= radius; dx++) {
      final spatialDistSq = (dx * dx + dy * dy).toDouble();
      spatialWeights[(dy + radius) * (2 * radius + 1) + (dx + radius)] = exp(-spatialDistSq / spatialSigmaSq);
    }
  }

  for (int y = radius; y < h - radius; y++) {
    for (int x = radius; x < w - radius; x++) {
      final centerP = src.getPixel(x, y);
      final cr = centerP.r.toDouble();
      final cg = centerP.g.toDouble();
      final cb = centerP.b.toDouble();

      // Calculate Skin Confidence (YCbCr Locus)
      final lum = 0.299 * cr + 0.587 * cg + 0.114 * cb;
      final cbVal = 128 - 0.168736 * cr - 0.331264 * cg + 0.5 * cb;
      final crVal = 128 + 0.5 * cr - 0.418688 * cg - 0.081312 * cb;

      final isSkinColor = (cr > cg && cg > cb && (cr - cg) > 10 && lum > 40 && cbVal >= 75 && cbVal <= 130 && crVal >= 130 && crVal <= 180);

      if (!isSkinColor) {
        continue;
      }

      double weightSum = 0;
      double rSum = 0, gSum = 0, bSum = 0;
      
      int weightIdx = 0;

      for (int dy = -radius; dy <= radius; dy++) {
        for (int dx = -radius; dx <= radius; dx++) {
          final np = src.getPixel(x + dx, y + dy);
          final nr = np.r.toDouble();
          final ng = np.g.toDouble();
          final nb = np.b.toDouble();

          final colorDistSq = (cr - nr) * (cr - nr) + (cg - ng) * (cg - ng) + (cb - nb) * (cb - nb);

          // Bilateral weights (spatial pre-calculated, removed sqrt from color)
          final spatialW = spatialWeights[weightIdx++];
          final colorW = exp(-colorDistSq / colorSigmaSq);
          final wFactor = spatialW * colorW;

          rSum += nr * wFactor;
          gSum += ng * wFactor;
          bSum += nb * wFactor;
          weightSum += wFactor;
        }
      }

      if (weightSum > 0.001) {
        var smoothR = rSum / weightSum;
        var smoothG = gSum / weightSum;
        var smoothB = bSum / weightSum;

        // Blend with original based on strength
        var finalR = cr * (1.0 - strength) + smoothR * strength;
        var finalG = cg * (1.0 - strength) + smoothG * strength;
        var finalB = cb * (1.0 - strength) + smoothB * strength;

        // Apply skin radiance / soft tone whitening
        if (whitening > 1.0) {
          final lift = (whitening - 1.0) * 0.8;
          finalR = (finalR * (1.0 + lift)).clamp(0.0, 255.0);
          finalG = (finalG * (1.0 + lift * 0.9)).clamp(0.0, 255.0);
          finalB = (finalB * (1.0 + lift * 0.85)).clamp(0.0, 255.0);
        }

        output.setPixelRgb(
          x,
          y,
          finalR.round().clamp(0, 255),
          finalG.round().clamp(0, 255),
          finalB.round().clamp(0, 255),
        );
      }
    }
  }

  return output;
}
