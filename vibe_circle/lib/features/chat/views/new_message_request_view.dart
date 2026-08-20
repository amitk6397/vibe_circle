import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_field.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_pill.dart';
import '../controllers/chat_controller.dart';
import '../../../routes/app_routes.dart';

class NewMessageRequestView extends StatelessWidget {
  const NewMessageRequestView({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController chatController = Get.isRegistered<ChatController>()
        ? Get.find<ChatController>()
        : Get.put(ChatController());

    final TextEditingController introController = TextEditingController();
    final args = Get.arguments as Map<String, dynamic>?;
    final String personId = args?['personId'] ?? '';
    final String name = args?['name'] ?? 'User';

    final RxInt duration = 10.obs;
    final RxBool saving = false.obs;
    final RxInt textLength = 0.obs;
    final RxInt coinsPerMinute = ((args?['chatPrice'] ?? 0) as num).toInt().obs;
    final RxList<int> durationOptions = <int>[5, 10, 15, 30].obs;

    // Load Pricing
    chatController.getCoinPricing().then((data) {
      if (data['chatCoinsPerMinute'] != null) {
        coinsPerMinute.value = (data['chatCoinsPerMinute'] as num).toInt();
      }
      if (data['chatDurationOptions'] is List) {
        durationOptions.assignAll((data['chatDurationOptions'] as List).map((e) => (e as num).toInt()).toList());
      }
    }).catchError((_) {});

    void send() async {
      final text = introController.text.trim();
      if (text.isEmpty) {
        Get.defaultDialog(
          title: 'Add an introduction',
          middleText: 'Write a short, respectful reason for reaching out.',
          textConfirm: 'OK',
          confirmTextColor: Colors.white,
          buttonColor: AppColors.primary,
          onConfirm: () => Get.back(),
        );
        return;
      }

      saving.value = true;
      try {
        await chatController.sendMessageRequest(personId, text, duration.value);
        Get.defaultDialog(
          title: 'Request sent',
          middleText: '$name can accept, reject, block, or report this request.',
          textConfirm: 'OK',
          confirmTextColor: Colors.white,
          buttonColor: AppColors.primary,
          onConfirm: () {
            Get.back();
            Get.back();
          },
        );
      } catch (e) {
        Get.defaultDialog(
          title: 'Coins required',
          middleText: e.toString().contains('coins')
              ? 'Please add enough coins to start this paid chat.'
              : e.toString(),
          textCancel: 'Cancel',
          textConfirm: 'View plans & coins',
          confirmTextColor: Colors.white,
          buttonColor: AppColors.primary,
          onConfirm: () {
            Get.back();
            Get.toNamed(AppRoutes.SUBSCRIPTION_PLANS);
          },
        );
      } finally {
        saving.value = false;
      }
    }

    return AppScreen(
      header: AppHeader(
        title: 'Message request',
        subtitle: 'Introduce yourself to $name',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Notice card
            const AppCard(
              child: Text(
                'Your first message is sent as a request. Media, links, and calls remain unavailable until it is accepted.',
                style: TextStyle(color: AppColors.text, fontSize: 13.0, height: 1.4),
              ),
            ),
            const SizedBox(height: 12.0),

            // Paid settings card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Paid private chat', style: AppTextStyles.h2),
                  const SizedBox(height: 4.0),
                  Obx(() => Text(
                    '${coinsPerMinute.value} coins/minute · choose duration',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13.0),
                  )),
                  const SizedBox(height: 12.0),
                  Obx(() => Wrap(
                    spacing: 8.0,
                    children: durationOptions.map((mins) {
                      final isSelected = duration.value == mins;
                      return AppPill(
                        label: '$mins min',
                        selected: isSelected,
                        onPressed: () => duration.value = mins,
                      );
                    }).toList(),
                  )),
                  const SizedBox(height: 12.0),
                  Obx(() {
                    final int totalCoins = coinsPerMinute.value * duration.value;
                    return Text(
                      'Total hold: $totalCoins coins',
                      style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 13.5),
                    );
                  }),
                  const SizedBox(height: 4.0),
                  Text(
                    'Charged only when $name accepts. An active plan and enough coins are required.',
                    style: const TextStyle(color: AppColors.muted, fontSize: 11.0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // Introduction Input
            AppField(
              label: 'Introduction',
              placeholder: 'Hi! I noticed we both enjoy...',
              controller: introController,
              maxLines: 4,
              onChanged: (val) => textLength.value = val.length,
            ),
            const SizedBox(height: 4.0),
            Obx(() => Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${textLength.value}/300 characters',
                style: const TextStyle(color: AppColors.muted, fontSize: 11.0),
              ),
            )),
            const SizedBox(height: 20.0),

            // Submit Button
            Obx(() => AppButton(
              title: 'Send paid request',
              loading: saving.value,
              disabled: saving.value || textLength.value > 300,
              onPressed: send,
            )),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }
}
