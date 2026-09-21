import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../../data/models/outfit_template.dart';
import '../../data/models/segmentation_result.dart';
import '../utils/file_utils.dart';
import 'portrait_segmentation_service.dart';

class OutfitExtractorService {
  OutfitExtractorService._();

  /// Automatically extract clothing/suit from any user-provided photo (Background Isolate)
  static Future<OutfitTemplate> extractOutfitFromPhoto(File imageFile, {String name = 'Custom Suit'}) async {
    final segmentation = await PortraitSegmentationService.segmentPerson(imageFile);
    final outputPath = await FileUtils.createProjectFilePath(prefix: 'outfit_custom', extension: 'png');

    final params = _OutfitExtractionParams(
      imagePath: imageFile.path,
      outputPath: outputPath,
      maskWidth: segmentation.mask?.width ?? 0,
      maskHeight: segmentation.mask?.height ?? 0,
      maskConfidences: segmentation.mask?.confidences,
      faceRectValues: segmentation.primaryFaceRect != null
          ? [
              segmentation.primaryFaceRect!.left,
              segmentation.primaryFaceRect!.top,
              segmentation.primaryFaceRect!.width,
              segmentation.primaryFaceRect!.height,
            ]
          : null,
    );

    final resultPath = await compute(_runOutfitExtractionIsolate, params);

    return OutfitTemplate(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: OutfitCategory.custom,
      styleDescription: 'Extracted from Custom Photo',
      isCustomImage: true,
      customImagePath: resultPath,
      badgeText: 'Custom',
    );
  }
}

class _OutfitExtractionParams {
  final String imagePath;
  final String outputPath;
  final int maskWidth;
  final int maskHeight;
  final Float32List? maskConfidences;
  final List<double>? faceRectValues;

  _OutfitExtractionParams({
    required this.imagePath,
    required this.outputPath,
    required this.maskWidth,
    required this.maskHeight,
    this.maskConfidences,
    this.faceRectValues,
  });
}

Future<String> _runOutfitExtractionIsolate(_OutfitExtractionParams params) async {
  final rawBytes = await File(params.imagePath).readAsBytes();
  final originalImage = img.decodeImage(rawBytes);

  if (originalImage == null) {
    throw Exception('Could not decode reference photo');
  }

  // Downsample large reference photos (e.g. 4000px down to max 1200px) for ultra-fast processing
  img.Image workingImage = originalImage;
  if (workingImage.width > 1200) {
    workingImage = img.copyResize(workingImage, width: 1200);
  }

  final imgW = workingImage.width;
  final imgH = workingImage.height;

  double chinBottom = imgH * 0.35;
  double faceCenterX = imgW / 2.0;
  double faceWidth = imgW * 0.35;

  if (params.faceRectValues != null && params.faceRectValues!.length == 4) {
    final scaleRatio = imgW / originalImage.width.toDouble();
    chinBottom = (params.faceRectValues![1] + params.faceRectValues![3]) * scaleRatio;
    faceCenterX = (params.faceRectValues![0] + params.faceRectValues![2] / 2) * scaleRatio;
    faceWidth = params.faceRectValues![2] * scaleRatio;
  }

  final outfitCanvas = img.Image(
    width: imgW,
    height: imgH,
    numChannels: 4,
  );

  SegmentationMaskData? mask;
  if (params.maskConfidences != null && params.maskWidth > 0 && params.maskHeight > 0) {
    mask = SegmentationMaskData(
      width: params.maskWidth,
      height: params.maskHeight,
      confidences: params.maskConfidences!,
    );
  }

  final neckRadiusX = faceWidth * 0.45;
  final neckRadiusY = faceWidth * 0.30;
  final neckCenterY = chinBottom - (neckRadiusY * 0.2);

  for (int y = 0; y < imgH; y++) {
    for (int x = 0; x < imgW; x++) {
      final dx = (x - faceCenterX) / neckRadiusX;
      final dy = (y - neckCenterY) / neckRadiusY;
      final isInsideHeadOrNeckCutout = y < chinBottom - (neckRadiusY * 0.8) || (dx * dx + dy * dy <= 1.0);

      if (isInsideHeadOrNeckCutout) {
        outfitCanvas.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }

      double alpha = 1.0;
      if (mask != null) {
        final normX = x / imgW.toDouble();
        final normY = y / imgH.toDouble();
        final conf = mask.getFeatheredConfidence(normX, normY, 0.005);

        if (conf <= 0.15) {
          alpha = 0.0;
        } else if (conf >= 0.85) {
          alpha = 1.0;
        } else {
          final t = (conf - 0.15) / 0.70;
          alpha = t * t * (3.0 - 2.0 * t);
        }
      }

      if (y >= chinBottom - neckRadiusY && y <= chinBottom + neckRadiusY) {
        final neckDist = sqrt(dx * dx + dy * dy);
        if (neckDist > 1.0 && neckDist < 1.3) {
          alpha *= (neckDist - 1.0) / 0.3;
        }
      }

      if (alpha > 0.0) {
        final p = workingImage.getPixel(x, y);
        final a = (alpha * 255).round().clamp(0, 255);
        outfitCanvas.setPixelRgba(x, y, p.r, p.g, p.b, a);
      } else {
        outfitCanvas.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }

  final pngBytes = img.encodePng(outfitCanvas);
  await File(params.outputPath).writeAsBytes(pngBytes);

  return params.outputPath;
}
