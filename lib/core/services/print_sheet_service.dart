import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/models/print_sheet_config.dart';
import '../utils/dpi_converter.dart';
import '../utils/file_utils.dart';

class PrintSheetResult {
  final String pdfPath;
  final String imagePath;
  final int totalCopiesRendered;

  const PrintSheetResult({
    required this.pdfPath,
    required this.imagePath,
    required this.totalCopiesRendered,
  });
}

class PrintSheetService {
  /// Generate 1:1 Physical Scale PDF and High-Res Sheet Image
  static Future<PrintSheetResult> generateSheet({
    required String photoPath,
    required PrintSheetConfig config,
    int dpi = 300,
  }) async {
    final photoBytes = await File(photoPath).readAsBytes();
    final photoImage = img.decodeImage(photoBytes);
    if (photoImage == null) {
      throw Exception('Failed to decode portrait photo for sheet generation');
    }

    // 1. Generate High-Res Sheet Image at 300 DPI
    final sheetImagePath = await _generateSheetImage(
      photoImage: photoImage,
      config: config,
      dpi: dpi,
    );

    // 2. Generate Exact 1:1 Physical Scale PDF Document
    final pdfPath = await _generateSheetPdf(
      photoBytes: photoBytes,
      config: config,
    );

    return PrintSheetResult(
      pdfPath: pdfPath,
      imagePath: sheetImagePath,
      totalCopiesRendered: config.actualCopies,
    );
  }

  /// Generate High-Res Raster Sheet Image (PNG/JPG)
  static Future<String> _generateSheetImage({
    required img.Image photoImage,
    required PrintSheetConfig config,
    int dpi = 300,
  }) async {
    final sheetWPx = DpiConverter.mmToPx(config.effectivePaperWidth, dpi);
    final sheetHPx = DpiConverter.mmToPx(config.effectivePaperHeight, dpi);

    // Create blank white canvas
    final sheetCanvas = img.Image(
      width: sheetWPx,
      height: sheetHPx,
      numChannels: 4,
    );
    img.fill(sheetCanvas, color: img.ColorRgb8(255, 255, 255));

    final photoWPx = DpiConverter.mmToPx(config.photoSize.widthMm, dpi);
    final photoHPx = DpiConverter.mmToPx(config.photoSize.heightMm, dpi);
    final gapPx = DpiConverter.mmToPx(config.gapMm, dpi);

    final startXPx = DpiConverter.mmToPx(config.startXOffsetMm, dpi);
    final startYPx = DpiConverter.mmToPx(config.startYOffsetMm, dpi);

    // Resize photo to target cell size
    final resizedPhoto = img.copyResize(
      photoImage,
      width: photoWPx,
      height: photoHPx,
      interpolation: img.Interpolation.cubic,
    );

    int count = 0;
    final maxCount = config.actualCopies;

    for (int r = 0; r < config.actualRows && count < maxCount; r++) {
      for (int c = 0; c < config.actualColumns && count < maxCount; c++) {
        final x = startXPx + c * (photoWPx + gapPx);
        final y = startYPx + r * (photoHPx + gapPx);

        // Draw photo onto canvas
        img.compositeImage(
          sheetCanvas,
          resizedPhoto,
          dstX: x,
          dstY: y,
        );

        // Draw cut lines / borders if requested
        if (config.cutLineType != CutLineType.none) {
          final lineColor = img.ColorRgb8(200, 200, 200);
          // Draw rectangle border around photo
          img.drawRect(
            sheetCanvas,
            x1: x,
            y1: y,
            x2: x + photoWPx,
            y2: y + photoHPx,
            color: lineColor,
          );
        }

        count++;
      }
    }

    final outPath = await FileUtils.createProjectFilePath(prefix: 'sheet', extension: 'jpg');
    final jpgBytes = img.encodeJpg(sheetCanvas, quality: 95);
    await File(outPath).writeAsBytes(jpgBytes);

    return outPath;
  }

  /// Generate Exact 1:1 Scale PDF Document
  static Future<String> _generateSheetPdf({
    required Uint8List photoBytes,
    required PrintSheetConfig config,
  }) async {
    final pdf = pw.Document();

    // 1 mm in PDF points = 72 / 25.4 = ~2.83464567 pt
    const double mmToPt = 72.0 / 25.4;

    final pageWidthPt = config.effectivePaperWidth * mmToPt;
    final pageHeightPt = config.effectivePaperHeight * mmToPt;
    final pageFormat = PdfPageFormat(pageWidthPt, pageHeightPt, marginAll: 0);

    final pdfImage = pw.MemoryImage(photoBytes);
    final photoWidthPt = config.photoSize.widthMm * mmToPt;
    final photoHeightPt = config.photoSize.heightMm * mmToPt;
    final startXPt = config.startXOffsetMm * mmToPt;
    final startYPt = config.startYOffsetMm * mmToPt;
    final gapPt = config.gapMm * mmToPt;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          final stackChildren = <pw.Widget>[];

          int count = 0;
          final maxCount = config.actualCopies;

          for (int r = 0; r < config.actualRows && count < maxCount; r++) {
            for (int c = 0; c < config.actualColumns && count < maxCount; c++) {
              final xPos = startXPt + c * (photoWidthPt + gapPt);
              // In PDF coordinates, (0,0) is bottom-left, so we invert Y
              final yPos = pageHeightPt - (startYPt + (r + 1) * photoHeightPt + r * gapPt);

              stackChildren.add(
                pw.Positioned(
                  left: xPos,
                  bottom: yPos,
                  child: pw.SizedBox(
                    width: photoWidthPt,
                    height: photoHeightPt,
                    child: pw.Container(
                      decoration: config.cutLineType != CutLineType.none
                          ? pw.BoxDecoration(
                              border: pw.Border.all(
                                color: PdfColors.grey400,
                                width: 0.5,
                                style: config.cutLineType == CutLineType.dashed
                                    ? pw.BorderStyle.dashed
                                    : pw.BorderStyle.solid,
                              ),
                            )
                          : null,
                      child: pw.Image(pdfImage, fit: pw.BoxFit.fill),
                    ),
                  ),
                ),
              );

              count++;
            }
          }

          // Optional tiny header/footer label
          if (config.showLabels) {
            stackChildren.add(
              pw.Positioned(
                left: startXPt,
                bottom: pageHeightPt - (startYPt - 4 * mmToPt),
                child: pw.Text(
                  '${config.photoSize.name} (${config.photoSize.dimensionString}) - Print at 100% Scale / Actual Size',
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            );
          }

          return pw.Stack(children: stackChildren);
        },
      ),
    );

    final outPdfPath = await FileUtils.createProjectFilePath(prefix: 'sheet_print', extension: 'pdf');
    final pdfBytes = await pdf.save();
    await File(outPdfPath).writeAsBytes(pdfBytes);

    return outPdfPath;
  }
}
