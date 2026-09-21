import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/outfit_template.dart';
import '../../../../data/repositories/outfit_repository.dart';
import '../controllers/editor_controller.dart';
import '../../../../core/widgets/outfit_painter.dart';

class OutfitSelectorPanel extends StatefulWidget {
  const OutfitSelectorPanel({super.key});

  @override
  State<OutfitSelectorPanel> createState() => _OutfitSelectorPanelState();
}

class _OutfitSelectorPanelState extends State<OutfitSelectorPanel> {
  final EditorController controller = Get.find<EditorController>();
  OutfitCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header & Remove Outfit
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.style, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Passport Outfits & Suits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Obx(
                  () => controller.selectedOutfit.value != null
                      ? TextButton.icon(
                          onPressed: controller.clearOutfit,
                          icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                          label: const Text('Remove', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip(label: 'All Outfits', category: null),
                  const SizedBox(width: 6),
                  ...OutfitCategory.values.map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: _buildCategoryChip(label: '${cat.emoji} ${cat.title}', category: cat),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Horizontal Outfits List (None + Custom Extractor + Preset Outfits + Custom Outfits)
            Obx(() {
              final presetOutfits = OutfitRepository.getByCategory(_selectedCategory);
              final customOutfits = controller.customOutfits.where((o) => _selectedCategory == null || _selectedCategory == OutfitCategory.custom).toList();
              final allDisplayOutfits = [...customOutfits, ...presetOutfits];

              return SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: allDisplayOutfits.length + 2,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildNoneCard();
                    }
                    if (index == 1) {
                      return _buildExtractCustomCard();
                    }
                    final outfit = allDisplayOutfits[index - 2];
                    return _buildOutfitCard(outfit);
                  },
                ),
              );
            }),
            const SizedBox(height: 10),

            // Fine-Tuning Adjustments when outfit is active
            Obx(() {
              final currentOutfit = controller.selectedOutfit.value;
              if (currentOutfit == null) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  child: const Text(
                    'Select any suit above or extract from your own photo.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Fit & Position: ${currentOutfit.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.flip, size: 18),
                            tooltip: 'Flip Outfit',
                            onPressed: controller.toggleOutfitFlip,
                          ),
                          IconButton(
                            icon: const Icon(Icons.restart_alt, size: 18),
                            tooltip: 'Reset Fit',
                            onPressed: controller.resetOutfitTransform,
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Scale & Position Sliders
                  Row(
                    children: [
                      Expanded(
                        child: _buildSlider(
                          label: 'Size / Scale',
                          value: controller.outfitTransform.value.scale,
                          min: 0.75,
                          max: 1.35,
                          onChanged: (v) => controller.updateOutfitTransform(
                            controller.outfitTransform.value.copyWith(scale: v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSlider(
                          label: 'Shoulder Width',
                          value: controller.outfitTransform.value.shoulderWidthScale,
                          min: 0.8,
                          max: 1.3,
                          onChanged: (v) => controller.updateOutfitTransform(
                            controller.outfitTransform.value.copyWith(shoulderWidthScale: v),
                          ),
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: _buildSlider(
                          label: 'Vertical Position (Up/Down)',
                          value: controller.outfitTransform.value.panY,
                          min: -60.0,
                          max: 60.0,
                          onChanged: (v) => controller.updateOutfitTransform(
                            controller.outfitTransform.value.copyWith(panY: v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSlider(
                          label: 'Horizontal (Left/Right)',
                          value: controller.outfitTransform.value.panX,
                          min: -50.0,
                          max: 50.0,
                          onChanged: (v) => controller.updateOutfitTransform(
                            controller.outfitTransform.value.copyWith(panX: v),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip({required String label, required OutfitCategory? category}) {
    final isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 11,
      ),
      onSelected: (_) => setState(() => _selectedCategory = category),
    );
  }

  Widget _buildNoneCard() {
    return Obx(() {
      final isSelected = controller.selectedOutfit.value == null;
      return InkWell(
        onTap: controller.clearOutfit,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 76,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 26, color: isSelected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(height: 4),
              Text(
                'Original\nClothes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildExtractCustomCard() {
    return InkWell(
      onTap: () => _showPhotoSourceDialog(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 84,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF10B981),
            width: 1.5,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 24, color: Color(0xFF10B981)),
            SizedBox(height: 4),
            Text(
              '+ Extract\nfrom Photo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF047857),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoSourceDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Extract Outfit from Custom Photo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select any reference photo with a suit/outfit. AI will isolate the clothes and fit it on your portrait.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Get.back();
                      controller.extractCustomOutfit(source: ImageSource.gallery);
                    },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('From Gallery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    onPressed: () {
                      Get.back();
                      controller.extractCustomOutfit(source: ImageSource.camera);
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutfitCard(OutfitTemplate outfit) {
    return Obx(() {
      final isSelected = controller.selectedOutfit.value?.id == outfit.id;
      return InkWell(
        onTap: () => controller.selectOutfit(outfit),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 86,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              if (!isSelected)
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            children: [
              // Preview Thumbnail (Vector or Extracted PNG)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: const Color(0xFFF1F5F9),
                    alignment: Alignment.center,
                    child: outfit.isCustomImage && outfit.customImagePath != null
                        ? Image.file(
                            File(outfit.customImagePath!),
                            fit: BoxFit.contain,
                          )
                        : CustomPaint(
                            size: const Size(54, 46),
                            painter: OutfitPainter(
                              outfit: outfit,
                              config: const OutfitTransformConfig(scale: 0.75),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                outfit.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
