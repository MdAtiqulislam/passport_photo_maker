import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/wizard_controller.dart';

class Step4Background extends GetView<WizardController> {
  const Step4Background({super.key});

  void _openCustomColorPicker(BuildContext context) {
    Color pickerColor = controller.selectedBackgroundColor.value;
    final isDark = context.isDarkTheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          'Pick Custom Background Color',
          style: TextStyle(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            pickerAreaHeightPercent: 0.7,
            enableAlpha: false,
            displayThumbColor: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: context.textSecondaryColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              controller.setBackgroundColor(pickerColor);
              Navigator.of(ctx).pop();
            },
            child: const Text('Apply Color'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose Background',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Select an official solid background color.',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Large Cutout with Solid Background Live Preview
          Expanded(
            child: Obx(() {
              final previewPath = controller.cutoutPreviewPath.value;

              return Container(
                decoration: BoxDecoration(
                  color: controller.selectedBackgroundColor.value,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Center(
                  child: previewPath.isNotEmpty && File(previewPath).existsSync()
                      ? Image.file(File(previewPath), fit: BoxFit.contain)
                      : Image.file(File(controller.activeImagePath.value), fit: BoxFit.contain),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Clean Presets Row: [ White ] [ Blue ] [ Light Blue ] [ Gray ] [ + Custom ]
          Obx(() {
            final sel = controller.selectedBackgroundColor.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Background Presets',
                  style: TextStyle(color: context.textPrimaryColor, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildColorCard(
                      context: context,
                      label: 'White',
                      color: Colors.white,
                      isSelected: sel == Colors.white,
                      onTap: () => controller.setBackgroundColor(Colors.white),
                    ),
                    const SizedBox(width: 8),
                    _buildColorCard(
                      context: context,
                      label: 'Blue',
                      color: const Color(0xFF0284C7),
                      isSelected: sel.value == const Color(0xFF0284C7).value,
                      onTap: () => controller.setBackgroundColor(const Color(0xFF0284C7)),
                    ),
                    const SizedBox(width: 8),
                    _buildColorCard(
                      context: context,
                      label: 'Light Blue',
                      color: const Color(0xFF7DD3FC),
                      isSelected: sel.value == const Color(0xFF7DD3FC).value,
                      onTap: () => controller.setBackgroundColor(const Color(0xFF7DD3FC)),
                    ),
                    const SizedBox(width: 8),
                    _buildColorCard(
                      context: context,
                      label: 'Gray',
                      color: const Color(0xFF94A3B8),
                      isSelected: sel.value == const Color(0xFF94A3B8).value,
                      onTap: () => controller.setBackgroundColor(const Color(0xFF94A3B8)),
                    ),
                    const SizedBox(width: 8),
                    _buildCustomPickerCard(
                      context: context,
                      isSelected: !WizardController.backgroundPresets.any((p) => p.value == sel.value),
                      onTap: () => _openCustomColorPicker(context),
                    ),
                  ],
                ),
              ],
            );
          }),
          const SizedBox(height: 20),

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
            label: const Text('Continue to Adjust Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildColorCard({
    required BuildContext context,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: context.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.accent : context.borderColor,
              width: isSelected ? 2.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26),
                ),
                child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.black) : null,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.accent : context.textSecondaryColor,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomPickerCard({
    required BuildContext context,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: context.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.accent : context.borderColor,
              width: isSelected ? 2.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.colorize, size: 20, color: AppColors.accent),
              const SizedBox(height: 4),
              Text(
                '+ Custom',
                style: TextStyle(
                  color: isSelected ? AppColors.accent : context.textSecondaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
