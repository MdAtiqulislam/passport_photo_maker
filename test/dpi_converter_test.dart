import 'package:flutter_test/flutter_test.dart';
import 'package:passport_photo_maker/core/utils/dpi_converter.dart';

void main() {
  group('DpiConverter Unit Tests', () {
    test('Converts 35x45 mm to pixels at 300 DPI accurately', () {
      // 35 / 25.4 * 300 = 413.3858... -> 413 px
      final wPx = DpiConverter.mmToPx(35.0, 300);
      // 45 / 25.4 * 300 = 531.496... -> 531 px
      final hPx = DpiConverter.mmToPx(45.0, 300);

      expect(wPx, equals(413));
      expect(hPx, equals(531));
    });

    test('Converts 2x2 inch to pixels at 300 DPI accurately', () {
      // 2 * 300 = 600 px
      final wPx = DpiConverter.inchToPx(2.0, 300);
      final hPx = DpiConverter.inchToPx(2.0, 300);

      expect(wPx, equals(600));
      expect(hPx, equals(600));
    });

    test('Converts cm and inches to mm accurately', () {
      expect(DpiConverter.toMm(3.5, DimensionUnit.cm), closeTo(35.0, 0.01));
      expect(DpiConverter.toMm(2.0, DimensionUnit.inch), closeTo(50.8, 0.01));
      expect(DpiConverter.toMm(413, DimensionUnit.px, dpi: 300), closeTo(34.96, 0.1));
    });
  });
}
