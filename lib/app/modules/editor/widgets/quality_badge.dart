import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/editor_controller.dart';
import '../../../../core/constants/app_colors.dart';

class QualityBadge extends GetView<EditorController> {
  const QualityBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isCheckingQuality.value) {
        return const SizedBox.shrink();
      }

      final report = controller.qualityReport.value;
      if (report == null) return const SizedBox.shrink();

      final hasWarnings = report.warnings.isNotEmpty;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: hasWarnings ? AppColors.warning.withOpacity(0.15) : AppColors.success.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasWarnings ? AppColors.warning : AppColors.success,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasWarnings ? Icons.info_outline : Icons.check_circle_outline,
              size: 14,
              color: hasWarnings ? AppColors.warning : AppColors.success,
            ),
            const SizedBox(width: 4),
            Text(
              hasWarnings ? 'Quality Notice' : 'HD Quality Verified',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: hasWarnings ? const Color(0xFFB45309) : const Color(0xFF047857),
              ),
            ),
          ],
        ),
      );
    });
  }
}
