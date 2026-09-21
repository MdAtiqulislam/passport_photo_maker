import 'dart:math';
import 'paper_size.dart';
import 'photo_size.dart';

enum CutLineType { none, thin, dashed }

enum PrintSheetAlignment {
  top('Top of Page', '⬆️'),
  center('Center of Page', '⏺️');

  final String label;
  final String emoji;
  const PrintSheetAlignment(this.label, this.emoji);
}

class PrintSheetConfig {
  final PaperSize paperSize;
  final PhotoSize photoSize;
  final int copies;
  final double marginMm;
  final double gapMm;
  final CutLineType cutLineType;
  final PrintSheetAlignment alignment;
  final bool isLandscape;
  final bool showLabels;

  const PrintSheetConfig({
    required this.paperSize,
    required this.photoSize,
    this.copies = 8,
    this.marginMm = 5.0,
    this.gapMm = 2.0,
    this.cutLineType = CutLineType.dashed,
    this.alignment = PrintSheetAlignment.top,
    this.isLandscape = false,
    this.showLabels = true,
  });

  /// Usable page width in mm considering orientation
  double get effectivePaperWidth =>
      isLandscape ? max(paperSize.widthMm, paperSize.heightMm) : min(paperSize.widthMm, paperSize.heightMm);

  /// Usable page height in mm considering orientation
  double get effectivePaperHeight =>
      isLandscape ? min(paperSize.widthMm, paperSize.heightMm) : max(paperSize.widthMm, paperSize.heightMm);

  /// Maximum columns possible on this paper
  int get maxColumns {
    final availableW = effectivePaperWidth - (2 * marginMm);
    if (availableW <= 0) return 1;
    final singleW = photoSize.widthMm + gapMm;
    return max(1, ((availableW + gapMm) / singleW).floor());
  }

  /// Maximum rows possible on this paper
  int get maxRows {
    final availableH = effectivePaperHeight - (2 * marginMm);
    if (availableH <= 0) return 1;
    final singleH = photoSize.heightMm + gapMm;
    return max(1, ((availableH + gapMm) / singleH).floor());
  }

  /// Total maximum copies that can fit on one sheet
  int get maxFitCopies => maxColumns * maxRows;

  /// Effective number of copies to render (clamped between 1 and maxFitCopies)
  int get actualCopies => min(copies, maxFitCopies);

  /// Actual columns required for the requested copies
  int get actualColumns {
    if (actualCopies <= 0) return 1;
    if (actualCopies <= maxColumns) return actualCopies;
    return maxColumns;
  }

  /// Actual rows required for the requested copies
  int get actualRows {
    if (actualCopies <= 0) return 1;
    return (actualCopies / actualColumns).ceil();
  }

  /// Calculate the layout X offset on the page in mm (centered horizontally)
  double get startXOffsetMm {
    final totalContentWidth = (actualColumns * photoSize.widthMm) + ((actualColumns - 1) * gapMm);
    return max(marginMm, (effectivePaperWidth - totalContentWidth) / 2);
  }

  /// Calculate the layout Y offset on the page in mm (defaults to starting from Top)
  double get startYOffsetMm {
    if (alignment == PrintSheetAlignment.top) {
      return marginMm;
    }
    final totalContentHeight = (actualRows * photoSize.heightMm) + ((actualRows - 1) * gapMm);
    return max(marginMm, (effectivePaperHeight - totalContentHeight) / 2);
  }

  PrintSheetConfig copyWith({
    PaperSize? paperSize,
    PhotoSize? photoSize,
    int? copies,
    double? marginMm,
    double? gapMm,
    CutLineType? cutLineType,
    PrintSheetAlignment? alignment,
    bool? isLandscape,
    bool? showLabels,
  }) {
    return PrintSheetConfig(
      paperSize: paperSize ?? this.paperSize,
      photoSize: photoSize ?? this.photoSize,
      copies: copies ?? this.copies,
      marginMm: marginMm ?? this.marginMm,
      gapMm: gapMm ?? this.gapMm,
      cutLineType: cutLineType ?? this.cutLineType,
      alignment: alignment ?? this.alignment,
      isLandscape: isLandscape ?? this.isLandscape,
      showLabels: showLabels ?? this.showLabels,
    );
  }
}
