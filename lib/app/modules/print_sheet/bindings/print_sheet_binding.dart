import 'package:get/get.dart';
import '../controllers/print_sheet_controller.dart';

class PrintSheetBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PrintSheetController>(() => PrintSheetController());
  }
}
