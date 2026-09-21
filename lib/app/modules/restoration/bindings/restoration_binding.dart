import 'package:get/get.dart';
import '../controllers/restoration_controller.dart';

class RestorationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RestorationController>(
      () => RestorationController(),
    );
  }
}
