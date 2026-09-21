import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/camera_controller.dart';
import '../widgets/camera_guide_overlay.dart';
import '../../../../core/constants/app_colors.dart';

class CameraView extends GetView<CustomCameraController> {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(
          () {
            if (!controller.isInitialized.value || controller.cameraController == null) {
              // Camera fallback for simulator/web or when permissions not granted
              return _buildCameraFallback(context);
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                // Live Viewfinder
                Center(
                  child: CameraPreview(controller.cameraController!),
                ),

                // Biometric Guidelines Overlay
                CameraGuideOverlay(
                  aspectRatio: controller.photoSize.aspectRatio,
                  showGuidelines: controller.showGuidelines.value,
                ),

                // Top Toolbar
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCircleButton(
                        icon: Icons.close,
                        onTap: () => Get.back(),
                      ),
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${controller.photoSize.name} (${controller.photoSize.dimensionString})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCircleButton(
                            icon: controller.showGuidelines.value ? Icons.grid_on : Icons.grid_off,
                            onTap: controller.toggleGuidelines,
                          ),
                          const SizedBox(width: 8),
                          _buildCircleButton(
                            icon: controller.isFlashOn.value ? Icons.flash_on : Icons.flash_off,
                            onTap: controller.toggleFlash,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Bottom Camera Controls
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery Button
                        _buildCircleButton(
                          icon: Icons.photo_library,
                          size: 48,
                          onTap: controller.pickFromGallery,
                        ),

                        // Shutter Button
                        GestureDetector(
                          onTap: controller.capturePhoto,
                          child: Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: controller.isTakingPhoto.value
                                  ? const CircularProgressIndicator(color: AppColors.primary)
                                  : null,
                            ),
                          ),
                        ),

                        // Switch Camera
                        _buildCircleButton(
                          icon: Icons.flip_camera_ios,
                          size: 48,
                          onTap: controller.switchCamera,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 42,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }

  Widget _buildCameraFallback(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.camera_alt_outlined, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Camera Not Available',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'No physical camera was detected or camera permissions were not granted. You can select a portrait photo from your gallery.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose from Gallery'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Back to Home', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}
