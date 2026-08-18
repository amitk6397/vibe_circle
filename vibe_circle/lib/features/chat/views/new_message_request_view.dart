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

class NewMessageRequestView extends StatefulWidget {
  const NewMessageRequestView({super.key});

  @override
  State<NewMessageRequestView> createState() => _NewMessageRequestViewState();
}

class _NewMessageRequestViewState extends State<NewMessageRequestView> {
  final ChatController _chatController = Get.find<ChatController>();
  final TextEditingController _introController = TextEditingController();

  String _personId = '';
  String _name = '';
  int _duration = 10;
  bool _saving = false;

  Map<String, dynamic> _pricing = {
    'chatCoinsPerMinute': 0,
    'chatDurationOptions': [5, 10, 15, 30],
  };

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _personId = args?['personId'] ?? '';
    _name = args?['name'] ?? 'User';
    _pricing['chatCoinsPerMinute'] = args?['chatPrice'] ?? 0;

    _loadPricing();
  }

  void _loadPricing() async {
    try {
      final data = await _chatController.getCoinPricing();
      setState(() {
        _pricing = data;
      });
    } catch (_) {}
  }

  void _send() async {
    final text = _introController.text.trim();
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

    setState(() => _saving = true);
    try {
      await _chatController.sendMessageRequest(_personId, text, _duration);
      Get.defaultDialog(
        title: 'Request sent',
        middleText: '$_name can accept, reject, block, or report this request.',
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
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final num rate = _pricing['chatCoinsPerMinute'] ?? 0;
    final List<dynamic> options = _pricing['chatDurationOptions'] ?? [5, 10, 15, 30];

    return AppScreen(
      header: AppHeader(
        title: 'Message request',
        subtitle: 'Introduce yourself to $_name',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppCard(
              child: Text(
                'Your first message is sent as a request. Media, links, phone numbers, and calls remain '
                'unavailable until it is accepted.',
                style: TextStyle(color: AppColors.text, fontSize: 13.5, height: 1.4),
              ),
            ),
            const SizedBox(height: 16.0),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Paid private chat', style: AppTextStyles.h2),
                  const SizedBox(height: 4.0),
                  Text(
                    '$rate coins/minute · choose duration',
                    style: const TextStyle(color: AppColors.text, fontSize: 13.0),
                  ),
                  const SizedBox(height: 10.0),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: options.map((item) {
                      final minutes = int.parse(item.toString());
                      return AppPill(
                        label: '$minutes min',
                        selected: _duration == minutes,
                        onPressed: () => setState(() => _duration = minutes),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'Total hold: ${rate * _duration} coins',
                    style: const TextStyle(color: AppColors.text, fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Charged only when $_name accepts. An active plan and enough coins are required.',
                    style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            AppField(
              label: 'Introduction',
              controller: _introController,
              placeholder: 'Hi! I noticed we both enjoy...',
              keyboardType: TextInputType.multiline,
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 4.0),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_introController.text.length}/300 characters',
                style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
              ),
            ),
            const SizedBox(height: 20.0),
            AppButton(
              title: 'Send paid request',
              loading: _saving,
              disabled: _saving || _introController.text.length > 300 || _introController.text.trim().isEmpty,
              onPressed: _send,
            ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }
}
