import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/photo_size.dart';

class TemplateRepository {
  List<PhotoSize> _cachedTemplates = [];

  Future<List<PhotoSize>> getAllTemplates() async {
    if (_cachedTemplates.isNotEmpty) return _cachedTemplates;

    try {
      final jsonString = await rootBundle.loadString('assets/templates/all_templates.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _cachedTemplates = jsonList.map((item) => PhotoSize.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      _cachedTemplates = _getDefaultFallbackTemplates();
    }
    return _cachedTemplates;
  }

  Future<List<PhotoSize>> getPopularTemplates() async {
    final all = await getAllTemplates();
    const popularIds = ['bd_passport', 'us_passport', 'uk_passport', 'ca_passport', 'schengen_visa', 'in_passport', 'bd_stamp', 'bd_job'];
    return all.where((t) => popularIds.contains(t.id)).toList();
  }

  Future<List<PhotoSize>> getTemplatesByCategory(String category) async {
    final all = await getAllTemplates();
    if (category == 'All') return all;
    return all.where((t) => t.category.toLowerCase() == category.toLowerCase()).toList();
  }

  Future<List<PhotoSize>> searchTemplates(String query) async {
    final all = await getAllTemplates();
    if (query.trim().isEmpty) return all;
    final q = query.toLowerCase().trim();
    return all.where((t) {
      return t.country.toLowerCase().contains(q) ||
          t.name.toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q);
    }).toList();
  }

  List<PhotoSize> _getDefaultFallbackTemplates() {
    return const [
      PhotoSize(
        id: 'bd_passport',
        country: 'Bangladesh',
        countryCode: 'BD',
        flag: '🇧🇩',
        name: 'Passport Photo',
        category: 'Passport',
        widthMm: 35.0,
        heightMm: 45.0,
        recommendedDpi: 300,
        backgroundColor: 'White',
        description: 'Standard Bangladesh Passport (35×45 mm)',
        officialNotes: 'White background, 70-80% face height.',
      ),
      PhotoSize(
        id: 'us_passport',
        country: 'United States',
        countryCode: 'US',
        flag: '🇺🇸',
        name: 'Passport & Visa (2×2 in)',
        category: 'Passport',
        widthMm: 50.8,
        heightMm: 50.8,
        recommendedDpi: 300,
        backgroundColor: 'White',
        description: 'US Passport & Visa (2×2 inches / 51×51 mm)',
        officialNotes: 'White background, 1 to 1 3/8 inches face length.',
      ),
      PhotoSize(
        id: 'schengen_visa',
        country: 'Schengen Area (EU)',
        countryCode: 'EU',
        flag: '🇪🇺',
        name: 'Schengen Visa Photo',
        category: 'Visa',
        widthMm: 35.0,
        heightMm: 45.0,
        recommendedDpi: 300,
        backgroundColor: 'Light Gray',
        description: 'Schengen 27 European Countries (35×45 mm)',
        officialNotes: 'Light grey/white background, 70-80% face coverage.',
      ),
    ];
  }
}
