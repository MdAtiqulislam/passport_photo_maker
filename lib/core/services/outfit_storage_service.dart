import 'dart:io';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../data/models/outfit_template.dart';
import '../utils/file_utils.dart';

class OutfitStorageService extends GetxService {
  late final GetStorage _box;
  static const String _keyUserOutfits = 'user_custom_outfits';

  Future<OutfitStorageService> init() async {
    await GetStorage.init();
    _box = GetStorage();
    return this;
  }

  /// Get all saved user custom outfits
  List<OutfitTemplate> getUserOutfits() {
    try {
      if (!Get.isRegistered<StorageServiceSafe>()) {
        // Fallback for tests or direct GetStorage
      }
      final list = _box.read<List>(_keyUserOutfits);
      if (list == null) return [];
      return list
          .map((item) => OutfitTemplate.fromJson(Map<String, dynamic>.from(item as Map)))
          .where((o) => o.customImagePath != null && File(o.customImagePath!).existsSync())
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Save new or updated user outfit
  Future<OutfitTemplate> saveCustomOutfit({
    required String name,
    required String sourceImagePath,
    OutfitCategory category = OutfitCategory.custom,
    String? styleDescription,
  }) async {
    // 1. Copy image to persistent application documents folder
    final persistentPath = await FileUtils.createProjectFilePath(prefix: 'outfit_custom', extension: 'png');
    final srcFile = File(sourceImagePath);
    await srcFile.copy(persistentPath);

    final outfit = OutfitTemplate(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: category,
      styleDescription: styleDescription ?? 'Personal Imported Outfit',
      isCustomImage: true,
      customImagePath: persistentPath,
      isUserCustom: true,
      createdAt: DateTime.now(),
    );

    final current = getUserOutfits();
    current.insert(0, outfit);
    await _persistList(current);

    return outfit;
  }

  /// Rename user outfit
  Future<void> renameUserOutfit(String id, String newName) async {
    final list = getUserOutfits();
    final index = list.indexWhere((o) => o.id == id);
    if (index >= 0) {
      list[index] = list[index].copyWith(name: newName);
      await _persistList(list);
    }
  }

  /// Delete user outfit and delete image file from storage
  Future<void> deleteUserOutfit(String id) async {
    final list = getUserOutfits();
    final toDelete = list.firstWhereOrNull((o) => o.id == id);
    if (toDelete != null && toDelete.customImagePath != null) {
      try {
        final f = File(toDelete.customImagePath!);
        if (f.existsSync()) {
          await f.delete();
        }
      } catch (_) {}
    }

    list.removeWhere((o) => o.id == id);
    await _persistList(list);
  }

  Future<void> _persistList(List<OutfitTemplate> list) async {
    final raw = list.map((o) => o.toJson()).toList();
    await _box.write(_keyUserOutfits, raw);
  }
}

class StorageServiceSafe {}
