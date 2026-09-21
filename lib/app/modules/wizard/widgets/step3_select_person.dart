import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../editor/views/manual_mask_editor_view.dart';
import '../controllers/wizard_controller.dart';

class Step3SelectPerson extends GetView<WizardController> {
  const Step3SelectPerson({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Select Person',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'We automatically selected the main person.',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),

          // Main Viewport (Mask Overlay or Interactive Brush Canvas)
          Expanded(
            child: Obx(() {
              final activeImg = controller.activeImagePath.value;
              final mask = controller.workingMask.value;
              final isManual = controller.isManualSelectionActive.value;

              if (activeImg.isEmpty || !File(activeImg).existsSync()) {
                return Center(child: Text('No image loaded', style: TextStyle(color: context.textSecondaryColor)));
              }

              return Container(
                decoration: BoxDecoration(
                  color: context.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isManual ? AppColors.accent : context.borderColor,
                    width: isManual ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Base Image & Mask Layer
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onPanUpdate: isManual
                              ? (details) {
                                  final normX = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                                  final normY = (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);
                                  controller.applyBrushStroke(normX, normY);
                                }
                              : null,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(activeImg),
                                fit: BoxFit.contain,
                              ),
                              if (mask != null)
                                CustomPaint(
                                  painter: MaskOverlayPainter(
                                    mask: mask,
                                    showRubyOverlay: true,
                                    brushSize: controller.brushRadius.value,
                                    isAddMode: controller.isAddMode.value,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Top Status Overlay
                    Positioned(
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isManual ? '🖌️ Manual Brush Active (Draw to paint)' : '✨ Auto Person Detection Ready',
                          style: TextStyle(
                            color: isManual ? AppColors.accent : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 14),

          // Manual Selection Toolbar (Only shown when user taps Adjust Manually)
          Obx(() {
            if (!controller.isManualSelectionActive.value) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Add / Remove Mode Toggle & Undo / Redo
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: true, label: Text('Add'), icon: Icon(Icons.add_circle_outline, size: 16)),
                            ButtonSegment(value: false, label: Text('Erase'), icon: Icon(Icons.remove_circle_outline, size: 16)),
                          ],
                          selected: {controller.isAddMode.value},
                          onSelectionChanged: (set) => controller.isAddMode.value = set.first,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Undo',
                          icon: const Icon(Icons.undo),
                          onPressed: controller.canUndo.value ? controller.undoSelection : null,
                        ),
                        IconButton(
                          tooltip: 'Redo',
                          icon: const Icon(Icons.redo),
                          onPressed: controller.canRedo.value ? controller.redoSelection : null,
                        ),
                        IconButton(
                          tooltip: 'Reset to Auto',
                          icon: const Icon(Icons.refresh),
                          onPressed: controller.resetSelectionToAuto,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Brush Size Slider
                  Row(
                    children: [
                      Icon(Icons.brush, size: 18, color: context.textSecondaryColor),
                      const SizedBox(width: 8),
                      Text('Brush Size', style: TextStyle(color: context.textSecondaryColor, fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: controller.brushRadius.value,
                          min: 8.0,
                          max: 60.0,
                          activeColor: AppColors.accent,
                          onChanged: (val) => controller.brushRadius.value = val,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          // Action Buttons
          Obx(() {
            final isManual = controller.isManualSelectionActive.value;

            if (isManual) {
              return ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  controller.isManualSelectionActive.value = false;
                  controller.nextStep();
                },
                icon: const Icon(Icons.check, size: 20),
                label: const Text('Apply Selection & Continue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              );
            }

            return Column(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: controller.nextStep,
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text('✓ Use Auto Selection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.textPrimaryColor,
                    side: BorderSide(color: context.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => controller.isManualSelectionActive.value = true,
                  icon: const Icon(Icons.touch_app_outlined, size: 18),
                  label: const Text('✋ Adjust Selection Manually', style: TextStyle(fontSize: 14)),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
