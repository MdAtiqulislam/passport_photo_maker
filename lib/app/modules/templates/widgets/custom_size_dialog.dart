import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/dpi_converter.dart';
import '../controllers/templates_controller.dart';

class CustomSizeDialog extends StatefulWidget {
  const CustomSizeDialog({super.key});

  @override
  State<CustomSizeDialog> createState() => _CustomSizeDialogState();
}

class _CustomSizeDialogState extends State<CustomSizeDialog> {
  final _nameController = TextEditingController(text: 'Custom Photo');
  final _widthController = TextEditingController(text: '35');
  final _heightController = TextEditingController(text: '45');
  DimensionUnit _selectedUnit = DimensionUnit.mm;
  int _selectedDpi = 300;

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.straighten, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Custom Photo Size',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Document Name',
                  hintText: 'e.g. Employee ID, Exam Card',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _widthController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Width',
                        suffixText: _selectedUnit.name,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Height',
                        suffixText: _selectedUnit.name,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Unit of Measurement', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: DimensionUnit.values.map((unit) {
                  final isSelected = _selectedUnit == unit;
                  return ChoiceChip(
                    label: Text(unit.name.toUpperCase()),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedUnit = unit);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Resolution (DPI)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [150, 200, 300, 600].map((dpi) {
                  final isSelected = _selectedDpi == dpi;
                  return ChoiceChip(
                    label: Text('$dpi DPI'),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedDpi = dpi);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final w = double.tryParse(_widthController.text.trim()) ?? 35.0;
                        final h = double.tryParse(_heightController.text.trim()) ?? 45.0;
                        final name = _nameController.text.trim().isEmpty ? 'Custom Size' : _nameController.text.trim();

                        final controller = Get.find<TemplatesController>();
                        Get.back();
                        controller.createCustomSize(
                          width: w,
                          height: h,
                          unit: _selectedUnit,
                          dpi: _selectedDpi,
                          name: name,
                        );
                      },
                      child: const Text('Apply Size'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
