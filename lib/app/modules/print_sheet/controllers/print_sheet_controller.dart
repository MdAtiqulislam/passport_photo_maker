import 'package:get/get.dart';
import '../../../../core/services/print_sheet_service.dart';
import '../../../../data/models/paper_size.dart';
import '../../../../data/models/photo_project.dart';
import '../../../../data/models/photo_size.dart';
import '../../../../data/models/print_sheet_config.dart';
import '../../../../data/repositories/project_repository.dart';
import '../../../routes/app_pages.dart';

class PrintSheetController extends GetxController {
  late PhotoProject project;
  late PhotoSize photoSize;
  late String processedImagePath;

  final ProjectRepository _projectRepo = ProjectRepository();

  // Print Sheet Configuration state
  final Rx<PaperSize> selectedPaperSize = PaperSize.photo4x6.obs;
  final RxInt selectedCopies = 8.obs;
  final RxDouble marginMm = 5.0.obs;
  final RxDouble gapMm = 2.0.obs;
  final Rx<CutLineType> selectedCutLine = CutLineType.dashed.obs;
  final Rx<PrintSheetAlignment> selectedAlignment = PrintSheetAlignment.top.obs;
  final RxBool isLandscape = false.obs;
  final RxBool showLabels = true.obs;

  final RxBool isGenerating = false.obs;

  PrintSheetConfig get currentConfig => PrintSheetConfig(
        paperSize: selectedPaperSize.value,
        photoSize: photoSize,
        copies: selectedCopies.value,
        marginMm: marginMm.value,
        gapMm: gapMm.value,
        alignment: selectedAlignment.value,
        cutLineType: selectedCutLine.value,
        isLandscape: isLandscape.value,
        showLabels: showLabels.value,
      );

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null) {
      project = args['project'] as PhotoProject;
      photoSize = args['photoSize'] as PhotoSize;
      processedImagePath = args['processedImagePath'] as String;
    }

    // Default copies selection based on paper size
    _adjustInitialCopies();
  }

  void _adjustInitialCopies() {
    final maxCopies = currentConfig.maxFitCopies;
    if (selectedCopies.value > maxCopies) {
      selectedCopies.value = maxCopies;
    }
  }

  void setPaperSize(PaperSize size) {
    // A4 is pro or free
    selectedPaperSize.value = size;
    _adjustInitialCopies();
  }

  void setCopies(int count) {
    final maxCopies = currentConfig.maxFitCopies;
    selectedCopies.value = count.clamp(1, maxCopies);
  }

  void incrementCopies() {
    final maxCopies = currentConfig.maxFitCopies;
    if (selectedCopies.value < maxCopies) {
      selectedCopies.value++;
    }
  }

  void decrementCopies() {
    if (selectedCopies.value > 1) {
      selectedCopies.value--;
    }
  }

  void setMaxFitCopies() {
    selectedCopies.value = currentConfig.maxFitCopies;
  }

  void toggleOrientation() {
    isLandscape.value = !isLandscape.value;
    _adjustInitialCopies();
  }

  void setCutLineType(CutLineType type) {
    selectedCutLine.value = type;
  }

  /// Generate High-Res PDF and Sheet Image, then navigate to Export
  Future<void> generateAndExport() async {
    try {
      isGenerating.value = true;

      final result = await PrintSheetService.generateSheet(
        photoPath: processedImagePath,
        config: currentConfig,
        dpi: photoSize.recommendedDpi,
      );

      final updatedProject = PhotoProject(
        id: project.id,
        title: project.title,
        originalImagePath: project.originalImagePath,
        processedImagePath: project.processedImagePath,
        sheetImagePath: result.imagePath,
        pdfPath: result.pdfPath,
        photoSize: photoSize,
        backgroundColor: project.backgroundColor,
        createdAt: project.createdAt,
        copies: selectedCopies.value,
      );

      await _projectRepo.saveProject(updatedProject);

      Get.toNamed(Routes.EXPORT, arguments: {
        'project': updatedProject,
        'photoSize': photoSize,
        'processedImagePath': processedImagePath,
        'sheetImagePath': result.imagePath,
        'pdfPath': result.pdfPath,
        'config': currentConfig,
      });
    } catch (e) {
      Get.snackbar('Generation Failed', 'Could not generate print sheet: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isGenerating.value = false;
    }
  }
}
