import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:passport_photo_maker/data/models/outfit_template.dart';
import 'package:passport_photo_maker/data/repositories/outfit_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Outfit Gallery & Template System Tests', () {
    late OutfitRepository repository;

    setUp(() {
      Get.testMode = true;
      repository = OutfitRepository();
    });

    test('OutfitTemplate model JSON serialization & deserialization', () {
      final template = OutfitTemplate(
        id: 'test_suit_123',
        name: 'Presidential Charcoal Suit',
        category: OutfitCategory.suits,
        styleDescription: 'Diplomatic Standard',
        suitColor: const Color(0xFF1E293B),
        shirtColor: Colors.white,
        tieColor: const Color(0xFF991B1B),
        hasTie: true,
        isUserCustom: true,
        customImagePath: '/app/storage/outfit_123.png',
        anchorX: 0.05,
        anchorY: -0.02,
        defaultScale: 1.05,
        createdAt: DateTime(2026, 8, 24),
      );

      final json = template.toJson();
      final reconstructed = OutfitTemplate.fromJson(json);

      expect(reconstructed.id, equals('test_suit_123'));
      expect(reconstructed.name, equals('Presidential Charcoal Suit'));
      expect(reconstructed.category, equals(OutfitCategory.suits));
      expect(reconstructed.isUserCustom, isTrue);
      expect(reconstructed.customImagePath, equals('/app/storage/outfit_123.png'));
      expect(reconstructed.anchorX, closeTo(0.05, 0.001));
      expect(reconstructed.anchorY, closeTo(-0.02, 0.001));
      expect(reconstructed.defaultScale, closeTo(1.05, 0.001));
    });

    test('OutfitRepository starts empty for manual user collection', () {
      final allTemplates = repository.getAllTemplates(includeCustom: false);
      expect(allTemplates.isEmpty, isTrue);

      final suits = repository.getTemplatesByCategory(OutfitCategory.suits);
      expect(suits.isEmpty, isTrue);
    });

    test('OutfitTransformConfig copyWith updates transformation parameters safely', () {
      const initial = OutfitTransformConfig();
      expect(initial.scale, equals(1.0));
      expect(initial.panX, equals(0.0));
      expect(initial.panY, equals(0.0));
      expect(initial.rotationDegrees, equals(0.0));
      expect(initial.flipHorizontal, isFalse);

      final updated = initial.copyWith(
        scale: 1.15,
        panX: 12.0,
        panY: -8.0,
        rotationDegrees: 3.5,
        flipHorizontal: true,
      );

      expect(updated.scale, equals(1.15));
      expect(updated.panX, equals(12.0));
      expect(updated.panY, equals(-8.0));
      expect(updated.rotationDegrees, equals(3.5));
      expect(updated.flipHorizontal, isTrue);
    });
  });
}
