import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/photo_size.dart';
import '../../../../data/repositories/template_repository.dart';
import '../../../../core/utils/dpi_converter.dart';
import '../../../routes/app_pages.dart';

class TemplatesController extends GetxController {
  final TemplateRepository _templateRepo = TemplateRepository();

  final RxList<PhotoSize> allTemplates = <PhotoSize>[].obs;
  final RxList<PhotoSize> filteredTemplates = <PhotoSize>[].obs;
  final RxString selectedCategory = 'All'.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = true.obs;

  final searchController = TextEditingController();

  final List<String> categories = [
    'All',
    'Passport',
    'Visa',
    'ID Card',
    'Stamp',
    'Job',
  ];

  @override
  void onInit() {
    super.onInit();
    loadTemplates();
  }

  Future<void> loadTemplates() async {
    isLoading.value = true;
    allTemplates.value = await _templateRepo.getAllTemplates();
    _applyFilter();
    isLoading.value = false;
  }

  void setCategory(String category) {
    selectedCategory.value = category;
    _applyFilter();
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    _applyFilter();
  }

  void _applyFilter() {
    var list = allTemplates.toList();
    if (selectedCategory.value != 'All') {
      list = list.where((t) => t.category.toLowerCase() == selectedCategory.value.toLowerCase()).toList();
    }
    if (searchQuery.value.trim().isNotEmpty) {
      final q = searchQuery.value.toLowerCase().trim();
      list = list.where((t) {
        return t.country.toLowerCase().contains(q) ||
            t.name.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q);
      }).toList();
    }
    filteredTemplates.value = list;
  }

  void selectTemplate(PhotoSize template) {
    final imagePath = Get.arguments?['imagePath'] as String?;
    if (imagePath != null) {
      // Direct navigation to editor with chosen template
      Get.toNamed(Routes.EDITOR, arguments: {
        'imagePath': imagePath,
        'photoSize': template,
      });
    } else {
      // Pick or take photo for this template
      Get.back(result: template);
    }
  }

  void createCustomSize({
    required double width,
    required double height,
    required DimensionUnit unit,
    int dpi = 300,
    String name = 'Custom Document',
  }) {
    final widthMm = DpiConverter.toMm(width, unit, dpi: dpi);
    final heightMm = DpiConverter.toMm(height, unit, dpi: dpi);

    final customTemplate = PhotoSize.custom(
      widthMm: widthMm,
      heightMm: heightMm,
      dpi: dpi,
      name: name,
    );

    selectTemplate(customTemplate);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
