import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../data/models/photo_project.dart';

class StorageService extends GetxService {
  late final GetStorage _box;

  static const String _keyProjects = 'saved_projects';
  static const String _keyOnboardingDone = 'onboarding_done';
  static const String _keyIsPro = 'is_pro_unlocked';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyAiCredits = 'ai_credits';

  Future<StorageService> init([GetStorage? customBox]) async {
    if (customBox != null) {
      _box = customBox;
      return this;
    }
    await GetStorage.init();
    _box = GetStorage();
    return this;
  }

  // Onboarding
  bool get isOnboardingCompleted => _box.read<bool>(_keyOnboardingDone) ?? false;
  Future<void> setOnboardingCompleted() async => await _box.write(_keyOnboardingDone, true);

  // Pro status
  bool get isProUser => _box.read<bool>(_keyIsPro) ?? false;
  Future<void> setProUser(bool value) async => await _box.write(_keyIsPro, value);

  // Theme mode
  String get themeMode => _box.read<String>(_keyThemeMode) ?? 'system';
  Future<void> setThemeMode(String mode) async => await _box.write(_keyThemeMode, mode);

  // AI Credits
  int get aiCredits => _box.read<int>(_keyAiCredits) ?? 2;
  bool get hasAiCredits => aiCredits > 0;

  Future<void> addCredits(int amount) async {
    final current = aiCredits;
    await _box.write(_keyAiCredits, current + amount);
  }

  Future<void> deductCredit() async {
    final current = aiCredits;
    if (current > 0) {
      await _box.write(_keyAiCredits, current - 1);
    }
  }

  // Saved Projects
  List<PhotoProject> getProjects() {
    try {
      final list = _box.read<List>(_keyProjects);
      if (list == null) return [];
      return list.map((item) => PhotoProject.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveProject(PhotoProject project) async {
    final list = getProjects();
    final index = list.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      list[index] = project;
    } else {
      list.insert(0, project);
    }
    final rawList = list.map((p) => p.toJson()).toList();
    await _box.write(_keyProjects, rawList);
  }

  Future<void> deleteProject(String id) async {
    final list = getProjects();
    list.removeWhere((p) => p.id == id);
    final rawList = list.map((p) => p.toJson()).toList();
    await _box.write(_keyProjects, rawList);
  }

  Future<void> clearAllProjects() async {
    await _box.remove(_keyProjects);
  }
}
