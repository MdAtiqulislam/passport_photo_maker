import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/premium_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/file_utils.dart';

class SettingsController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final PremiumService _premiumService = Get.find<PremiumService>();

  final RxDouble storageUsageMb = 0.0.obs;
  final RxString themeMode = 'system'.obs;
  final RxBool isPro = false.obs;

  final RxInt aiCredits = 0.obs;

  @override
  void onInit() {
    super.onInit();
    themeMode.value = _storage.themeMode;
    isPro.value = _premiumService.isPro.value;
    aiCredits.value = _premiumService.aiCredits.value;
    _premiumService.aiCredits.listen((val) => aiCredits.value = val);
    _premiumService.isPro.listen((val) => isPro.value = val);
    loadStorageUsage();
  }

  Future<void> loadStorageUsage() async {
    storageUsageMb.value = await FileUtils.getStorageUsageMb();
  }

  Future<void> addDebugCredits() async {
    await _storage.addCredits(10);
    _premiumService.refreshCredits();
    Get.snackbar(
      'Debug Credits Added 🪙',
      'Added 10 AI credits for testing.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> resetAllPremium() async {
    await _premiumService.resetPro();
    // Reset credits to 2
    final box = GetStorage();
    await box.write('ai_credits', 2);
    _premiumService.refreshCredits();
    Get.snackbar(
      'Premium Reset',
      'Reset Pro to locked and credits to 2.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.warning,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> clearTempFiles() async {
    final deleted = await FileUtils.clearTemporaryFiles();
    await loadStorageUsage();
    Get.snackbar(
      'Cleanup Complete',
      'Cleaned up $deleted temporary cache files.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> clearAllProjects() async {
    await _storage.clearAllProjects();
    await loadStorageUsage();
    Get.snackbar(
      'History Cleared',
      'All saved project history has been removed.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> setTheme(String mode) async {
    themeMode.value = mode;
    await _storage.setThemeMode(mode);
    if (mode == 'dark') {
      Get.changeThemeMode(ThemeMode.dark);
    } else if (mode == 'light') {
      Get.changeThemeMode(ThemeMode.light);
    } else {
      Get.changeThemeMode(ThemeMode.system);
    }
  }

  void openUpgradePro() {
    _premiumService.showUpgradeDialog();
  }
}
