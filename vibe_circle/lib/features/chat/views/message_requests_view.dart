import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../controllers/chat_controller.dart';
import '../models/message_request_model.dart';
import '../../../routes/app_routes.dart';

class MessageRequestsView extends GetView<ChatController> {
  const MessageRequestsView({super.key});

  void _act(MessageRequest item, String action) async {
    try {
      await controller.respondMessageRequest(item.id, action);
      if (action == 'accept') {
        final conversationId = item.conversationId;
        if (conversationId != null && conversationId.isNotEmpty) {
          Get.toNamed(AppRoutes.PRIVATE_CHAT, arguments: {
            'chatId': conversationId,
            'name': item.senderName,
            'personId': item.senderId,
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
        subtitle: 'Review introductions before starting a conversation',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Obx(() {
          final List<MessageRequest> pendingList = controller.messageRequestsList
              .map((raw) => raw is MessageRequest ? raw : MessageRequest.fromJson(raw as Map<String, dynamic>))
              .where((x) => x.status == 'pending')
              .toList();

          if (controller.loading.value && pendingList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (pendingList.isEmpty) {
            return const AppEmptyState(
              icon: Icons.mail_outline,
              title: 'No message requests',
              text: 'New introductions will appear here.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: pendingList.map((item) {
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
                            item.senderName,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.bold,
                              fontSize: 15.0,
                            ),
                          ),
                          if (item.totalPriceCoins > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                '🪙 ${item.totalPriceCoins} coins',
                                style: const TextStyle(
                                  color: Color(0xFFFF9800),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        item.introduction.isNotEmpty ? item.introduction : 'Hi, I would like to connect.',
                        style: const TextStyle(color: AppColors.text, fontSize: 13.5, height: 1.3),
                      ),
                      if (item.durationMinutes > 0) ...[
                        const SizedBox(height: 6.0),
                        Text(
                          'Paid chat: ${item.durationMinutes} min${item.chatPricePerMinute > 0 ? ' · ${item.chatPricePerMinute} coins/min' : ''} · ${item.totalPriceCoins} coins total.',
                          style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
                        ),
                      ],
                      const SizedBox(height: 14.0),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              title: 'Accept',
                              compact: true,
                              onPressed: () => _act(item, 'accept'),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: AppButton(
                              title: 'Reject',
                              compact: true,
                              tone: AppButtonTone.secondary,
                              onPressed: () => _act(item, 'reject'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4.0),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _act(item, 'block'),
                          child: const Text('Block user', style: TextStyle(color: AppColors.danger, fontSize: 12.0)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ),
    );
  }
}
