import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class SpotHealingWidget extends StatefulWidget {
  final String imagePath;
  final Function(double normX, double normY, double normRadius) onHealSpot;
  final VoidCallback onUndo;
  final bool canUndo;

  const SpotHealingWidget({
    super.key,
    required this.imagePath,
    required this.onHealSpot,
    required this.onUndo,
    required this.canUndo,
  });

  @override
  State<SpotHealingWidget> createState() => _SpotHealingWidgetState();
}

class _SpotHealingWidgetState extends State<SpotHealingWidget> {
  final TransformationController _transformController = TransformationController();
  double _brushRadiusPx = 18.0; // 8 to 45 px
  Offset? _touchPosition;
  bool _isHealing = false;
  Size? _imageNaturalSize;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;

  @override
  void initState() {
    super.initState();
    _resolveImageSize();
  }

  @override
  void didUpdateWidget(covariant SpotHealingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _resolveImageSize();
    }
  }

  void _resolveImageSize() {
    if (widget.imagePath.isEmpty || !File(widget.imagePath).existsSync()) return;

    final imageProvider = FileImage(File(widget.imagePath));
    _imageStream?.removeListener(_imageListener!);
    _imageStream = imageProvider.resolve(const ImageConfiguration());
    _imageListener = ImageStreamListener((ImageInfo info, bool _) {
      if (mounted) {
        setState(() {
          _imageNaturalSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
        });
      }
    });
    _imageStream!.addListener(_imageListener!);
  }

  @override
  void dispose() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    _transformController.dispose();
    super.dispose();
  }

  void _handleTap(TapUpDetails details, BoxConstraints constraints) {
    if (_isHealing || widget.imagePath.isEmpty) return;

    final containerW = constraints.maxWidth;
    final containerH = constraints.maxHeight;
    if (containerW <= 0 || containerH <= 0) return;

    final imgW = _imageNaturalSize?.width ?? containerW;
    final imgH = _imageNaturalSize?.height ?? containerH;

    final containerAspect = containerW / containerH;
    final imgAspect = imgW / imgH;

    double renderedW, renderedH, offsetX, offsetY;
    if (containerAspect > imgAspect) {
      // Letterbox on left & right
      renderedH = containerH;
      renderedW = containerH * imgAspect;
      offsetX = (containerW - renderedW) / 2.0;
      offsetY = 0.0;
    } else {
      // Letterbox on top & bottom
      renderedW = containerW;
      renderedH = containerW / imgAspect;
      offsetX = 0.0;
      offsetY = (containerH - renderedH) / 2.0;
    }

    // Invert the transformation matrix (zoom / pan)
    final localPos = details.localPosition;
    final matrix = _transformController.value;
    final invertedMatrix = Matrix4.inverted(matrix);
    final transformedPoint = MatrixUtils.transformPoint(invertedMatrix, localPos);

    // Calculate position relative to rendered image
    final imgX = transformedPoint.dx - offsetX;
    final imgY = transformedPoint.dy - offsetY;

    // If tapped in letterbox bars, ignore
    if (imgX < 0 || imgX > renderedW || imgY < 0 || imgY > renderedH) {
      return;
    }

    final normX = (imgX / renderedW).clamp(0.0, 1.0);
    final normY = (imgY / renderedH).clamp(0.0, 1.0);
    final normRadius = (_brushRadiusPx / renderedW).clamp(0.005, 0.20);

    setState(() {
      _touchPosition = localPos;
      _isHealing = true;
    });

    widget.onHealSpot(normX, normY, normRadius);

    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _isHealing = false;
          _touchPosition = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Toolbar: Brush Size + Undo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: context.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              const Icon(Icons.brush, size: 16, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                'Size: ${_brushRadiusPx.round()}px',
                style: TextStyle(color: context.textPrimaryColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Slider(
                  value: _brushRadiusPx,
                  min: 6.0,
                  max: 45.0,
                  activeColor: AppColors.accent,
                  inactiveColor: context.cardAltColor,
                  onChanged: (val) => setState(() => _brushRadiusPx = val),
                ),
              ),
              IconButton(
                icon: Icon(Icons.undo_rounded, color: widget.canUndo ? AppColors.accent : context.textSecondaryColor),
                tooltip: 'Undo Last Heal',
                onPressed: widget.canUndo ? widget.onUndo : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Hint bar
        Text(
          '🔍 Pinch to zoom. Tap directly on any spot or scratch to heal it.',
          style: TextStyle(color: context.textSecondaryColor, fontSize: 11),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),

        // Interactive Viewport
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTapUp: (details) => _handleTap(details, constraints),
                      child: InteractiveViewer(
                        transformationController: _transformController,
                        minScale: 1.0,
                        maxScale: 6.0,
                        child: Center(
                          child: widget.imagePath.isNotEmpty && File(widget.imagePath).existsSync()
                              ? Image.file(
                                  File(widget.imagePath),
                                  fit: BoxFit.contain,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),

                    // Touch Healing feedback ring
                    if (_touchPosition != null)
                      Positioned(
                        left: _touchPosition!.dx - _brushRadiusPx,
                        top: _touchPosition!.dy - _brushRadiusPx,
                        child: IgnorePointer(
                          child: Container(
                            width: _brushRadiusPx * 2,
                            height: _brushRadiusPx * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.accent, width: 2),
                              color: AppColors.accent.withOpacity(0.25),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
