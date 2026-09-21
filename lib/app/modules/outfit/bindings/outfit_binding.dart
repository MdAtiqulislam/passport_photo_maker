import 'package:get/get.dart';
import '../controllers/outfit_gallery_controller.dart';

class OutfitBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OutfitGalleryController>(
      () => OutfitGalleryController(),
    );
  }
}
