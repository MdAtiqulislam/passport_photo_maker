import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/onnx_restoration_controller.dart';
import '../../../../core/constants/app_colors.dart';

class OnnxRestorationView extends GetView<OnnxRestorationController> {
  const OnnxRestorationView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(OnnxRestorationController());
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('ONNX On-Device Restoration POC'),
        backgroundColor: AppColors.primary,
      ),
      body: Obx(() {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Display Area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: controller.originalImagePath.value.isEmpty
                      ? const Center(child: Text("Select an Image"))
                      : controller.restoredImagePath.value.isNotEmpty
                          ? _buildComparisonView()
                          : Image.file(File(controller.originalImagePath.value), fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 16),

              // Status / Error Messages
              if (controller.isProcessing.value)
                const Center(child: CircularProgressIndicator()),
              if (controller.errorMsg.value.isNotEmpty)
                Text(
                  controller.errorMsg.value,
                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.pickImage,
                      child: const Text('Select Image'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                      onPressed: controller.originalImagePath.value.isNotEmpty && !controller.isProcessing.value
                          ? controller.restoreImage
                          : null,
                      child: const Text('Restore (ONNX)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildComparisonView() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              const Text("Before", style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: Image.file(File(controller.originalImagePath.value), fit: BoxFit.contain)),
            ],
          ),
        ),
        const VerticalDivider(width: 2, color: Colors.black12),
        Expanded(
          child: Column(
            children: [
              const Text("After (ONNX)", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
              Expanded(child: Image.file(File(controller.restoredImagePath.value), fit: BoxFit.contain)),
            ],
          ),
        ),
      ],
    );
  }
}
