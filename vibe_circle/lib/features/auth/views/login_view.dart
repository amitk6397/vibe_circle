import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../routes/app_routes.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      header: AppHeader(
        title: 'Welcome back',
        subtitle: 'Your circle is waiting.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero logo block
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56.0,
                height: 56.0,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18.0),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.people,
                  size: 30.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Log in to VibeCircle',
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Your email stays private and is never displayed publicly.',
                style: AppTextStyles.muted,
              ),
            ],
          ),
          const SizedBox(height: 24.0),

          // Email Field
          AppField(
            label: 'Email',
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            placeholder: 'you@example.com',
          ),
          const SizedBox(height: 16.0),

          // Password Field
          AppField(
            label: 'Password',
            controller: controller.passwordController,
            secureTextEntry: true,
            placeholder: 'At least 8 characters',
          ),
          const SizedBox(height: 12.0),

          // Error box if error state exists
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

          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Get.toNamed(AppRoutes.FORGOT_PASSWORD),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text(
                'Forgot password?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0),

          // Buttons
          Obx(() => AppButton(
                title: 'Log in',
                loading: controller.loading.value,
                onPressed: () => controller.login(),
              )),
          const SizedBox(height: 12.0),
          AppButton(
            title: 'Create a new account',
            tone: AppButtonTone.secondary,
            onPressed: () => Get.toNamed(AppRoutes.REGISTER),
          ),
          const SizedBox(height: 24.0),

          // Legal info text
          const Text(
            'By continuing, you agree to the Terms, Privacy Policy, and 18+ Community Rules.',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
