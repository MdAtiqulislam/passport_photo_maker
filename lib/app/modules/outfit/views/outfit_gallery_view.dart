import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/outfit_painter.dart';
import '../../../../data/models/outfit_template.dart';
import '../controllers/outfit_gallery_controller.dart';

class OutfitGalleryView extends GetView<OutfitGalleryController> {
  const OutfitGalleryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgScaffold,
      appBar: AppBar(
        backgroundColor: context.bgSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimaryColor, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Outfit Gallery',
          style: TextStyle(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => controller.importOutfitFromGallery(context),
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
              label: const Text('Add Outfit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category Selector Tabs
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Obx(() {
              final sel = controller.selectedCategory.value;

              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: OutfitCategory.values.map((cat) {
                  final isSel = sel == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text('${cat.emoji} ${cat.title}'),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      backgroundColor: context.bgCard,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : context.textPrimaryColor,
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => controller.selectCategory(cat),
                    ),
                  );
                }).toList(),
              );
            }),
          ),

          // Outfits Grid
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: AppColors.accent));
              }

              final list = controller.filteredOutfits;
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.checkroom_outlined, size: 56, color: context.textSecondaryColor),
                      const SizedBox(height: 12),
                      Text(
                        'No outfits in this category',
                        style: TextStyle(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Import a transparent PNG outfit from your gallery.',
                        style: TextStyle(color: context.textSecondaryColor, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: const BorderSide(color: AppColors.accent),
                        ),
                        onPressed: () => controller.importOutfitFromGallery(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Import Outfit'),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.82,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final outfit = list[index];
                  return _buildOutfitCard(context, outfit);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitCard(BuildContext context, OutfitTemplate outfit) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Badges & Options Menu
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 4, top: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: outfit.isUserCustom ? const Color(0xFF065F46) : const Color(0xFF0369A1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    outfit.isUserCustom ? 'My Outfit' : outfit.category.title,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                if (outfit.isUserCustom)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 18, color: context.textSecondaryColor),
                    color: context.bgCard,
                    onSelected: (val) {
                      if (val == 'rename') {
                        controller.promptRenameOutfit(context, outfit);
                      } else if (val == 'delete') {
                        controller.confirmDeleteOutfit(context, outfit);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'rename', child: Text('Rename', style: TextStyle(color: context.textPrimaryColor))),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
                    ],
                  )
                else
                  const SizedBox(height: 28),
              ],
            ),
          ),

          // Outfit Visual Preview
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: outfit.isCustomImage && outfit.customImagePath != null
                    ? Image.file(File(outfit.customImagePath!), fit: BoxFit.contain)
                    : CustomPaint(
                        size: const Size(120, 100),
                        painter: OutfitPainter(
                          outfit: outfit,
                          config: const OutfitTransformConfig(scale: 0.9),
                        ),
                      ),
              ),
            ),
          ),

          // Title and Select Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  outfit.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => controller.useOutfit(outfit),
                  child: const Text('Use Outfit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
