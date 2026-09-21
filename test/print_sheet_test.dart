import 'package:flutter_test/flutter_test.dart';
import 'package:passport_photo_maker/data/models/paper_size.dart';
import 'package:passport_photo_maker/data/models/photo_size.dart';
import 'package:passport_photo_maker/data/models/print_sheet_config.dart';

void main() {
  group('Print Sheet Layout Engine Tests', () {
    const passport35x45 = PhotoSize(
      id: 'bd_passport',
      country: 'Bangladesh',
      countryCode: 'BD',
      flag: '🇧🇩',
      name: 'Passport Photo',
      category: 'Passport',
      widthMm: 35.0,
      heightMm: 45.0,
    );

    test('Calculates max copies for 35x45mm on 4x6 inch paper', () {
      // 4x6 inch is 101.6 x 152.4 mm
      // Margin = 5mm, Gap = 2mm
      // Available Width = 101.6 - 10 = 91.6 mm -> fits floor((91.6 + 2) / (35 + 2)) = 2 cols
      // Available Height = 152.4 - 10 = 142.4 mm -> fits floor((142.4 + 2) / (45 + 2)) = 3 rows
      // Total max fit = 2 * 3 = 6 photos
      const config = PrintSheetConfig(
        paperSize: PaperSize.photo4x6,
        photoSize: passport35x45,
        marginMm: 5.0,
        gapMm: 2.0,
      );

      expect(config.maxColumns, equals(2));
      expect(config.maxRows, equals(3));
      expect(config.maxFitCopies, equals(6));
    });

    test('Calculates max copies for 35x45mm on A4 paper', () {
      // A4 is 210 x 297 mm
      // Margin = 5mm, Gap = 2mm
      // Available Width = 210 - 10 = 200 mm -> fits floor((200 + 2) / (35 + 2)) = 5 cols
      // Available Height = 297 - 10 = 287 mm -> fits floor((287 + 2) / (45 + 2)) = 6 rows
      // Total max fit = 5 * 6 = 30 photos
      const config = PrintSheetConfig(
        paperSize: PaperSize.a4,
        photoSize: passport35x45,
        marginMm: 5.0,
        gapMm: 2.0,
      );

      expect(config.maxColumns, equals(5));
      expect(config.maxRows, equals(6));
      expect(config.maxFitCopies, equals(30));
    });

    test('Aligns photos to top of page by default', () {
      const config = PrintSheetConfig(
        paperSize: PaperSize.photo4x6,
        photoSize: passport35x45,
        copies: 2,
        marginMm: 5.0,
        gapMm: 2.0,
      );

      expect(config.alignment, equals(PrintSheetAlignment.top));
      expect(config.startYOffsetMm, equals(5.0)); // Aligns right to top margin
    });

    test('Aligns photos to center of page when selected', () {
      const config = PrintSheetConfig(
        paperSize: PaperSize.photo4x6,
        photoSize: passport35x45,
        copies: 2,
        marginMm: 5.0,
        gapMm: 2.0,
        alignment: PrintSheetAlignment.center,
      );

      expect(config.alignment, equals(PrintSheetAlignment.center));
      expect(config.startYOffsetMm, greaterThan(5.0)); // Centered vertically on 152.4mm page
    });
  });
}
