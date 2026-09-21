import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:passport_photo_maker/app/modules/wizard/controllers/wizard_controller.dart';
import 'package:passport_photo_maker/data/models/photo_size.dart';
import 'package:passport_photo_maker/data/models/segmentation_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Step-by-Step Wizard Architecture Tests', () {
    late WizardController controller;

    setUp(() {
      Get.testMode = true;
      controller = WizardController();
    });

    tearDown(() {
      Get.reset();
    });

    test('Initializes with default step 1 and official 35x45mm passport preset', () {
      expect(controller.currentStep.value, equals(1));
      expect(controller.selectedBackgroundColor.value, equals(Colors.white));
      expect(controller.copyCount.value, equals(8));
      expect(controller.selectedPhotoSize.value.widthMm, equals(35.0));
      expect(controller.selectedPhotoSize.value.heightMm, equals(45.0));
      expect(controller.isProcessing.value, isFalse);
    });

    test('Preserves state when navigating backward', () {
      controller.rawImagePath.value = '/fake/path/photo.jpg';
      controller.activeImagePath.value = '/fake/path/photo.jpg';
      controller.currentStep.value = 4; // Background step

      // User chooses Blue background
      controller.setBackgroundColor(const Color(0xFF0284C7));
      expect(controller.selectedBackgroundColor.value, equals(const Color(0xFF0284C7)));

      // User changes copy count
      controller.setCopyCount(12);
      expect(controller.copyCount.value, equals(12));

      // Go back to Step 3
      controller.previousStep();
      expect(controller.currentStep.value, equals(3));

      // State is fully preserved
      expect(controller.selectedBackgroundColor.value, equals(const Color(0xFF0284C7)));
      expect(controller.copyCount.value, equals(12));
      expect(controller.activeImagePath.value, equals('/fake/path/photo.jpg'));
    });

    test('Step 3 undo and redo stack tracks mask alterations', () {
      final confs = Float32List.fromList([0.0, 0.0, 0.0, 0.0]);
      final mask = SegmentationMaskData(width: 2, height: 2, confidences: confs);
      controller.segmentationResult.value = SegmentationResult(isPersonDetected: true, mask: mask);
      controller.workingMask.value = mask.clone();

      expect(controller.canUndo.value, isFalse);
      expect(controller.canRedo.value, isFalse);

      // Apply stroke
      controller.applyBrushStroke(0.5, 0.5);
      expect(controller.canUndo.value, isTrue);

      // Undo stroke
      controller.undoSelection();
      expect(controller.canRedo.value, isTrue);

      // Redo stroke
      controller.redoSelection();
      expect(controller.canUndo.value, isTrue);
    });

    test('Photo Size selection updates aspectRatio and dimensions', () {
      const usVisa = PhotoSize(
        id: 'us_visa',
        country: 'USA',
        countryCode: 'US',
        flag: '🇺🇸',
        name: 'Visa Photo',
        category: 'Visa',
        widthMm: 50.8,
        heightMm: 50.8,
      );

      controller.selectPhotoSize(usVisa);
      expect(controller.selectedPhotoSize.value.id, equals('us_visa'));
      expect(controller.selectedPhotoSize.value.aspectRatio, closeTo(1.0, 0.001));
    });

    test('Create Another resets state and navigates back to Step 1', () {
      controller.currentStep.value = 8;
      controller.activeImagePath.value = '/path/img.jpg';
      controller.singleProcessedImagePath.value = '/path/out.jpg';

      controller.createAnother();

      expect(controller.currentStep.value, equals(1));
      expect(controller.activeImagePath.value, isEmpty);
      expect(controller.singleProcessedImagePath.value, isEmpty);
    });
  });
}
