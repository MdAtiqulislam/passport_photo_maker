import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class BeforeAfterSlider extends StatefulWidget {
  final String originalImagePath;
  final String restoredImagePath;
  final double initialPosition;

  const BeforeAfterSlider({
    super.key,
    required this.originalImagePath,
    required this.restoredImagePath,
    this.initialPosition = 0.5,
  });

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  late double _splitPosition;

  @override
  void initState() {
    super.initState();
    _splitPosition = widget.initialPosition;
  }

  void _updatePosition(Offset localPosition, Size size) {
    if (size.width <= 0) return;
    setState(() {
      _splitPosition = (localPosition.dx / size.width).clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;
        final splitX = totalWidth * _splitPosition;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            _updatePosition(details.localPosition, Size(totalWidth, totalHeight));
          },
          onTapDown: (details) {
            _updatePosition(details.localPosition, Size(totalWidth, totalHeight));
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Layer 1: Restored Image (Full Background)
                if (widget.restoredImagePath.isNotEmpty && File(widget.restoredImagePath).existsSync())
                  Image.file(
                    File(widget.restoredImagePath),
                    fit: BoxFit.contain,
                  ),

                // Layer 2: Original Image (Clipped to left side of split)
                if (widget.originalImagePath.isNotEmpty && File(widget.originalImagePath).existsSync())
                  ClipRect(
                    clipper: _HorizontalSplitClipper(splitFraction: _splitPosition),
                    child: Image.file(
                      File(widget.originalImagePath),
                      fit: BoxFit.contain,
                    ),
                  ),

                // Layer 3: Vertical Divider Line
                Positioned(
                  left: splitX - 1.5,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 3,
                    color: Colors.white,
                    child: Center(
                      child: Container(
                        width: 1,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),

                // Layer 4: Drag Handle Bubble
                Positioned(
                  left: splitX - 18,
                  top: (totalHeight / 2) - 18,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.compare_arrows_rounded,
                      size: 22,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),

                // Layer 5: "Original" Badge (Top Left)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text(
                      'Original',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Layer 6: "Restored" Badge (Top Right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                    ),
                    child: const Text(
                      '✨ Restored',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HorizontalSplitClipper extends CustomClipper<Rect> {
  final double splitFraction;

  _HorizontalSplitClipper({required this.splitFraction});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * splitFraction, size.height);
  }

  @override
  bool shouldReclip(covariant _HorizontalSplitClipper oldClipper) {
    return oldClipper.splitFraction != splitFraction;
  }
}
