import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../routes/app_pages.dart';
import '../controllers/wizard_controller.dart';
import '../widgets/step1_add_photo.dart';
import '../widgets/step2_clean_photo.dart';
import '../widgets/step3_select_person.dart';
import '../widgets/step4_choose_background.dart';
import '../widgets/step5_adjust_photo.dart';
import '../widgets/step6_choose_size.dart';
import '../widgets/step7_print_layout.dart';
import '../widgets/step8_save_share.dart';
import '../widgets/wizard_progress_bar.dart';

class WizardView extends GetView<WizardController> {
  const WizardView({super.key});

  Widget _buildCurrentStepView(int step) {
    switch (step) {
      case 1:
        return const Step1AddPhoto();
      case 2:
        return const Step2CleanPhoto();
      case 3:
        return const Step3SelectPerson();
      case 4:
        return const Step4Background();
      case 5:
        return const Step5AdjustPhoto();
      case 6:
        return const Step6ChooseSize();
      case 7:
        return const Step7PrintLayout();
      case 8:
        return const Step8SaveShare();
      default:
        return const Step1AddPhoto();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final step = controller.currentStep.value;

      return Scaffold(
        backgroundColor: context.bgScaffold,
        appBar: AppBar(
          backgroundColor: context.bgSurface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              step == 8 ? Icons.home_rounded : Icons.arrow_back_ios_new_rounded,
              color: context.textPrimaryColor,
              size: 20,
            ),
            onPressed: () {
              if (step == 8) {
                Get.offAllNamed(Routes.HOME);
              } else {
                controller.previousStep();
              }
            },
          ),
          title: Text(
            step == 8 ? 'Photo Ready 🎉' : 'Passport Photo Maker',
            style: TextStyle(color: context.textPrimaryColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            if (step < 8)
              IconButton(
                tooltip: 'Exit to Home',
                icon: Icon(Icons.close_rounded, color: context.textSecondaryColor),
                onPressed: () => Get.offAllNamed(Routes.HOME),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(step <= 7 ? 46.0 : 0.0),
            child: WizardProgressBar(currentStep: step, totalSteps: 7),
          ),
        ),
        body: Stack(
          children: [
            // Active Step Content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: SizedBox(
                key: ValueKey<int>(step),
                child: _buildCurrentStepView(step),
              ),
            ),

            // Friendly Processing Overlay
            if (controller.isProcessing.value)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: context.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.accent),
                        const SizedBox(height: 16),
                        Obx(
                          () => Text(
                            controller.processingMessage.value.isNotEmpty
                                ? controller.processingMessage.value
                                : 'Processing...',
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
