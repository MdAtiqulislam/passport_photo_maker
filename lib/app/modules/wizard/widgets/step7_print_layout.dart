import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/paper_size.dart';
import '../../../../data/models/print_sheet_config.dart';
import '../controllers/wizard_controller.dart';

class Step7PrintLayout extends GetView<WizardController> {
  const Step7PrintLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'How Many Copies?',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Select copies, position and paper size for your print sheet.',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Big Stepper: [-] 8 [+]
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: context.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Number of Photos',
                  style: TextStyle(color: context.textPrimaryColor, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: context.cardAltColor,
                        foregroundColor: context.textPrimaryColor,
                      ),
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: () => controller.setCopyCount(controller.copyCount.value - 1),
                    ),
                    const SizedBox(width: 12),
                    Obx(
                      () => Text(
                        '${controller.copyCount.value}',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () => controller.setCopyCount(controller.copyCount.value + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Paper Size & Position Selector Tabs
          Obx(() {
            final selPaper = controller.selectedPaperSize.value;
            final selAlign = controller.selectedSheetAlignment.value;

            return Row(
              children: [
                // Paper Size Cards
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Paper Size', style: TextStyle(color: context.textSecondaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: PaperSize.allSizes.take(2).map((paper) {
                          final isSel = selPaper.id == paper.id;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: InkWell(
                                onTap: () => controller.selectPaperSize(paper),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: isSel ? AppColors.primary : context.bgCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSel ? AppColors.accent : context.borderColor,
                                      width: isSel ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        paper.name,
                                        style: TextStyle(
                                          color: isSel ? Colors.white : context.textPrimaryColor,
                                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${paper.widthMm.round()}×${paper.heightMm.round()}mm',
                                        style: TextStyle(
                                          color: isSel ? Colors.white70 : context.textSecondaryColor,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Sheet Position Selection
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Position', style: TextStyle(color: context.textSecondaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: PrintSheetAlignment.values.map((align) {
                          final isSel = selAlign == align;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: InkWell(
                                onTap: () => controller.selectedSheetAlignment.value = align,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: isSel ? const Color(0xFF0284C7) : context.bgCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSel ? AppColors.accent : context.borderColor,
                                      width: isSel ? 2 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(align.emoji, style: const TextStyle(fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text(
                                        align == PrintSheetAlignment.top ? 'Top' : 'Center',
                                        style: TextStyle(
                                          color: isSel ? Colors.white : context.textPrimaryColor,
                                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 10),

          // Live Sheet Layout Grid Preview (Scaled precisely to bounds without overflowing)
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.cardAltColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.borderColor),
              ),
              child: Center(
                child: Obx(() {
                  final copies = controller.copyCount.value;
                  final cutout = controller.cutoutPreviewPath.value;
                  final photoSize = controller.selectedPhotoSize.value;
                  final paperSize = controller.selectedPaperSize.value;

                  final printConfig = PrintSheetConfig(
                    paperSize: paperSize,
                    photoSize: photoSize,
                    copies: copies,
                    marginMm: controller.pageMarginMm.value,
                    gapMm: controller.photoSpacingMm.value,
                    alignment: controller.selectedSheetAlignment.value,
                  );

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final paperW = printConfig.effectivePaperWidth;
                      final paperH = printConfig.effectivePaperHeight;
                      final paperAspect = paperW / paperH;

                      double canvasW = constraints.maxWidth;
                      double canvasH = canvasW / paperAspect;

                      if (canvasH > constraints.maxHeight) {
                        canvasH = constraints.maxHeight;
                        canvasW = canvasH * paperAspect;
                      }

                      final scale = canvasW / paperW;

                      final photoW = photoSize.widthMm * scale;
                      final photoH = photoSize.heightMm * scale;
                      final startX = printConfig.startXOffsetMm * scale;
                      final startY = printConfig.startYOffsetMm * scale;
                      final gap = printConfig.gapMm * scale;

                      final imageFile = cutout.isNotEmpty && File(cutout).existsSync()
                          ? File(cutout)
                          : (controller.activeImagePath.value.isNotEmpty && File(controller.activeImagePath.value).existsSync()
                              ? File(controller.activeImagePath.value)
                              : null);

                      return Container(
                        width: canvasW,
                        height: canvasH,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            children: [
                              ...List.generate(printConfig.actualCopies, (index) {
                                final row = index ~/ printConfig.actualColumns;
                                final col = index % printConfig.actualColumns;

                                final left = startX + col * (photoW + gap);
                                final top = startY + row * (photoH + gap);

                                return Positioned(
                                  left: left,
                                  top: top,
                                  width: photoW,
                                  height: photoH,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black38, width: 0.5),
                                    ),
                                    child: imageFile != null
                                        ? Image.file(imageFile, fit: BoxFit.cover)
                                        : const SizedBox.shrink(),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Primary Action
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: controller.generateFinalPassportAndSheet,
            icon: const Icon(Icons.print_rounded, size: 20),
            label: const Text('Create Print Sheet 🎉', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
