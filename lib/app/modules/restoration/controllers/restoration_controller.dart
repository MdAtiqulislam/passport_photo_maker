import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/ai_enhance_service.dart';
import '../../../../core/services/ai_restore_api_service.dart';
import '../../../../core/services/photo_restoration_service.dart';
import '../../../../core/services/premium_service.dart';
import '../../../../data/models/ai_enhance_result.dart';
import '../../../../data/models/restoration_models.dart';
import '../../../routes/app_pages.dart';

class RestorationController extends GetxController {
  final ImagePicker _picker = ImagePicker();

  // State Management
  final RxString originalImagePath = ''.obs;
  final RxString restoredImagePath = ''.obs;
  final Rx<PhotoAnalysisReport?> analysisReport = Rx<PhotoAnalysisReport?>(null);
  final Rx<RestorationResult?> restorationResult = Rx<RestorationResult?>(null);

  // Loading States
  final RxBool isAnalyzing = false.obs;
  final RxBool isRestoring = false.obs;
  final RxString statusMessage = ''.obs;

  // Studio Mode Tab: 0 = Compare/Auto Restore, 1 = Beauty Camera, 2 = Spot Healer
  final RxInt selectedStudioTab = 0.obs;

  // Options State
  final Rx<RestorationStrength> selectedStrength = RestorationStrength.medium.obs;
  final RxBool colorizeBw = false.obs;
  final RxInt upscaleFactor = 1.obs; // 1, 2, 4
  final Rx<AiEnhanceProfile> selectedBeautyProfile = AiEnhanceProfile.beautySmooth.obs;

  // Healing Undo History Stack
  final RxList<String> healingHistory = <String>[].obs;

  // Fine Tune Sliders
  final RxDouble fineBrightness = 0.0.obs;
  final RxDouble fineContrast = 1.0.obs;
  final RxDouble fineSharpness = 1.0.obs;
  final RxDouble fineSaturation = 1.0.obs;
  final RxDouble fineTemperature = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map && args['imagePath'] != null) {
      final path = args['imagePath'] as String;
      if (path.isNotEmpty) {
        _setPhotoAndAnalyze(path);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 1: PHOTO SELECTION
  // ---------------------------------------------------------------------------
  Future<void> choosePhotoFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
      if (photo != null) {
        await _setPhotoAndAnalyze(photo.path);
      }
    } catch (e) {
      _showFriendlyError('Could not open gallery', 'Please check storage permissions in settings.');
    }
  }

  Future<void> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 100);
      if (photo != null) {
        await _setPhotoAndAnalyze(photo.path);
      }
    } catch (e) {
      _showFriendlyError('Could not open camera', 'Please check camera permissions in settings.');
    }
  }

  Future<void> _setPhotoAndAnalyze(String path) async {
    originalImagePath.value = path;
    restoredImagePath.value = '';
    restorationResult.value = null;
    analysisReport.value = null;
    healingHistory.clear();

    isAnalyzing.value = true;
    statusMessage.value = 'Analyzing photo quality & defects...';

    try {
      final report = await PhotoRestorationService.analyzePhoto(File(path));
      analysisReport.value = report;
      isAnalyzing.value = false;

      // Automatically trigger initial restoration
      await runRestoration();
    } catch (e) {
      isAnalyzing.value = false;
      _showFriendlyError("Couldn't analyze photo", 'Try a clearer or higher-resolution image.');
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 2 & 3: RESTORATION ENGINE
  // ---------------------------------------------------------------------------
  Future<void> runRestoration() async {
    if (originalImagePath.value.isEmpty) return;

    isRestoring.value = true;
    statusMessage.value = 'Repairing scratches, noise & faded colors...';

    try {
      final currentReport = analysisReport.value;
      final isGrayscale = currentReport?.isGrayscale ?? false;

      final options = RestorationOptions(
        strength: selectedStrength.value,
        repairScratches: currentReport?.needsScratchRepair ?? true,
        reduceNoise: currentReport?.needsNoiseReduction ?? true,
        deblurAndSharpen: true,
        recoverFadedColors: true,
        autoWhiteBalance: !isGrayscale,
        colorize: isGrayscale && colorizeBw.value,
        upscaleFactor: upscaleFactor.value,
        brightness: fineBrightness.value,
        contrast: fineContrast.value,
        sharpness: fineSharpness.value,
        saturation: fineSaturation.value,
        temperature: fineTemperature.value,
      );

      final result = await PhotoRestorationService.restorePhoto(
        imageFile: File(originalImagePath.value),
        options: options,
      );

      restorationResult.value = result;
      restoredImagePath.value = result.restoredImagePath;
      healingHistory.clear();
      healingHistory.add(result.restoredImagePath);
      isRestoring.value = false;
    } catch (e) {
      isRestoring.value = false;
      _showFriendlyError("Couldn't restore photo", 'An error occurred during restoration. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // BEAUTY CAMERA ENHANCE
  // ---------------------------------------------------------------------------
  Future<void> applyBeautyEnhance(AiEnhanceProfile profile) async {
    selectedBeautyProfile.value = profile;
    final currentTarget = restoredImagePath.value.isNotEmpty ? restoredImagePath.value : originalImagePath.value;
    if (currentTarget.isEmpty) return;

    isRestoring.value = true;
    statusMessage.value = 'Applying ${profile.title} skin smoothing & glow...';

    try {
      final result = await AiEnhanceService.enhancePhoto(
        imagePath: currentTarget,
        profile: profile,
      );
      restoredImagePath.value = result.enhancedImagePath;
      healingHistory.add(result.enhancedImagePath);
      isRestoring.value = false;
    } catch (e) {
      isRestoring.value = false;
      _showFriendlyError('Beauty Enhance', 'Could not apply beauty filter: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // AI CLOUD RESTORE (PRO FEATURE — REPLICATE GFPGAN)
  // ---------------------------------------------------------------------------
  Future<void> runAiCloudRestore() async {
    final currentTarget = originalImagePath.value;
    if (currentTarget.isEmpty) return;

    final premium = Get.find<PremiumService>();

    // Check if user can use AI restore (Pro or has credits)
    if (!premium.canUseAiRestore) {
      premium.showEarnCreditsDialog();
      return;
    }

    // Check if API is configured
    if (!AiRestoreApiService.isConfigured) {
      _showFriendlyError(
        'AI Not Configured',
        'Replicate API token is not set. Please configure it to use cloud AI restoration.',
      );
      return;
    }

    isRestoring.value = true;
    statusMessage.value = '🤖 Running AI Face Restoration (GFPGAN)...';

    try {
      final result = await AiRestoreApiService.restoreWithAi(
        imageFile: File(currentTarget),
        upscale: 2,
      );

      // Consume credit (Pro users are exempt)
      await premium.consumeAiCredit();

      restoredImagePath.value = result.restoredImagePath;
      healingHistory.clear();
      healingHistory.add(result.restoredImagePath);
      isRestoring.value = false;

      Get.snackbar(
        '🤖 AI Restored!',
        'Photo restored with GFPGAN in ${(result.processingTimeMs / 1000).toStringAsFixed(1)}s',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF065F46),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      isRestoring.value = false;
      _showFriendlyError('AI Restore Failed', '$e');
    }
  }

  // ---------------------------------------------------------------------------
  // TOUCH SPOT HEALING
  // ---------------------------------------------------------------------------
  Future<void> healTouchSpot(double normX, double normY, double normRadius) async {
    final currentTarget = restoredImagePath.value.isNotEmpty ? restoredImagePath.value : originalImagePath.value;
    if (currentTarget.isEmpty) return;

    try {
      final healedPath = await PhotoRestorationService.healSpotAtCoordinates(
        imageFile: File(currentTarget),
        normX: normX,
        normY: normY,
        normRadius: normRadius,
      );

      healingHistory.add(healedPath);
      restoredImagePath.value = healedPath;
    } catch (e) {
      _showFriendlyError('Spot Healing', 'Could not heal selected area: $e');
    }
  }

  void undoLastHeal() {
    if (healingHistory.length > 1) {
      healingHistory.removeLast();
      restoredImagePath.value = healingHistory.last;
    } else if (healingHistory.isNotEmpty) {
      restoredImagePath.value = healingHistory.first;
    }
  }

  bool get canUndoHealing => healingHistory.length > 1;

  void setStrength(RestorationStrength strength) {
    if (selectedStrength.value == strength) return;
    selectedStrength.value = strength;
    runRestoration();
  }

  void toggleColorize(bool value) {
    if (colorizeBw.value == value) return;
    colorizeBw.value = value;
    runRestoration();
  }

  void setUpscaleFactor(int factor) {
    if (upscaleFactor.value == factor) return;
    upscaleFactor.value = factor;
    runRestoration();
  }

  void applyFineTune({
    required double brightness,
    required double contrast,
    required double sharpness,
    required double saturation,
    required double temperature,
  }) {
    fineBrightness.value = brightness;
    fineContrast.value = contrast;
    fineSharpness.value = sharpness;
    fineSaturation.value = saturation;
    fineTemperature.value = temperature;
    runRestoration();
  }

  void resetFineTune() {
    fineBrightness.value = 0.0;
    fineContrast.value = 1.0;
    fineSharpness.value = 1.0;
    fineSaturation.value = 1.0;
    fineTemperature.value = 0.0;
    runRestoration();
  }

  // ---------------------------------------------------------------------------
  // STEP 4: ACTIONS & PASSPORT WORKFLOW HANDOFF
  // ---------------------------------------------------------------------------
  Future<void> saveToDevice() async {
    final path = restoredImagePath.value;
    if (path.isEmpty || !File(path).existsSync()) return;

    Get.snackbar(
      'Saved Successfully! 💾',
      'Restored photo has been saved to your device.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF065F46),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> sharePhoto() async {
    final path = restoredImagePath.value;
    if (path.isEmpty || !File(path).existsSync()) return;

    try {
      await Share.shareXFiles(
        [XFile(path)],
        text: 'AI Restored & Enhanced Photo',
      );
    } catch (e) {
      Get.snackbar('Share Notice', 'Could not share photo: $e', colorText: Colors.white);
    }
  }

  /// Seamless handoff into Passport Photo Maker Wizard
  void useForPassportPhoto() {
    final path = restoredImagePath.value.isNotEmpty ? restoredImagePath.value : originalImagePath.value;
    if (path.isEmpty || !File(path).existsSync()) return;

    // Send restored image directly into Step-by-step Passport Photo Wizard
    Get.toNamed(Routes.WIZARD, arguments: {
      'imagePath': path,
    });
  }

  /// Automatically crop out surrounding table/background from physical print photos
  Future<void> autoCropPrintedCard() async {
    if (originalImagePath.value.isEmpty) return;
    isRestoring.value = true;
    statusMessage.value = 'Auto-cropping photo card from background...';
    try {
      final croppedPath = await PhotoRestorationService.autoCropPhotoCard(File(originalImagePath.value));
      await _setPhotoAndAnalyze(croppedPath);
      Get.snackbar(
        'Auto-Cropped! ✂️',
        'Cropped physical photo card from table background.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF065F46),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      isRestoring.value = false;
      _showFriendlyError('Auto-Crop Notice', 'Could not detect distinct photo card edges.');
    }
  }

  void resetAndChooseAnother() {
    originalImagePath.value = '';
    restoredImagePath.value = '';
    analysisReport.value = null;
    restorationResult.value = null;
    selectedStrength.value = RestorationStrength.medium;
    colorizeBw.value = false;
    upscaleFactor.value = 1;
    healingHistory.clear();
    resetFineTune();
  }

  void _showFriendlyError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF991B1B),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    );
  }
}
