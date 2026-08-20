import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../controllers/register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      header: AppHeader(
        title: 'Create account',
        subtitle: 'Only four details to begin.',
        onBack: () => Get.back(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Photo Selector
          Center(
            child: GestureDetector(
              onTap: () => controller.pickAvatar(),
              child: Column(
                children: [
                  Obx(() {
                    final avatar = controller.avatar.value;
                    return Container(
                      width: 92.0,
                      height: 92.0,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        image: avatar != null
                            ? DecorationImage(
                                image: FileImage(File(avatar.uri)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: avatar == null
                          ? const Icon(
                              Icons.camera_alt,
                              size: 30.0,
                              color: AppColors.primary,
                            )
                          : null,
                    );
                  }),
                  const SizedBox(height: 8.0),
                  const Text(
                    'Tap to choose a profile photo',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20.0),

          // Fields
          AppField(
            label: 'Name',
            controller: controller.nameController,
            placeholder: 'Your name',
          ),
          const SizedBox(height: 16.0),

          AppField(
            label: 'Age',
            controller: controller.ageController,
            keyboardType: TextInputType.number,
            placeholder: '18 or older',
          ),
          const SizedBox(height: 16.0),

          AppField(
            label: 'Email',
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            placeholder: 'Private email',
          ),
          const SizedBox(height: 16.0),

          AppField(
            label: 'Password',
            controller: controller.passwordController,
            secureTextEntry: true,
            placeholder: 'At least 8 characters',
          ),
          const SizedBox(height: 16.0),

          AppField(
            label: 'Referral Code',
            controller: controller.referralController,
            placeholder: '8-character code (Optional)',
          ),
          const SizedBox(height: 16.0),

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
                const SizedBox(height: 16.0),
              ],
            );
          }),

          // Secure notice box
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock,
                  size: 20.0,
                  color: AppColors.success,
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    'Your email, password, and exact date of birth are never shown on your profile.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          // Button
          Obx(() => AppButton(
                title: 'Continue',
                loading: controller.loading.value,
                onPressed: () => controller.register(),
              )),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }
}
