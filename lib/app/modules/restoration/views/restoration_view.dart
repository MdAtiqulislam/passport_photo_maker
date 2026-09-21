import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/premium_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/ai_enhance_result.dart';
import '../../../../data/models/restoration_models.dart';
import '../controllers/restoration_controller.dart';
import '../widgets/before_after_slider.dart';
import '../widgets/spot_healing_widget.dart';

class RestorationView extends GetView<RestorationController> {
  const RestorationView({super.key});

  void _openFineTuneSheet(BuildContext context) {
    double b = controller.fineBrightness.value;
    double c = controller.fineContrast.value;
    double s = controller.fineSharpness.value;
    double sat = controller.fineSaturation.value;
    double t = controller.fineTemperature.value;
    final isDark = context.isDarkTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🎛️ Fine Tune Adjustments',
                        style: TextStyle(color: context.textPrimaryColor, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            b = 0.0;
                            c = 1.0;
                            s = 1.0;
                            sat = 1.0;
                            t = 0.0;
                          });
                          controller.resetFineTune();
                        },
                        child: const Text('Reset', style: TextStyle(color: AppColors.accent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildSliderRow(context, 'Brightness', b, -0.5, 0.5, (v) {
                    setModalState(() => b = v);
                  }),
                  _buildSliderRow(context, 'Contrast', c, 0.7, 1.4, (v) {
                    setModalState(() => c = v);
                  }),
                  _buildSliderRow(context, 'Sharpness', s, 0.5, 2.0, (v) {
                    setModalState(() => s = v);
                  }),
                  _buildSliderRow(context, 'Saturation', sat, 0.0, 2.0, (v) {
                    setModalState(() => sat = v);
                  }),
                  _buildSliderRow(context, 'Warmth / Temp', t, -0.5, 0.5, (v) {
                    setModalState(() => t = v);
                  }),

                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      controller.applyFineTune(
                        brightness: b,
                        contrast: c,
                        sharpness: s,
                        saturation: sat,
                        temperature: t,
                      );
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Apply Adjustments', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSliderRow(
    BuildContext context,
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: context.textSecondaryColor, fontSize: 13)),
            Text(value.toStringAsFixed(2), style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          activeColor: AppColors.accent,
          inactiveColor: context.cardAltColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasPhoto = controller.originalImagePath.value.isNotEmpty;

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
            'AI Photo Restoration & Beauty',
            style: TextStyle(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            if (hasPhoto)
              IconButton(
                tooltip: 'Choose another',
                icon: Icon(Icons.refresh_rounded, color: context.textSecondaryColor),
                onPressed: controller.resetAndChooseAnother,
              ),
          ],
        ),
        body: Stack(
          children: [
            if (!hasPhoto) _buildInitialPickerScreen(context) else _buildRestorationStudioScreen(context),

            // Loading Overlay
            if (controller.isAnalyzing.value || controller.isRestoring.value)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: context.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.accent),
                        const SizedBox(height: 16),
                        Obx(
                          () => Text(
                            controller.statusMessage.value,
                            style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // SCREEN 1: INITIAL PHOTO PICKER
  // ---------------------------------------------------------------------------
  Widget _buildInitialPickerScreen(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_fix_high_rounded, color: AppColors.primary, size: 40),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Restore & Beautify Old Photos',
            style: TextStyle(color: context.textPrimaryColor, fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Remove white spots & scratches, smooth skin tones, deblur facial features, and prepare clean passport portraits.',
            style: TextStyle(color: context.textSecondaryColor, fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: controller.choosePhotoFromGallery,
            icon: const Icon(Icons.photo_library_rounded),
            label: const Text('Choose from Gallery', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: context.textPrimaryColor,
              side: BorderSide(color: context.borderColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: controller.takePhoto,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Scan / Take Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 2: RESTORATION STUDIO
  // ---------------------------------------------------------------------------
  Widget _buildRestorationStudioScreen(BuildContext context) {
    final report = controller.analysisReport.value;
    final isGrayscale = report?.isGrayscale ?? false;
    final currentTab = controller.selectedStudioTab.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mode Tabs: [ 🔄 Compare ] [ 🌸 Beauty ] [ 🩹 Spot Healer ] [ 🤖 AI Pro ]
          Container(
            decoration: BoxDecoration(
              color: context.cardAltColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                Expanded(child: _buildTabButton(context, 0, '🔄 Compare', Icons.compare_arrows_rounded)),
                Expanded(child: _buildTabButton(context, 1, '🌸 Beauty', Icons.face_retouching_natural_rounded)),
                Expanded(child: _buildTabButton(context, 2, '🩹 Spot Heal', Icons.brush_rounded)),
                Expanded(child: _buildTabButton(context, 3, '🤖 AI Pro', Icons.auto_fix_high_rounded)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Top Action Row: Auto-Crop + Credit Badge + Tags
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
                  onPressed: controller.autoCropPrintedCard,
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
                  return Container(
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
                      ],
                    ),
                  );
                }),
                const SizedBox(width: 6),
                if (report != null && report.detectedDefectLabels.isNotEmpty)
                  ...report.detectedDefectLabels.map((tag) {
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_fix_high, size: 11, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            tag,
                            style: TextStyle(color: context.textPrimaryColor, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Dynamic Main Viewport based on selected Tab
          Expanded(
            child: currentTab == 0
                ? BeforeAfterSlider(
                    originalImagePath: controller.originalImagePath.value,
                    restoredImagePath: controller.restoredImagePath.value.isNotEmpty
                        ? controller.restoredImagePath.value
                        : controller.originalImagePath.value,
                  )
                : currentTab == 1
                    ? _buildBeautyCameraViewport(context)
                    : currentTab == 2
                        ? SpotHealingWidget(
                            imagePath: controller.restoredImagePath.value.isNotEmpty
                                ? controller.restoredImagePath.value
                                : controller.originalImagePath.value,
                            onHealSpot: (x, y, r) => controller.healTouchSpot(x, y, r),
                            onUndo: controller.undoLastHeal,
                            canUndo: controller.canUndoHealing,
                          )
                        : _buildAiProStudioViewport(context),
          ),
          const SizedBox(height: 8),

          // Bottom Control Card (Strength / Beauty Profiles / Fine Tune)
          if (currentTab == 0)
            _buildAutoRestoreControls(context, isGrayscale, report)
          else if (currentTab == 1)
            _buildBeautyProfileBar(context)
          else if (currentTab == 3)
            _buildAiProControls(context),

          const SizedBox(height: 8),

          // Primary Actions
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: controller.useForPassportPhoto,
            icon: const Icon(Icons.badge_outlined, size: 18),
            label: const Text('Use for Passport Photo ➔', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.textPrimaryColor,
                    side: BorderSide(color: context.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: controller.saveToDevice,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Save Photo', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.textPrimaryColor,
                    side: BorderSide(color: context.borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: controller.sharePhoto,
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, int tabIndex, String label, IconData icon) {
    final isSel = controller.selectedStudioTab.value == tabIndex;
    return GestureDetector(
      onTap: () => controller.selectedStudioTab.value = tabIndex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSel ? (tabIndex == 3 ? AppColors.gold : AppColors.primary) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: isSel ? Colors.white : context.textSecondaryColor),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: isSel ? Colors.white : context.textSecondaryColor,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeautyCameraViewport(BuildContext context) {
    return BeforeAfterSlider(
      originalImagePath: controller.originalImagePath.value,
      restoredImagePath: controller.restoredImagePath.value.isNotEmpty
          ? controller.restoredImagePath.value
          : controller.originalImagePath.value,
    );
  }

  Widget _buildAiProStudioViewport(BuildContext context) {
    return BeforeAfterSlider(
      originalImagePath: controller.originalImagePath.value,
      restoredImagePath: controller.restoredImagePath.value.isNotEmpty
          ? controller.restoredImagePath.value
          : controller.originalImagePath.value,
    );
  }

  Widget _buildAiProControls(BuildContext context) {
    final premium = Get.find<PremiumService>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🤖 AI Face Restoration Pro',
                style: TextStyle(color: context.textPrimaryColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Obx(() => Text(
                    premium.isPro.value ? 'PRO Unlimited' : '🪙 ${premium.aiCredits.value} Left',
                    style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold),
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() {
            if (premium.isPro.value || premium.aiCredits.value > 0) {
              return ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: controller.runAiCloudRestore,
                icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                label: Text(
                  premium.isPro.value ? 'Run Cloud AI Restore (PRO)' : 'Run Cloud AI Restore (1 Credit)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              );
            }

            return Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => premium.showEarnCreditsDialog(),
                    icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
                    label: const Text('Watch Ad (+1 Credit)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => premium.showUpgradeDialog(triggerFeature: 'Unlimited AI Restoration'),
                    icon: const Icon(Icons.workspace_premium, size: 16),
                    label: const Text('Upgrade Pro', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBeautyProfileBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🌸 Beauty Camera Profiles',
                style: TextStyle(color: context.textPrimaryColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () => _openFineTuneSheet(context),
                child: const Row(
                  children: [
                    Icon(Icons.tune, size: 14, color: AppColors.accent),
                    SizedBox(width: 4),
                    Text('Fine Tune', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AiEnhanceProfile.values.map((prof) {
                final isSel = controller.selectedBeautyProfile.value == prof;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(prof.title),
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    backgroundColor: context.cardAltColor,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : context.textPrimaryColor,
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => controller.applyBeautyEnhance(prof),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoRestoreControls(BuildContext context, bool isGrayscale, PhotoAnalysisReport? report) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Restoration Strength',
                style: TextStyle(color: context.textPrimaryColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () => _openFineTuneSheet(context),
                child: const Row(
                  children: [
                    Icon(Icons.tune, size: 14, color: AppColors.accent),
                    SizedBox(width: 4),
                    Text('Fine Tune', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: RestorationStrength.values.map((st) {
              final isSel = controller.selectedStrength.value == st;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: ChoiceChip(
                    label: Center(child: Text(st.title, style: const TextStyle(fontSize: 11))),
                    selected: isSel,
                    selectedColor: AppColors.primary,
                    backgroundColor: context.cardAltColor,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : context.textPrimaryColor,
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => controller.setStrength(st),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
