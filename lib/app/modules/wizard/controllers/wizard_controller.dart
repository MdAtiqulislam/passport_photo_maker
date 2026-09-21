import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/ai_enhance_service.dart';
import '../../../../core/services/ai_restore_api_service.dart';
import '../../../../core/services/photo_restoration_service.dart';
import '../../../../core/services/premium_service.dart';
import '../../../../core/services/portrait_segmentation_service.dart';
import '../../../../core/services/print_sheet_service.dart';
import '../../../../data/models/ai_enhance_result.dart';
import '../../../../data/models/outfit_template.dart';
import '../../../../data/models/paper_size.dart';
import '../../../../data/models/photo_project.dart';
import '../../../../data/models/photo_size.dart';
import '../../../../data/models/print_sheet_config.dart';
import '../../../../data/models/segmentation_result.dart';
import '../../../../data/repositories/outfit_repository.dart';
import '../../../../data/repositories/project_repository.dart';
import '../../../../data/repositories/template_repository.dart';

class WizardController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final ProjectRepository _projectRepo = ProjectRepository();
  final TemplateRepository _templateRepo = TemplateRepository();

  // Current Step: 1 to 8
  final RxInt currentStep = 1.obs;
  static const int totalSteps = 7; // Main flow steps 1 to 7, Step 8 is completion

  // Friendly Loading State
  final RxBool isProcessing = false.obs;
  final RxString processingMessage = ''.obs;

  // STEP 1 — Photo Assets
  final RxString rawImagePath = ''.obs;
  final RxString activeImagePath = ''.obs;

  // STEP 2 — AI Photo Enhancement, Beauty Camera & Spot Healing
  final RxBool isEnhancedApplied = false.obs;
  final RxString enhancedImagePath = ''.obs;
  final Rx<AiEnhanceProfile> selectedEnhanceProfile = AiEnhanceProfile.beautySmooth.obs;
  final Rx<AiEnhanceResult?> enhanceResult = Rx<AiEnhanceResult?>(null);
  final RxBool showEnhancedComparison = true.obs;
  final RxInt step2SubTab = 0.obs; // 0 = Beauty & Lighting, 1 = Spot Healer
  final RxList<String> wizardHealingHistory = <String>[].obs;

  // STEP 3 — Person Selection & Segmentation
  final Rx<SegmentationResult?> segmentationResult = Rx<SegmentationResult?>(null);
  final Rx<SegmentationMaskData?> workingMask = Rx<SegmentationMaskData?>(null);
  final RxBool isManualSelectionActive = false.obs;
  final RxDouble brushRadius = 24.0.obs;
  final RxBool isAddMode = true.obs;
  final RxDouble brushFeather = 0.3.obs;
  final List<SegmentationMaskData> _undoStack = [];
  final List<SegmentationMaskData> _redoStack = [];
  final RxBool canUndo = false.obs;
  final RxBool canRedo = false.obs;

  // STEP 4 — Background Color
  final Rx<Color> selectedBackgroundColor = Colors.white.obs;
  static const List<Color> backgroundPresets = [
    Colors.white,
    Color(0xFF0284C7), // Blue
    Color(0xFF7DD3FC), // Light Blue
    Color(0xFF94A3B8), // Gray
  ];

  // STEP 5 — Framing & Adjustments
  final RxDouble zoomScale = 1.0.obs;
  final RxDouble panOffsetX = 0.0.obs;
  final RxDouble panOffsetY = 0.0.obs;
  final RxInt rotationDegrees = 0.obs;
  final RxBool flipHorizontal = false.obs;
  final RxDouble chestBoundaryRatio = 0.85.obs;
  final RxDouble headroomRatio = 0.10.obs;
  final RxDouble edgeFeatherRadius = 2.0.obs;
  final RxBool showAdvancedAdjustments = false.obs;
  double cropX = 0.0;
  double cropY = 0.0;
  double cropWidth = 1.0;
  double cropHeight = 1.0;

  // Formal Outfits
  final Rx<OutfitTemplate?> selectedOutfit = Rx<OutfitTemplate?>(null);
  final Rx<OutfitTransformConfig> outfitTransform = const OutfitTransformConfig().obs;
  final RxList<OutfitTemplate> availableOutfits = <OutfitTemplate>[].obs;

  // STEP 6 — Photo Sizing
  final Rx<PhotoSize> selectedPhotoSize = const PhotoSize(
    id: 'bd_passport',
    country: 'Standard',
    countryCode: 'GEN',
    flag: '📄',
    name: 'Passport Photo',
    category: 'Passport',
    widthMm: 35.0,
    heightMm: 45.0,
  ).obs;
  final RxList<PhotoSize> allSizes = <PhotoSize>[].obs;

  // STEP 7 — Print Sheet Layout
  final RxInt copyCount = 8.obs;
  final Rx<PaperSize> selectedPaperSize = PaperSize.photo4x6.obs;
  final Rx<PrintSheetAlignment> selectedSheetAlignment = PrintSheetAlignment.top.obs;
  final RxBool includeCutLines = true.obs;
  final RxDouble photoSpacingMm = 3.0.obs;
  final RxDouble pageMarginMm = 5.0.obs;

  // STEP 8 — Generated Artifacts
  final RxString singleProcessedImagePath = ''.obs;
  final RxString sheetImagePath = ''.obs;
  final RxString pdfPath = ''.obs;
  final Rx<PhotoProject?> savedProject = Rx<PhotoProject?>(null);

  // Auto Cutout Preview Path
  final RxString cutoutPreviewPath = ''.obs;
  Timer? _debounceTimer;

  @override
  void onInit() {
    super.onInit();
    availableOutfits.value = OutfitRepository().getAllTemplates();
    _loadTemplates();

    final args = Get.arguments;
    if (args != null && args is Map) {
      if (args['imagePath'] != null) {
        rawImagePath.value = args['imagePath'] as String;
        activeImagePath.value = rawImagePath.value;
      }
      if (args['photoSize'] != null) {
        selectedPhotoSize.value = args['photoSize'] as PhotoSize;
      }
    }

    if (rawImagePath.value.isNotEmpty) {
      currentStep.value = 2; // Jump directly to Step 2 (Clean Up) if image already provided
      _runInitialAnalysis();
    }
  }

  Future<void> _loadTemplates() async {
    allSizes.value = await _templateRepo.getAllTemplates();
  }

  // ---------------------------------------------------------------------------
  // STEP 1 — ADD PHOTO
  // ---------------------------------------------------------------------------
  Future<void> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 100);
      if (photo != null) {
        await _setImageAndProceedToStep2(photo.path);
      }
    } catch (e) {
      _showFriendlyError('Could not open camera', 'Please check camera permissions in device settings.');
    }
  }

  Future<void> chooseFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
      if (photo != null) {
        await _setImageAndProceedToStep2(photo.path);
      }
    } catch (e) {
      _showFriendlyError('Could not open gallery', 'Please check storage permissions.');
    }
  }

  Future<void> _setImageAndProceedToStep2(String path) async {
    rawImagePath.value = path;
    activeImagePath.value = path;
    isEnhancedApplied.value = false;
    enhancedImagePath.value = '';
    currentStep.value = 2;
    _runInitialAnalysis();
  }

  // ---------------------------------------------------------------------------
  // STEP 2 — CLEAN PHOTO (AI ENHANCE, BEAUTY CAMERA & SPOT HEALING)
  // ---------------------------------------------------------------------------
  Future<void> runAiEnhancement() async {
    if (activeImagePath.value.isEmpty) return;
    _startLoading('Cleaning noise, smoothing skin & balancing lighting...');

    try {
      final res = await AiEnhanceService.enhancePhoto(
        imagePath: rawImagePath.value,
        profile: selectedEnhanceProfile.value,
      );
      enhanceResult.value = res;
      enhancedImagePath.value = res.enhancedImagePath;
      activeImagePath.value = res.enhancedImagePath;
      isEnhancedApplied.value = true;
      showEnhancedComparison.value = true;
      wizardHealingHistory.clear();
      wizardHealingHistory.add(res.enhancedImagePath);
      _stopLoading();
    } catch (e) {
      _stopLoading();
      _showFriendlyError("Couldn't enhance photo", 'We will continue with your original high-quality photo.');
    }
  }

  void switchEnhanceProfile(AiEnhanceProfile profile) {
    selectedEnhanceProfile.value = profile;
    runAiEnhancement();
  }

  Future<void> healTouchSpotInWizard(double normX, double normY, double normRadius) async {
    final currentTarget = activeImagePath.value;
    if (currentTarget.isEmpty) return;

    try {
      final healedPath = await PhotoRestorationService.healSpotAtCoordinates(
        imageFile: File(currentTarget),
        normX: normX,
        normY: normY,
        normRadius: normRadius,
      );

      wizardHealingHistory.add(healedPath);
      activeImagePath.value = healedPath;
      enhancedImagePath.value = healedPath;
      isEnhancedApplied.value = true;
    } catch (e) {
      _showFriendlyError('Spot Healing', 'Could not heal spot: $e');
    }
  }

  void undoHealingInWizard() {
    if (wizardHealingHistory.length > 1) {
      wizardHealingHistory.removeLast();
      activeImagePath.value = wizardHealingHistory.last;
      enhancedImagePath.value = wizardHealingHistory.last;
    } else if (wizardHealingHistory.isNotEmpty) {
      activeImagePath.value = rawImagePath.value;
      enhancedImagePath.value = '';
      isEnhancedApplied.value = false;
      wizardHealingHistory.clear();
    }
  }

  bool get canUndoWizardHealing => wizardHealingHistory.isNotEmpty;

  Future<void> autoCropCardInWizard() async {
    final current = rawImagePath.value;
    if (current.isEmpty) return;

    _startLoading('Auto-cropping photo card from background...');
    try {
      final croppedPath = await PhotoRestorationService.autoCropPhotoCard(File(current));
      rawImagePath.value = croppedPath;
      activeImagePath.value = croppedPath;
      wizardHealingHistory.clear();
      isEnhancedApplied.value = false;
      _stopLoading();
      _runInitialAnalysis();
      Get.snackbar(
        'Auto-Cropped! ✂️',
        'Cropped physical photo card from table background.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF065F46),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      _stopLoading();
      _showFriendlyError('Auto-Crop', 'Could not detect distinct photo card edges.');
    }
  }

  // ---------------------------------------------------------------------------
  // AI CLOUD RESTORE (PRO — REPLICATE GFPGAN)
  // ---------------------------------------------------------------------------
  Future<void> runAiCloudRestore() async {
    final current = activeImagePath.value.isNotEmpty ? activeImagePath.value : rawImagePath.value;
    if (current.isEmpty) return;

    final premium = Get.find<PremiumService>();

    // Check credits / Pro
    if (!premium.canUseAiRestore) {
      premium.showEarnCreditsDialog();
      return;
    }

    // Check API configured
    if (!AiRestoreApiService.isConfigured) {
      _showFriendlyError(
        'AI Not Configured',
        'Replicate API token is not set. Please configure it to use cloud AI restoration.',
      );
      return;
    }

    _startLoading('🤖 Running AI Face Restoration (GFPGAN)...');

    try {
      final result = await AiRestoreApiService.restoreWithAi(
        imageFile: File(current),
        upscale: 2,
      );

      // Consume credit (Pro users are exempt)
      await premium.consumeAiCredit();

      activeImagePath.value = result.restoredImagePath;
      enhancedImagePath.value = result.restoredImagePath;
      isEnhancedApplied.value = true;
      showEnhancedComparison.value = true;
      wizardHealingHistory.clear();
      wizardHealingHistory.add(result.restoredImagePath);
      _stopLoading();

      Get.snackbar(
        '🤖 AI Restored!',
        'Photo restored with GFPGAN in ${(result.processingTimeMs / 1000).toStringAsFixed(1)}s',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF065F46),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      _stopLoading();
      _showFriendlyError('AI Restore Failed', '$e');
    }
  }

  void keepOriginalPhoto() {
    isEnhancedApplied.value = false;
    activeImagePath.value = rawImagePath.value;
  }

  void useEnhancedPhoto() {
    if (enhancedImagePath.value.isNotEmpty) {
      isEnhancedApplied.value = true;
      activeImagePath.value = enhancedImagePath.value;
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 3 — PERSON SELECTION
  // ---------------------------------------------------------------------------
  Future<void> _runInitialAnalysis() async {
    if (activeImagePath.value.isEmpty) return;
    _startLoading('Analyzing photo & detecting person...');

    try {
      final file = File(activeImagePath.value);
      final result = await PortraitSegmentationService.segmentPerson(file);
      segmentationResult.value = result;

      if (result.mask != null) {
        workingMask.value = result.mask!.clone();
        _undoStack.clear();
        _redoStack.clear();
        _updateUndoRedoStatus();
      }

      _stopLoading();
      _generateCutoutPreview();
    } catch (e) {
      _stopLoading();
      _showFriendlyError('Person detection notice', 'Could not detect subject automatically. You can select manually.');
    }
  }

  void applyBrushStroke(double normX, double normY) {
    if (workingMask.value == null) return;
    _pushUndoState();

    workingMask.value!.applyBrushStroke(
      normX: normX,
      normY: normY,
      normRadius: brushRadius.value / 300.0,
      isAdd: isAddMode.value,
      feather: brushFeather.value,
    );
    workingMask.refresh();
  }

  void _pushUndoState() {
    if (workingMask.value == null) return;
    _undoStack.add(workingMask.value!.clone());
    if (_undoStack.length > 15) _undoStack.removeAt(0);
    _redoStack.clear();
    _updateUndoRedoStatus();
  }

  void undoSelection() {
    if (_undoStack.isEmpty || workingMask.value == null) return;
    _redoStack.add(workingMask.value!.clone());
    workingMask.value = _undoStack.removeLast();
    _updateUndoRedoStatus();
    workingMask.refresh();
    _debounceRegenerateCutout();
  }

  void redoSelection() {
    if (_redoStack.isEmpty || workingMask.value == null) return;
    _undoStack.add(workingMask.value!.clone());
    workingMask.value = _redoStack.removeLast();
    _updateUndoRedoStatus();
    workingMask.refresh();
    _debounceRegenerateCutout();
  }

  void resetSelectionToAuto() {
    if (segmentationResult.value?.mask != null) {
      _pushUndoState();
      workingMask.value = segmentationResult.value!.mask!.clone();
      workingMask.refresh();
      _debounceRegenerateCutout();
    }
  }

  void _updateUndoRedoStatus() {
    canUndo.value = _undoStack.isNotEmpty;
    canRedo.value = _redoStack.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // STEP 4 & 5 — BACKGROUND & ADJUSTMENTS PREVIEW GENERATION
  // ---------------------------------------------------------------------------
  void setBackgroundColor(Color color) {
    selectedBackgroundColor.value = color;
    _debounceRegenerateCutout();
  }

  void rotate90() {
    rotationDegrees.value = (rotationDegrees.value + 90) % 360;
    _debounceRegenerateCutout();
  }

  void toggleFlip() {
    flipHorizontal.value = !flipHorizontal.value;
    _debounceRegenerateCutout();
  }

  void updateCropBounds({
    required double normX,
    required double normY,
    required double normW,
    required double normH,
  }) {
    cropX = normX;
    cropY = normY;
    cropWidth = normW;
    cropHeight = normH;
  }

  void selectOutfit(OutfitTemplate? outfit) {
    selectedOutfit.value = outfit;
  }

  void triggerCutoutRegeneration() {
    _debounceRegenerateCutout();
  }

  void _debounceRegenerateCutout() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 180), () {
      _generateCutoutPreview();
    });
  }

  Future<void> _generateCutoutPreview() async {
    if (activeImagePath.value.isEmpty || segmentationResult.value == null) return;

    try {
      final cropConfig = PortraitCropConfig(
        chestBoundaryRatio: chestBoundaryRatio.value,
        headroomRatio: headroomRatio.value,
        edgeFeatherRadius: edgeFeatherRadius.value,
        panX: panOffsetX.value / 300.0,
        panY: panOffsetY.value / 300.0,
        zoomScale: zoomScale.value,
        rotationDegrees: rotationDegrees.value,
        flipHorizontal: flipHorizontal.value,
        backgroundColor: selectedBackgroundColor.value,
        customCropRect: (cropWidth < 0.99 || cropHeight < 0.99 || cropX > 0.01 || cropY > 0.01)
            ? Rect.fromLTWH(cropX, cropY, cropWidth, cropHeight)
            : null,
      );

      final segData = segmentationResult.value!.copyWith(mask: workingMask.value);

      final previewPath = await PortraitSegmentationService.createPortrait(
        imageFile: File(activeImagePath.value),
        segmentation: segData,
        cropConfig: cropConfig,
        targetWidthPx: 450,
        targetHeightPx: 600,
        targetAspectRatio: selectedPhotoSize.value.aspectRatio,
        isPreview: true,
      );

      cutoutPreviewPath.value = previewPath;
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // STEP 6 — CHOOSE SIZE
  // ---------------------------------------------------------------------------
  void selectPhotoSize(PhotoSize size) {
    selectedPhotoSize.value = size;
    _generateCutoutPreview();
  }

  // ---------------------------------------------------------------------------
  // STEP 7 — PRINT LAYOUT & FINAL GENERATION
  // ---------------------------------------------------------------------------
  void setCopyCount(int count) {
    copyCount.value = count.clamp(1, 40);
  }

  void selectPaperSize(PaperSize paper) {
    selectedPaperSize.value = paper;
  }

  Future<void> generateFinalPassportAndSheet() async {
    _startLoading('Creating official passport photo & print sheet...');

    try {
      // 1. Render Final 300 DPI Passport Photo
      final targetWPx = selectedPhotoSize.value.getWidthPx(dpi: 300);
      final targetHPx = selectedPhotoSize.value.getHeightPx(dpi: 300);

      final cropConfig = PortraitCropConfig(
        chestBoundaryRatio: chestBoundaryRatio.value,
        headroomRatio: headroomRatio.value,
        edgeFeatherRadius: edgeFeatherRadius.value,
        panX: panOffsetX.value / 300.0,
        panY: panOffsetY.value / 300.0,
        zoomScale: zoomScale.value,
        rotationDegrees: rotationDegrees.value,
        flipHorizontal: flipHorizontal.value,
        backgroundColor: selectedBackgroundColor.value,
        customCropRect: (cropWidth < 0.99 || cropHeight < 0.99 || cropX > 0.01 || cropY > 0.01)
            ? Rect.fromLTWH(cropX, cropY, cropWidth, cropHeight)
            : null,
      );

      final segData = segmentationResult.value != null
          ? segmentationResult.value!.copyWith(mask: workingMask.value)
          : SegmentationResult.failure('No mask');

      final finalPortraitPath = await PortraitSegmentationService.createPortrait(
        imageFile: File(activeImagePath.value),
        segmentation: segData,
        cropConfig: cropConfig,
        targetWidthPx: targetWPx,
        targetHeightPx: targetHPx,
        targetAspectRatio: selectedPhotoSize.value.aspectRatio,
        isPreview: false,
      );

      singleProcessedImagePath.value = finalPortraitPath;

      // 2. Generate Multi-Copy Print Sheet & PDF
      final printConfig = PrintSheetConfig(
        paperSize: selectedPaperSize.value,
        photoSize: selectedPhotoSize.value,
        copies: copyCount.value,
        marginMm: pageMarginMm.value,
        gapMm: photoSpacingMm.value,
        alignment: selectedSheetAlignment.value,
        cutLineType: includeCutLines.value ? CutLineType.dashed : CutLineType.none,
      );

      final sheetResult = await PrintSheetService.generateSheet(
        photoPath: finalPortraitPath,
        config: printConfig,
        dpi: 300,
      );

      sheetImagePath.value = sheetResult.imagePath;
      pdfPath.value = sheetResult.pdfPath;

      // 3. Save Project to Database
      final project = PhotoProject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: '${selectedPhotoSize.value.country} ${selectedPhotoSize.value.name}',
        originalImagePath: rawImagePath.value,
        processedImagePath: finalPortraitPath,
        sheetImagePath: sheetResult.imagePath,
        pdfPath: sheetResult.pdfPath,
        photoSize: selectedPhotoSize.value,
        createdAt: DateTime.now(),
        copies: copyCount.value,
        backgroundColor: selectedBackgroundColor.value.toString(),
      );

      await _projectRepo.saveProject(project);
      savedProject.value = project;

      _stopLoading();
      currentStep.value = 8; // Step 8 — Success & Share
    } catch (e) {
      _stopLoading();
      _showFriendlyError('Generation failed', 'Could not generate print sheet: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // NAVIGATION & STATE PRESERVATION
  // ---------------------------------------------------------------------------
  void nextStep() {
    switch (currentStep.value) {
      case 1:
        if (activeImagePath.value.isNotEmpty) currentStep.value = 2;
        break;
      case 2:
        currentStep.value = 3;
        if (segmentationResult.value == null) {
          _runInitialAnalysis();
        }
        break;
      case 3:
        currentStep.value = 4;
        break;
      case 4:
        currentStep.value = 5;
        break;
      case 5:
        currentStep.value = 6;
        break;
      case 6:
        currentStep.value = 7;
        break;
      case 7:
        generateFinalPassportAndSheet();
        break;
    }
  }

  void previousStep() {
    if (currentStep.value > 1) {
      currentStep.value--;
    } else {
      Get.back();
    }
  }

  void createAnother() {
    // Reset state and return to Step 1
    rawImagePath.value = '';
    activeImagePath.value = '';
    enhancedImagePath.value = '';
    isEnhancedApplied.value = false;
    segmentationResult.value = null;
    workingMask.value = null;
    cutoutPreviewPath.value = '';
    singleProcessedImagePath.value = '';
    sheetImagePath.value = '';
    pdfPath.value = '';
    currentStep.value = 1;
  }

  void _startLoading(String message) {
    isProcessing.value = true;
    processingMessage.value = message;
  }

  void _stopLoading() {
    isProcessing.value = false;
    processingMessage.value = '';
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

  @override
  void onClose() {
    _debounceTimer?.cancel();
    PaintingBinding.instance.imageCache.clear();
    super.onClose();
  }
}
