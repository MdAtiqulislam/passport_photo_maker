enum AiEnhanceProfile {
  subtle('Subtle', 'Gentle exposure & color balance'),
  balanced('Balanced ✨', 'Studio lighting & natural clarity (Recommended)'),
  beautySmooth('Beauty Smooth 🌸', 'Flawless skin smoothing & blemish softening'),
  glamRadiance('Glam Radiance ✨', 'Vibrant skin glow, whitening & eye clarity'),
  studioPro('Studio Pro 📸', 'Crisp edge detail & maximum noise reduction');

  final String title;
  final String description;
  const AiEnhanceProfile(this.title, this.description);
}

class AiEnhanceResult {
  final String originalImagePath;
  final String enhancedImagePath;
  final AiEnhanceProfile profile;
  final double exposureAdjustment;
  final double contrastMultiplier;
  final double sharpnessFactor;
  final bool noiseReduced;
  final bool whiteBalanceCorrected;
  final String summary;

  const AiEnhanceResult({
    required this.originalImagePath,
    required this.enhancedImagePath,
    required this.profile,
    required this.exposureAdjustment,
    required this.contrastMultiplier,
    required this.sharpnessFactor,
    required this.noiseReduced,
    required this.whiteBalanceCorrected,
    required this.summary,
  });
}
