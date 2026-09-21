import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/outfit_template.dart';
import '../../../../data/repositories/outfit_repository.dart';
import '../../../routes/app_pages.dart';

class OutfitGalleryController extends GetxController {
  final OutfitRepository _outfitRepo = OutfitRepository();
  final ImagePicker _picker = ImagePicker();

  final Rx<OutfitCategory> selectedCategory = OutfitCategory.all.obs;
  final RxList<OutfitTemplate> allOutfits = <OutfitTemplate>[].obs;
  final RxList<OutfitTemplate> filteredOutfits = <OutfitTemplate>[].obs;
  final RxList<OutfitTemplate> myOutfits = <OutfitTemplate>[].obs;
  final Rx<OutfitTemplate?> selectedOutfit = Rx<OutfitTemplate?>(null);

  final RxBool isLoading = true.obs;
  String? targetPortraitPath;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map && args['imagePath'] != null) {
      targetPortraitPath = args['imagePath'] as String;
    }
    loadOutfits();
  }

  void loadOutfits() {
    isLoading.value = true;
    allOutfits.value = _outfitRepo.getAllTemplates(includeCustom: true);
    myOutfits.value = allOutfits.where((o) => o.isUserCustom).toList();
    _applyFilter();
    isLoading.value = false;
  }

  void selectCategory(OutfitCategory category) {
    selectedCategory.value = category;
    _applyFilter();
  }

  void _applyFilter() {
    if (selectedCategory.value == OutfitCategory.all) {
      filteredOutfits.value = allOutfits;
    } else if (selectedCategory.value == OutfitCategory.custom) {
      filteredOutfits.value = myOutfits;
    } else {
      filteredOutfits.value = allOutfits.where((o) => o.category == selectedCategory.value).toList();
    }
  }

  // ---------------------------------------------------------------------------
  // IMPORT CUSTOM OUTFIT FROM GALLERY
  // ---------------------------------------------------------------------------
  Future<void> importOutfitFromGallery(BuildContext context) async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
      if (picked == null) return;

      final nameController = TextEditingController(text: 'My Custom Suit');
      OutfitCategory category = OutfitCategory.custom;

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Save Custom Outfit',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 120,
                        height: 140,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(picked.path), fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Outfit Name',
                        labelStyle: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Select Category',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        OutfitCategory.suits,
                        OutfitCategory.shirts,
                        OutfitCategory.blazers,
                        OutfitCategory.jackets,
                        OutfitCategory.womenFormal,
                        OutfitCategory.custom,
                      ].map((cat) {
                        final isSel = category == cat;
                        return ChoiceChip(
                          label: Text('${cat.emoji} ${cat.title}'),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : (isDark ? Colors.white70 : AppColors.textPrimary),
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (_) {
                            setModalState(() {
                              category = cat;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white60 : AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim().isNotEmpty ? nameController.text.trim() : 'Custom Outfit';
                    Navigator.of(ctx).pop();

                    final saved = await _outfitRepo.saveCustomOutfit(
                      name: name,
                      sourceImagePath: picked.path,
                      category: category,
                    );

                    if (saved != null) {
                      loadOutfits();
                      Get.snackbar(
                        'Outfit Saved! ✨',
                        'Added "$name" to ${category.title}.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: const Color(0xFF065F46),
                        colorText: Colors.white,
                      );
                    }
                  },
                  child: const Text('Save Outfit'),
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      Get.snackbar('Import Notice', 'Could not import image: $e', colorText: Colors.white);
    }
  }

  // ---------------------------------------------------------------------------
  // OUTFIT ACTIONS (USE, RENAME, DELETE)
  // ---------------------------------------------------------------------------
  void useOutfit(OutfitTemplate outfit) {
    selectedOutfit.value = outfit;

    if (targetPortraitPath != null && targetPortraitPath!.isNotEmpty) {
      // Open editor directly with portrait
      Get.toNamed(Routes.OUTFIT_EDITOR, arguments: {
        'imagePath': targetPortraitPath,
        'outfit': outfit,
      });
    } else {
      // Pick a photo or launch Wizard with this outfit
      Get.toNamed(Routes.OUTFIT_EDITOR, arguments: {
        'outfit': outfit,
      });
    }
  }

  void confirmDeleteOutfit(BuildContext context, OutfitTemplate outfit) {
    if (!outfit.isUserCustom) {
      Get.snackbar('Notice', 'Built-in template outfits cannot be deleted.', colorText: Colors.white);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete this outfit?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text('Are you sure you want to remove "${outfit.name}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF991B1B)),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _outfitRepo.deleteCustomOutfit(outfit.id);
              loadOutfits();
              Get.snackbar('Deleted', 'Outfit removed from My Outfits.', snackPosition: SnackPosition.BOTTOM);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void promptRenameOutfit(BuildContext context, OutfitTemplate outfit) {
    final nameController = TextEditingController(text: outfit.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Rename Outfit', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'New Name', labelStyle: TextStyle(color: Colors.white70)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                Navigator.of(ctx).pop();
                await _outfitRepo.renameCustomOutfit(outfit.id, newName);
                loadOutfits();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
