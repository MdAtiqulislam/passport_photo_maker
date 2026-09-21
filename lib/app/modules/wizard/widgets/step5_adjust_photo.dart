import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/outfit_painter.dart';
import '../../../../data/models/outfit_template.dart';
import '../../../routes/app_pages.dart';
import '../../camera/widgets/camera_guide_overlay.dart';
import '../controllers/wizard_controller.dart';

class Step5AdjustPhoto extends StatefulWidget {
  const Step5AdjustPhoto({super.key});

  @override
  State<Step5AdjustPhoto> createState() => _Step5AdjustPhotoState();
}

class _Step5AdjustPhotoState extends State<Step5AdjustPhoto> {
  final WizardController controller = Get.find<WizardController>();
  final TransformationController _transformController = TransformationController();

  double _viewportW = 0;
  double _viewportH = 0;
  double _frameW = 0;
  double _frameH = 0;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformationChanged);
  }

  void _onTransformationChanged() {
    final matrix = _transformController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final translation = matrix.getTranslation();

    controller.zoomScale.value = scale;
    controller.panOffsetX.value = translation.x;
    controller.panOffsetY.value = translation.y;

    _calculateNormalizedCrop();
  }

  void _calculateNormalizedCrop() {
    if (_viewportW <= 0 || _viewportH <= 0 || _frameW <= 0 || _frameH <= 0) return;

    final matrix = _transformController.value;
    final scale = matrix.getMaxScaleOnAxis().clamp(0.5, 6.0);
    final translation = matrix.getTranslation();

    final targetAspectRatio = controller.selectedPhotoSize.value.aspectRatio;
    final containerAspect = _viewportW / _viewportH;
    double baseDisplayW;
    double baseDisplayH;

    if (targetAspectRatio > containerAspect) {
      baseDisplayW = _viewportW;
      baseDisplayH = _viewportW / targetAspectRatio;
    } else {
      baseDisplayH = _viewportH;
      baseDisplayW = _viewportH * targetAspectRatio;
    }

    final baseLeft = (_viewportW - baseDisplayW) / 2.0;
    final baseTop = (_viewportH - baseDisplayH) / 2.0;

    final frameLeft = (_viewportW - _frameW) / 2.0;
    final frameTop = (_viewportH - _frameH) / 2.0;
    final frameRight = frameLeft + _frameW;
    final frameBottom = frameTop + _frameH;

    final double normLeft = ((frameLeft - translation.x - baseLeft) / (baseDisplayW * scale)).clamp(0.0, 1.0);
    final double normTop = ((frameTop - translation.y - baseTop) / (baseDisplayH * scale)).clamp(0.0, 1.0);
    final double normRight = ((frameRight - translation.x - baseLeft) / (baseDisplayW * scale)).clamp(0.0, 1.0);
    final double normBottom = ((frameBottom - translation.y - baseTop) / (baseDisplayH * scale)).clamp(0.0, 1.0);

    final double normW = (normRight - normLeft).clamp(0.05, 1.0);
    final double normH = (normBottom - normTop).clamp(0.05, 1.0);

    controller.updateCropBounds(
      normX: normLeft,
      normY: normTop,
      normW: normW,
      normH: normH,
    );
  }

  void _openOutfitSelectorModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '👔 Choose Formal Outfit',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (controller.selectedOutfit.value != null)
                        TextButton(
                          onPressed: () {
                            controller.selectOutfit(null);
                            Navigator.of(ctx).pop();
                          },
                          child: const Text('Clear Outfit', style: TextStyle(color: Colors.redAccent)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: controller.availableOutfits.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.checkroom_outlined, size: 48, color: Colors.white38),
                                const SizedBox(height: 10),
                                const Text(
                                  'No Outfits Saved Yet',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Import transparent PNG outfits from Outfit Gallery',
                                  style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    Get.toNamed(Routes.OUTFIT_GALLERY);
                                  },
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Open Outfit Gallery'),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            controller: scrollController,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.88,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: controller.availableOutfits.length,
                            itemBuilder: (context, index) {
                              final outfit = controller.availableOutfits[index];
                              final isSel = controller.selectedOutfit.value?.id == outfit.id;

                              return InkWell(
                                onTap: () {
                                  controller.selectOutfit(outfit);
                                  Navigator.of(ctx).pop();
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSel ? AppColors.primary : const Color(0xFF334155),
                                      width: isSel ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Center(
                                          child: outfit.isCustomImage && outfit.customImagePath != null
                                              ? Image.file(File(outfit.customImagePath!), fit: BoxFit.contain)
                                              : CustomPaint(
                                                  size: const Size(90, 70),
                                                  painter: OutfitPainter(
                                                    outfit: outfit,
                                                    config: OutfitTransformConfig(scale: 0.75),
                                                  ),
                                                ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child: Text(
                                          outfit.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: isSel ? AppColors.accent : Colors.white,
                                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformationChanged);
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Adjust Your Photo',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Drag to position & pinch to zoom into the passport frame.',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Viewport with Biometric Guide Box
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _viewportW = constraints.maxWidth;
                _viewportH = constraints.maxHeight;

                final targetAspectRatio = controller.selectedPhotoSize.value.aspectRatio;
                _frameW = _viewportW * 0.78;
                _frameH = _frameW / targetAspectRatio;

                if (_frameH > _viewportH * 0.85) {
                  _frameH = _viewportH * 0.85;
                  _frameW = _frameH * targetAspectRatio;
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _calculateNormalizedCrop();
                });

                return Container(
                  decoration: BoxDecoration(
                    color: context.cardAltColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.borderColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Transformable Viewport
                      Positioned.fill(
                        child: Obx(() {
                          final cutout = controller.cutoutPreviewPath.value;
                          final displayPath = (cutout.isNotEmpty && File(cutout).existsSync())
                              ? cutout
                              : controller.activeImagePath.value;

                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..rotateZ(controller.rotationDegrees.value * 3.1415926535 / 180)
                              ..scale(controller.flipHorizontal.value ? -1.0 : 1.0, 1.0),
                            child: InteractiveViewer(
                              transformationController: _transformController,
                              minScale: 0.8,
                              maxScale: 4.0,
                              boundaryMargin: const EdgeInsets.all(200),
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.file(File(displayPath), fit: BoxFit.contain),
                                    if (controller.selectedOutfit.value != null)
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: OutfitPainter(
                                            outfit: controller.selectedOutfit.value!,
                                            config: controller.outfitTransform.value,
                                            faceRect: controller.segmentationResult.value?.primaryFaceRect,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),

                      // Outer Dark Cutout Mask
                      IgnorePointer(
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.65),
                            BlendMode.srcOut,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black,
                                  backgroundBlendMode: BlendMode.dstOut,
                                ),
                              ),
                              Center(
                                child: Container(
                                  width: _frameW,
                                  height: _frameH,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Biometric Guides Overlay
                      IgnorePointer(
                        child: Center(
                          child: Container(
                            width: _frameW,
                            height: _frameH,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.accent, width: 2.0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: CustomPaint(
                              painter: BiometricGuidePainter(
                                showGuidelines: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Quick Rotate / Flip / Outfit / Advanced Tools (Scrollable to prevent overflow)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.textPrimaryColor,
                    side: BorderSide(color: context.borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: controller.rotate90,
                  icon: const Icon(Icons.rotate_right, size: 18),
                  label: const Text('Rotate 90°', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.textPrimaryColor,
                    side: BorderSide(color: context.borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: controller.toggleFlip,
                  icon: const Icon(Icons.flip, size: 18),
                  label: const Text('Flip', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Obx(() {
                  final hasOutfit = controller.selectedOutfit.value != null;
                  return OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: hasOutfit ? const Color(0xFF10B981) : context.textPrimaryColor,
                      side: BorderSide(color: hasOutfit ? const Color(0xFF10B981) : context.borderColor),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () => _openOutfitSelectorModal(context),
                    icon: const Icon(Icons.checkroom_rounded, size: 18),
                    label: Text(hasOutfit ? 'Outfit ✓' : 'Outfit', style: const TextStyle(fontSize: 12)),
                  );
                }),
                const SizedBox(width: 8),
                Obx(() => OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: controller.showAdvancedAdjustments.value ? AppColors.accent : context.textSecondaryColor,
                        side: BorderSide(
                          color: controller.showAdvancedAdjustments.value ? AppColors.accent : context.borderColor,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => controller.showAdvancedAdjustments.toggle(),
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('Advanced', style: TextStyle(fontSize: 12)),
                    )),
              ],
            ),
          ),

          // Expandable Advanced Controls (Headroom, Chest boundary, Formal Suits)
          Obx(() {
            if (!controller.showAdvancedAdjustments.value) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Chest Cutoff', style: TextStyle(color: context.textSecondaryColor, fontSize: 11)),
                      Expanded(
                        child: Slider(
                          value: controller.chestBoundaryRatio.value,
                          min: 0.65,
                          max: 1.0,
                          activeColor: AppColors.accent,
                          onChanged: (val) {
                            controller.chestBoundaryRatio.value = val;
                            controller.triggerCutoutRegeneration();
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Headroom', style: TextStyle(color: context.textSecondaryColor, fontSize: 11)),
                      Expanded(
                        child: Slider(
                          value: controller.headroomRatio.value,
                          min: 0.05,
                          max: 0.20,
                          activeColor: AppColors.accent,
                          onChanged: (val) {
                            controller.headroomRatio.value = val;
                            controller.triggerCutoutRegeneration();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),

          // Primary Continue Action
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: controller.nextStep,
            icon: const Icon(Icons.arrow_forward, size: 20),
            label: const Text('Continue to Photo Size', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
