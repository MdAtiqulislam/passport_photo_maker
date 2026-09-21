import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:passport_photo_maker/core/services/ai_enhance_service.dart';
import 'package:passport_photo_maker/data/models/ai_enhance_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Photo Enhancement Engine Tests', () {
    late String testImagePath;

    setUp(() async {
      final image = img.Image(width: 300, height: 300);
      for (int y = 0; y < 300; y++) {
        for (int x = 0; x < 300; x++) {
          if (y > 100 && y < 250 && x > 80 && x < 220) {
            // Simulated skin tone region (warm peach)
            image.setPixelRgb(x, y, 220, 160, 140);
          } else {
            // Simulated ambient background with slight indoor yellowish tint
            image.setPixelRgb(x, y, 180, 175, 150);
          }
        }
      }

      final dir = Directory.systemTemp.createTempSync('ai_enhance_test');
      testImagePath = '${dir.path}/test_photo.jpg';
      final jpgBytes = img.encodeJpg(image, quality: 90);
      await File(testImagePath).writeAsBytes(jpgBytes);
    });

    test('AiEnhanceProfile enum values have descriptive titles', () {
      expect(AiEnhanceProfile.subtle.title, contains('Subtle'));
      expect(AiEnhanceProfile.balanced.title, contains('Balanced'));
      expect(AiEnhanceProfile.beautySmooth.title, contains('Beauty Smooth'));
      expect(AiEnhanceProfile.glamRadiance.title, contains('Glam Radiance'));
      expect(AiEnhanceProfile.studioPro.title, contains('Studio Pro'));
    });

    test('AiEnhanceService enhances photo with Balanced profile successfully', () async {
      final outPath = '${Directory.systemTemp.path}/out_balanced.jpg';
      final result = await AiEnhanceService.enhancePhoto(
        imagePath: testImagePath,
        profile: AiEnhanceProfile.balanced,
        outputPath: outPath,
      );

      expect(result.originalImagePath, equals(testImagePath));
      expect(result.enhancedImagePath, isNotEmpty);
      expect(File(result.enhancedImagePath).existsSync(), isTrue);

      final enhancedBytes = await File(result.enhancedImagePath).readAsBytes();
      final decodedEnhanced = img.decodeImage(enhancedBytes);

      expect(decodedEnhanced, isNotNull);
      expect(decodedEnhanced!.width, equals(300));
      expect(decodedEnhanced.height, equals(300));
      expect(result.noiseReduced, isTrue);
      expect(result.whiteBalanceCorrected, isTrue);
      expect(result.summary, contains('Balanced'));
    });

    test('AiEnhanceService applies Beauty Smooth skin smoothing', () async {
      final outPath = '${Directory.systemTemp.path}/out_beauty.jpg';
      final result = await AiEnhanceService.enhancePhoto(
        imagePath: testImagePath,
        profile: AiEnhanceProfile.beautySmooth,
        outputPath: outPath,
      );

      expect(result.profile, equals(AiEnhanceProfile.beautySmooth));
      expect(File(result.enhancedImagePath).existsSync(), isTrue);
      expect(result.summary, contains('Beauty Smooth'));
    });

    test('AiEnhanceService handles Studio Pro profile with higher sharpness', () async {
      final outPath = '${Directory.systemTemp.path}/out_pro.jpg';
      final result = await AiEnhanceService.enhancePhoto(
        imagePath: testImagePath,
        profile: AiEnhanceProfile.studioPro,
        outputPath: outPath,
      );

      expect(result.profile, equals(AiEnhanceProfile.studioPro));
      expect(result.sharpnessFactor, equals(0.26));
      expect(File(result.enhancedImagePath).existsSync(), isTrue);
    });

    test('AiEnhanceService handles Subtle profile with gentle adjustments', () async {
      final outPath = '${Directory.systemTemp.path}/out_subtle.jpg';
      final result = await AiEnhanceService.enhancePhoto(
        imagePath: testImagePath,
        profile: AiEnhanceProfile.subtle,
        outputPath: outPath,
      );

      expect(result.profile, equals(AiEnhanceProfile.subtle));
      expect(result.contrastMultiplier, equals(1.04));
      expect(File(result.enhancedImagePath).existsSync(), isTrue);
    });
  });
}
