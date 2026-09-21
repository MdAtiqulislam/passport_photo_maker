enum RestorationStrength {
  low('Low', 'Subtle cleanup & mild contrast', 0.6),
  medium('Medium', 'Balanced scratch, noise & detail repair', 1.0),
  high('High', 'Maximum restoration for heavily damaged photos', 1.4);

  final String title;
  final String description;
  final double factor;

  const RestorationStrength(this.title, this.description, this.factor);
}

class PhotoAnalysisReport {
  final int width;
  final int height;
  final bool isGrayscale;
  final double noiseLevel; // 0.0 to 1.0 (higher = noisier)
  final double blurLevel; // 0.0 to 1.0 (higher = blurrier)
  final double fadingScore; // 0.0 to 1.0 (higher = more washed out/faded)
  final double contrastScore; // 0.0 to 1.0 (lower = lower contrast)
  final int estimatedDamagePoints; // count of scratch/speckle candidate clusters
  final double overallQualityScore; // 0.0 to 100.0
  final List<String> detectedDefectLabels;

  const PhotoAnalysisReport({
    required this.width,
    required this.height,
    required this.isGrayscale,
    required this.noiseLevel,
    required this.blurLevel,
    required this.fadingScore,
    required this.contrastScore,
    required this.estimatedDamagePoints,
    required this.overallQualityScore,
    required this.detectedDefectLabels,
  });

  bool get needsScratchRepair => estimatedDamagePoints > 15;
  bool get needsNoiseReduction => noiseLevel > 0.25;
  bool get needsDeblur => blurLevel > 0.30;
  bool get needsColorRecovery => fadingScore > 0.30 || contrastScore < 0.45;
  bool get isLowResolution => width < 600 || height < 600;
}

class RestorationOptions {
  final RestorationStrength strength;
  final bool repairScratches;
  final bool reduceNoise;
  final bool deblurAndSharpen;
  final bool recoverFadedColors;
  final bool autoWhiteBalance;
  final bool colorize; // Only applicable for B&W photos
  final int upscaleFactor; // 1 (none), 2 (2x), 4 (4x)
  final double brightness; // -1.0 to 1.0 (default 0.0)
  final double contrast; // 0.5 to 1.5 (default 1.0)
  final double sharpness; // 0.0 to 2.0 (default 1.0)
  final double saturation; // 0.0 to 2.0 (default 1.0)
  final double temperature; // -1.0 (cool) to 1.0 (warm) (default 0.0)

  const RestorationOptions({
    this.strength = RestorationStrength.medium,
    this.repairScratches = true,
    this.reduceNoise = true,
    this.deblurAndSharpen = true,
    this.recoverFadedColors = true,
    this.autoWhiteBalance = true,
    this.colorize = false,
    this.upscaleFactor = 1,
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.sharpness = 1.0,
    this.saturation = 1.0,
    this.temperature = 0.0,
  });

  RestorationOptions copyWith({
    RestorationStrength? strength,
    bool? repairScratches,
    bool? reduceNoise,
    bool? deblurAndSharpen,
    bool? recoverFadedColors,
    bool? autoWhiteBalance,
    bool? colorize,
    int? upscaleFactor,
    double? brightness,
    double? contrast,
    double? sharpness,
    double? saturation,
    double? temperature,
  }) {
    return RestorationOptions(
      strength: strength ?? this.strength,
      repairScratches: repairScratches ?? this.repairScratches,
      reduceNoise: reduceNoise ?? this.reduceNoise,
      deblurAndSharpen: deblurAndSharpen ?? this.deblurAndSharpen,
      recoverFadedColors: recoverFadedColors ?? this.recoverFadedColors,
      autoWhiteBalance: autoWhiteBalance ?? this.autoWhiteBalance,
      colorize: colorize ?? this.colorize,
      upscaleFactor: upscaleFactor ?? this.upscaleFactor,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      sharpness: sharpness ?? this.sharpness,
      saturation: saturation ?? this.saturation,
      temperature: temperature ?? this.temperature,
    );
  }
}

class RestorationResult {
  final String originalImagePath;
  final String restoredImagePath;
  final PhotoAnalysisReport analysisReport;
  final RestorationOptions optionsUsed;
  final int processingTimeMs;
  final int finalWidth;
  final int finalHeight;

  const RestorationResult({
    required this.originalImagePath,
    required this.restoredImagePath,
    required this.analysisReport,
    required this.optionsUsed,
    required this.processingTimeMs,
    required this.finalWidth,
    required this.finalHeight,
  });
}
