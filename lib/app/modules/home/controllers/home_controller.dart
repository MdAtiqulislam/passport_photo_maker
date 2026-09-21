import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/premium_service.dart';
import '../../../../data/models/photo_project.dart';
import '../../../../data/models/photo_size.dart';
import '../../../../data/repositories/project_repository.dart';
import '../../../../data/repositories/template_repository.dart';
import '../../../routes/app_pages.dart';

class HomeController extends GetxController {
  final TemplateRepository _templateRepo = TemplateRepository();
  final ProjectRepository _projectRepo = ProjectRepository();
  final PremiumService premiumService = Get.find<PremiumService>();

  final ImagePicker _picker = ImagePicker();

  final RxList<PhotoProject> recentProjects = <PhotoProject>[].obs;
  final RxList<PhotoSize> popularTemplates = <PhotoSize>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  void loadDashboardData() async {
    isLoading.value = true;
    recentProjects.value = _projectRepo.getAllProjects();
    popularTemplates.value = await _templateRepo.getPopularTemplates();
    isLoading.value = false;
  }

  /// 📷 Create Passport Photo via Guided Wizard (Camera)
  Future<void> onTakePhoto() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (picked != null) {
        Get.toNamed(Routes.WIZARD, arguments: {
          'imagePath': picked.path,
        })?.then((_) => loadDashboardData());
      }
    } catch (e) {
      Get.toNamed(Routes.WIZARD)?.then((_) => loadDashboardData());
    }
  }

  /// 🖼 Choose Photo from Gallery & Launch Guided Wizard
  Future<void> onChooseFromGallery() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (picked != null) {
        Get.toNamed(Routes.WIZARD, arguments: {
          'imagePath': picked.path,
        })?.then((_) => loadDashboardData());
      }
    } catch (e) {
      Get.toNamed(Routes.WIZARD)?.then((_) => loadDashboardData());
    }
  }

  /// Launch Wizard from scratch
  void startWizard() {
    Get.toNamed(Routes.WIZARD)?.then((_) => loadDashboardData());
  }

  /// 🛠️ Open AI Photo Restoration Studio
  void openRestorationStudio() {
    Get.toNamed(Routes.RESTORATION)?.then((_) => loadDashboardData());
  }

  /// 👔 Open Outfit Gallery
  void openOutfitGallery() {
    Get.toNamed(Routes.OUTFIT_GALLERY)?.then((_) => loadDashboardData());
  }

  /// ✨ Quick AI Enhance
  Future<void> openAiEnhance() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
      if (picked != null) {
        Get.toNamed(Routes.WIZARD, arguments: {
          'imagePath': picked.path,
        })?.then((_) => loadDashboardData());
      }
    } catch (_) {}
  }

  void openHistory() {
    Get.toNamed(Routes.HISTORY)?.then((_) => loadDashboardData());
  }

  void openSettings() {
    Get.toNamed(Routes.SETTINGS)?.then((_) => loadDashboardData());
  }
}
