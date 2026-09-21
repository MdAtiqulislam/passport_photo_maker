import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/editor_controller.dart';
import '../../../../core/constants/app_colors.dart';

class AdjustmentPanel extends GetView<EditorController> {
  const AdjustmentPanel({super.key});

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
                const Text('Photo Adjustments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  onPressed: controller.resetAdjustments,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // AI Photo Enhancement Studio Trigger Button
            Obx(
              () => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: controller.isEnhancedApplied.value
                        ? [const Color(0xFF065F46), const Color(0xFF047857)]
                        : [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: controller.openAiEnhanceScreen,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.isEnhancedApplied.value
                                      ? '✨ AI Enhancement Applied'
                                      : '✨ AI Photo Enhancement & Denoise',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  controller.isEnhancedApplied.value
                                      ? 'Tap to compare Before/After or switch profiles'
                                      : 'Clean noise, sharpen edges & balance exposure',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Manual Auto Enhance quick button
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.isAutoEnhanced.value ? AppColors.gold : AppColors.primaryLight,
                    foregroundColor: controller.isAutoEnhanced.value ? Colors.black : AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: controller.toggleAutoEnhance,
                  icon: const Icon(Icons.tune, size: 18),
                  label: Text(
                    controller.isAutoEnhanced.value ? 'Tone Boost Applied' : 'One-Tap Tone Boost',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Brightness Slider
            Obx(
              () => _buildSlider(
                label: 'Brightness',
                icon: Icons.brightness_6,
                value: controller.brightness.value,
                min: -1.0,
                max: 1.0,
                onChanged: (v) => controller.brightness.value = v,
              ),
            ),

            // Contrast Slider
            Obx(
              () => _buildSlider(
                label: 'Contrast',
                icon: Icons.tonality,
                value: controller.contrast.value,
                min: 0.5,
                max: 1.8,
                onChanged: (v) => controller.contrast.value = v,
              ),
            ),

            // Saturation Slider
            Obx(
              () => _buildSlider(
                label: 'Saturation',
                icon: Icons.color_lens_outlined,
                value: controller.saturation.value,
                min: 0.0,
                max: 2.0,
                onChanged: (v) => controller.saturation.value = v,
              ),
            ),

            // Warmth Slider
            Obx(
              () => _buildSlider(
                label: 'Warmth',
                icon: Icons.wb_sunny_outlined,
                value: controller.warmth.value,
                min: -1.0,
                max: 1.0,
                onChanged: (v) => controller.warmth.value = v,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              activeColor: AppColors.primary,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
