import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/export_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class ExportView extends GetView<ExportController> {
  const ExportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgScaffold,
      appBar: AppBar(
        backgroundColor: context.bgSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimaryColor, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Export & Print',
          style: TextStyle(color: context.textPrimaryColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.home_outlined, color: context.textSecondaryColor),
            tooltip: 'Home',
            onPressed: controller.goHome,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Selector Tabs (Single Photo vs Print Sheet vs PDF)
            Container(
              decoration: BoxDecoration(
                color: context.cardAltColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.borderColor),
              ),
              padding: const EdgeInsets.all(4),
              child: Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: _buildModeTab(
                        context: context,
                        mode: ExportMode.singlePhoto,
                        label: 'Single Photo',
                        icon: Icons.person_outline,
                      ),
                    ),
                    if (controller.sheetImagePath != null)
                      Expanded(
                        child: _buildModeTab(
                          context: context,
                          mode: ExportMode.printSheet,
                          label: 'Print Sheet',
                          icon: Icons.grid_view,
                        ),
                      ),
                    if (controller.pdfPath != null)
                      Expanded(
                        child: _buildModeTab(
                          context: context,
                          mode: ExportMode.pdfDocument,
                          label: 'PDF Document',
                          icon: Icons.picture_as_pdf,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Live Preview Box
            Center(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  color: context.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Obx(() {
                  switch (controller.activeMode.value) {
                    case ExportMode.singlePhoto:
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(controller.processedImagePath),
                          fit: BoxFit.contain,
                        ),
                      );
                    case ExportMode.printSheet:
                      return controller.sheetImagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(controller.sheetImagePath!),
                                fit: BoxFit.contain,
                              ),
                            )
                          : Center(child: Text('No Sheet Generated', style: TextStyle(color: context.textSecondaryColor)));
                    case ExportMode.pdfDocument:
                      return Container(
                        width: 200,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf, color: AppColors.error, size: 54),
                            const SizedBox(height: 12),
                            Text(
                              'Ready-to-Print PDF',
                              style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${controller.photoSize.name} • 1:1 Scale',
                              style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                            ),
                          ],
                        ),
                      );
                  }
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Document Details Card
            Container(
              decoration: BoxDecoration(
                color: context.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDetailRow(context, 'Document', '${controller.photoSize.country} ${controller.photoSize.name}'),
                  Divider(color: context.borderColor, height: 16),
                  _buildDetailRow(context, 'Dimensions', controller.photoSize.dimensionString),
                  Divider(color: context.borderColor, height: 16),
                  _buildDetailRow(context, 'Resolution', controller.photoSize.pixelString),
                  if (controller.config != null) ...[
                    Divider(color: context.borderColor, height: 16),
                    _buildDetailRow(
                      context,
                      'Paper Layout',
                      '${controller.config!.paperSize.name} (${controller.config!.actualCopies} Copies)',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Export Options: DPI and Format (Scrollable Row to prevent RenderFlex overflow)
            Text(
              'Export Quality (DPI)',
              style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(
                () => Row(
                  children: [150, 300, 600].map((dpi) {
                    final isSelected = controller.selectedDpi.value == dpi;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text('$dpi DPI ${dpi == 300 ? '(Standard)' : dpi == 600 ? '(HD Pro)' : ''}'),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: context.cardAltColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : context.textPrimaryColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                        onSelected: (_) => controller.setDpi(dpi),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Primary Actions: Save, Share, Print
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: controller.shareFile,
                icon: const Icon(Icons.share, size: 20),
                label: const Text('Share (WhatsApp, Drive, Email)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: controller.printDocument,
                    icon: const Icon(Icons.print, size: 20),
                    label: const Text('Direct Print'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: context.borderColor),
                      foregroundColor: context.textPrimaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: controller.saveToDevice,
                    icon: const Icon(Icons.download_done, size: 20),
                    label: const Text('Save Device'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required BuildContext context,
    required ExportMode mode,
    required String label,
    required IconData icon,
  }) {
    final isSelected = controller.activeMode.value == mode;
    return InkWell(
      onTap: () => controller.setMode(mode),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? (context.isDarkTheme ? const Color(0xFF1E293B) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColors.primary : context.textSecondaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : context.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.textSecondaryColor, fontSize: 13)),
        Text(value, style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
