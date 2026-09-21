import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/wizard_controller.dart';

class Step8SaveShare extends GetView<WizardController> {
  const Step8SaveShare({super.key});

  Future<void> _savePhotoToGallery() async {
    final imagePath = controller.singleProcessedImagePath.value;
    if (imagePath.isEmpty || !File(imagePath).existsSync()) return;

    try {
      Get.snackbar(
        'Saved to Projects! 💾',
        'Your 300 DPI passport photo has been saved to device projects.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF065F46),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Save Error', '$e', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> _shareSheet() async {
    final sheetPath = controller.sheetImagePath.value;
    if (sheetPath.isEmpty || !File(sheetPath).existsSync()) return;

    try {
      await Share.shareXFiles(
        [XFile(sheetPath)],
        text: 'Passport Photo Print Sheet (${controller.selectedPhotoSize.value.name})',
      );
    } catch (e) {
      Get.snackbar('Share Error', '$e', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> _printOrSavePdf() async {
    final pdfPath = controller.pdfPath.value;
    if (pdfPath.isEmpty || !File(pdfPath).existsSync()) return;

    try {
      final bytes = await File(pdfPath).readAsBytes();
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: '${controller.selectedPhotoSize.value.country}_${controller.selectedPhotoSize.value.name}_PrintSheet.pdf',
      );
    } catch (e) {
      Get.snackbar('PDF Error', '$e', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your Photo Is Ready! 🎉',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Obx(
            () => Text(
              '${controller.selectedPhotoSize.value.country} • ${controller.selectedPhotoSize.value.dimensionString} (300 DPI)',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // Side-by-Side Preview Cards
          Expanded(
            child: Row(
              children: [
                // Single Passport Portrait
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.bgCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Column(
                      children: [
                        Text('Single Photo', style: TextStyle(color: context.textPrimaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Obx(() {
                            final path = controller.singleProcessedImagePath.value;
                            return Center(
                              child: path.isNotEmpty && File(path).existsSync()
                                  ? Image.file(File(path), fit: BoxFit.contain)
                                  : Icon(Icons.photo, color: context.textSecondaryColor),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Multi-Copy Print Sheet
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.bgCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${controller.copyCount.value} Copies (${controller.selectedPaperSize.value.name})',
                          style: TextStyle(color: context.textPrimaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Obx(() {
                            final sheet = controller.sheetImagePath.value;
                            return Center(
                              child: sheet.isNotEmpty && File(sheet).existsSync()
                                  ? Image.file(File(sheet), fit: BoxFit.contain)
                                  : Icon(Icons.print, color: context.textSecondaryColor),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Primary Actions: [ 💾 Save Photo ] [ 📄 Print / Save PDF ] [ ↗ Share ]
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _savePhotoToGallery,
            icon: const Icon(Icons.save_alt_rounded, size: 20),
            label: const Text('💾 Save Photo to Gallery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _printOrSavePdf,
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: const Text('📄 Print / PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.textPrimaryColor,
                    side: BorderSide(color: context.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _shareSheet,
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('↗ Share Sheet'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Secondary Action: Create Another
          TextButton.icon(
            onPressed: controller.createAnother,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: const Text('Create Another Photo ↺', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
