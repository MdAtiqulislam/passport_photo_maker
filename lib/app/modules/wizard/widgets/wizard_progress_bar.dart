import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class WizardProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const WizardProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 7,
  });

  String _getStepName(int step) {
    switch (step) {
      case 1:
        return 'Add Photo';
      case 2:
        return 'Clean Photo';
      case 3:
        return 'Select Person';
      case 4:
        return 'Choose Background';
      case 5:
        return 'Adjust Photo';
      case 6:
        return 'Choose Size';
      case 7:
        return 'Print Layout';
      case 8:
        return 'Completed 🎉';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentStep > totalSteps) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: context.bgSurface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step $currentStep of $totalSteps',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _getStepName(currentStep),
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Dots & Connector Lines
          Row(
            children: List.generate(totalSteps * 2 - 1, (index) {
              if (index.isEven) {
                // Step Dot
                final stepIndex = (index ~/ 2) + 1;
                final isCompleted = stepIndex < currentStep;
                final isCurrent = stepIndex == currentStep;

                return Container(
                  width: isCurrent ? 14 : 10,
                  height: isCurrent ? 14 : 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCurrent
                        ? AppColors.primary
                        : (isCompleted ? const Color(0xFF10B981) : (context.isDarkTheme ? const Color(0xFF475569) : const Color(0xFFCBD5E1))),
                    border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 7, color: Colors.white)
                      : null,
                );
              } else {
                // Connector Line
                final precedingStep = (index ~/ 2) + 1;
                final isPassed = precedingStep < currentStep;

                return Expanded(
                  child: Container(
                    height: 2,
                    color: isPassed
                        ? const Color(0xFF10B981)
                        : (context.isDarkTheme ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                );
              }
            }),
          ),
        ],
      ),
    );
  }
}
