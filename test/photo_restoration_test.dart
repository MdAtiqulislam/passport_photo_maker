import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:passport_photo_maker/app/modules/restoration/controllers/restoration_controller.dart';
import 'package:passport_photo_maker/core/services/photo_restoration_service.dart';
import 'package:passport_photo_maker/data/models/restoration_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File sampleColorFile;
  late File sampleGrayscaleFile;
  late File sampleScratchedFile;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('restoration_test_');

    // 1. Create Sample Color Photo (100x120)
    final colorImg = img.Image(width: 100, height: 120);
    for (int y = 0; y < 120; y++) {
      for (int x = 0; x < 100; x++) {
        colorImg.setPixelRgb(x, y, (120 + x).clamp(0, 255), (80 + y).clamp(0, 255), 60);
      }
    }
    sampleColorFile = File('${tempDir.path}/sample_color.jpg');
    await sampleColorFile.writeAsBytes(img.encodeJpg(colorImg));

    // 2. Create Sample Grayscale / B&W Photo (100x120)
    final grayImg = img.Image(width: 100, height: 120);
    for (int y = 0; y < 120; y++) {
      for (int x = 0; x < 100; x++) {
        final lum = (100 + (x + y) ~/ 2).clamp(0, 255);
        grayImg.setPixelRgb(x, y, lum, lum, lum);
      }
    }
    sampleGrayscaleFile = File('${tempDir.path}/sample_gray.jpg');
    await sampleGrayscaleFile.writeAsBytes(img.encodeJpg(grayImg));

    // 3. Create Sample Scratched Photo (White line artifacts)
    final scratchedImg = img.Image.from(colorImg);
    for (int i = 10; i < 90; i++) {
      scratchedImg.setPixelRgb(i, i, 255, 255, 255); // diagonal scratch
    }
    sampleScratchedFile = File('${tempDir.path}/sample_scratched.jpg');
    await sampleScratchedFile.writeAsBytes(img.encodeJpg(scratchedImg));
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AI Photo Restoration Engine Tests', () {
    test('PhotoAnalysisReport correctly identifies color vs grayscale images', () async {
      final colorReport = await PhotoRestorationService.analyzePhoto(sampleColorFile);
      expect(colorReport.isGrayscale, isFalse);
      expect(colorReport.width, equals(100));
      expect(colorReport.height, equals(120));

      final grayReport = await PhotoRestorationService.analyzePhoto(sampleGrayscaleFile);
      expect(grayReport.isGrayscale, isTrue);
      expect(grayReport.detectedDefectLabels, contains('Black & White Photo'));
    });

    test('PhotoAnalysisReport detects scratch and impulse damage points', () async {
      final scratchedReport = await PhotoRestorationService.analyzePhoto(sampleScratchedFile);
      expect(scratchedReport.estimatedDamagePoints, greaterThan(0));
    });

    test('PhotoRestorationService restores photo with Medium strength', () async {
      final outPath = '${tempDir.path}/restored_medium.jpg';
      final result = await PhotoRestorationService.restorePhoto(
        imageFile: sampleColorFile,
        options: const RestorationOptions(strength: RestorationStrength.medium),
        outputPath: outPath,
      );

      expect(File(result.restoredImagePath).existsSync(), isTrue);
      expect(result.finalWidth, equals(100));
      expect(result.finalHeight, equals(120));
      expect(result.processingTimeMs, greaterThan(0));
    });

    test('PhotoRestorationService applies B&W colorization when enabled', () async {
      final outPath = '${tempDir.path}/restored_colorized.jpg';
      final result = await PhotoRestorationService.restorePhoto(
        imageFile: sampleGrayscaleFile,
        options: const RestorationOptions(
          strength: RestorationStrength.medium,
          colorize: true,
        ),
        outputPath: outPath,
      );

      expect(File(result.restoredImagePath).existsSync(), isTrue);
      // Verify image now has color channels
      final restoredImg = img.decodeImage(await File(result.restoredImagePath).readAsBytes())!;
      final p = restoredImg.getPixel(50, 60);
      expect(p.r, isNot(equals(p.b))); // Color channels are distinct
    });

    test('PhotoRestorationService performs 2x upscaling when requested', () async {
      final outPath = '${tempDir.path}/restored_upscaled.jpg';
      final result = await PhotoRestorationService.restorePhoto(
        imageFile: sampleColorFile,
        options: const RestorationOptions(upscaleFactor: 2),
        outputPath: outPath,
      );

      expect(result.finalWidth, equals(200));
      expect(result.finalHeight, equals(240));
    });

    test('PhotoRestorationService heals explicit spot at coordinates successfully', () async {
      final outPath = '${tempDir.path}/healed.jpg';
      final healedPath = await PhotoRestorationService.healSpotAtCoordinates(
        imageFile: sampleColorFile,
        normX: 0.5,
        normY: 0.5,
        normRadius: 0.05,
        outputPath: outPath,
      );

      expect(File(healedPath).existsSync(), isTrue);
      final healedImg = img.decodeImage(await File(healedPath).readAsBytes());
      expect(healedImg, isNotNull);
      expect(healedImg!.width, equals(100));
      expect(healedImg.height, equals(120));
    });

    test('RestorationController manages state and strength switching', () {
      Get.testMode = true;
      final controller = RestorationController();

      expect(controller.selectedStrength.value, equals(RestorationStrength.medium));
      expect(controller.upscaleFactor.value, equals(1));
      expect(controller.colorizeBw.value, isFalse);

      controller.setStrength(RestorationStrength.high);
      expect(controller.selectedStrength.value, equals(RestorationStrength.high));

      controller.toggleColorize(true);
      expect(controller.colorizeBw.value, isTrue);

      controller.setUpscaleFactor(2);
      expect(controller.upscaleFactor.value, equals(2));

      controller.resetAndChooseAnother();
      expect(controller.originalImagePath.value, isEmpty);
      expect(controller.restoredImagePath.value, isEmpty);
      expect(controller.selectedStrength.value, equals(RestorationStrength.medium));
    });
  });
}
