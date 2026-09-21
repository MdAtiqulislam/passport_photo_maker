import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/segmentation_result.dart';

class ManualMaskEditorView extends StatefulWidget {
  final SegmentationMaskData initialMask;
  final String imagePath;
  final Function(SegmentationMaskData newMask) onApply;

  const ManualMaskEditorView({
    super.key,
    required this.initialMask,
    required this.imagePath,
    required this.onApply,
  });

  @override
  State<ManualMaskEditorView> createState() => _ManualMaskEditorViewState();
}

class _ManualMaskEditorViewState extends State<ManualMaskEditorView> {
  late SegmentationMaskData _workingMask;
  late SegmentationMaskData _originalAutoMask;

  // History Stacks for Undo / Redo
  final List<Float32List> _undoStack = [];
  final List<Float32List> _redoStack = [];

  // Brush Controls
  bool _isAddMode = true; // true = + Add, false = - Remove
  double _brushSize = 25.0; // 5.0 .. 80.0
  final double _feather = 0.25; // 0.0 .. 0.60
  bool _isNavigationMode = false; // true = Pan & Zoom, false = Paint
  bool _showMaskOverlay = true; // true = Ruby Mask, false = Cutout Preview

  // Transformation for Pan & Zoom
  final TransformationController _transformController = TransformationController();
  Offset? _lastPointerPos;

  @override
  void initState() {
    super.initState();
    _originalAutoMask = widget.initialMask.clone();
    _workingMask = widget.initialMask.clone();
    _saveSnapshot();
  }

  void _saveSnapshot() {
    _undoStack.add(Float32List.fromList(_workingMask.confidences));
    if (_undoStack.length > 20) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.length > 1) {
      final current = _undoStack.removeLast();
      _redoStack.add(current);
      final prev = _undoStack.last;
      setState(() {
        _workingMask.confidences.setAll(0, prev);
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      final next = _redoStack.removeLast();
      _undoStack.add(next);
      setState(() {
        _workingMask.confidences.setAll(0, next);
      });
    }
  }

  void _resetToAuto() {
    _saveSnapshot();
    setState(() {
      _workingMask = _originalAutoMask.clone();
    });
  }

  void _clearAll() {
    _saveSnapshot();
    setState(() {
      _workingMask = SegmentationMaskData.empty(_workingMask.width, _workingMask.height);
    });
  }

  void _onPaintStart(Offset localPos, Size renderSize) {
    if (_isNavigationMode) return;
    _saveSnapshot();
    _paintAt(localPos, renderSize);
  }

  void _onPaintUpdate(Offset localPos, Size renderSize) {
    if (_isNavigationMode) return;
    _paintAt(localPos, renderSize);
  }

  void _paintAt(Offset localPos, Size renderSize) {
    // Map screen coordinate inside render box to normalized 0.0 .. 1.0 mask coordinate
    final normX = (localPos.dx / renderSize.width).clamp(0.0, 1.0);
    final normY = (localPos.dy / renderSize.height).clamp(0.0, 1.0);
    final normRadius = (_brushSize / renderSize.width).clamp(0.005, 0.25);

    setState(() {
      _lastPointerPos = localPos;
      _workingMask.applyBrushStroke(
        normX: normX,
        normY: normY,
        normRadius: normRadius,
        isAdd: _isAddMode,
        feather: _feather,
      );
    });
  }

  void _onPaintEnd() {
    setState(() {
      _lastPointerPos = null;
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manual Selection Refine', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Brush over missing parts to add or unwanted areas to remove', style: TextStyle(color: AppColors.accent, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              widget.onApply(_workingMask);
              Get.back();
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Apply Selection', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Mode Indicator Bar
          Container(
            color: const Color(0xFF1E293B),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Paint Mode vs Navigation Mode
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSegmentButton(
                            label: '🖌️ Paint Mode',
                            isSelected: !_isNavigationMode,
                            onTap: () => setState(() => _isNavigationMode = false),
                          ),
                        ),
                        Expanded(
                          child: _buildSegmentButton(
                            label: '🔍 Zoom & Pan',
                            isSelected: _isNavigationMode,
                            onTap: () => setState(() => _isNavigationMode = true),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Mask Overlay Toggle
                IconButton(
                  tooltip: _showMaskOverlay ? 'Mask Overlay (Ruby)' : 'Cutout Preview',
                  icon: Icon(
                    _showMaskOverlay ? Icons.visibility : Icons.visibility_off,
                    color: _showMaskOverlay ? AppColors.accent : Colors.white60,
                  ),
                  onPressed: () => setState(() => _showMaskOverlay = !_showMaskOverlay),
                ),
              ],
            ),
          ),

          // Main Painting Canvas
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    panEnabled: _isNavigationMode,
                    scaleEnabled: _isNavigationMode,
                    minScale: 0.8,
                    maxScale: 5.0,
                    child: GestureDetector(
                      onPanStart: (details) => _onPaintStart(details.localPosition, constraints.biggest),
                      onPanUpdate: (details) => _onPaintUpdate(details.localPosition, constraints.biggest),
                      onPanEnd: (_) => _onPaintEnd(),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Base Original Photo
                          Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.contain,
                          ),

                          // Live Mask Silhouette Overlay
                          Positioned.fill(
                            child: CustomPaint(
                              painter: MaskOverlayPainter(
                                mask: _workingMask,
                                showRubyOverlay: _showMaskOverlay,
                                lastPointerPos: _lastPointerPos,
                                brushSize: _brushSize,
                                isAddMode: _isAddMode,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Brush Controls & Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add / Remove Brush Switch & Actions
                Row(
                  children: [
                    // Brush Mode: + Add / - Remove
                    Expanded(
                      flex: 3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildBrushModeButton(
                                label: '+ Add (Subject)',
                                isSelected: _isAddMode,
                                color: const Color(0xFF10B981),
                                onTap: () => setState(() => _isAddMode = true),
                              ),
                            ),
                            Expanded(
                              child: _buildBrushModeButton(
                                label: '- Remove (BG)',
                                isSelected: !_isAddMode,
                                color: const Color(0xFFEF4444),
                                onTap: () => setState(() => _isAddMode = false),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Undo, Redo, Reset Actions
                    IconButton(
                      icon: const Icon(Icons.undo, color: Colors.white),
                      tooltip: 'Undo',
                      onPressed: _undoStack.length > 1 ? _undo : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.redo, color: Colors.white),
                      tooltip: 'Redo',
                      onPressed: _redoStack.isNotEmpty ? _redo : null,
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      color: const Color(0xFF1E293B),
                      onSelected: (value) {
                        if (value == 'reset') _resetToAuto();
                        if (value == 'clear') _clearAll();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'reset',
                          child: Row(
                            children: [
                              Icon(Icons.restart_alt, color: AppColors.accent, size: 18),
                              SizedBox(width: 8),
                              Text('Reset to Auto Mask', style: TextStyle(color: Colors.white, fontSize: 13)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              Icon(Icons.clear_all, color: Colors.redAccent, size: 18),
                              SizedBox(width: 8),
                              Text('Clear Entire Mask', style: TextStyle(color: Colors.white, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Brush Size & Feather Sliders
                Row(
                  children: [
                    const Text('Brush Size', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: _brushSize,
                        min: 5.0,
                        max: 80.0,
                        divisions: 15,
                        activeColor: _isAddMode ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        onChanged: (v) => setState(() => _brushSize = v),
                      ),
                    ),
                    Container(
                      width: 36,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_brushSize.round()}px',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondaryDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildBrushModeButton({required String label, required bool isSelected, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondaryDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class MaskOverlayPainter extends CustomPainter {
  final SegmentationMaskData mask;
  final bool showRubyOverlay;
  final Offset? lastPointerPos;
  final double brushSize;
  final bool isAddMode;

  MaskOverlayPainter({
    required this.mask,
    required this.showRubyOverlay,
    this.lastPointerPos,
    required this.brushSize,
    required this.isAddMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    if (showRubyOverlay) {
      // Draw semi-transparent ruby red / emerald green mask over excluded/included regions
      final maskPaint = Paint()..style = PaintingStyle.fill;

      final cellW = size.width / mask.width;
      final cellH = size.height / mask.height;

      // Sample a coarse grid for performance during touch painting
      const step = 2;
      for (int y = 0; y < mask.height; y += step) {
        for (int x = 0; x < mask.width; x += step) {
          final conf = mask.getConfidence(x, y);

          // Highlight unselected (background) with transparent red overlay
          if (conf < 0.5) {
            final alpha = ((1.0 - conf) * 120).round().clamp(0, 150);
            maskPaint.color = Color.fromARGB(alpha, 239, 68, 68);
            canvas.drawRect(Rect.fromLTWH(x * cellW, y * cellH, cellW * step, cellH * step), maskPaint);
          } else {
            final alpha = (conf * 70).round().clamp(0, 90);
            maskPaint.color = Color.fromARGB(alpha, 16, 185, 129);
            canvas.drawRect(Rect.fromLTWH(x * cellW, y * cellH, cellW * step, cellH * step), maskPaint);
          }
        }
      }
    }

    // Draw Live Brush Pointer Circle
    if (lastPointerPos != null) {
      final brushPaint = Paint()
        ..color = isAddMode ? const Color(0xFF10B981) : const Color(0xFFEF4444)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(lastPointerPos!, brushSize, brushPaint);

      final centerDotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(lastPointerPos!, 2.5, centerDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
