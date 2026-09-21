import 'package:flutter/material.dart';

enum OutfitCategory {
  all('All Outfits', '✨'),
  suits('Suits', '👔'),
  shirts('Shirts', '👔'),
  blazers('Blazers', '🧥'),
  jackets('Jackets', '🧥'),
  womenFormal('Women\'s', '👗'),
  custom('My Outfits', '📸');

  final String title;
  final String emoji;
  const OutfitCategory(this.title, this.emoji);
}

class OutfitTemplate {
  final String id;
  final String name;
  final OutfitCategory category;
  final String styleDescription;
  final Color suitColor;
  final Color shirtColor;
  final Color tieColor;
  final Color lapelAccentColor;
  final bool hasTie;
  final bool isVNeck;
  final bool isDoubleBreasted;
  final String? badgeText;
  final bool isCustomImage;
  final String? customImagePath;
  final bool isUserCustom;
  final double anchorX; // Normalized anchor offset X (-0.5 to 0.5, default 0.0)
  final double anchorY; // Normalized anchor offset Y (-0.5 to 0.5, default 0.0)
  final double defaultScale;
  final double defaultRotation;
  final DateTime? createdAt;

  const OutfitTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.styleDescription,
    this.suitColor = const Color(0xFF18181B),
    this.shirtColor = const Color(0xFFFFFFFF),
    this.tieColor = const Color(0xFF991B1B),
    this.lapelAccentColor = const Color(0xFF1E293B),
    this.hasTie = true,
    this.isVNeck = false,
    this.isDoubleBreasted = false,
    this.badgeText,
    this.isCustomImage = false,
    this.customImagePath,
    this.isUserCustom = false,
    this.anchorX = 0.0,
    this.anchorY = 0.0,
    this.defaultScale = 1.0,
    this.defaultRotation = 0.0,
    this.createdAt,
  });

  OutfitTemplate copyWith({
    String? id,
    String? name,
    OutfitCategory? category,
    String? styleDescription,
    Color? suitColor,
    Color? shirtColor,
    Color? tieColor,
    Color? lapelAccentColor,
    bool? hasTie,
    bool? isVNeck,
    bool? isDoubleBreasted,
    String? badgeText,
    bool? isCustomImage,
    String? customImagePath,
    bool? isUserCustom,
    double? anchorX,
    double? anchorY,
    double? defaultScale,
    double? defaultRotation,
    DateTime? createdAt,
  }) {
    return OutfitTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      styleDescription: styleDescription ?? this.styleDescription,
      suitColor: suitColor ?? this.suitColor,
      shirtColor: shirtColor ?? this.shirtColor,
      tieColor: tieColor ?? this.tieColor,
      lapelAccentColor: lapelAccentColor ?? this.lapelAccentColor,
      hasTie: hasTie ?? this.hasTie,
      isVNeck: isVNeck ?? this.isVNeck,
      isDoubleBreasted: isDoubleBreasted ?? this.isDoubleBreasted,
      badgeText: badgeText ?? this.badgeText,
      isCustomImage: isCustomImage ?? this.isCustomImage,
      customImagePath: customImagePath ?? this.customImagePath,
      isUserCustom: isUserCustom ?? this.isUserCustom,
      anchorX: anchorX ?? this.anchorX,
      anchorY: anchorY ?? this.anchorY,
      defaultScale: defaultScale ?? this.defaultScale,
      defaultRotation: defaultRotation ?? this.defaultRotation,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'styleDescription': styleDescription,
      'suitColor': suitColor.value,
      'shirtColor': shirtColor.value,
      'tieColor': tieColor.value,
      'lapelAccentColor': lapelAccentColor.value,
      'hasTie': hasTie,
      'isVNeck': isVNeck,
      'isDoubleBreasted': isDoubleBreasted,
      'badgeText': badgeText,
      'isCustomImage': isCustomImage,
      'customImagePath': customImagePath,
      'isUserCustom': isUserCustom,
      'anchorX': anchorX,
      'anchorY': anchorY,
      'defaultScale': defaultScale,
      'defaultRotation': defaultRotation,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory OutfitTemplate.fromJson(Map<String, dynamic> json) {
    OutfitCategory cat = OutfitCategory.custom;
    for (final c in OutfitCategory.values) {
      if (c.name == json['category']) {
        cat = c;
        break;
      }
    }

    return OutfitTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      category: cat,
      styleDescription: json['styleDescription'] as String? ?? 'Custom Outfit',
      suitColor: Color(json['suitColor'] as int? ?? 0xFF18181B),
      shirtColor: Color(json['shirtColor'] as int? ?? 0xFFFFFFFF),
      tieColor: Color(json['tieColor'] as int? ?? 0xFF991B1B),
      lapelAccentColor: Color(json['lapelAccentColor'] as int? ?? 0xFF1E293B),
      hasTie: json['hasTie'] as bool? ?? true,
      isVNeck: json['isVNeck'] as bool? ?? false,
      isDoubleBreasted: json['isDoubleBreasted'] as bool? ?? false,
      badgeText: json['badgeText'] as String?,
      isCustomImage: json['isCustomImage'] as bool? ?? false,
      customImagePath: json['customImagePath'] as String?,
      isUserCustom: json['isUserCustom'] as bool? ?? false,
      anchorX: (json['anchorX'] as num?)?.toDouble() ?? 0.0,
      anchorY: (json['anchorY'] as num?)?.toDouble() ?? 0.0,
      defaultScale: (json['defaultScale'] as num?)?.toDouble() ?? 1.0,
      defaultRotation: (json['defaultRotation'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}

class OutfitTransformConfig {
  final double scale; // 0.7 .. 1.4
  final double shoulderWidthScale; // 0.7 .. 1.4
  final double neckDepthScale; // 0.7 .. 1.4
  final double panX; // -80 .. 80 px
  final double panY; // -80 .. 80 px
  final double rotationDegrees; // -15 .. 15
  final bool flipHorizontal;

  const OutfitTransformConfig({
    this.scale = 1.0,
    this.shoulderWidthScale = 1.0,
    this.neckDepthScale = 1.0,
    this.panX = 0.0,
    this.panY = 0.0,
    this.rotationDegrees = 0.0,
    this.flipHorizontal = false,
  });

  OutfitTransformConfig copyWith({
    double? scale,
    double? shoulderWidthScale,
    double? neckDepthScale,
    double? panX,
    double? panY,
    double? rotationDegrees,
    bool? flipHorizontal,
  }) {
    return OutfitTransformConfig(
      scale: scale ?? this.scale,
      shoulderWidthScale: shoulderWidthScale ?? this.shoulderWidthScale,
      neckDepthScale: neckDepthScale ?? this.neckDepthScale,
      panX: panX ?? this.panX,
      panY: panY ?? this.panY,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      flipHorizontal: flipHorizontal ?? this.flipHorizontal,
    );
  }
}
