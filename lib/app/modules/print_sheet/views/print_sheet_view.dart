import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/print_sheet_controller.dart';
import '../widgets/sheet_preview_widget.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/paper_size.dart';
import '../../../../data/models/print_sheet_config.dart';

class PrintSheetView extends GetView<PrintSheetController> {
  const PrintSheetView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Print Sheet Generator', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.screen_rotation, color: Colors.white70),
            tooltip: 'Toggle Orientation',
            onPressed: controller.toggleOrientation,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Live Interactive Sheet Canvas Preview
              const Expanded(
                flex: 5,
                child: SheetPreviewWidget(),
              ),

              // Controls Panel
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Paper Size Selector
                        const Text('1. Paper Size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Obx(
                            () {
                              final selectedId = controller.selectedPaperSize.value.id;
                              return Row(
                                children: PaperSize.allSizes.map((paper) {
                                  final isSelected = selectedId == paper.id;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ChoiceChip(
                                      label: Text(paper.name),
                                      selected: isSelected,
                                      selectedColor: AppColors.primaryLight,
                                      labelStyle: TextStyle(
                                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                      onSelected: (_) => controller.setPaperSize(paper),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Copies Selector with Quick Numbers & Stepper
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('2. Number of Copies', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Obx(
                              () => Text(
                                '${controller.selectedCopies.value} / ${controller.currentConfig.maxFitCopies} max',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Stepper [-] [+]
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    onPressed: controller.decrementCopies,
                                  ),
                                  Obx(
                                    () => Text(
                                      '${controller.selectedCopies.value}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    onPressed: controller.incrementCopies,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Quick preset chips
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Obx(
                                  () => Row(
                                    children: [4, 6, 8, 12, 16, 20, 24].map((count) {
                                      final isSelected = controller.selectedCopies.value == count;
                                      final fits = count <= controller.currentConfig.maxFitCopies;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 6.0),
                                        child: ChoiceChip(
                                          label: Text('$count'),
                                          selected: isSelected,
                                          selectedColor: AppColors.primary,
                                          labelStyle: TextStyle(
                                            color: isSelected ? Colors.white : (fits ? AppColors.textPrimary : AppColors.textMuted),
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                          onSelected: fits ? (_) => controller.setCopies(count) : null,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Cut Lines & Margins
                        const Text('3. Cut Lines & Layout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        Obx(
                          () => Row(
                            children: [
                              _buildCutLineOption(label: 'None', type: CutLineType.none),
                              const SizedBox(width: 8),
                              _buildCutLineOption(label: 'Solid Lines', type: CutLineType.thin),
                              const SizedBox(width: 8),
                              _buildCutLineOption(label: '✂️ Dashed', type: CutLineType.dashed),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Margin & Spacing Sliders
                        Obx(
                          () => Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Margin: ${controller.marginMm.value.toStringAsFixed(0)} mm', style: const TextStyle(fontSize: 12)),
                                    Slider(
                                      value: controller.marginMm.value,
                                      min: 2.0,
                                      max: 15.0,
                                      onChanged: (v) => controller.marginMm.value = v,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Gap: ${controller.gapMm.value.toStringAsFixed(0)} mm', style: const TextStyle(fontSize: 12)),
                                    Slider(
                                      value: controller.gapMm.value,
                                      min: 0.0,
                                      max: 10.0,
                                      onChanged: (v) => controller.gapMm.value = v,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom CTA
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).cardColor,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: controller.generateAndExport,
                    icon: const Icon(Icons.picture_as_pdf, size: 22),
                    label: const Text(
                      'Export 1:1 Scale PDF & Share',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Generating Spinner
          Obx(
            () => controller.isGenerating.value
                ? Container(
                    color: Colors.black.withOpacity(0.7),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 16),
                          Text(
                            'Generating Print-Ready 1:1 Scale PDF...',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildCutLineOption({required String label, required CutLineType type}) {
    final isSelected = controller.selectedCutLine.value == type;
    return Expanded(
      child: InkWell(
        onTap: () => controller.setCutLineType(type),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
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
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
