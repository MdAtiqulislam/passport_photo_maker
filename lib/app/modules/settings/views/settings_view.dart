import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../restoration/views/onnx_restoration_view.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Storage'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // PRO Upgrade Banner
          Obx(
            () => controller.isPro.value
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.workspace_premium, color: Colors.white, size: 32),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PRO Member 🌟', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('All features unlocked forever', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  )
                : InkWell(
                    onTap: controller.openUpgradePro,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.stars, color: Colors.amberAccent, size: 32),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Unlock Lifetime PRO ⭐', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('PDF Sheets, 600 DPI, No Ads', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 24),

          // Section 1: Storage Management
          const Text('Storage & Cache', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storage_outlined, color: AppColors.primary),
                  title: const Text('App Storage Used'),
                  subtitle: Obx(() => Text('${controller.storageUsageMb.value.toStringAsFixed(2)} MB')),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined, color: AppColors.warning),
                  title: const Text('Clear Temporary Cache'),
                  subtitle: const Text('Delete intermediate processing and temp images'),
                  trailing: TextButton(
                    onPressed: controller.clearTempFiles,
                    child: const Text('Clear'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Delete All Saved Projects'),
                  subtitle: const Text('Remove all created passport photos'),
                  trailing: TextButton(
                    onPressed: () {
                      Get.dialog(
                        AlertDialog(
                          title: const Text('Delete All Projects?'),
                          content: const Text('This action cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                              onPressed: () {
                                controller.clearAllProjects();
                                Get.back();
                              },
                              child: const Text('Delete All'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Premium & AI Credits
          const Text('Premium & AI Credits', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Card(
            child: Obx(
              () => Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.toll_rounded, color: AppColors.accent),
                    title: const Text('AI Restoration Credits'),
                    subtitle: Text(controller.isPro.value ? 'Unlimited (PRO Member)' : '🪙 ${controller.aiCredits.value} Credits remaining'),
                    trailing: controller.isPro.value
                        ? null
                        : TextButton(
                            onPressed: controller.addDebugCredits,
                            child: const Text('Add 10 (Debug)'),
                          ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restart_alt_rounded, color: AppColors.error),
                    title: const Text('Reset Premium Status'),
                    subtitle: const Text('Reset Pro status and set credits to 2'),
                    trailing: TextButton(
                      onPressed: controller.resetAllPremium,
                      child: const Text('Reset', style: TextStyle(color: AppColors.error)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section: Developer Tools (POC)
          const Text('Developer & POC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.memory, color: Colors.purple),
                  title: const Text('Test ONNX On-Device AI'),
                  subtitle: const Text('Open the native Android ONNX inference POC'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Get.to(() => const OnnxRestorationView()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Appearance & Theme
          const Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Card(
            child: Obx(
              () => Column(
                children: [
                  RadioListTile<String>(
                    secondary: const Icon(Icons.brightness_auto, color: AppColors.primary),
                    title: const Text('System Default', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Follow system dark/light mode'),
                    value: 'system',
                    groupValue: controller.themeMode.value,
                    onChanged: (v) => controller.setTheme(v!),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    secondary: const Icon(Icons.light_mode, color: Colors.orange),
                    title: const Text('Light Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Bright & clean standard theme'),
                    value: 'light',
                    groupValue: controller.themeMode.value,
                    onChanged: (v) => controller.setTheme(v!),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    secondary: const Icon(Icons.dark_mode, color: Colors.indigoAccent),
                    title: const Text('Dark Theme', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('OLED friendly dark interface'),
                    value: 'dark',
                    groupValue: controller.themeMode.value,
                    onChanged: (v) => controller.setTheme(v!),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: Legal & Privacy
          const Text('Privacy & Compliance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.shield_outlined, color: AppColors.success),
                  title: Text('100% On-Device Processing'),
                  subtitle: Text('Your photos and biometric data never leave your phone. Zero cloud upload.'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.gavel_outlined, color: AppColors.primary),
                  title: const Text('Official Requirement Disclaimer'),
                  subtitle: Text(AppStrings.disclaimer),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App version info
          Center(
            child: Column(
              children: [
                Text(
                  AppStrings.appName,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Version 1.0.0 • Offline Ready',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
