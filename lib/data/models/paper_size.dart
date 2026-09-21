class PaperSize {
  final String id;
  final String name;
  final double widthMm;
  final double heightMm;
  final String dimensionLabel;
  final bool isPopular;

  const PaperSize({
    required this.id,
    required this.name,
    required this.widthMm,
    required this.heightMm,
    required this.dimensionLabel,
    this.isPopular = false,
  });

  static const PaperSize a4 = PaperSize(
    id: 'a4',
    name: 'A4',
    widthMm: 210.0,
    heightMm: 297.0,
    dimensionLabel: '210 × 297 mm',
    isPopular: true,
  );

  static const PaperSize photo4x6 = PaperSize(
    id: '4x6',
    name: '4×6 inch (10×15 cm)',
    widthMm: 101.6,
    heightMm: 152.4,
    dimensionLabel: '4 × 6 inches',
    isPopular: true,
  );

  static const PaperSize letter = PaperSize(
    id: 'letter',
    name: 'US Letter',
    widthMm: 215.9,
    heightMm: 279.4,
    dimensionLabel: '8.5 × 11 inches',
  );

  static const PaperSize a5 = PaperSize(
    id: 'a5',
    name: 'A5',
    widthMm: 148.0,
    heightMm: 210.0,
    dimensionLabel: '148 × 210 mm',
  );

  static const PaperSize photo5x7 = PaperSize(
    id: '5x7',
    name: '5×7 inch',
    widthMm: 127.0,
    heightMm: 177.8,
    dimensionLabel: '5 × 7 inches',
  );

  static const List<PaperSize> allSizes = [
    photo4x6,
    a4,
    letter,
    a5,
    photo5x7,
  ];

  static PaperSize fromId(String id) {
    return allSizes.firstWhere((p) => p.id == id, orElse: () => photo4x6);
  }
}
