import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/image_processing_service.dart';
import '../../../../core/services/portrait_segmentation_service.dart';
import '../../../../data/models/photo_project.dart';
import '../../../../data/models/photo_size.dart';
import '../../../../data/models/segmentation_result.dart';
import '../../../../data/models/outfit_template.dart';
import '../../../../data/repositories/project_repository.dart';
import '../../../../core/services/outfit_extractor_service.dart';
import '../../../routes/app_pages.dart';
import '../views/manual_mask_editor_view.dart';
import '../views/outfit_fitting_studio_view.dart';
import '../views/ai_enhance_view.dart';

class EditorController extends GetxController {
  late String sourceImagePath;
  late PhotoSize photoSize;

  final ProjectRepository _projectRepo = ProjectRepository();
  final ImagePicker _picker = ImagePicker();

  // Quality check
  final Rx<PhotoQualityReport?> qualityReport = Rx<PhotoQualityReport?>(null);
  final RxBool isCheckingQuality = true.obs;
  final RxBool isProcessing = false.obs;

  // AI Segmentation States
  final RxBool isSegmenting = false.obs;
  final RxString segmentationStatus = 'Analyzing photo...'.obs;
  final Rx<SegmentationResult?> segmentationResult = Rx<SegmentationResult?>(null);
  final RxString autoCutoutPath = ''.obs;
  final RxBool isAutoResultMode = true.obs; // Toggle: [ Original ] vs [ Auto Result ]
  final RxBool isManualSelectionActive = false.obs;
  SegmentationMaskData? _initialAutoMask;

  // Active Tab: 0 = Cutout & Framing, 1 = Outfits, 2 = Background, 3 = Adjustments
  final RxInt activeTabIndex = 0.obs;

  // Formal Outfit Changer State
  final Rx<OutfitTemplate?> selectedOutfit = Rx<OutfitTemplate?>(null);
  final Rx<OutfitTransformConfig> outfitTransform = const OutfitTransformConfig().obs;
  final RxList<OutfitTemplate> customOutfits = <OutfitTemplate>[].obs;

  // Transformations & Biometric Framing
  final RxDouble zoomScale = 1.0.obs;
  final RxDouble panOffsetX = 0.0.obs;
  final RxDouble panOffsetY = 0.0.obs;
  final RxInt rotationDegrees = 0.obs;
  final RxBool flipHorizontal = false.obs;
  final RxBool showGuidelines = true.obs;

  // Smart Head-to-Chest Framing & Feathering
  final RxDouble chestBoundaryRatio = 0.85.obs; // 0.65 (tighter around neck/shoulders) .. 1.0 (full chest/bust)
  final RxDouble headroomRatio = 0.10.obs;
  final RxDouble edgeFeatherRadius = 2.0.obs; // 0.5 .. 5.0 px (Photoshop Edge Softening)

  // Image Adjustments
  final RxDouble brightness = 0.0.obs; // -1.0 .. 1.0
  final RxDouble contrast = 1.0.obs; // 0.0 .. 2.0
  final RxDouble saturation = 1.0.obs; // 0.0 .. 2.0
  final RxDouble sharpness = 0.0.obs; // 0.0 .. 1.0
  final RxDouble warmth = 0.0.obs; // -1.0 .. 1.0
  final RxBool isAutoEnhanced = false.obs;

  // Background
  final Rx<Color> selectedBackgroundColor = Colors.white.obs;

  // Normalized Crop coordinates (0.0 .. 1.0)
  double cropX = 0.0;
  double cropY = 0.0;
  double cropWidth = 1.0;
  double cropHeight = 1.0;

  // AI Photo Enhancement
  String originalSourceImagePath = '';
  final RxString enhancedImagePath = ''.obs;
  final RxBool isEnhancedApplied = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null) {
      sourceImagePath = args['imagePath'] as String;
      originalSourceImagePath = sourceImagePath;
      photoSize = args['photoSize'] as PhotoSize? ??
          const PhotoSize(
            id: 'bd_passport',
            country: 'Bangladesh',
            countryCode: 'BD',
            flag: '🇧🇩',
            name: 'Passport Photo',
            category: 'Passport',
            widthMm: 35.0,
            heightMm: 45.0,
          );
    }
    _initPipeline();
  }

  Future<void> _initPipeline() async {
    await _runQualityCheck();
    await runAutomaticSegmentation();
  }

  Future<void> _runQualityCheck() async {
    isCheckingQuality.value = true;
    qualityReport.value = await ImageProcessingService.analyzeImageQuality(sourceImagePath);
    isCheckingQuality.value = false;
  }

  /// AI Automatic Person Segmentation & Solid Background Workflow
  Future<void> runAutomaticSegmentation() async {
    try {
      isSegmenting.value = true;
      segmentationStatus.value = 'Analyzing photo...';
      await Future.delayed(const Duration(milliseconds: 150));

      segmentationStatus.value = 'Detecting person & face...';
      final file = File(sourceImagePath);
      final result = await PortraitSegmentationService.segmentPerson(file);
      segmentationResult.value = result;

      if (!result.isPersonDetected) {
        isSegmenting.value = false;
        _showNoPersonDialog(result.errorMessage ?? 'Could not detect a person in this photo.');
        return;
      }

      if (result.hasMultiplePeople) {
        // Multiple people detected: sort largest primary or notify
        segmentationStatus.value = 'Multiple people detected. Selected primary subject.';
      }

      if (result.mask != null) {
        _initialAutoMask = result.mask!.clone();
      }
      isManualSelectionActive.value = false;

      segmentationStatus.value = 'Removing background & applying solid color...';
      await _generateAutoCutout();

      isAutoResultMode.value = true;
    } catch (e) {
      debugPrint('Segmentation error: $e');
    } finally {
      isSegmenting.value = false;
    }
  }

  void openManualMaskEditor() {
    if (segmentationResult.value?.mask == null) {
      Get.snackbar('Processing', 'Please wait for photo analysis to finish', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final maskToEdit = segmentationResult.value!.mask!;
    Get.to(
      () => ManualMaskEditorView(
        initialMask: maskToEdit,
        imagePath: sourceImagePath,
        onApply: (newMask) {
          isManualSelectionActive.value = true;
          segmentationResult.value = segmentationResult.value!.copyWith(mask: newMask);
          _generateAutoCutout();
          Get.snackbar('Manual Mask Applied', 'Portrait background updated with manual selection', snackPosition: SnackPosition.BOTTOM);
        },
      ),
    );
  }

  void resetToAutoMask() {
    if (_initialAutoMask != null && segmentationResult.value != null) {
      isManualSelectionActive.value = false;
      segmentationResult.value = segmentationResult.value!.copyWith(mask: _initialAutoMask!.clone());
      _generateAutoCutout();
      Get.snackbar('Auto Selection Restored', 'Reverted to automatic AI person cutout', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Timer? _debounceTimer;
  bool _isRegenerating = false;

  Future<void> _generateAutoCutout({bool isPreview = true}) async {
    if (segmentationResult.value == null || !segmentationResult.value!.isPersonDetected) return;
    if (_isRegenerating && isPreview) return;

    _isRegenerating = true;
    try {
      final targetWPx = photoSize.getWidthPx(dpi: isPreview ? 150 : 300);
      final targetHPx = photoSize.getHeightPx(dpi: isPreview ? 150 : 300);

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

      final resultPath = await PortraitSegmentationService.createPortrait(
        imageFile: File(sourceImagePath),
        segmentation: segmentationResult.value!,
        cropConfig: cropConfig,
        targetWidthPx: targetWPx,
        targetHeightPx: targetHPx,
        targetAspectRatio: photoSize.aspectRatio,
        isPreview: isPreview,
      );

      autoCutoutPath.value = resultPath;
    } catch (e) {
      debugPrint('Error generating cutout: $e');
    } finally {
      _isRegenerating = false;
    }
  }

  void toggleResultMode(bool isAuto) {
    isAutoResultMode.value = isAuto;
  }

  void onChestBoundaryChanged(double value) {
    chestBoundaryRatio.value = value;
    _debounceRegenerateCutout();
  }

  void onHeadroomChanged(double value) {
    headroomRatio.value = value;
    _debounceRegenerateCutout();
  }

  void selectOutfit(OutfitTemplate outfit) {
    selectedOutfit.value = outfit;
    _debounceRegenerateCutout();
  }

  void clearOutfit() {
    selectedOutfit.value = null;
    _debounceRegenerateCutout();
  }

  void updateOutfitTransform(OutfitTransformConfig config) {
    outfitTransform.value = config;
    _debounceRegenerateCutout();
  }

  void resetOutfitTransform() {
    outfitTransform.value = const OutfitTransformConfig();
    _debounceRegenerateCutout();
  }

  void openOutfitStudio() {
    Get.to(() => const OutfitFittingStudioView());
  }

  void toggleOutfitFlip() {
    outfitTransform.value = outfitTransform.value.copyWith(
      flipHorizontal: !outfitTransform.value.flipHorizontal,
    );
    _debounceRegenerateCutout();
  }

  Future<void> extractCustomOutfit({ImageSource source = ImageSource.gallery}) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 100);
      if (picked == null) return;

      Get.snackbar('Extracting Outfit', 'Analyzing clothing from reference photo...', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));

      final customTemplate = await OutfitExtractorService.extractOutfitFromPhoto(
        File(picked.path),
        name: 'Custom Outfit #${customOutfits.length + 1}',
      );

      customOutfits.add(customTemplate);
      selectOutfit(customTemplate);

      Get.snackbar('Outfit Extracted ✨', 'Custom outfit applied to your portrait!', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Extraction Error', 'Could not extract outfit from this photo: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void onEdgeFeatherChanged(double value) {
    edgeFeatherRadius.value = value;
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

  void toggleGuidelines() {
    showGuidelines.value = !showGuidelines.value;
  }

  void openAiEnhanceScreen() {
    Get.to(
      () => AiEnhanceView(
        imagePath: originalSourceImagePath.isNotEmpty ? originalSourceImagePath : sourceImagePath,
        onApplyEnhanced: (newEnhancedPath) {
          applyEnhancedImage(newEnhancedPath);
        },
      ),
    );
  }

  Future<void> applyEnhancedImage(String newEnhancedPath) async {
    if (originalSourceImagePath.isEmpty) {
      originalSourceImagePath = sourceImagePath;
    }
    enhancedImagePath.value = newEnhancedPath;
    sourceImagePath = newEnhancedPath;
    isEnhancedApplied.value = true;

    // Clear Flutter image cache so updated file renders immediately
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    // Re-run segmentation & auto cutout with enhanced photo
    await runAutomaticSegmentation();
  }

  Future<void> revertToOriginalPhoto() async {
    if (originalSourceImagePath.isNotEmpty) {
      sourceImagePath = originalSourceImagePath;
      isEnhancedApplied.value = false;
      enhancedImagePath.value = '';

      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      await runAutomaticSegmentation();
    }
  }

  void toggleAutoEnhance() {
    isAutoEnhanced.value = !isAutoEnhanced.value;
    if (isAutoEnhanced.value) {
      brightness.value = 0.15;
      contrast.value = 1.15;
      saturation.value = 1.05;
    } else {
      resetAdjustments();
    }
  }

  void resetAdjustments() {
    brightness.value = 0.0;
    contrast.value = 1.0;
    saturation.value = 1.0;
    sharpness.value = 0.0;
    warmth.value = 0.0;
    isAutoEnhanced.value = false;
  }

  void resetAll() {
    zoomScale.value = 1.0;
    panOffsetX.value = 0.0;
    panOffsetY.value = 0.0;
    rotationDegrees.value = 0;
    flipHorizontal.value = false;
    chestBoundaryRatio.value = 0.85;
    headroomRatio.value = 0.10;
    resetAdjustments();
    selectedBackgroundColor.value = Colors.white;
    _generateAutoCutout();
  }

  void setBackgroundColor(Color color) {
    selectedBackgroundColor.value = color;
    _debounceRegenerateCutout();
  }

  void _debounceRegenerateCutout() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (segmentationResult.value != null && segmentationResult.value!.isPersonDetected) {
        _generateAutoCutout(isPreview: true);
      }
    });
  }

  void updateCropBounds({
    required double normX,
    required double normY,
    required double normW,
    required double normH,
  }) {
    cropX = normX.clamp(0.0, 1.0);
    cropY = normY.clamp(0.0, 1.0);
    cropWidth = normW.clamp(0.1, 1.0);
    cropHeight = normH.clamp(0.1, 1.0);
  }

  void _showNoPersonDialog(String message) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_off_outlined, color: AppColors.warning),
            SizedBox(width: 8),
            Text('No Person Detected'),
          ],
        ),
        content: Text(
          '$message\nPlease select a clear front-facing portrait photo with adequate lighting.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              runAutomaticSegmentation();
            },
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
              if (picked != null) {
                sourceImagePath = picked.path;
                _initPipeline();
              }
            },
            child: const Text('Choose Another Photo'),
          ),
        ],
      ),
    );
  }

  /// Process photo and navigate to Print Sheet or Export screen
  Future<void> generateAndProceed({bool goToPrintSheet = true}) async {
    try {
      isProcessing.value = true;

      String finalProcessedPath;

      if (isAutoResultMode.value) {
        // Generate high-resolution 300 DPI final portrait in background isolate
        await _generateAutoCutout(isPreview: false);
        finalProcessedPath = autoCutoutPath.value;
      } else {
        final targetWPx = photoSize.getWidthPx(dpi: 300);
        final targetHPx = photoSize.getHeightPx(dpi: 300);

        finalProcessedPath = await ImageProcessingService.processPhoto(
          sourceImagePath: sourceImagePath,
          cropX: cropX,
          cropY: cropY,
          cropWidth: cropWidth,
          cropHeight: cropHeight,
          rotationDegrees: rotationDegrees.value,
          flipHorizontal: flipHorizontal.value,
          brightness: brightness.value,
          contrast: contrast.value,
          saturation: saturation.value,
          warmth: warmth.value,
          applyAutoEnhance: isAutoEnhanced.value,
          targetBackgroundColor: selectedBackgroundColor.value,
          targetWidthPx: targetWPx,
          targetHeightPx: targetHPx,
          outputDpi: photoSize.recommendedDpi,
        );
      }

      final project = PhotoProject(
        id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
        title: '${photoSize.country} ${photoSize.name}',
        originalImagePath: sourceImagePath,
        processedImagePath: finalProcessedPath,
        photoSize: photoSize,
        backgroundColor: '#${selectedBackgroundColor.value.value.toRadixString(16)}',
        createdAt: DateTime.now(),
      );

      await _projectRepo.saveProject(project);

      if (goToPrintSheet) {
        Get.toNamed(Routes.PRINT_SHEET, arguments: {
          'project': project,
          'photoSize': photoSize,
          'processedImagePath': finalProcessedPath,
        });
      } else {
        Get.toNamed(Routes.EXPORT, arguments: {
          'project': project,
          'photoSize': photoSize,
          'processedImagePath': finalProcessedPath,
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to process photo: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isProcessing.value = false;
    }
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    super.onClose();
  }
}
