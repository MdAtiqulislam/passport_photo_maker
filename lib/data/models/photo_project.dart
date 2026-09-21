import 'photo_size.dart';

class PhotoProject {
  final String id;
  final String title;
  final String originalImagePath;
  final String processedImagePath;
  final String? sheetImagePath;
  final String? pdfPath;
  final PhotoSize photoSize;
  final String? backgroundColor;
  final DateTime createdAt;
  final int copies;

  PhotoProject({
    required this.id,
    required this.title,
    required this.originalImagePath,
    required this.processedImagePath,
    this.sheetImagePath,
    this.pdfPath,
    required this.photoSize,
    this.backgroundColor = 'White',
    required this.createdAt,
    this.copies = 8,
  });

  factory PhotoProject.fromJson(Map<String, dynamic> json) {
    return PhotoProject(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Passport Photo',
      originalImagePath: json['originalImagePath'] as String? ?? '',
      processedImagePath: json['processedImagePath'] as String? ?? '',
      sheetImagePath: json['sheetImagePath'] as String?,
      pdfPath: json['pdfPath'] as String?,
      photoSize: PhotoSize.fromJson(Map<String, dynamic>.from(json['photoSize'] as Map)),
      backgroundColor: json['backgroundColor'] as String? ?? 'White',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      copies: json['copies'] as int? ?? 8,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'originalImagePath': originalImagePath,
      'processedImagePath': processedImagePath,
      'sheetImagePath': sheetImagePath,
      'pdfPath': pdfPath,
      'photoSize': photoSize.toJson(),
      'backgroundColor': backgroundColor,
      'createdAt': createdAt.toIso8601String(),
      'copies': copies,
    };
  }
}
