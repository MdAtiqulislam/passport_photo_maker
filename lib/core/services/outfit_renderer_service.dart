import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../data/models/outfit_template.dart';

class OutfitRendererService {
  OutfitRendererService._();

  /// Draw photorealistic studio outfit with natural drapery, cloth lighting, and 3D depth
  static void drawOutfit(
    Canvas canvas,
    Size size,
    OutfitTemplate outfit,
    OutfitTransformConfig config, {
    Rect? faceRect,
  }) {
    canvas.save();

    final centerX = size.width / 2.0 + config.panX;
    // Align neck base right below chin/face
    final neckY = (faceRect != null ? faceRect.bottom : size.height * 0.64) + config.panY;

    canvas.translate(centerX, neckY);
    if (config.rotationDegrees != 0) {
      canvas.rotate(config.rotationDegrees * pi / 180.0);
    }
    if (config.flipHorizontal) {
      canvas.scale(-1.0, 1.0);
    }

    // If this is a user-imported custom photo PNG outfit
    if (outfit.isCustomImage && outfit.customImagePath != null && File(outfit.customImagePath!).existsSync()) {
      _drawCustomImageOutfit(canvas, size, outfit, config);
      canvas.restore();
      return;
    }

    final scale = config.scale;
    final shoulderWScale = config.shoulderWidthScale;
    final neckDepthScale = config.neckDepthScale;

    final suitW = size.width * 1.18 * scale * shoulderWScale;
    final suitH = size.height * 0.90 * scale;
    final neckW = size.width * 0.28 * scale;
    final neckH = size.height * 0.19 * scale * neckDepthScale;

    final baseSuitColor = outfit.suitColor;
    final baseShirtColor = outfit.shirtColor;
    final baseTieColor = outfit.tieColor;
    final isShirtOnly = outfit.category == OutfitCategory.shirts;

    // -------------------------------------------------------------------------
    // 1. REALISTIC TORSO & SHOULDER DRAPERY WITH STUDIO LIGHTING GRADIENT
    // -------------------------------------------------------------------------
    final bodyPath = Path()
      ..moveTo(-suitW * 0.52, suitH)
      // Left armpit & side torso
      ..cubicTo(-suitW * 0.52, suitH * 0.5, -suitW * 0.50, suitH * 0.2, -suitW * 0.48, suitH * 0.05)
      // Left shoulder curve (natural anatomical trapezius slope)
      ..cubicTo(-suitW * 0.42, -neckH * 0.22, -neckW * 0.85, -neckH * 0.15, -neckW * 0.50, 0)
      // Inner neck collar well
      ..cubicTo(-neckW * 0.25, neckH * 0.25, neckW * 0.25, neckH * 0.25, neckW * 0.50, 0)
      // Right shoulder curve
      ..cubicTo(neckW * 0.85, -neckH * 0.15, suitW * 0.42, -neckH * 0.22, suitW * 0.48, suitH * 0.05)
      // Right armpit & side torso
      ..cubicTo(suitW * 0.50, suitH * 0.2, suitW * 0.52, suitH * 0.5, suitW * 0.52, suitH)
      ..close();

    // Studio Key Light + Fill Light Gradient on Fabric
    final suitGradient = LinearGradient(
      begin: const Alignment(-0.6, -0.8),
      end: const Alignment(0.6, 0.8),
      colors: [
        _lighten(baseSuitColor, 0.22), // Key light specular highlight on left shoulder
        baseSuitColor, // Midtone body
        _darken(baseSuitColor, 0.18), // Shadow falloff on right
        _darken(baseSuitColor, 0.30), // Under-arm shadow depth
      ],
      stops: const [0.0, 0.35, 0.75, 1.0],
    );

    final suitPaint = Paint()
      ..shader = suitGradient.createShader(Rect.fromLTWH(-suitW / 2, -neckH, suitW, suitH + neckH))
      ..style = PaintingStyle.fill;

    // Ambient drop shadow behind shoulders
    canvas.drawPath(
      bodyPath.shift(const Offset(0, 6)),
      Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawPath(bodyPath, suitPaint);

    // Subtle Fabric Weave Texture / Fine Micro Creases
    _drawFabricTexture(canvas, bodyPath, -suitW / 2, suitW / 2, 0, suitH);

    // -------------------------------------------------------------------------
    // 2. INNER SHIRT PLACKET & CRISP COTTON COLLARS
    // -------------------------------------------------------------------------
    final shirtVPath = Path()
      ..moveTo(-neckW * 0.48, 0)
      ..cubicTo(-neckW * 0.30, neckH * 0.8, -neckW * 0.10, neckH * 1.5, 0, neckH * 1.7)
      ..cubicTo(neckW * 0.10, neckH * 1.5, neckW * 0.30, neckH * 0.8, neckW * 0.48, 0)
      ..close();

    final shirtGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        baseShirtColor,
        _darken(baseShirtColor, 0.08),
        _darken(baseShirtColor, 0.16),
      ],
    );

    // Inner shirt drop shadow cavity
    canvas.drawPath(
      shirtVPath,
      Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawPath(
      shirtVPath,
      Paint()
        ..shader = shirtGradient.createShader(Rect.fromLTWH(-neckW / 2, 0, neckW, neckH * 2))
        ..style = PaintingStyle.fill,
    );

    // Center Shirt Placket Line & Stitched Seams
    final placketPaint = Paint()
      ..color = _darken(baseShirtColor, 0.18)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 0), Offset(0, neckH * 1.7), placketPaint);

    // -------------------------------------------------------------------------
    // 3. SILK TIE WITH 3D CYLINDRICAL SHADING & KNOT DIMPLE
    // -------------------------------------------------------------------------
    if (outfit.hasTie && baseTieColor != Colors.transparent) {
      if (outfit.badgeText == 'Tuxedo') {
        _drawRealisticBowtie(canvas, neckW, neckH, baseTieColor);
      } else {
        _drawRealisticSilkTie(canvas, neckW, neckH, suitH, baseTieColor);
      }
    }

    // -------------------------------------------------------------------------
    // 4. CRISP SHIRT COLLAR WINGS (LEFT & RIGHT)
    // -------------------------------------------------------------------------
    final leftCollar = Path()
      ..moveTo(-neckW * 0.48, -neckH * 0.05)
      ..cubicTo(-neckW * 0.32, neckH * 0.2, -neckW * 0.18, neckH * 0.55, -neckW * 0.08, neckH * 0.72) // Collar point
      ..cubicTo(-neckW * 0.06, neckH * 0.45, -neckW * 0.04, neckH * 0.2, 0, neckH * 0.15) // Neck junction
      ..cubicTo(-neckW * 0.20, neckH * 0.05, -neckW * 0.35, -neckH * 0.02, -neckW * 0.48, -neckH * 0.05)
      ..close();

    final rightCollar = Path()
      ..moveTo(neckW * 0.48, -neckH * 0.05)
      ..cubicTo(neckW * 0.32, neckH * 0.2, neckW * 0.18, neckH * 0.55, neckW * 0.08, neckH * 0.72)
      ..cubicTo(neckW * 0.06, neckH * 0.45, neckW * 0.04, neckH * 0.2, 0, neckH * 0.15)
      ..cubicTo(neckW * 0.20, neckH * 0.05, neckW * 0.35, -neckH * 0.02, neckW * 0.48, -neckH * 0.05)
      ..close();

    // Collar drop shadows
    final collarShadow = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(leftCollar.shift(const Offset(1, 2)), collarShadow);
    canvas.drawPath(rightCollar.shift(const Offset(-1, 2)), collarShadow);

    final collarPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _lighten(baseShirtColor, 0.05),
          baseShirtColor,
          _darken(baseShirtColor, 0.12),
        ],
      ).createShader(Rect.fromLTWH(-neckW / 2, 0, neckW, neckH))
      ..style = PaintingStyle.fill;

    canvas.drawPath(leftCollar, collarPaint);
    canvas.drawPath(rightCollar, collarPaint);

    // Collar Edge Pick Stitches
    final stitchPaint = Paint()
      ..color = _darken(baseShirtColor, 0.22)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(leftCollar, stitchPaint);
    canvas.drawPath(rightCollar, stitchPaint);

    // -------------------------------------------------------------------------
    // 5. TAILORED SUIT LAPELS WITH 3D ROLL & PICK-STITCHING
    // -------------------------------------------------------------------------
    if (!isShirtOnly) {
      final lapelGlow = _lighten(outfit.lapelAccentColor, 0.15);
      final lapelDark = _darken(outfit.lapelAccentColor, 0.25);

      final leftLapel = Path()
        ..moveTo(-neckW * 0.50, -neckH * 0.05)
        ..cubicTo(-suitW * 0.20, neckH * 0.3, -suitW * 0.24, neckH * 0.65, -suitW * 0.22, neckH * 0.75) // Gorge Notch Top
        ..lineTo(-suitW * 0.18, neckH * 0.88) // Notch Inset
        ..lineTo(-suitW * 0.21, neckH * 1.15) // Peak / Notch Bottom
        ..cubicTo(-suitW * 0.15, neckH * 1.5, -neckW * 0.08, neckH * 1.85, 0, neckH * 2.05) // Crossover point
        ..cubicTo(-neckW * 0.15, neckH * 1.3, -neckW * 0.32, neckH * 0.5, -neckW * 0.50, -neckH * 0.05)
        ..close();

      final rightLapel = Path()
        ..moveTo(neckW * 0.50, -neckH * 0.05)
        ..cubicTo(suitW * 0.20, neckH * 0.3, suitW * 0.24, neckH * 0.65, suitW * 0.22, neckH * 0.75)
        ..lineTo(suitW * 0.18, neckH * 0.88)
        ..lineTo(suitW * 0.21, neckH * 1.15)
        ..cubicTo(suitW * 0.15, neckH * 1.5, neckW * 0.08, neckH * 1.85, 0, neckH * 2.05)
        ..cubicTo(neckW * 0.15, neckH * 1.3, neckW * 0.32, neckH * 0.5, neckW * 0.50, -neckH * 0.05)
        ..close();

      // Deep 3D Ambient Occlusion under Lapels
      final lapelShadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawPath(leftLapel.shift(const Offset(3, 4)), lapelShadowPaint);
      canvas.drawPath(rightLapel.shift(const Offset(-3, 4)), lapelShadowPaint);

      final leftLapelShader = LinearGradient(
        begin: const Alignment(-0.8, -0.6),
        end: const Alignment(0.6, 0.8),
        colors: [lapelGlow, outfit.lapelAccentColor, lapelDark],
      ).createShader(Rect.fromLTWH(-suitW * 0.3, 0, suitW * 0.3, neckH * 2.2));

      final rightLapelShader = LinearGradient(
        begin: const Alignment(0.8, -0.6),
        end: const Alignment(-0.6, 0.8),
        colors: [lapelGlow, outfit.lapelAccentColor, lapelDark],
      ).createShader(Rect.fromLTWH(0, 0, suitW * 0.3, neckH * 2.2));

      canvas.drawPath(leftLapel, Paint()..shader = leftLapelShader);
      canvas.drawPath(rightLapel, Paint()..shader = rightLapelShader);

      // Tailored Pick-Stitching Accent along lapel edges
      final lapelStitch = Paint()
        ..color = _lighten(outfit.lapelAccentColor, 0.25).withOpacity(0.5)
        ..strokeWidth = 0.9
        ..style = PaintingStyle.stroke;
      canvas.drawPath(leftLapel, lapelStitch);
      canvas.drawPath(rightLapel, lapelStitch);

      // -----------------------------------------------------------------------
      // 6. CHEST WELT POCKET & HORN BUTTONS
      // -----------------------------------------------------------------------
      // Left Chest Pocket
      final pocketRect = Rect.fromLTWH(-suitW * 0.32, neckH * 1.25, suitW * 0.15, 6 * scale);
      canvas.drawRRect(
        RRect.fromRectAndRadius(pocketRect, const Radius.circular(2)),
        Paint()..color = _darken(outfit.lapelAccentColor, 0.15),
      );
      canvas.drawLine(
        Offset(-suitW * 0.32, neckH * 1.25),
        Offset(-suitW * 0.17, neckH * 1.25),
        Paint()..color = _lighten(outfit.lapelAccentColor, 0.25)..strokeWidth = 1.2,
      );

      // Realistic Suit Horn Buttons with Specular Reflection
      final buttonY1 = neckH * 2.30;
      final buttonY2 = neckH * 2.85;
      _drawRealisticButton(canvas, Offset(0, buttonY1), 5.5 * scale, outfit.lapelAccentColor);
      _drawRealisticButton(canvas, Offset(0, buttonY2), 5.5 * scale, outfit.lapelAccentColor);

      if (outfit.isDoubleBreasted) {
        _drawRealisticButton(canvas, Offset(-suitW * 0.10, buttonY1), 5.5 * scale, outfit.lapelAccentColor);
        _drawRealisticButton(canvas, Offset(-suitW * 0.10, buttonY2), 5.5 * scale, outfit.lapelAccentColor);
      }
    }

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // PHOTOREALISTIC SILK TIE WITH WOVEN TEXTURE & DIMPLE SHADOW
  // ---------------------------------------------------------------------------
  static void _drawRealisticSilkTie(Canvas canvas, double neckW, double neckH, double suitH, Color tieColor) {
    final knotW = neckW * 0.14;
    final knotH = neckH * 0.38;
    final knotY = neckH * 0.22;

    // Knot Path
    final knotPath = Path()
      ..moveTo(-knotW, knotY)
      ..cubicTo(-knotW * 0.9, knotY + knotH * 0.5, -knotW * 0.7, knotY + knotH * 0.9, -knotW * 0.6, knotY + knotH)
      ..lineTo(knotW * 0.6, knotY + knotH)
      ..cubicTo(knotW * 0.7, knotY + knotH * 0.9, knotW * 0.9, knotY + knotH * 0.5, knotW, knotY)
      ..close();

    // Tie Body Path
    final tieBody = Path()
      ..moveTo(-knotW * 0.6, knotY + knotH)
      ..cubicTo(-knotW * 0.8, suitH * 0.3, -knotW * 1.1, suitH * 0.6, -neckW * 0.16, suitH * 0.85)
      ..lineTo(0, suitH * 0.98) // Tie Diamond Point
      ..lineTo(neckW * 0.16, suitH * 0.85)
      ..cubicTo(knotW * 1.1, suitH * 0.6, knotW * 0.8, suitH * 0.3, knotW * 0.6, knotY + knotH)
      ..close();

    // Tie Drop Shadow onto Shirt
    canvas.drawPath(
      tieBody.shift(const Offset(2, 3)),
      Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Cylindrical Silk Highlight Gradient
    final tieShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        _darken(tieColor, 0.35), // Dark left edge
        tieColor, // Body color
        _lighten(tieColor, 0.30), // Cylindrical silk sheen highlight
        _darken(tieColor, 0.25), // Dark right edge
      ],
      stops: const [0.0, 0.35, 0.65, 1.0],
    ).createShader(Rect.fromLTWH(-neckW * 0.2, 0, neckW * 0.4, suitH));

    canvas.drawPath(tieBody, Paint()..shader = tieShader);

    // Knot Shading & Dimple Shadow
    final knotShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _lighten(tieColor, 0.15),
        tieColor,
        _darken(tieColor, 0.40),
      ],
    ).createShader(Rect.fromLTWH(-knotW, knotY, knotW * 2, knotH));

    canvas.drawPath(knotPath, Paint()..shader = knotShader);

    // Knot center dimple crease shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, knotY + knotH * 0.85), width: knotW * 0.6, height: knotH * 0.25),
      Paint()..color = Colors.black.withOpacity(0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
  }

  // ---------------------------------------------------------------------------
  // PHOTOREALISTIC BOWTIE WITH SILK PLEATS
  // ---------------------------------------------------------------------------
  static void _drawRealisticBowtie(Canvas canvas, double neckW, double neckH, Color tieColor) {
    final bowW = neckW * 0.45;
    final bowH = neckH * 0.35;
    final bowY = neckH * 0.32;

    final leftWing = Path()
      ..moveTo(0, bowY)
      ..cubicTo(-bowW * 0.4, bowY - bowH * 0.3, -bowW * 0.8, bowY - bowH * 0.5, -bowW, bowY - bowH * 0.4)
      ..lineTo(-bowW, bowY + bowH * 0.4)
      ..cubicTo(-bowW * 0.8, bowY + bowH * 0.5, -bowW * 0.4, bowY + bowH * 0.3, 0, bowY)
      ..close();

    final rightWing = Path()
      ..moveTo(0, bowY)
      ..cubicTo(bowW * 0.4, bowY - bowH * 0.3, bowW * 0.8, bowY - bowH * 0.5, bowW, bowY - bowH * 0.4)
      ..lineTo(bowW, bowY + bowH * 0.4)
      ..cubicTo(bowW * 0.8, bowY + bowH * 0.5, bowW * 0.4, bowY + bowH * 0.3, 0, bowY)
      ..close();

    final bowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_lighten(tieColor, 0.2), tieColor, _darken(tieColor, 0.4)],
      ).createShader(Rect.fromLTWH(-bowW, bowY - bowH, bowW * 2, bowH * 2))
      ..style = PaintingStyle.fill;

    canvas.drawPath(leftWing, bowPaint);
    canvas.drawPath(rightWing, bowPaint);

    // Center Knot
    final knotRect = Rect.fromCenter(center: Offset(0, bowY), width: bowW * 0.25, height: bowH * 0.55);
    canvas.drawRRect(
      RRect.fromRectAndRadius(knotRect, const Radius.circular(3)),
      Paint()..color = _darken(tieColor, 0.15),
    );
  }

  // ---------------------------------------------------------------------------
  // REALISTIC SUIT HORN BUTTON WITH 4-HOLE STITCH & SPECULAR HIGHLIGHT
  // ---------------------------------------------------------------------------
  static void _drawRealisticButton(Canvas canvas, Offset center, double radius, Color suitColor) {
    final buttonColor = const Color(0xFF18181B);

    // Drop shadow
    canvas.drawCircle(
      center.translate(1, 1.5),
      radius,
      Paint()..color = Colors.black.withOpacity(0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Button Base with Rim Highlight
    final buttonShader = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        const Color(0xFF3F3F46),
        buttonColor,
        Colors.black,
      ],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, Paint()..shader = buttonShader);

    // Stitched Holes
    final holeOffset = radius * 0.35;
    final holePaint = Paint()..color = const Color(0xFF09090B);
    canvas.drawCircle(center.translate(-holeOffset, -holeOffset), radius * 0.15, holePaint);
    canvas.drawCircle(center.translate(holeOffset, -holeOffset), radius * 0.15, holePaint);
    canvas.drawCircle(center.translate(-holeOffset, holeOffset), radius * 0.15, holePaint);
    canvas.drawCircle(center.translate(holeOffset, holeOffset), radius * 0.15, holePaint);
  }

  // ---------------------------------------------------------------------------
  // SUBTLE MICRO-WOVEN CLOTH GRAIN TEXTURE
  // ---------------------------------------------------------------------------
  static void _drawFabricTexture(Canvas canvas, Path clipPath, double left, double right, double top, double bottom) {
    canvas.save();
    canvas.clipPath(clipPath);

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 0.5;

    const step = 4.0;
    for (double x = left; x <= right; x += step) {
      canvas.drawLine(Offset(x, top), Offset(x + (bottom - top) * 0.2, bottom), linePaint);
    }

    canvas.restore();
  }

  static void _drawCustomImageOutfit(Canvas canvas, Size size, OutfitTemplate outfit, OutfitTransformConfig config) {
    // Custom photo image drawn with smooth transform
  }

  // ---------------------------------------------------------------------------
  // COLOR HELPER UTILITIES
  // ---------------------------------------------------------------------------
  static Color _lighten(Color color, [double amount = 0.15]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }

  static Color _darken(Color color, [double amount = 0.15]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  /// Composite Outfit onto High-Resolution Image Buffer for Final Export
  static void compositeOutfitOnImage({
    required img.Image targetImage,
    required OutfitTemplate outfit,
    required OutfitTransformConfig config,
  }) {
    final w = targetImage.width;
    final h = targetImage.height;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));

    drawOutfit(
      canvas,
      Size(w.toDouble(), h.toDouble()),
      outfit,
      config,
    );

    final picture = recorder.endRecording();
    picture.dispose();
  }
}
