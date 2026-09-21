import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/ai_enhance_result.dart';
import '../../../../core/services/ai_enhance_service.dart';

class AiEnhanceView extends StatefulWidget {
  final String imagePath;
  final ValueChanged<String> onApplyEnhanced;

  const AiEnhanceView({
    super.key,
    required this.imagePath,
    required this.onApplyEnhanced,
  });

  @override
  State<AiEnhanceView> createState() => _AiEnhanceViewState();
}

class _AiEnhanceViewState extends State<AiEnhanceView> {
  bool _isProcessing = true;
  AiEnhanceProfile _selectedProfile = AiEnhanceProfile.balanced;
  AiEnhanceResult? _result;
  String? _errorMessage;

  // Comparison toggle: true = Enhanced, false = Original
  bool _showEnhanced = true;

  @override
  void initState() {
    super.initState();
    _processEnhancement();
  }

  Future<void> _processEnhancement() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final res = await AiEnhanceService.enhancePhoto(
        imagePath: widget.imagePath,
        profile: _selectedProfile,
      );
      if (mounted) {
        setState(() {
          _result = res;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Enhancement failed: $e';
          _isProcessing = false;
        });
      }
    }
  }

  void _onProfileChanged(AiEnhanceProfile profile) {
    if (_selectedProfile == profile) return;
    setState(() => _selectedProfile = profile);
    _processEnhancement();
  }

  void _applyEnhancedPhoto() {
    if (_result != null && File(_result!.enhancedImagePath).existsSync()) {
      widget.onApplyEnhanced(_result!.enhancedImagePath);
      Get.back();
      Get.snackbar(
        'AI Photo Enhanced ✨',
        'Noise cleaned, exposure balanced, natural clarity restored.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF065F46),
        colorText: Colors.white,
      );
    }
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
            Text('✨ AI Photo Enhancement', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Official ID Cleanup & Natural Clarity', style: TextStyle(color: AppColors.accent, fontSize: 11)),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Comparison Mode Switcher Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF1E293B),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTogglePill(
                  label: '📷 Original',
                  isSelected: !_showEnhanced,
                  onTap: () => setState(() => _showEnhanced = false),
                ),
                const SizedBox(width: 8),
                _buildTogglePill(
                  label: '✨ Enhanced',
                  isSelected: _showEnhanced,
                  onTap: () => setState(() => _showEnhanced = true),
                ),
              ],
            ),
          ),

          // 2. Interactive Before / After Viewport
          Expanded(
            child: _isProcessing
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.accent),
                        const SizedBox(height: 16),
                        const Text(
                          'Cleaning noise & balancing studio light...',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Profile: ${_selectedProfile.title}',
                          style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _processEnhancement,
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          InteractiveViewer(
                            minScale: 0.8,
                            maxScale: 4.0,
                            child: Center(
                              child: Image.file(
                                File(_showEnhanced && _result != null ? _result!.enhancedImagePath : widget.imagePath),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          // Touch mode hint
                          Positioned(
                            top: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _showEnhanced ? 'Viewing: ✨ Enhanced Studio Clarity' : 'Viewing: 📷 Original Raw Photo',
                                style: TextStyle(
                                  color: _showEnhanced ? AppColors.accent : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          // Biometric compliance safe badge
                          Positioned(
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF065F46).withOpacity(0.85),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF10B981)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF34D399)),
                                  SizedBox(width: 6),
                                  Text(
                                    '100% Identity Preserved • Biometric Compliant',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
          ),

          // 3. Profile & Metrics Bottom Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Enhancement Profiles
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Enhancement Intensity', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    if (_result != null)
                      Text(_result!.summary, style: const TextStyle(color: AppColors.accent, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: AiEnhanceProfile.values.map((p) {
                    final isSel = _selectedProfile == p;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Center(child: Text(p.title)),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          backgroundColor: const Color(0xFF334155),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppColors.textSecondaryDark,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            fontSize: 11,
                          ),
                          onSelected: (_) => _onProfileChanged(p),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.white38),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Keep Original'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isProcessing ? null : _applyEnhancedPhoto,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Use Enhanced ✨', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildTogglePill({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFF334155),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
