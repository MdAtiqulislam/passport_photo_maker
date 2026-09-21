import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/models/restoration_models.dart';
import '../../../../core/services/photo_restoration_service.dart';

class OnnxRestorationController extends GetxController {
  final isProcessing = false.obs;
  final RxString originalImagePath = ''.obs;
  final RxString restoredImagePath = ''.obs;
  final RxString errorMsg = ''.obs;

  final ImagePicker _picker = ImagePicker();
  static const MethodChannel _channel = MethodChannel('com.passportphotomaker.restoration/onnx');

  void selectImage(String path) {
    originalImagePath.value = path;
    restoredImagePath.value = '';
    errorMsg.value = '';
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectImage(image.path);
    }
  }

  Future<void> restoreImage() async {
    if (originalImagePath.value.isEmpty) return;

    try {
      isProcessing.value = true;
      errorMsg.value = '';

      final stopwatch = Stopwatch()..start();

      // 1. First Pass: Use local OpenCV engine to remove scratches/spots and recover faded colors
      final cleanedResult = await PhotoRestorationService.restorePhoto(
        imageFile: File(originalImagePath.value),
        options: const RestorationOptions(
          strength: RestorationStrength.medium,
          repairScratches: true,      // Fix the white spots/dust
          recoverFadedColors: true,   // Fix the color fading
          reduceNoise: false,         // Let ONNX handle noise
          deblurAndSharpen: false,    // Let ONNX handle sharpness
          colorize: false,
          upscaleFactor: 1,           // Let ONNX upscale
        ),
      );

      // 2. Second Pass: Invoke native Android ONNX inference (Real-ESRGAN) to upscale and deblur
      final resultPath = await _channel.invokeMethod<String>('runRestorationModel', {
        'imagePath': cleanedResult.restoredImagePath,
        'modelName': 'mobile_restoration_model.onnx' // Placed in android/app/src/main/assets/
      });

      stopwatch.stop();

      if (resultPath != null && resultPath.isNotEmpty) {
        restoredImagePath.value = resultPath;
        print("RESTORE_DEBUG: Inference successful in ${stopwatch.elapsedMilliseconds} ms");
      } else {
        errorMsg.value = "Failed to restore image (Native layer returned null)";
      }
    } on PlatformException catch (e) {
      errorMsg.value = "Native Error: ${e.message}";
      print("RESTORE_DEBUG: Exception: ${e.message}");
    } catch (e) {
      errorMsg.value = "Unexpected Error: $e";
      print("RESTORE_DEBUG: Exception: $e");
    } finally {
      isProcessing.value = false;
    }
  }
}
