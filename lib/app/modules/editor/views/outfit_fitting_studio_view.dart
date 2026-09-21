import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/outfit_painter.dart';
import '../../../../data/models/outfit_template.dart';
import '../../../../data/repositories/outfit_repository.dart';
import '../controllers/editor_controller.dart';

class OutfitFittingStudioView extends StatefulWidget {
  const OutfitFittingStudioView({super.key});

  @override
  State<OutfitFittingStudioView> createState() => _OutfitFittingStudioViewState();
}

class _OutfitFittingStudioViewState extends State<OutfitFittingStudioView> {
  final EditorController controller = Get.find<EditorController>();

  late OutfitTemplate? _activeOutfit;
  late OutfitTransformConfig _activeTransform;
  OutfitCategory? _selectedCategory;
  bool _showSliders = true;

  @override
  void initState() {
    super.initState();
    _activeOutfit = controller.selectedOutfit.value;
    _activeTransform = controller.outfitTransform.value;
  }

  void _onOutfitSelected(OutfitTemplate? outfit) {
    setState(() {
      _activeOutfit = outfit;
      if (outfit != null) {
        _showSliders = true;
      }
    });
  }

  void _applyAndClose() {
    if (_activeOutfit == null) {
      controller.clearOutfit();
    } else {
      controller.selectedOutfit.value = _activeOutfit;
      controller.updateOutfitTransform(_activeTransform);
    }
    Get.back();
    Get.snackbar(
      _activeOutfit != null ? 'Outfit Applied ✨' : 'Original Clothes Restored',
      _activeOutfit != null ? 'Fitted ${_activeOutfit!.name} to your passport photo' : 'Removed outfit overlay',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  void _showCustomPhotoPicker() {
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
                    onPressed: () async {
                      Get.back();
                      await controller.extractCustomOutfit(source: ImageSource.gallery);
                      setState(() {
                        _activeOutfit = controller.selectedOutfit.value;
                        _activeTransform = controller.outfitTransform.value;
                      });
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
                    onPressed: () async {
                      Get.back();
                      await controller.extractCustomOutfit(source: ImageSource.camera);
                      setState(() {
                        _activeOutfit = controller.selectedOutfit.value;
                        _activeTransform = controller.outfitTransform.value;
                      });
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

  @override
  Widget build(BuildContext context) {
    final presetOutfits = OutfitRepository.getByCategory(_selectedCategory);
    final customOutfits = controller.customOutfits.where((o) => _selectedCategory == null || _selectedCategory == OutfitCategory.custom).toList();
    final allOutfits = [...customOutfits, ...presetOutfits];

    final isAuto = controller.isAutoResultMode.value;
    final cutoutPath = controller.autoCutoutPath.value;
    final displayFile = (isAuto && cutoutPath.isNotEmpty && File(cutoutPath).existsSync())
        ? File(cutoutPath)
        : File(controller.sourceImagePath);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👔 Outfit Fitting Studio', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Select formal suit & adjust fit onto your portrait', style: TextStyle(color: AppColors.accent, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _applyAndClose,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Apply & Done', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Upper Live Fitting Viewport with Gestures
          Expanded(
            flex: 5,
            child: Container(
              color: const Color(0xFF0B1120),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Base Portrait Photo
                  Center(
                    child: Image.file(
                      displayFile,
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Overlay Outfit
                  if (_activeOutfit != null)
                    Positioned.fill(
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _activeTransform = _activeTransform.copyWith(
                              panX: _activeTransform.panX + details.delta.dx,
                              panY: _activeTransform.panY + details.delta.dy,
                            );
                          });
                        },
                        child: _activeOutfit!.isCustomImage && _activeOutfit!.customImagePath != null
                            ? Transform.translate(
                                offset: Offset(_activeTransform.panX, _activeTransform.panY),
                                child: Transform.scale(
                                  scale: _activeTransform.scale,
                                  child: Transform.flip(
                                    flipX: _activeTransform.flipHorizontal,
                                    child: Image.file(
                                      File(_activeOutfit!.customImagePath!),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              )
                            : CustomPaint(
                                painter: OutfitPainter(
                                  outfit: _activeOutfit!,
                                  config: _activeTransform,
                                  faceRect: controller.segmentationResult.value?.primaryFaceRect,
                                ),
                              ),
                      ),
                    ),

                  // Floating Quick Fit Buttons
                  if (_activeOutfit != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.flip, color: Colors.white, size: 18),
                              tooltip: 'Flip Direction',
                              onPressed: () => setState(() {
                                _activeTransform = _activeTransform.copyWith(
                                  flipHorizontal: !_activeTransform.flipHorizontal,
                                );
                              }),
                            ),
                            IconButton(
                              icon: const Icon(Icons.restart_alt, color: Colors.white, size: 18),
                              tooltip: 'Reset Position',
                              onPressed: () => setState(() {
                                _activeTransform = const OutfitTransformConfig();
                              }),
                            ),
                            IconButton(
                              icon: Icon(_showSliders ? Icons.tune : Icons.tune, color: _showSliders ? AppColors.accent : Colors.white60, size: 18),
                              tooltip: 'Toggle Sliders',
                              onPressed: () => setState(() => _showSliders = !_showSliders),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Touch Guidance Hint
                  if (_activeOutfit != null)
                    Positioned(
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '👆 Drag suit to position onto your neck & shoulders',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom Wardrobe & Controls Panel
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category Filter Chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SingleChildScrollView(
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
                ),

                // Precision Sliders (Collapsible)
                if (_activeOutfit != null && _showSliders)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    color: const Color(0xFF0F172A),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSlider(
                                label: 'Size',
                                value: _activeTransform.scale,
                                min: 0.75,
                                max: 1.35,
                                onChanged: (v) => setState(() => _activeTransform = _activeTransform.copyWith(scale: v)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSlider(
                                label: 'Shoulders',
                                value: _activeTransform.shoulderWidthScale,
                                min: 0.8,
                                max: 1.3,
                                onChanged: (v) => setState(() => _activeTransform = _activeTransform.copyWith(shoulderWidthScale: v)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSlider(
                                label: 'Vertical',
                                value: _activeTransform.panY,
                                min: -60.0,
                                max: 60.0,
                                onChanged: (v) => setState(() => _activeTransform = _activeTransform.copyWith(panY: v)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Wardrobe Carousel
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: allOutfits.length + 2,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildNoneCard();
                        }
                        if (index == 1) {
                          return _buildExtractCustomCard();
                        }
                        final outfit = allOutfits[index - 2];
                        return _buildOutfitCard(outfit);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({required String label, required OutfitCategory? category}) {
    final isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: const Color(0xFF334155),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondaryDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 11,
      ),
      onSelected: (_) => setState(() => _selectedCategory = category),
    );
  }

  Widget _buildNoneCard() {
    final isSelected = _activeOutfit == null;
    return InkWell(
      onTap: () => _onOutfitSelected(null),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 76,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : const Color(0xFF334155),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white12,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 28, color: isSelected ? AppColors.accent : Colors.white70),
            const SizedBox(height: 4),
            Text(
              'Original\nClothes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.accent : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractCustomCard() {
    return InkWell(
      onTap: _showCustomPhotoPicker,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 84,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF065F46).withOpacity(0.4),
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
                color: Color(0xFF34D399),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutfitCard(OutfitTemplate outfit) {
    final isSelected = _activeOutfit?.id == outfit.id;
    return InkWell(
      onTap: () => _onOutfitSelected(outfit),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 86,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : const Color(0xFF334155),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white12,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            // Preview Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: const Color(0xFF1E293B),
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
            Text('${((value / (max == min ? 1 : max)) * 100).round()}%', style: const TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
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
