import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'storage_service.dart';
import 'ad_service.dart';
import '../constants/app_colors.dart';

class PremiumService extends GetxService {
  final StorageService _storage = Get.find<StorageService>();
  final RxBool isPro = false.obs;
  final RxInt aiCredits = 0.obs;

  @override
  void onInit() {
    super.onInit();
    isPro.value = _storage.isProUser;
    refreshCredits();
  }

  bool get canUseAiRestore => isPro.value || aiCredits.value > 0;

  void refreshCredits() {
    aiCredits.value = _storage.aiCredits;
  }

  Future<void> consumeAiCredit() async {
    if (isPro.value) return;
    await _storage.deductCredit();
    refreshCredits();
  }

  Future<void> unlockPro() async {
    await _storage.setProUser(true);
    isPro.value = true;
  }

  Future<void> resetPro() async {
    await _storage.setProUser(false);
    isPro.value = false;
  }

  void showEarnCreditsDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.monetization_on, color: AppColors.gold, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                '🪙 Earn AI Credits',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Watch a short ad to earn 1 AI credit for professional photo restoration.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                  label: const Text(
                    '🎬 Watch Ad to Earn Credit',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  onPressed: () async {
                    Get.back(); // close dialog
                    final adService = Get.find<AdService>();
                    final shown = await adService.showRewardedAdForCredits();
                    if (!shown) {
                      Get.snackbar(
                        'Ad not ready',
                        'Please try again in a moment.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.redAccent,
                        colorText: Colors.white,
                      );
                    } else {
                      // refresh credits after a delay to account for ad duration/reward sync
                      Future.delayed(const Duration(seconds: 2), () {
                        refreshCredits();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primary),
                  ),
                  onPressed: () {
                    Get.back();
                    showUpgradeDialog();
                  },
                  child: const Text(
                    'Upgrade to Pro — Unlimited AI',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Maybe Later', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showUpgradeDialog({String? triggerFeature}) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium, color: AppColors.gold, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Unlock Lifetime PRO',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                triggerFeature != null
                    ? 'Upgrade to Pro to access $triggerFeature and unlimited professional features.'
                    : 'Get unlimited access to all country presets, print-ready PDF sheets, HD 600 DPI, and zero ads.',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildFeatureItem('All International Passport & Visa Presets'),
              _buildFeatureItem('Multi-Copy Ready-to-Print PDF Sheets'),
              _buildFeatureItem('High-Resolution (300 & 600 DPI) Output'),
              _buildFeatureItem('Smart Auto-Enhance & Background Tools'),
              _buildFeatureItem('Unlimited AI Photo Restoration'),
              _buildFeatureItem('100% Ad-Free Experience Forever'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await unlockPro();
                    Get.back();
                    Get.snackbar(
                      'PRO Unlocked! 🌟',
                      'Thank you for upgrading to Lifetime Pro.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.success,
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(16),
                    );
                  },
                  child: const Text(
                    'Unlock Lifetime Pro — \$14.99',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Maybe Later', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
