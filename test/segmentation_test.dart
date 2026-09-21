import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passport_photo_maker/core/services/portrait_segmentation_service.dart';
import 'package:passport_photo_maker/data/models/segmentation_result.dart';

void main() {
  group('Portrait Segmentation & Smart Boundary Unit Tests', () {
    test('Calculates smart head-to-chest boundary with face detection', () {
      // 1000 x 1000 image, face at (300, 200, 400, 400)
      const faceRect = Rect.fromLTWH(300, 200, 400, 400);

      final cropRect = PortraitSegmentationService.calculateSmartHeadToChestBoundary(
        imageWidth: 1000,
        imageHeight: 1000,
        faceRect: faceRect,
        chestBoundaryRatio: 0.85,
        headroomRatio: 0.10,
        targetAspectRatio: 35.0 / 45.0,
      );

      // Verify that cropRect is within image bounds
      expect(cropRect.left, greaterThanOrEqualTo(0.0));
      expect(cropRect.top, greaterThanOrEqualTo(0.0));
      expect(cropRect.right, lessThanOrEqualTo(1000.0));
      expect(cropRect.bottom, lessThanOrEqualTo(1000.0));

      // Verify aspect ratio
      final calculatedRatio = cropRect.width / cropRect.height;
      expect(calculatedRatio, closeTo(35.0 / 45.0, 0.05));
    });

    test('SegmentationMaskData correctly indexes and retrieves confidences', () {
      final confs = Float32List.fromList([0.1, 0.5, 0.9, 0.0]);
      final maskData = SegmentationMaskData(width: 2, height: 2, confidences: confs);

      expect(maskData.getConfidence(0, 0), closeTo(0.1, 0.001));
      expect(maskData.getConfidence(1, 0), closeTo(0.5, 0.001));
      expect(maskData.getConfidence(0, 1), closeTo(0.9, 0.001));
      expect(maskData.getConfidence(1, 1), closeTo(0.0, 0.001));
      // Out of bounds
      expect(maskData.getConfidence(-1, 0), equals(0.0));
      expect(maskData.getConfidence(5, 5), equals(0.0));
    });

    test('PortraitCropConfig default parameters and copyWith', () {
      const config = PortraitCropConfig();
      expect(config.chestBoundaryRatio, equals(0.85));
      expect(config.headroomRatio, equals(0.10));
      expect(config.backgroundColor, equals(Colors.white));

      final updated = config.copyWith(
        chestBoundaryRatio: 0.70,
        backgroundColor: Colors.blue,
      );
      expect(updated.chestBoundaryRatio, equals(0.70));
      expect(updated.backgroundColor, equals(Colors.blue));
      expect(updated.headroomRatio, equals(0.10));
    });
    test('SegmentationMaskData clone and clear create independent copies', () {
      final confs = Float32List.fromList([0.2, 0.4, 0.6, 0.8]);
      final original = SegmentationMaskData(width: 2, height: 2, confidences: confs);
      final cloned = original.clone();

      // Modify cloned
      cloned.setConfidence(0, 0, 1.0);
      expect(cloned.getConfidence(0, 0), equals(1.0));
      expect(original.getConfidence(0, 0), closeTo(0.2, 0.001)); // Original unchanged

      final emptyMask = SegmentationMaskData.empty(2, 2);
      expect(emptyMask.getConfidence(0, 0), equals(0.0));
      expect(emptyMask.getConfidence(1, 1), equals(0.0));
    });

    test('SegmentationMaskData applyBrushStroke correctly adds and removes areas', () {
      // 10x10 empty mask
      final mask = SegmentationMaskData.empty(10, 10);

      // Paint center with Add brush
      mask.applyBrushStroke(
        normX: 0.5,
        normY: 0.5,
        normRadius: 0.2, // 2px radius
        isAdd: true,
        feather: 0.0,
      );

      // Center should now have high confidence
      expect(mask.getConfidence(5, 5), equals(1.0));

      // Now erase center with Remove brush
      mask.applyBrushStroke(
        normX: 0.5,
        normY: 0.5,
        normRadius: 0.2,
        isAdd: false,
        feather: 0.0,
      );

      // Center should now be erased (0.0)
      expect(mask.getConfidence(5, 5), equals(0.0));
    });

    test('SegmentationMaskData bilinear and gaussian feathering interpolation', () {
      final confs = Float32List.fromList([
        0.0, 1.0,
        0.0, 1.0,
      ]);
      final mask = SegmentationMaskData(width: 2, height: 2, confidences: confs);

      // Midpoint (0.5, 0.5) should smoothly interpolate to 0.5
      final bilinearMid = mask.getBilinearConfidence(0.5, 0.5);
      expect(bilinearMid, closeTo(0.5, 0.05));

      // Feathered sampling should produce smooth non-discrete values
      final feathered = mask.getFeatheredConfidence(0.5, 0.5, 0.1);
      expect(feathered, greaterThan(0.0));
      expect(feathered, lessThan(1.0));
    });
  });
}
