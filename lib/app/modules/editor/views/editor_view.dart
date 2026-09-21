import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/editor_controller.dart';
import '../widgets/adjustment_panel.dart';
import '../widgets/background_panel.dart';
import '../widgets/chest_boundary_panel.dart';
import '../widgets/outfit_selector_panel.dart';
import '../widgets/crop_editor_widget.dart';
import '../widgets/quality_badge.dart';
import '../../../../core/constants/app_colors.dart';

class EditorView extends GetView<EditorController> {
  const EditorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121824),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          children: [
            Text(
              '${controller.photoSize.country} ${controller.photoSize.name}',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              controller.photoSize.dimensionString,
              style: const TextStyle(color: AppColors.accent, fontSize: 12),
            ),
          ],
        ),
        actions: [
          const QualityBadge(),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'Reprocess Cutout',
            onPressed: controller.runAutomaticSegmentation,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Colors.white70),
            tooltip: 'Reset All',
            onPressed: controller.resetAll,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Top Comparison & Selection Mode: [ Original ] | [ Auto Cutout ] & [ Manual Brush ]
              Container(
                color: const Color(0xFF1E293B),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Obx(
                          () => Row(
                            children: [
                              Expanded(
                                child: _buildModeTab(
                                  label: '📷 Original',
                                  isSelected: !controller.isAutoResultMode.value,
                                  onTap: () => controller.toggleResultMode(false),
                                ),
                              ),
                              Expanded(
                                child: _buildModeTab(
                                  label: controller.isManualSelectionActive.value ? '🖌️ Manual Cutout' : '✨ Auto Cutout',
                                  isSelected: controller.isAutoResultMode.value,
                                  onTap: () => controller.toggleResultMode(true),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Manual Selection Refinement Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF334155),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: controller.openManualMaskEditor,
                      icon: const Icon(Icons.brush, size: 16, color: AppColors.accent),
                      label: const Text('Manual Refine', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // Main Canvas / Interactive Cutout & Crop Viewport
              const Expanded(
                flex: 6,
                child: CropEditorWidget(),
              ),

              // Quick Transform Toolbar (Rotate, Flip, Guidelines, Auto Enhance, Outfit Studio)
              Container(
                color: const Color(0xFF1E293B),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildToolButton(
                        icon: Icons.rotate_right,
                        label: 'Rotate',
                        onTap: controller.rotate90,
                      ),
                      _buildToolButton(
                        icon: Icons.flip,
                        label: 'Flip',
                        onTap: controller.toggleFlip,
                      ),
                      Obx(
                        () => _buildToolButton(
                          icon: controller.showGuidelines.value ? Icons.grid_on : Icons.grid_off,
                          label: 'Guides',
                          isActive: controller.showGuidelines.value,
                          onTap: controller.toggleGuidelines,
                        ),
                      ),
                      Obx(
                        () => _buildToolButton(
                          icon: Icons.auto_awesome,
                          label: controller.isEnhancedApplied.value ? '✨ AI Enhanced' : '✨ AI Enhance',
                          isActive: controller.isEnhancedApplied.value,
                          onTap: controller.openAiEnhanceScreen,
                        ),
                      ),
                      _buildToolButton(
                        icon: Icons.style,
                        label: 'Outfit Studio',
                        onTap: controller.openOutfitStudio,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Tab Selection
              Container(
                color: Theme.of(context).cardColor,
                child: Obx(
                  () => Row(
                    children: [
                      _buildTabItem(index: 0, label: 'Framing', icon: Icons.accessibility_new),
                      _buildTabItem(index: 1, label: 'Outfits', icon: Icons.style),
                      _buildTabItem(index: 2, label: 'Solid BG', icon: Icons.palette_outlined),
                      _buildTabItem(index: 3, label: 'Adjust', icon: Icons.tune),
                    ],
                  ),
                ),
              ),

              // Bottom Panel Body
              Expanded(
                flex: 5,
                child: Obx(() {
                  switch (controller.activeTabIndex.value) {
                    case 0:
                      return const ChestBoundaryPanel();
                    case 1:
                      return const OutfitSelectorPanel();
                    case 2:
                      return const BackgroundPanel();
                    case 3:
                    default:
                      return const AdjustmentPanel();
                  }
                }),
              ),

              // Bottom Action Buttons: Print Sheet or Export Single Photo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.primary),
                        ),
                        onPressed: () => controller.generateAndProceed(goToPrintSheet: false),
                        icon: const Icon(Icons.download, size: 20),
                        label: const Text('Single Photo'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => controller.generateAndProceed(goToPrintSheet: true),
                        icon: const Icon(Icons.print_outlined, size: 20),
                        label: const Text(
                          'Generate Print Sheet ⭐',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Progressive AI Segmentation Loading Overlay
          Obx(
            () => controller.isSegmenting.value
                ? Container(
                    color: Colors.black.withOpacity(0.8),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 48,
                              height: 48,
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 3.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Automatic Portrait Cutout',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Obx(
                              () => Text(
                                controller.segmentationStatus.value,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondaryDark,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Export Processing Overlay
          Obx(
            () => controller.isProcessing.value
                ? Container(
                    color: Colors.black.withOpacity(0.7),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 16),
                          Text(
                            'Preparing High-Resolution Output...',
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

  Widget _buildModeTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondaryDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({required int index, required String label, required IconData icon}) {
    final isSelected = controller.activeTabIndex.value == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (index == 1) {
            controller.openOutfitStudio();
          } else {
            controller.activeTabIndex.value = index;
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? AppColors.accent : Colors.white, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.accent : Colors.white70,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
