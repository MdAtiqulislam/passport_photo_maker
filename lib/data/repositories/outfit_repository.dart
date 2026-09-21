import 'package:get/get.dart';
import '../../core/services/outfit_storage_service.dart';
import '../models/outfit_template.dart';

class OutfitRepository {
  OutfitStorageService? get _storage =>
      Get.isRegistered<OutfitStorageService>() ? Get.find<OutfitStorageService>() : null;

  // Empty initial templates so user can manually build their own personal outfit gallery
  static const List<OutfitTemplate> templates = [];

  static List<OutfitTemplate> getByCategory(OutfitCategory? category) {
    if (category == null || category == OutfitCategory.all) {
      return templates;
    }
    return templates.where((t) => t.category == category).toList();
  }

  List<OutfitTemplate> getAllTemplates({bool includeCustom = true}) {
    return _storage?.getUserOutfits() ?? [];
  }

  List<OutfitTemplate> getTemplatesByCategory(OutfitCategory category) {
    final list = _storage?.getUserOutfits() ?? [];
    if (category == OutfitCategory.all || category == OutfitCategory.custom) {
      return list;
    }
    return list.where((t) => t.category == category).toList();
  }

  Future<OutfitTemplate?> saveCustomOutfit({
    required String name,
    required String sourceImagePath,
    OutfitCategory category = OutfitCategory.custom,
  }) async {
    return await _storage?.saveCustomOutfit(
      name: name,
      sourceImagePath: sourceImagePath,
      category: category,
    );
  }

  Future<void> deleteCustomOutfit(String id) async {
    await _storage?.deleteUserOutfit(id);
  }

  Future<void> renameCustomOutfit(String id, String newName) async {
    await _storage?.renameUserOutfit(id, newName);
  }
}
