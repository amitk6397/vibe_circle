import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../controllers/chat_controller.dart';
import '../../../routes/app_routes.dart';

class ArchivedChatsView extends GetView<ChatController> {
  const ArchivedChatsView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.loadArchivedConversations();

    return AppScreen(
      header: AppHeader(
        title: 'Archived chats',
        onBack: () => Get.back(),
      ),
      child: Obx(() {
        if (controller.loading.value && controller.archivedChatsList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value.isNotEmpty) {
          return AppEmptyState(
            icon: Icons.cloud_off,
            title: 'Archived chats unavailable',
            text: controller.error.value,
            action: 'Retry',
            onAction: () => controller.loadArchivedConversations(),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...controller.archivedChatsList.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0, left: 16.0, right: 16.0),
                child: AppCard(
                  onPressed: () => Get.toNamed(
                    AppRoutes.PRIVATE_CHAT,
                    arguments: {
                      'chatId': item['id'].toString(),
                      'name': item['name'],
                      'personId': item['personId'],
                      'avatarUrl': item['avatarUrl'],
                    },
                  ),
                  child: Row(
                    children: [
                      AppAvatar(
                        name: item['name'],
                        avatarUrl: item['avatarUrl'],
                        size: 40.0,
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              item['lastMessage'] ?? 'Open conversation',
                              style: const TextStyle(color: AppColors.muted, fontSize: 12.0),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (controller.archivedChatsList.isEmpty)
              const AppEmptyState(
                icon: Icons.archive_outlined,
                title: 'No archived chats',
                text: 'Nothing is stored in this section yet.',
              ),
          ],
        );
      }),
    );
  }
}

