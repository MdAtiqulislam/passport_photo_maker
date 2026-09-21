import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/print_sheet_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/print_sheet_config.dart';

class SheetPreviewWidget extends GetView<PrintSheetController> {
  const SheetPreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final config = controller.currentConfig;
      final paperW = config.effectivePaperWidth;
      final paperH = config.effectivePaperHeight;
      final paperAspectRatio = paperW / paperH;

      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: AspectRatio(
          aspectRatio: paperAspectRatio,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final previewW = constraints.maxWidth;
                final scaleFactor = previewW / paperW;

                final photoWPx = config.photoSize.widthMm * scaleFactor;
                final photoHPx = config.photoSize.heightMm * scaleFactor;
                final gapPx = config.gapMm * scaleFactor;

                final startXPx = config.startXOffsetMm * scaleFactor;
                final startYPx = config.startYOffsetMm * scaleFactor;

                final children = <Widget>[];
                int rendered = 0;
                final totalToRender = config.actualCopies;

                for (int r = 0; r < config.actualRows && rendered < totalToRender; r++) {
                  for (int c = 0; c < config.actualColumns && rendered < totalToRender; c++) {
                    final left = startXPx + c * (photoWPx + gapPx);
                    final top = startYPx + r * (photoHPx + gapPx);

                    children.add(
                      Positioned(
                        left: left,
                        top: top,
                        width: photoWPx,
                        height: photoHPx,
                        child: Container(
                          decoration: BoxDecoration(
                            border: config.cutLineType != CutLineType.none
                                ? Border.all(
                                    color: const Color(0xFFCBD5E1),
                                    width: 0.8,
                                  )
                                : null,
                          ),
                          child: ClipRect(
                            child: Image.file(
                              File(controller.processedImagePath),
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                    );

                    rendered++;
                  }
                }

                // Tiny header label in preview
                if (config.showLabels) {
                  children.add(
                    Positioned(
                      top: 4,
                      left: 6,
                      right: 6,
                      child: Text(
                        '${config.paperSize.name} (${config.paperSize.dimensionLabel}) • ${config.actualCopies} Photos • 100% Scale',
                        style: const TextStyle(fontSize: 8, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }

                return Stack(children: children);
              },
            ),
          ),
        ),
      );
    });
  }
}
