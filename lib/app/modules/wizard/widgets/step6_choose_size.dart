import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/photo_size.dart';
import '../controllers/wizard_controller.dart';

class Step6ChooseSize extends GetView<WizardController> {
  const Step6ChooseSize({super.key});

  void _openAllSizesModal(BuildContext context) {
    final isDark = context.isDarkTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white38 : Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'All Country & Standard Presets',
                    style: TextStyle(color: context.textPrimaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: controller.allSizes.length,
                    separatorBuilder: (_, __) => Divider(color: context.borderColor, height: 1),
                    itemBuilder: (context, index) {
                      final item = controller.allSizes[index];
                      return ListTile(
                        leading: Text(item.flag, style: const TextStyle(fontSize: 24)),
                        title: Text(
                          '${item.country} • ${item.name}',
                          style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${item.dimensionString} • ${item.category}',
                          style: const TextStyle(color: AppColors.accent, fontSize: 12),
                        ),
                        onTap: () {
                          controller.selectPhotoSize(item);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openCustomSizeDialog(BuildContext context) {
    final isDark = context.isDarkTheme;
    final widthController = TextEditingController(text: '35');
    final heightController = TextEditingController(text: '45');
    String unit = 'mm';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            title: Text('Custom Dimensions', style: TextStyle(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: widthController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Width',
                    labelStyle: TextStyle(color: context.textSecondaryColor),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Height',
                    labelStyle: TextStyle(color: context.textSecondaryColor),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Unit: ', style: TextStyle(color: context.textSecondaryColor)),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('mm'),
                      selected: unit == 'mm',
                      onSelected: (v) => setModalState(() => unit = 'mm'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('inch'),
                      selected: unit == 'inch',
                      onSelected: (v) => setModalState(() => unit = 'inch'),
                    ),
                  ],
                ),
              ],
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
                  final w = double.tryParse(widthController.text) ?? 35.0;
                  final h = double.tryParse(heightController.text) ?? 45.0;

                  final widthMm = unit == 'inch' ? w * 25.4 : w;
                  final heightMm = unit == 'inch' ? h * 25.4 : h;

                  final customSize = PhotoSize(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    country: 'Custom',
                    countryCode: 'CUS',
                    flag: '📐',
                    name: '${w.toStringAsFixed(1)}×${h.toStringAsFixed(1)} $unit',
                    category: 'Custom',
                    widthMm: widthMm,
                    heightMm: heightMm,
                  );

                  controller.selectPhotoSize(customSize);
                  Navigator.of(ctx).pop();
                },
                child: const Text('Apply Size'),
              ),
            ],
          );
        },
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
            'Choose Photo Size',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Select your required passport or visa size specification.',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Primary Popular Cards (Passport, Visa, ID, Stamp)
          Expanded(
            child: Obx(() {
              final current = controller.selectedPhotoSize.value;

              final presets = [
                const PhotoSize(
                  id: 'bd_passport',
                  country: 'Standard',
                  countryCode: 'GEN',
                  flag: '📄',
                  name: 'Passport Photo',
                  category: 'Passport',
                  widthMm: 35.0,
                  heightMm: 45.0,
                ),
                const PhotoSize(
                  id: 'us_passport',
                  country: 'United States',
                  countryCode: 'US',
                  flag: '🇺🇸',
                  name: 'Passport & Visa',
                  category: 'Visa',
                  widthMm: 50.8,
                  heightMm: 50.8,
                ),
                const PhotoSize(
                  id: 'bd_stamp',
                  country: 'Standard',
                  countryCode: 'GEN',
                  flag: '🪪',
                  name: 'Stamp Size',
                  category: 'Stamp',
                  widthMm: 20.0,
                  heightMm: 25.0,
                ),
                const PhotoSize(
                  id: 'eu_schengen',
                  country: 'European Union',
                  countryCode: 'EU',
                  flag: '🇪🇺',
                  name: 'Schengen Visa',
                  category: 'Visa',
                  widthMm: 35.0,
                  heightMm: 45.0,
                ),
              ];

              return ListView(
                children: [
                  ...presets.map((item) {
                    final isSelected = current.id == item.id ||
                        (current.widthMm == item.widthMm && current.heightMm == item.heightMm && current.country == item.country);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: context.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : context.borderColor,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Text(item.flag, style: const TextStyle(fontSize: 28)),
                        title: Text(
                          item.name,
                          style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text(
                          '${item.country} • ${item.dimensionString}',
                          style: const TextStyle(color: AppColors.accent, fontSize: 12),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppColors.primary, size: 24)
                            : Icon(Icons.circle_outlined, color: context.textSecondaryColor, size: 24),
                        onTap: () => controller.selectPhotoSize(item),
                      ),
                    );
                  }),

                  const SizedBox(height: 8),

                  // View All Sizes & Custom Size Buttons (Wrapped)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.textPrimaryColor,
                            side: BorderSide(color: context.borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _openAllSizesModal(context),
                          icon: const Icon(Icons.public, size: 18),
                          label: const Text('View All Sizes', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accent,
                            side: const BorderSide(color: AppColors.accent),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _openCustomSizeDialog(context),
                          icon: const Icon(Icons.straighten, size: 18),
                          label: const Text('Custom Size', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),

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
            label: const Text('Continue to Print Layout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
