import 'package:flutter_test/flutter_test.dart';
import 'package:passport_photo_maker/data/models/photo_size.dart';
import 'package:passport_photo_maker/data/models/paper_size.dart';

void main() {
  test('PhotoSize model JSON serialization and deserialization', () {
    const size = PhotoSize(
      id: 'bd_passport',
      country: 'Bangladesh',
      countryCode: 'BD',
      flag: '🇧🇩',
      name: 'Passport Photo',
      category: 'Passport',
      widthMm: 35.0,
      heightMm: 45.0,
    );

    final json = size.toJson();
    final parsed = PhotoSize.fromJson(json);

    expect(parsed.id, equals('bd_passport'));
    expect(parsed.country, equals('Bangladesh'));
    expect(parsed.widthMm, equals(35.0));
    expect(parsed.heightMm, equals(45.0));
  });

  test('PaperSize presets are valid', () {
    expect(PaperSize.allSizes.length, greaterThanOrEqualTo(4));
    expect(PaperSize.a4.widthMm, equals(210.0));
    expect(PaperSize.a4.heightMm, equals(297.0));
  });
}
