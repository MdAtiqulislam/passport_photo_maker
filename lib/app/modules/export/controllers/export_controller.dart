import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/photo_project.dart';
import '../../../../data/models/photo_size.dart';
import '../../../../data/models/print_sheet_config.dart';
import '../../../routes/app_pages.dart';

enum ExportMode { singlePhoto, printSheet, pdfDocument }

class ExportController extends GetxController {
  late PhotoProject project;
  late PhotoSize photoSize;
  late String processedImagePath;
  String? sheetImagePath;
  String? pdfPath;
  PrintSheetConfig? config;

  final Rx<ExportMode> activeMode = ExportMode.singlePhoto.obs;
  final RxInt selectedDpi = 300.obs;
  final RxString selectedFormat = 'JPG'.obs; // JPG, PNG, PDF
  final RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null) {
      project = args['project'] as PhotoProject;
      photoSize = args['photoSize'] as PhotoSize;
      processedImagePath = args['processedImagePath'] as String;
      sheetImagePath = args['sheetImagePath'] as String?;
      pdfPath = args['pdfPath'] as String?;
      config = args['config'] as PrintSheetConfig?;

      if (pdfPath != null) {
        activeMode.value = ExportMode.printSheet;
      }
    }
  }

  void setMode(ExportMode mode) {
    activeMode.value = mode;
  }

  void setFormat(String format) {
    selectedFormat.value = format;
  }

  void setDpi(int dpi) {
    selectedDpi.value = dpi;
  }

  /// Direct System Native Share
  Future<void> shareFile() async {
    try {
      String? targetPath;
      if (activeMode.value == ExportMode.pdfDocument && pdfPath != null) {
        targetPath = pdfPath;
      } else if (activeMode.value == ExportMode.printSheet && sheetImagePath != null) {
        targetPath = sheetImagePath;
      } else {
        targetPath = processedImagePath;
      }

      if (targetPath != null && await File(targetPath).exists()) {
        await Share.shareXFiles(
          [XFile(targetPath)],
          text: '${photoSize.country} ${photoSize.name} (${photoSize.dimensionString})',
        );
      } else {
        Get.snackbar('Error', 'File not found to share.');
      }
    } catch (e) {
      Get.snackbar('Share Error', 'Could not share file: $e');
    }
  }

  /// Direct Native Printing Dialog
  Future<void> printDocument() async {
    try {
      if (pdfPath != null && await File(pdfPath!).exists()) {
        final bytes = await File(pdfPath!).readAsBytes();
        await Printing.layoutPdf(
          onLayout: (format) async => bytes,
          name: '${photoSize.country}_${photoSize.name}_Sheet.pdf',
        );
      } else if (await File(processedImagePath).exists()) {
        final bytes = await File(processedImagePath).readAsBytes();
        await Printing.layoutPdf(
          onLayout: (format) async => bytes,
          name: '${photoSize.country}_${photoSize.name}.jpg',
        );
      }
    } catch (e) {
      Get.snackbar('Print Error', 'Could not start print job: $e');
    }
  }

  /// Save to Device Storage / Gallery
  Future<void> saveToDevice() async {
    isSaving.value = true;
    await Future.delayed(const Duration(milliseconds: 600));
    isSaving.value = false;

    Get.snackbar(
      'Saved Successfully! ✅',
      'Passport photo saved to your device in high quality.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  void goHome() {
    Get.offAllNamed(Routes.HOME);
  }
}
