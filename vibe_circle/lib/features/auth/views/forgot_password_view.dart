import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../controllers/forgot_password_controller.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      header: AppHeader(
        title: 'Reset password',
        subtitle: 'We will email you a secure reset link.',
        onBack: () => Get.back(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppField(
            label: 'Email',
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            placeholder: 'you@example.com',
          ),
          const SizedBox(height: 16.0),
          Obx(() => AppButton(
                title: 'Send reset link',
                loading: controller.sending.value,
                disabled: !controller.emailController.text.contains('@') || controller.sending.value,
                onPressed: () => controller.sendResetLink(),
              )),
        ],
      ),
    );
  }
}
