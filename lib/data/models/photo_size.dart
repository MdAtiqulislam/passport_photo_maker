import '../../core/utils/dpi_converter.dart';

class PhotoSize {
  final String id;
  final String country;
  final String countryCode;
  final String flag;
  final String name;
  final String category; // 'Passport', 'Visa', 'ID Card', 'Stamp', 'Job', 'Custom'
  final double widthMm;
  final double heightMm;
  final int recommendedDpi;
  final String backgroundColor;
  final String description;
  final String officialNotes;
  final bool isPixel;
  final int? widthPx;
  final int? heightPx;

  const PhotoSize({
    required this.id,
    required this.country,
    required this.countryCode,
    required this.flag,
    required this.name,
    required this.category,
    required this.widthMm,
    required this.heightMm,
    this.recommendedDpi = 300,
    this.backgroundColor = 'White',
    this.description = '',
    this.officialNotes = '',
    this.isPixel = false,
    this.widthPx,
    this.heightPx,
  });

  /// Target aspect ratio for cropping (width / height)
  double get aspectRatio => widthMm / heightMm;

  /// Width in pixels at given DPI
  int getWidthPx({int dpi = 300}) {
    if (isPixel && widthPx != null) return widthPx!;
    return DpiConverter.mmToPx(widthMm, dpi);
  }

  /// Height in pixels at given DPI
  int getHeightPx({int dpi = 300}) {
    if (isPixel && heightPx != null) return heightPx!;
    return DpiConverter.mmToPx(heightMm, dpi);
  }

  /// Human readable dimension format (e.g. 35 × 45 mm)
  String get dimensionString => DpiConverter.formatDimension(widthMm: widthMm, heightMm: heightMm);

  /// Pixel description at 300 DPI
  String get pixelString => DpiConverter.formatPixelsAtDpi(widthMm: widthMm, heightMm: heightMm, dpi: recommendedDpi);

  factory PhotoSize.custom({
    required double widthMm,
    required double heightMm,
    int dpi = 300,
    String name = 'Custom Size',
  }) {
    return PhotoSize(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      country: 'Custom',
      countryCode: 'CUSTOM',
      flag: '📐',
      name: name,
      category: 'Custom',
      widthMm: widthMm,
      heightMm: heightMm,
      recommendedDpi: dpi,
      backgroundColor: 'White',
      description: 'Custom dimensions (${widthMm.toStringAsFixed(1)} × ${heightMm.toStringAsFixed(1)} mm)',
      officialNotes: 'User defined custom dimensions.',
    );
  }

  factory PhotoSize.fromJson(Map<String, dynamic> json) {
    return PhotoSize(
      id: json['id'] as String? ?? 'preset_${DateTime.now().millisecondsSinceEpoch}',
      country: json['country'] as String? ?? 'General',
      countryCode: json['countryCode'] as String? ?? 'GEN',
      flag: json['flag'] as String? ?? '🌐',
      name: json['name'] as String? ?? 'Document Photo',
      category: json['category'] as String? ?? 'Passport',
      widthMm: (json['widthMm'] as num?)?.toDouble() ?? 35.0,
      heightMm: (json['heightMm'] as num?)?.toDouble() ?? 45.0,
      recommendedDpi: json['recommendedDpi'] as int? ?? 300,
      backgroundColor: json['backgroundColor'] as String? ?? 'White',
      description: json['description'] as String? ?? '',
      officialNotes: json['officialNotes'] as String? ?? '',
      isPixel: json['isPixel'] as bool? ?? false,
      widthPx: json['widthPx'] as int?,
      heightPx: json['heightPx'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'country': country,
      'countryCode': countryCode,
      'flag': flag,
      'name': name,
      'category': category,
      'widthMm': widthMm,
      'heightMm': heightMm,
      'recommendedDpi': recommendedDpi,
      'backgroundColor': backgroundColor,
      'description': description,
      'officialNotes': officialNotes,
      'isPixel': isPixel,
      if (widthPx != null) 'widthPx': widthPx,
      if (heightPx != null) 'heightPx': heightPx,
    };
  }

  PhotoSize copyWith({
    String? id,
    String? country,
    String? countryCode,
    String? flag,
    String? name,
    String? category,
    double? widthMm,
    double? heightMm,
    int? recommendedDpi,
    String? backgroundColor,
    String? description,
    String? officialNotes,
  }) {
    return PhotoSize(
      id: id ?? this.id,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      flag: flag ?? this.flag,
      name: name ?? this.name,
      category: category ?? this.category,
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      recommendedDpi: recommendedDpi ?? this.recommendedDpi,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      description: description ?? this.description,
      officialNotes: officialNotes ?? this.officialNotes,
      isPixel: isPixel,
      widthPx: widthPx,
      heightPx: heightPx,
    );
  }
}
