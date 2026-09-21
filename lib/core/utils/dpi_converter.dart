enum DimensionUnit { mm, cm, inch, px }

class DpiConverter {
  DpiConverter._();

  static const double mmPerInch = 25.4;
  static const double cmPerInch = 2.54;

  /// Convert mm to pixels at a given DPI
  static int mmToPx(double mm, int dpi) {
    return ((mm / mmPerInch) * dpi).round();
  }

  /// Convert cm to pixels at a given DPI
  static int cmToPx(double cm, int dpi) {
    return ((cm / cmPerInch) * dpi).round();
  }

  /// Convert inches to pixels at a given DPI
  static int inchToPx(double inch, int dpi) {
    return (inch * dpi).round();
  }

  /// Convert pixels to mm at a given DPI
  static double pxToMm(int px, int dpi) {
    return (px / dpi) * mmPerInch;
  }

  /// Convert any unit value to millimeters
  static double toMm(double value, DimensionUnit unit, {int dpi = 300}) {
    switch (unit) {
      case DimensionUnit.mm:
        return value;
      case DimensionUnit.cm:
        return value * 10.0;
      case DimensionUnit.inch:
        return value * mmPerInch;
      case DimensionUnit.px:
        return pxToMm(value.round(), dpi);
    }
  }

  /// Convert millimeters to any unit
  static double fromMm(double mm, DimensionUnit unit, {int dpi = 300}) {
    switch (unit) {
      case DimensionUnit.mm:
        return mm;
      case DimensionUnit.cm:
        return mm / 10.0;
      case DimensionUnit.inch:
        return mm / mmPerInch;
      case DimensionUnit.px:
        return mmToPx(mm, dpi).toDouble();
    }
  }

  /// Format dimension string (e.g. "35 × 45 mm" or "2 × 2 in")
  static String formatDimension({
    required double widthMm,
    required double heightMm,
    int dpi = 300,
  }) {
    // If exact 2x2 inch
    if ((widthMm - 50.8).abs() < 0.2 && (heightMm - 50.8).abs() < 0.2) {
      return '2×2 inch (51×51 mm)';
    }
    return '${widthMm.toStringAsFixed(widthMm.truncateToDouble() == widthMm ? 0 : 1)} × ${heightMm.toStringAsFixed(heightMm.truncateToDouble() == heightMm ? 0 : 1)} mm';
  }

  /// Calculate pixel size at 300 DPI
  static String formatPixelsAtDpi({
    required double widthMm,
    required double heightMm,
    int dpi = 300,
  }) {
    final wPx = mmToPx(widthMm, dpi);
    final hPx = mmToPx(heightMm, dpi);
    return '$wPx × $hPx px @ $dpi DPI';
  }
}
