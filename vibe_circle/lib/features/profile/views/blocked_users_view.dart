import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../discovery/controllers/discovery_controller.dart';
import '../controllers/profile_controller.dart';
import '../../discovery/models/person.dart';

class BlockedUsersView extends GetView<ProfileController> {
  const BlockedUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final DiscoveryController discoveryController = Get.find<DiscoveryController>();

    return AppScreen(
      header: AppHeader(
        title: 'Blocked users',
        subtitle: 'Blocked accounts cannot contact or discover you.',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Obx(() {
          final List<String> blockedIds = authController.blockedUsers;
          final List<Person> blockedPeople = discoveryController.people.where((p) => blockedIds.contains(p.id)).toList();

          return blockedPeople.isNotEmpty
              ? Column(
                  children: blockedPeople.map((person) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: AppCard(
                        child: Row(
                          children: [
                            AppAvatar(
                              name: person.name,
                              avatarUrl: person.avatarUrl,
                              size: 44.0,
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Text(
                                person.name,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            AppButton(
                              title: 'Unblock',
                              compact: true,
                              tone: AppButtonTone.secondary,
                              onPressed: () => controller.unblockUser(person.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                )
              : const AppEmptyState(
                  icon: Icons.shield_outlined,
                  title: 'No blocked users',
                  text: 'Accounts you block will appear here.',
                );
        }),
      ),
    );
  }
}

