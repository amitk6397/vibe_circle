import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_pill.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../community/controllers/community_controller.dart';
import '../controllers/profile_controller.dart';
import '../../../routes/app_routes.dart';

class MyProfileView extends GetView<AuthController> {
  const MyProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final communityController = Get.find<CommunityController>();

    return AppScreen(
      header: AppHeader(
        title: 'My profile',
        onBack: () => Get.back(),
        right: AppButton(
          title: 'Edit',
          compact: true,
          tone: AppButtonTone.secondary,
          onPressed: () => Get.toNamed(AppRoutes.EDIT_PROFILE),
        ),
      ),
      child: Obx(() {
        final profile = controller.profile.value;
        if (profile == null) {
          return const Center(child: Text('Profile not loaded.'));
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    AppAvatar(
                      name: profile.name,
                      avatarUrl: profile.avatarUrl,
                      size: 96.0,
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      profile.name,
                      style: const TextStyle(color: Colors.white, fontSize: 22.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '@${profile.username ?? 'user'} · ${profile.city ?? 'Local'}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 13.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                AppCard(
                  child: Text(
                    profile.bio!,
                    style: const TextStyle(color: AppColors.text, fontSize: 13.5, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16.0),
              ],

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.MY_CREATIONS),
                      child: _buildStat('${communityController.posts.length}', 'Posts'),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.CONNECTIONS),
                      child: Obx(() {
                        final profileCtrl = Get.isRegistered<ProfileController>()
                            ? Get.find<ProfileController>()
                            : Get.put(ProfileController());
                        return _buildStat('${profileCtrl.connections.length}', 'Followers');
                      }),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: _buildStat('${communityController.joinedCommunities.length}', 'Communities'),
                  ),
                ],
              ),
              const SizedBox(height: 22.0),

              const Text('Badges', style: AppTextStyles.title),
              const SizedBox(height: 10.0),
              const Row(
                children: [
                  AppPill(label: 'Helpful human', selected: true),
                  SizedBox(width: 8.0),
                  AppPill(label: 'Good listener', selected: false),
                  SizedBox(width: 8.0),
                  AppPill(label: 'Early member', selected: false),
                ],
              ),
              const SizedBox(height: 30.0),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(color: AppColors.text, fontSize: 24.0, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4.0),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 11.0),
          ),
        ],
      ),
    );
  }
}
