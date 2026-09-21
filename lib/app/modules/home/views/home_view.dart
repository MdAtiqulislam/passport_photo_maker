import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/home_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../data/models/photo_project.dart';
import '../../../routes/app_pages.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgScaffold,
      appBar: AppBar(
        backgroundColor: context.bgSurface,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 30, borderRadius: 8),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                AppStrings.appName,
                maxLines: 1,
                style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: context.textSecondaryColor),
            tooltip: 'Saved Photos',
            onPressed: controller.openHistory,
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: context.textSecondaryColor),
            tooltip: 'Settings',
            onPressed: controller.openSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => controller.loadDashboardData(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // Welcome Header & Subtitle
            const SizedBox(height: 8),
            Text(
              'Passport Photo Maker',
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a professional passport photo in a few simple steps.',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Large Primary Button: [ 📷 Create Passport Photo ]
            InkWell(
              onTap: controller.onTakePhoto,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_rounded, size: 28, color: Colors.white),
                    SizedBox(width: 14),
                    Text(
                      'Create Passport Photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Large Secondary Button: [ 🖼 Choose Photo ]
            InkWell(
              onTap: controller.onChooseFromGallery,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: BoxDecoration(
                  color: context.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.borderColor, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.photo_library_rounded, size: 26, color: AppColors.accent),
                    const SizedBox(width: 14),
                    Text(
                      'Choose Photo',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // More Tools Section
            Text(
              'More Tools',
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: controller.openRestorationStudio,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      decoration: BoxDecoration(
                        color: context.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.auto_fix_high_rounded, color: Color(0xFF38BDF8), size: 26),
                          const SizedBox(height: 6),
                          Text(
                            'Restore Photo',
                            style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Fix old/faded',
                            style: TextStyle(color: context.textSecondaryColor, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: controller.openOutfitGallery,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      decoration: BoxDecoration(
                        color: context.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.checkroom_rounded, color: Color(0xFF34D399), size: 26),
                          const SizedBox(height: 6),
                          Text(
                            'Outfit Gallery',
                            style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Suits & shirts',
                            style: TextStyle(color: context.textSecondaryColor, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: controller.openAiEnhance,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      decoration: BoxDecoration(
                        color: context.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFFFBBF24), size: 26),
                          const SizedBox(height: 6),
                          Text(
                            'AI Enhance',
                            style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Studio light',
                            style: TextStyle(color: context.textSecondaryColor, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Recent Projects Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Projects',
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: controller.openHistory,
                  child: const Text('View All', style: TextStyle(color: AppColors.accent, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                );
              }

              if (controller.recentProjects.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: BoxDecoration(
                    color: context.bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.photo_library_outlined, size: 40, color: context.textSecondaryColor),
                      const SizedBox(height: 12),
                      Text(
                        'No photos created yet',
                        style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Take or choose a photo above to start the wizard.',
                        style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                      ),
                    ],
                  ),
                );
              }

              final displayList = controller.recentProjects.take(4).toList();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final proj = displayList[index];
                  return _buildRecentProjectCard(context, proj);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProjectCard(BuildContext context, PhotoProject project) {
    final dateFormat = DateFormat('MMM dd • hh:mm a');
    return Container(
      decoration: BoxDecoration(
        color: context.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 44,
            height: 56,
            child: File(project.processedImagePath).existsSync()
                ? Image.file(File(project.processedImagePath), fit: BoxFit.cover)
                : const Icon(Icons.photo, color: AppColors.primary),
          ),
        ),
        title: Text(
          project.title,
          style: TextStyle(color: context.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${project.photoSize.dimensionString} • ${dateFormat.format(project.createdAt)}',
          style: TextStyle(fontSize: 11, color: context.textSecondaryColor),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.textSecondaryColor),
        onTap: () {
          Get.toNamed(Routes.EXPORT, arguments: {
            'project': project,
            'photoSize': project.photoSize,
            'processedImagePath': project.processedImagePath,
            'sheetImagePath': project.sheetImagePath,
            'pdfPath': project.pdfPath,
          })?.then((_) => controller.loadDashboardData());
        },
      ),
    );
  }
}
