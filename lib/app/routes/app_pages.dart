import 'package:get/get.dart';

import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/camera/bindings/camera_binding.dart';
import '../modules/camera/views/camera_view.dart';
import '../modules/templates/bindings/templates_binding.dart';
import '../modules/templates/views/templates_view.dart';
import '../modules/editor/bindings/editor_binding.dart';
import '../modules/editor/views/editor_view.dart';
import '../modules/print_sheet/bindings/print_sheet_binding.dart';
import '../modules/print_sheet/views/print_sheet_view.dart';
import '../modules/export/bindings/export_binding.dart';
import '../modules/export/views/export_view.dart';
import '../modules/history/bindings/history_binding.dart';
import '../modules/history/views/history_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/wizard/bindings/wizard_binding.dart';
import '../modules/wizard/views/wizard_view.dart';
import '../modules/restoration/bindings/restoration_binding.dart';
import '../modules/restoration/views/restoration_view.dart';
import '../modules/outfit/bindings/outfit_binding.dart';
import '../modules/outfit/views/outfit_editor_view.dart';
import '../modules/outfit/views/outfit_gallery_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.ONBOARDING,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: _Paths.CAMERA,
      page: () => const CameraView(),
      binding: CameraBinding(),
    ),
    GetPage(
      name: _Paths.TEMPLATES,
      page: () => const TemplatesView(),
      binding: TemplatesBinding(),
    ),
    GetPage(
      name: _Paths.EDITOR,
      page: () => const EditorView(),
      binding: EditorBinding(),
    ),
    GetPage(
      name: _Paths.PRINT_SHEET,
      page: () => const PrintSheetView(),
      binding: PrintSheetBinding(),
    ),
    GetPage(
      name: _Paths.EXPORT,
      page: () => const ExportView(),
      binding: ExportBinding(),
    ),
    GetPage(
      name: _Paths.HISTORY,
      page: () => const HistoryView(),
      binding: HistoryBinding(),
    ),
    GetPage(
      name: _Paths.SETTINGS,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: _Paths.WIZARD,
      page: () => const WizardView(),
      binding: WizardBinding(),
    ),
    GetPage(
      name: _Paths.RESTORATION,
      page: () => const RestorationView(),
      binding: RestorationBinding(),
    ),
    GetPage(
      name: _Paths.OUTFIT_GALLERY,
      page: () => const OutfitGalleryView(),
      binding: OutfitBinding(),
    ),
    GetPage(
      name: _Paths.OUTFIT_EDITOR,
      page: () => const OutfitEditorView(),
    ),
  ];
}
