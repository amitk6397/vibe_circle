import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_data.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_pill.dart';
import '../controllers/basic_profile_controller.dart';
import '../controllers/auth_controller.dart';

class BasicProfileView extends GetView<BasicProfileController> {
  const BasicProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final currentAvatarUri = authController.profile.value?.avatarUrl;

    return AppScreen(
      header: const AppHeader(
        title: 'Make it yours',
        subtitle: 'Optional details improve recommendations.',
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
                            : (currentAvatarUri != null && currentAvatarUri.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(currentAvatarUri),
                                    fit: BoxFit.cover,
                                  )
                                : null),
                      ),
                      alignment: Alignment.center,
                      child: avatar == null && (currentAvatarUri == null || currentAvatarUri.isEmpty)
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

          // Username Field
          AppField(
            label: 'Username',
            controller: controller.usernameController,
            placeholder: 'unique.username',
          ),
          const SizedBox(height: 20.0),

          // Choose Interests
          const Text('Choose interests', style: AppTextStyles.title),
          const SizedBox(height: 8.0),
          Obx(() => Wrap(
                spacing: 9.0,
                runSpacing: 9.0,
                children: AppData.interests.map((x) {
                  return AppPill(
                    label: x,
                    selected: controller.selectedInterests.contains(x),
                    onPressed: () => controller.toggleInterest(x),
                  );
                }).toList(),
              )),
          const SizedBox(height: 20.0),

          // Languages
          const Text('Languages', style: AppTextStyles.title),
          const SizedBox(height: 8.0),
          Obx(() => Wrap(
                spacing: 9.0,
                runSpacing: 9.0,
                children: AppData.languages.map((x) {
                  return AppPill(
                    label: x,
                    selected: controller.selectedLanguages.contains(x),
                    onPressed: () => controller.toggleLanguage(x),
                  );
                }).toList(),
              )),
          const SizedBox(height: 20.0),

          // Date of birth
          AppField(
            label: 'Date of birth (optional)',
            controller: controller.dobController,
            placeholder: 'YYYY-MM-DD',
          ),
          const SizedBox(height: 16.0),

          // Gender
          AppField(
            label: 'Gender (optional)',
            controller: controller.genderController,
            placeholder: 'Your gender',
          ),
          const SizedBox(height: 20.0),

          // Conversation Topics
          const Text('Conversation topics', style: AppTextStyles.title),
          const SizedBox(height: 8.0),
          Obx(() => Wrap(
                spacing: 9.0,
                runSpacing: 9.0,
                children: AppData.conversationTopics.map((topic) {
                  return AppPill(
                    label: topic,
                    selected: controller.selectedTopics.contains(topic),
                    onPressed: () => controller.toggleTopic(topic),
                  );
                }).toList(),
              )),
          const SizedBox(height: 20.0),

          // Errors
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

          // Finish Button
          Obx(() => AppButton(
                title: 'Open VibeCircle',
                loading: controller.saving.value,
                disabled: controller.saving.value,
                onPressed: () => controller.finish(),
              )),
          const SizedBox(height: 24.0),
        ],
      ),
    );
  }
}
