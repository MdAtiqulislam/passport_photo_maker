import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/premium_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/ai_enhance_result.dart';
import '../../restoration/widgets/spot_healing_widget.dart';
import '../controllers/wizard_controller.dart';

class Step2CleanPhoto extends GetView<WizardController> {
  const Step2CleanPhoto({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sub-Tab Switcher: [ 🌸 Beauty ] [ 🩹 Spot Healer ] [ 🤖 AI Pro ]
          Container(
            decoration: BoxDecoration(
              color: context.cardAltColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor),
            ),
            padding: const EdgeInsets.all(3),
            child: Obx(
              () => Row(
                children: [
                  Expanded(child: _buildSubTabButton(context, tabIndex: 0, label: '🌸 Beauty', icon: Icons.face_retouching_natural_rounded)),
                  Expanded(child: _buildSubTabButton(context, tabIndex: 1, label: '🩹 Spot Heal', icon: Icons.brush_rounded)),
                  Expanded(child: _buildSubTabButton(context, tabIndex: 2, label: '🤖 AI Pro', icon: Icons.auto_fix_high_rounded)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Auto Crop Physical Photo Card Action
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: controller.autoCropCardInWizard,
                  icon: const Icon(Icons.crop, size: 12),
                  label: const Text('✂️ Auto-Crop Card', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                // Credit Badge
                Obx(() {
                  final premium = Get.find<PremiumService>();
                  if (premium.isPro.value) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium, size: 12, color: AppColors.gold),
                          SizedBox(width: 4),
                          Text('PRO ∞', style: TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }
                  return GestureDetector(
                    onTap: () => premium.showEarnCreditsDialog(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.toll_rounded, size: 12, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            '🪙 ${premium.aiCredits.value} Credits',
                            style: TextStyle(color: context.textPrimaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.add_circle, size: 12, color: AppColors.primary),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Dynamic Main Viewport based on sub-tab
          Expanded(
            child: Obx(() {
              final subTab = controller.step2SubTab.value;

              // Tab 1: Spot Healer Canvas
              if (subTab == 1) {
                return SpotHealingWidget(
                  imagePath: controller.activeImagePath.value.isNotEmpty
                      ? controller.activeImagePath.value
                      : controller.rawImagePath.value,
                  onHealSpot: (x, y, r) => controller.healTouchSpotInWizard(x, y, r),
                  onUndo: controller.undoHealingInWizard,
                  canUndo: controller.canUndoWizardHealing,
                );
              }

              // Tab 2: AI Restore Pro
              if (subTab == 2) {
                return _buildAiRestoreProViewport(context);
              }

              // Tab 0: Beauty & Lighting Preview
              final isEnhanced = controller.isEnhancedApplied.value && controller.enhancedImagePath.value.isNotEmpty;
              final displayPath = (isEnhanced && controller.showEnhancedComparison.value)
                  ? controller.enhancedImagePath.value
                  : controller.rawImagePath.value;

              if (displayPath.isEmpty || !File(displayPath).existsSync()) {
                return Center(child: Text('No photo loaded', style: TextStyle(color: context.textSecondaryColor)));
              }

              return Container(
                decoration: BoxDecoration(
                  color: context.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.borderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 3.5,
                      child: Center(child: Image.file(File(displayPath), fit: BoxFit.contain)),
                    ),
                    if (isEnhanced)
                      Positioned(
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPillTab(label: '📷 Original', isSelected: !controller.showEnhancedComparison.value, onTap: () => controller.showEnhancedComparison.value = false),
                              _buildPillTab(label: '✨ Enhanced', isSelected: controller.showEnhancedComparison.value, onTap: () => controller.showEnhancedComparison.value = true),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(12)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_outlined, color: AppColors.success, size: 14),
                            SizedBox(width: 6),
                            Text('Identity Protected • Natural Beautification', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 10),

          // Bottom Controls: Profiles or AI Restore button
          Obx(() {
            final subTab = controller.step2SubTab.value;

            // Beauty profiles for Tab 0
            if (subTab == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: context.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🌸 Beauty & Lighting Profiles', style: TextStyle(color: context.textPrimaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: AiEnhanceProfile.values.map((p) {
                          final isSel = controller.selectedEnhanceProfile.value == p;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ChoiceChip(
                              label: Text(p.title),
                              selected: isSel,
                              selectedColor: AppColors.primary,
                              backgroundColor: context.cardAltColor,
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : context.textPrimaryColor,
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (_) => controller.switchEnhanceProfile(p),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          }),

          // Primary Actions
          Obx(() {
            final isEnhanced = controller.isEnhancedApplied.value;
            final subTab = controller.step2SubTab.value;

            if (!isEnhanced && subTab == 0) {
              return Column(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: controller.runAiEnhancement,
                    icon: const Icon(Icons.auto_awesome, size: 20),
                    label: const Text('✨ Clean & Beautify with AI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textSecondaryColor,
                      side: BorderSide(color: context.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: controller.nextStep,
                    child: const Text('Skip & Continue', style: TextStyle(fontSize: 14)),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textPrimaryColor,
                      side: BorderSide(color: context.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: controller.keepOriginalPhoto,
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text('Original'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      controller.useEnhancedPhoto();
                      controller.nextStep();
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Continue ➔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AI RESTORE PRO VIEWPORT
  // ---------------------------------------------------------------------------
  Widget _buildAiRestoreProViewport(BuildContext context) {
    final isEnhanced = controller.isEnhancedApplied.value && controller.enhancedImagePath.value.isNotEmpty;
    final displayPath = isEnhanced ? controller.enhancedImagePath.value : controller.rawImagePath.value;

    if (displayPath.isEmpty || !File(displayPath).existsSync()) {
      return Center(child: Text('No photo loaded', style: TextStyle(color: context.textSecondaryColor)));
    }

    return Container(
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          InteractiveViewer(
            minScale: 0.8,
            maxScale: 3.5,
            child: Center(child: Image.file(File(displayPath), fit: BoxFit.contain)),
          ),

          // AI Restore Action Overlay
          if (!isEnhanced)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.auto_fix_high_rounded, color: AppColors.gold, size: 48),
                            const SizedBox(height: 12),
                            const Text(
                              '🤖 AI Face Restoration',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Deep AI will reconstruct facial details,\nremove heavy scratches, deblur & upscale 2x.',
                              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            _buildAiRestoreButton(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Before/After pill for AI restored
          if (isEnhanced)
            Positioned(
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(24)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPillTab(label: '📷 Before', isSelected: !controller.showEnhancedComparison.value, onTap: () => controller.showEnhancedComparison.value = false),
                    _buildPillTab(label: '🤖 AI Restored', isSelected: controller.showEnhancedComparison.value, onTap: () => controller.showEnhancedComparison.value = true),
                  ],
                ),
              ),
            ),

          // PRO badge
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('PRO Feature • Cloud AI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiRestoreButton(BuildContext context) {
    final premium = Get.find<PremiumService>();

    if (premium.isPro.value || premium.aiCredits.value > 0) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: controller.runAiCloudRestore,
        icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
        label: Text(
          premium.isPro.value ? '🤖 Run AI Restore (PRO)' : '🤖 Run AI Restore (1 Credit)',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      );
    }

    // No credits — show Watch Ad button
    return Column(
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () => premium.showEarnCreditsDialog(),
          icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
          label: const Text('🎬 Watch Ad to Earn Credit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => premium.showUpgradeDialog(triggerFeature: 'AI Photo Restoration'),
          child: const Text('⭐ Upgrade to Pro — Unlimited', style: TextStyle(color: AppColors.gold, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildSubTabButton(BuildContext context, {required int tabIndex, required String label, required IconData icon}) {
    final isSel = controller.step2SubTab.value == tabIndex;
    return GestureDetector(
      onTap: () => controller.step2SubTab.value = tabIndex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSel ? (tabIndex == 2 ? AppColors.gold : AppColors.primary) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: isSel ? Colors.white : context.textSecondaryColor),
            const SizedBox(width: 3),
            Text(label, style: TextStyle(color: isSel ? Colors.white : context.textSecondaryColor, fontWeight: isSel ? FontWeight.bold : FontWeight.w500, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildPillTab({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: isSelected ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
