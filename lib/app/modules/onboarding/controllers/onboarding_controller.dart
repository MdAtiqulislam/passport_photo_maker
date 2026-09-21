import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/storage_service.dart';
import '../../../routes/app_pages.dart';

class OnboardingController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  final List<Map<String, String>> pages = [
    {
      'title': 'Create Official Passport Photos',
      'subtitle': 'Take or upload a photo and get precise standard passport and visa photos in seconds.',
      'icon': '📸',
    },
    {
      'title': 'Auto Guidelines & Background Tools',
      'subtitle': 'Ensure compliance with official biometric guidelines, eye/chin alignment, and custom backgrounds.',
      'icon': '🎨',
    },
    {
      'title': 'Print Multiple Copies on 1 Sheet',
      'subtitle': 'Fit 8, 12, or 20 copies on A4 or 4×6 inch paper with cutting lines and export 1:1 scale PDF.',
      'icon': '📄',
    },
  ];

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void nextPage() {
    if (currentPage.value < pages.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      completeOnboarding();
    }
  }

  Future<void> completeOnboarding() async {
    await _storage.setOnboardingCompleted();
    Get.offAllNamed(Routes.HOME);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
