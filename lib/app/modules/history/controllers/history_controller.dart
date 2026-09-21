import 'package:get/get.dart';
import '../../../../data/models/photo_project.dart';
import '../../../../data/repositories/project_repository.dart';
import '../../../routes/app_pages.dart';

class HistoryController extends GetxController {
  final ProjectRepository _projectRepo = ProjectRepository();
  final RxList<PhotoProject> projects = <PhotoProject>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadProjects();
  }

  void loadProjects() {
    isLoading.value = true;
    projects.value = _projectRepo.getAllProjects();
    isLoading.value = false;
  }

  Future<void> deleteProject(String id) async {
    await _projectRepo.deleteProject(id);
    loadProjects();
  }

  Future<void> clearAll() async {
    await _projectRepo.clearAllProjects();
    loadProjects();
  }

  void openProject(PhotoProject project) {
    Get.toNamed(Routes.EXPORT, arguments: {
      'project': project,
      'photoSize': project.photoSize,
      'processedImagePath': project.processedImagePath,
      'sheetImagePath': project.sheetImagePath,
      'pdfPath': project.pdfPath,
    });
  }

  void reEditProject(PhotoProject project) {
    Get.toNamed(Routes.EDITOR, arguments: {
      'imagePath': project.originalImagePath,
      'photoSize': project.photoSize,
    });
  }
}
