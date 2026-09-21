import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/editor_controller.dart';
import '../../../../core/constants/app_colors.dart';

class ChestBoundaryPanel extends GetView<EditorController> {
  const ChestBoundaryPanel({super.key});

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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.accessibility_new, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Smart Head-to-Chest Framing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                TextButton.icon(
                  onPressed: controller.runAutomaticSegmentation,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reprocess', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'Fine-tune the natural portrait cutoff from chin down to chest/bust.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),

            // Visual Chest Boundary Quick Preset Chips
            Obx(
              () => Row(
                children: [
                  _buildPresetChip(label: 'Neck & Shoulders', value: 0.70),
                  const SizedBox(width: 8),
                  _buildPresetChip(label: 'Standard Chest', value: 0.85),
                  const SizedBox(width: 8),
                  _buildPresetChip(label: 'Full Bust', value: 1.0),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Chest Boundary Slider
            Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Chest Boundary Cutoff', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(
                        '${(controller.chestBoundaryRatio.value * 100).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                      ),
                    ],
                  ),
                  Slider(
                    value: controller.chestBoundaryRatio.value.clamp(0.65, 1.0),
                    min: 0.65,
                    max: 1.0,
                    divisions: 14,
                    activeColor: AppColors.primary,
                    onChanged: controller.onChestBoundaryChanged,
                  ),
                ],
              ),
            ),

            // Headroom Slider
            Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Headroom (Top Margin)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(
                        '${(controller.headroomRatio.value * 100).round()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                      ),
                    ],
                  ),
                  Slider(
                    value: controller.headroomRatio.value.clamp(0.05, 0.20),
                    min: 0.05,
                    max: 0.20,
                    divisions: 15,
                    activeColor: AppColors.primary,
                    onChanged: controller.onHeadroomChanged,
                  ),
                ],
              ),
            ),

            // Photoshop Edge Softness / Feather Slider
            Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.blur_on, size: 16, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('Edge Softness (Feather)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Text(
                        '${controller.edgeFeatherRadius.value.toStringAsFixed(1)} px',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                      ),
                    ],
                  ),
                  Slider(
                    value: controller.edgeFeatherRadius.value.clamp(0.5, 5.0),
                    min: 0.5,
                    max: 5.0,
                    divisions: 18,
                    activeColor: AppColors.primary,
                    onChanged: controller.onEdgeFeatherChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Manual Mask Action Banner
            Obx(
              () => Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: controller.isManualSelectionActive.value ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: controller.isManualSelectionActive.value ? AppColors.primary : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      controller.isManualSelectionActive.value ? Icons.brush : Icons.auto_awesome,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.isManualSelectionActive.value
                            ? 'Manual mask active (edited with brush)'
                            : 'AI auto mask active',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (controller.isManualSelectionActive.value)
                      TextButton(
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                        onPressed: controller.resetToAutoMask,
                        child: const Text('Reset Auto', style: TextStyle(fontSize: 11)),
                      ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: controller.openManualMaskEditor,
                      icon: const Icon(Icons.edit, size: 13),
                      label: const Text('Refine Mask', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip({required String label, required double value}) {
    final isSelected = (controller.chestBoundaryRatio.value - value).abs() < 0.05;
    return Expanded(
      child: InkWell(
        onTap: () => controller.onChestBoundaryChanged(value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
