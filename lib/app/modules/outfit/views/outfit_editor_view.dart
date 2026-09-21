import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/outfit_painter.dart';
import '../../../../data/models/outfit_template.dart';
import '../../../routes/app_pages.dart';

class OutfitEditorView extends StatefulWidget {
  const OutfitEditorView({super.key});

  @override
  State<OutfitEditorView> createState() => _OutfitEditorViewState();
}

class _OutfitEditorViewState extends State<OutfitEditorView> {
  final ImagePicker _picker = ImagePicker();

  String? _imagePath;
  late OutfitTemplate _outfit;
  OutfitTransformConfig _transform = const OutfitTransformConfig();
  final bool _showControls = true;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args != null && args is Map) {
      _imagePath = args['imagePath'] as String?;
      if (args['outfit'] != null) {
        _outfit = args['outfit'] as OutfitTemplate;
      } else {
        _outfit = const OutfitTemplate(
          id: 'men_black_suit_red_tie',
          name: 'Black Suit & Red Tie',
          category: OutfitCategory.suits,
          styleDescription: 'Standard',
        );
      }
    }
  }

  Future<void> _pickPortraitPhoto() async {
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
      if (picked != null) {
        setState(() {
          _imagePath = picked.path;
        });
      }
    } catch (_) {}
  }

  void _applyToPassportWizard() {
    if (_imagePath == null || _imagePath!.isEmpty) {
      Get.snackbar('Notice', 'Please select a photo to fit your outfit onto.', colorText: Colors.white);
      return;
    }

    Get.toNamed(Routes.WIZARD, arguments: {
      'imagePath': _imagePath,
      'outfit': _outfit,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgScaffold,
      appBar: AppBar(
        backgroundColor: context.bgSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimaryColor, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          _outfit.name,
          style: TextStyle(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Reset adjustments',
            icon: Icon(Icons.refresh_rounded, color: context.textSecondaryColor),
            onPressed: () => setState(() => _transform = const OutfitTransformConfig()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Live Portrait & Outfit Canvas
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: context.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.borderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Layer 1: Base Portrait Image (or Select Photo placeholder)
                    if (_imagePath != null && File(_imagePath!).existsSync())
                      Image.file(File(_imagePath!), fit: BoxFit.contain)
                    else
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_add_alt_1_rounded, size: 64, color: context.textSecondaryColor),
                            const SizedBox(height: 12),
                            Text(
                              'Choose a Portrait Photo',
                              style: TextStyle(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Select a photo to fit this outfit onto.',
                              style: TextStyle(color: context.textSecondaryColor, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _pickPortraitPhoto,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Choose Photo'),
                            ),
                          ],
                        ),
                      ),

                    // Layer 2: Outfit Overlay (Interactive Draggable)
                    if (_imagePath != null)
                      Positioned.fill(
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              _transform = _transform.copyWith(
                                panX: (_transform.panX + details.delta.dx).clamp(-120.0, 120.0),
                                panY: (_transform.panY + details.delta.dy).clamp(-120.0, 120.0),
                              );
                            });
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (_outfit.isCustomImage && _outfit.customImagePath != null)
                                Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..translate(_transform.panX, _transform.panY + 40)
                                    ..rotateZ(_transform.rotationDegrees * 3.1415926535 / 180)
                                    ..scale(_transform.scale * (_transform.flipHorizontal ? -1.0 : 1.0), _transform.scale),
                                  child: Image.file(
                                    File(_outfit.customImagePath!),
                                    fit: BoxFit.contain,
                                  ),
                                )
                              else
                                CustomPaint(
                                  painter: OutfitPainter(
                                    outfit: _outfit,
                                    config: _transform,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Adjustment Sliders Drawer
          if (_showControls && _imagePath != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: context.bgCard,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(top: BorderSide(color: context.borderColor)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.straighten, size: 16, color: context.textSecondaryColor),
                      const SizedBox(width: 8),
                      Text('Size', style: TextStyle(color: context.textSecondaryColor, fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: _transform.scale,
                          min: 0.65,
                          max: 1.45,
                          activeColor: AppColors.accent,
                          onChanged: (val) => setState(() => _transform = _transform.copyWith(scale: val)),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Flip',
                        icon: Icon(Icons.flip, size: 18, color: context.textSecondaryColor),
                        onPressed: () => setState(() => _transform = _transform.copyWith(flipHorizontal: !_transform.flipHorizontal)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.rotate_right, size: 16, color: context.textSecondaryColor),
                      const SizedBox(width: 8),
                      Text('Rotate', style: TextStyle(color: context.textSecondaryColor, fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: _transform.rotationDegrees,
                          min: -15.0,
                          max: 15.0,
                          activeColor: AppColors.accent,
                          onChanged: (val) => setState(() => _transform = _transform.copyWith(rotationDegrees: val)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Apply to Passport Wizard Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _applyToPassportWizard,
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text('Apply to Passport Photo ➔', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
