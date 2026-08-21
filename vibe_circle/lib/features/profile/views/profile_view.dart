import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../community/controllers/community_controller.dart';
import '../controllers/profile_controller.dart';
import '../../../routes/app_routes.dart';

class ProfileView extends GetView<AuthController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final communityController = Get.find<CommunityController>();
    final profileController = Get.find<ProfileController>();

    final menu = [
      [Icons.favorite_border, 'Interests & languages', AppRoutes.INTERESTS_LANGUAGES],
      [Icons.card_giftcard, 'Daily Login Rewards 🎁', AppRoutes.DAILY_REWARDS],
      [Icons.share, 'Refer & Earn 🪙', AppRoutes.REFERRAL],
      [Icons.history, 'My activity', AppRoutes.MY_ACTIVITY],
      [Icons.grid_on, 'My creations', AppRoutes.MY_CREATIONS],
      [Icons.people_outline, 'Followers', AppRoutes.CONNECTIONS],
      [Icons.card_membership, 'Subscription plans', AppRoutes.SUBSCRIPTION_PLANS],
      [Icons.account_balance_wallet_outlined, 'Wallet & earnings dashboard', AppRoutes.WALLET],
      [Icons.block_flipped, 'Blocked users', AppRoutes.BLOCKED_USERS],
      [Icons.shield_outlined, 'My reports', AppRoutes.REPORTS],
      [Icons.key_outlined, 'Account management', AppRoutes.ACCOUNT_MANAGEMENT],
    ];

    return AppScreen(
      scroll: false,
      noPadding: true,
      header: AppHeader(
        title: 'Profile',
        right: AppIconButton(
          icon: Icons.settings_outlined,
          onPressed: () => Get.toNamed(AppRoutes.SETTINGS_SUPPORT),
        ),
      ),
      child: Obx(() {
        final profile = controller.profile.value;
        if (profile == null) {
          return const Center(child: Text('Profile not loaded.'));
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Hero Card
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: Column(
                  children: [
                    // Avatar
                    AppAvatar(
                      name: profile.name,
                      avatarUrl: profile.avatarUrl,
                      size: 90.0,
                    ),
                    const SizedBox(height: 12.0),
                    // Name & Handle
                    Text(
                      profile.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '@${profile.username ?? 'user'}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13.0,
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Get.toNamed(AppRoutes.MY_CREATIONS),
                            child: Column(
                              children: [
                                Text(
                                  '${communityController.posts.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                const Text(
                                  'Posts',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 1.0,
                          height: 30.0,
                          color: AppColors.border,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${communityController.joinedCommunities.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              const Text(
                                'Communities',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1.0,
                          height: 30.0,
                          color: AppColors.border,
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Get.toNamed(AppRoutes.CONNECTIONS),
                            child: Column(
                              children: [
                                Text(
                                  '${profileController.connections.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                const Text(
                                  'Followers',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            title: 'View Profile',
                            tone: AppButtonTone.secondary,
                            icon: Icons.person_outline,
                            onPressed: () => Get.toNamed(AppRoutes.MY_PROFILE),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: AppButton(
                            title: 'Edit Profile',
                            tone: AppButtonTone.primary,
                            icon: Icons.create_outlined,
                            onPressed: () => Get.toNamed(AppRoutes.EDIT_PROFILE),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // Menu items
              ...menu.map((item) {
                final icon = item[0] as IconData;
                final title = item[1] as String;
                final route = item[2] as String;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  child: ListTile(
                    leading: Icon(icon, color: AppColors.primary, size: 20.0),
                    title: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: AppColors.muted,
                      size: 18.0,
                    ),
                    onTap: () => Get.toNamed(route),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 2.0,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }
}
