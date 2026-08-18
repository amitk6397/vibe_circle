import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../controllers/chat_controller.dart';
import '../../../routes/app_routes.dart';

class MessageRequestsView extends GetView<ChatController> {
  const MessageRequestsView({super.key});

  void _act(dynamic item, String action) async {
    final String requestId = item['id'].toString();
    try {
      await controller.respondMessageRequest(requestId, action);
      if (action == 'accept') {
        final conversationId = item['conversation_id'] ?? item['chat_id'];
        if (conversationId != null) {
          Get.toNamed(AppRoutes.PRIVATE_CHAT, arguments: {
            'chatId': conversationId.toString(),
            'name': item['sender_name'] ?? 'User',
            'personId': item['sender_id']?.toString(),
          });
        }
      }
    } catch (e) {
      Get.snackbar('Action failed', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    controller.loadMessageRequests();

    return AppScreen(
      header: AppHeader(
        title: 'Message requests',
        subtitle: 'Members who want to connect with you.',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Obx(() {
          final pendingList = controller.messageRequestsList.where((x) => x['status'] == 'pending').toList();

          return controller.loading.value
              ? const Center(child: CircularProgressIndicator())
              : pendingList.isNotEmpty
                  ? Column(
                      children: pendingList.map((item) {
                        final String sender = item['sender_name'] ?? 'User';
                        final String intro = item['introduction'] ?? 'Hi, I would like to connect.';
                        final num dur = item['duration_minutes'] ?? 0;
                        final num price = item['total_price_coins'] ?? 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      sender,
                                      style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14.5),
                                    ),
                                    if (price > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        child: Text(
                                          '🪙 $price coins',
                                          style: const TextStyle(color: Color(0xFFFF9800), fontSize: 10.0, fontWeight: FontWeight.w900),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6.0),
                                Text(
                                  intro,
                                  style: const TextStyle(color: AppColors.text, fontSize: 13.0, height: 1.3),
                                ),
                                const SizedBox(height: 6.0),
                                Text(
                                  'Requested duration: $dur minutes',
                                  style: const TextStyle(color: AppColors.muted, fontSize: 11.0),
                                ),
                                const SizedBox(height: 12.0),
                                Row(
                                  children: [
                                    Expanded(
                                      child: AppButton(
                                        title: 'Ignore',
                                        tone: AppButtonTone.secondary,
                                        onPressed: () => _act(item, 'reject'),
                                      ),
                                    ),
                                    const SizedBox(width: 10.0),
                                    Expanded(
                                      child: AppButton(
                                        title: 'Accept',
                                        onPressed: () => _act(item, 'accept'),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  : const AppEmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: 'No pending requests',
                      text: 'When users send you message requests, they will show here.',
                    );
        }),
      ),
    );
  }
}

