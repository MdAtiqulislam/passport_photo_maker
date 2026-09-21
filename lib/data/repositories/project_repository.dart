import 'package:get/get.dart';
import '../../core/services/storage_service.dart';
import '../models/photo_project.dart';

class ProjectRepository {
  StorageService? get _storage => Get.isRegistered<StorageService>() ? Get.find<StorageService>() : null;

  List<PhotoProject> getAllProjects() {
    return _storage?.getProjects() ?? [];
  }

  Future<void> saveProject(PhotoProject project) async {
    await _storage?.saveProject(project);
  }

  Future<void> deleteProject(String id) async {
    await _storage?.deleteProject(id);
  }

  Future<void> clearAllProjects() async {
    await _storage?.clearAllProjects();
  }
}
