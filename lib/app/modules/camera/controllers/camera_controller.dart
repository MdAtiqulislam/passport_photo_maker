import 'dart:io';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../data/models/photo_size.dart';
import '../../../routes/app_pages.dart';

class CustomCameraController extends GetxController {
  CameraController? cameraController;
  final RxList<CameraDescription> availableCamerasList = <CameraDescription>[].obs;
  final RxInt selectedCameraIndex = 0.obs;
  final RxBool isInitialized = false.obs;
  final RxBool isTakingPhoto = false.obs;
  final RxBool isFlashOn = false.obs;
  final RxBool showGuidelines = true.obs;

  late PhotoSize photoSize;
  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args['photoSize'] is PhotoSize) {
      photoSize = args['photoSize'] as PhotoSize;
    } else {
      photoSize = const PhotoSize(
        id: 'bd_passport',
        country: 'Bangladesh',
        countryCode: 'BD',
        flag: '🇧🇩',
        name: 'Passport Photo',
        category: 'Passport',
        widthMm: 35.0,
        heightMm: 45.0,
      );
    }
    _initCameras();
  }

  Future<void> _initCameras() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        availableCamerasList.value = cameras;
        // Default to front camera for selfie passport or back camera
        final frontIndex = cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
        selectedCameraIndex.value = frontIndex >= 0 ? frontIndex : 0;
        await _initializeCameraController(cameras[selectedCameraIndex.value]);
      }
    } catch (_) {
      // Camera not available (e.g. desktop or simulator)
    }
  }

  Future<void> _initializeCameraController(CameraDescription description) async {
    final prevController = cameraController;
    final newController = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
    );

    cameraController = newController;
    if (prevController != null) {
      await prevController.dispose();
    }

    try {
      await newController.initialize();
      isInitialized.value = true;
    } catch (_) {
      isInitialized.value = false;
    }
  }

  Future<void> switchCamera() async {
    if (availableCamerasList.length < 2) return;
    isInitialized.value = false;
    selectedCameraIndex.value = (selectedCameraIndex.value + 1) % availableCamerasList.length;
    await _initializeCameraController(availableCamerasList[selectedCameraIndex.value]);
  }

  Future<void> toggleFlash() async {
    if (cameraController == null || !cameraController!.value.isInitialized) return;
    try {
      if (isFlashOn.value) {
        await cameraController!.setFlashMode(FlashMode.off);
        isFlashOn.value = false;
      } else {
        await cameraController!.setFlashMode(FlashMode.torch);
        isFlashOn.value = true;
      }
    } catch (_) {}
  }

  void toggleGuidelines() {
    showGuidelines.value = !showGuidelines.value;
  }

  Future<void> capturePhoto() async {
    if (cameraController == null || !cameraController!.value.isInitialized || isTakingPhoto.value) {
      return;
    }

    try {
      isTakingPhoto.value = true;
      final xFile = await cameraController!.takePicture();
      final tempPath = await FileUtils.createTempFilePath(extension: 'jpg');
      await File(xFile.path).copy(tempPath);

      Get.offNamed(Routes.EDITOR, arguments: {
        'imagePath': tempPath,
        'photoSize': photoSize,
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to capture photo: $e');
    } finally {
      isTakingPhoto.value = false;
    }
  }

  Future<void> pickFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (pickedFile != null) {
      Get.offNamed(Routes.EDITOR, arguments: {
        'imagePath': pickedFile.path,
        'photoSize': photoSize,
      });
    }
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }
}
