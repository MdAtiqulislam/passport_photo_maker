import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import '../controllers/editor_controller.dart';
import '../../../../core/constants/app_colors.dart';

class BackgroundPanel extends GetView<EditorController> {
  const BackgroundPanel({super.key});

  static final List<Map<String, dynamic>> presetColors = [
    {'name': 'White', 'color': AppColors.bgWhite, 'border': true},
    {'name': 'Off-White', 'color': AppColors.bgOffWhite, 'border': true},
    {'name': 'Light Blue', 'color': AppColors.bgLightBlue, 'border': false},
    {'name': 'Sky Blue', 'color': AppColors.bgSkyBlue, 'border': false},
    {'name': 'Navy Blue', 'color': AppColors.bgNavyBlue, 'border': false},
    {'name': 'Light Gray', 'color': AppColors.bgLightGray, 'border': false},
    {'name': 'Neutral Gray', 'color': AppColors.bgNeutralGray, 'border': false},
    {'name': 'Red (ID)', 'color': AppColors.bgRed, 'border': false},
  ];

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
            const Text('Background Replacement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            const Text(
              'Select standard solid passport background or pick a custom color.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Color Presets Grid
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ...presetColors.map((item) {
                  final color = item['color'] as Color;
                  final name = item['name'] as String;
                  final hasBorder = item['border'] as bool;

                  return Obx(
                    () {
                      final isSelected = controller.selectedBackgroundColor.value.value == color.value;
                      return InkWell(
                        onTap: () => controller.setBackgroundColor(color),
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (hasBorder ? const Color(0xFFCBD5E1) : Colors.transparent),
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.4),
                                      blurRadius: 8,
                                    ),
                                ],
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      size: 20,
                                      color: color == Colors.white ? AppColors.primary : Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),

                // Custom Color Picker Button
                InkWell(
                  onTap: () => _openColorPicker(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const SweepGradient(
                            colors: [
                              Colors.red,
                              Colors.yellow,
                              Colors.green,
                              Colors.cyan,
                              Colors.blue,
                              Colors.purple,
                              Colors.red,
                            ],
                          ),
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
                        ),
                        child: const Icon(Icons.colorize, size: 20, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Custom',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openColorPicker(BuildContext context) {
    Color pickedColor = controller.selectedBackgroundColor.value;
    Get.dialog(
      AlertDialog(
        title: const Text('Pick Background Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickedColor,
            onColorChanged: (color) => pickedColor = color,
            pickerAreaHeightPercent: 0.7,
            enableAlpha: false,
            displayThumbColor: true,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              controller.setBackgroundColor(pickedColor);
              Get.back();
            },
            child: const Text('Apply Color'),
          ),
        ],
      ),
    );
  }
}
