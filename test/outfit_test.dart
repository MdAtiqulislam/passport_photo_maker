import 'package:flutter_test/flutter_test.dart';
import 'package:passport_photo_maker/data/models/outfit_template.dart';
import 'package:passport_photo_maker/data/repositories/outfit_repository.dart';

void main() {
  group('Outfit Changer Engine Tests', () {
    test('OutfitRepository is empty initially for user manual curation', () {
      final allOutfits = OutfitRepository.templates;
      expect(allOutfits.isEmpty, isTrue);

      final suits = OutfitRepository.getByCategory(OutfitCategory.suits);
      expect(suits.isEmpty, isTrue);
    });

    test('OutfitTransformConfig copyWith and default parameters', () {
      const config = OutfitTransformConfig();
      expect(config.scale, equals(1.0));
      expect(config.shoulderWidthScale, equals(1.0));
      expect(config.panX, equals(0.0));
      expect(config.panY, equals(0.0));
      expect(config.flipHorizontal, isFalse);

      final updated = config.copyWith(
        scale: 1.15,
        shoulderWidthScale: 1.10,
        panY: 10.0,
        flipHorizontal: true,
      );

      expect(updated.scale, equals(1.15));
      expect(updated.shoulderWidthScale, equals(1.10));
      expect(updated.panY, equals(10.0));
      expect(updated.flipHorizontal, isTrue);
    });
  });
}
