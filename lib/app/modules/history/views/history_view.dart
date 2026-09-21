import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/history_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/photo_project.dart';

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Projects & History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear All',
            onPressed: () {
              if (controller.projects.isEmpty) return;
              Get.dialog(
                AlertDialog(
                  title: const Text('Clear All Projects?'),
                  content: const Text('This will delete all saved passport photo history from local storage.'),
                  actions: [
                    TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () {
                        controller.clearAll();
                        Get.back();
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.projects.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_outlined, size: 48, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text('No Saved Photos Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first passport photo or print sheet and it will be saved here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.projects.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final project = controller.projects[index];
            return _buildProjectCard(project);
          },
        );
      }),
    );
  }

  Widget _buildProjectCard(PhotoProject project) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final dateStr = dateFormat.format(project.createdAt);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: () => controller.openProject(project),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Photo Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 72,
                  child: File(project.processedImagePath).existsSync()
                      ? Image.file(
                          File(project.processedImagePath),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: AppColors.primaryLight,
                          child: const Icon(Icons.photo, color: AppColors.primary),
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      project.photoSize.dimensionString,
                      style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),

              // Actions menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                onSelected: (value) {
                  if (value == 'export') {
                    controller.openProject(project);
                  } else if (value == 'reedit') {
                    controller.reEditProject(project);
                  } else if (value == 'delete') {
                    controller.deleteProject(project.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Export / Share'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reedit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Re-Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
