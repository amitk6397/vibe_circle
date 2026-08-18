import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../controllers/notifications_controller.dart';
import '../../../routes/app_routes.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  void _removeNotification(dynamic item) {
    final String id = item['id'].toString();
    Get.defaultDialog(
      title: 'Delete notification?',
      middleText: 'This notification will be removed permanently.',
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.danger,
      onConfirm: () async {
        Get.back();
        try {
          await controller.removeNotification(id);
        } catch (_) {}
      },
    );
  }

  void _onNotificationTap(dynamic item) {
    controller.markAsRead(item['id'].toString());
    final String type = item['type'] ?? '';
    final data = item['data'] ?? {};

    if (type.contains('chat') && data['chatId'] != null) {
      Get.toNamed(AppRoutes.PRIVATE_CHAT, arguments: {
        'chatId': data['chatId'].toString(),
        'name': data['name'] ?? 'User',
      });
    } else if (type.contains('follow') || type.contains('connection')) {
      Get.toNamed(AppRoutes.CONNECTION_REQUEST);
    } else if (data['postId'] != null) {
      Get.toNamed(AppRoutes.POST_DETAILS, arguments: {
        'postId': data['postId'].toString(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      header: AppHeader(
        title: 'Notifications',
        onBack: () => Get.back(),
        right: TextButton(
          onPressed: () => controller.markAllAsRead(),
          child: const Text(
            'Read all',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13.0),
          ),
        ),
      ),
      child: Obx(() {
        return controller.loading.value
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...controller.items.map((item) {
                    final String title = item['title'] ?? 'Alert';
                    final String body = item['body'] ?? '';
                    final bool isRead = item['is_read'] ?? false;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0, left: 16.0, right: 16.0),
                      child: AppCard(
                        borderColor: isRead ? Colors.transparent : AppColors.primary,
                        onPressed: () => _onNotificationTap(item),
                        child: Row(
                          children: [
                            Container(
                              width: 38.0,
                              height: 38.0,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.notifications, color: AppColors.primary, size: 20.0),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: AppColors.text,
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    body,
                                    style: const TextStyle(color: AppColors.text, fontSize: 12.5),
                                  ),
                                  const SizedBox(height: 4.0),
                                  const Text(
                                    'Recent',
                                    style: TextStyle(color: AppColors.muted, fontSize: 10.0),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18.0),
                              onPressed: () => _removeNotification(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (!controller.loading.value && controller.items.isEmpty)
                    const AppEmptyState(
                      icon: Icons.notifications_off_outlined,
                      title: 'All caught up',
                      text: 'New connection, message, circle, and system alerts will appear here.',
                    ),
                ],
              );
      }),
    );
  }
}

