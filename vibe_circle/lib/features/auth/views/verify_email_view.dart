import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../controllers/verify_email_controller.dart';

class VerifyEmailView extends GetView<VerifyEmailController> {
  const VerifyEmailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AppScreen(
            header: AppHeader(
              title: 'Verify email',
              subtitle: 'We sent a code to ${controller.email.value}',
              onBack: () => Get.back(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Mail icon
                Center(
                  child: Container(
                    width: 128.0,
                    height: 128.0,
                    margin: const EdgeInsets.only(top: 35.0, bottom: 20.0),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(42.0),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.mail,
                      size: 54.0,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                // OTP Field
                AppField(
                  label: '6-digit code',
                  controller: controller.codeController,
                  keyboardType: TextInputType.number,
                  placeholder: '123456',
                ),
                const SizedBox(height: 16.0),

                // Verify Button
                Obx(() => AppButton(
                      title: 'Verify and continue',
                      loading: controller.verifying.value,
                      disabled: controller.codeController.text.length != 6 || controller.verifying.value,
                      onPressed: () => controller.verify(),
                    )),
                const SizedBox(height: 12.0),

                // Resend Button
                Obx(() => AppButton(
                      title: controller.cooldown.value > 0 ? 'Resend OTP in ${controller.cooldown.value}s' : 'Resend OTP',
                      tone: AppButtonTone.ghost,
                      loading: controller.sending.value,
                      disabled: controller.sending.value || controller.cooldown.value > 0,
                      onPressed: () => controller.sendOtp(),
                    )),
                const SizedBox(height: 16.0),

                // Error Box
                Obx(() {
                  final err = controller.error.value;
                  if (err.isEmpty) return const SizedBox.shrink();
                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          err,
                          style: AppTextStyles.error,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                    ],
                  );
                }),
              ],
            ),
          ),
          
          // Floating Snackbar
          Obx(() {
            final snack = controller.snackbar.value;
            if (snack.isEmpty) return const SizedBox.shrink();
            return Positioned(
              left: 16.0,
              right: 16.0,
              bottom: 20.0,
              child: Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.vpn_key_outlined,
                      color: Colors.white,
                      size: 20.0,
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        snack,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
