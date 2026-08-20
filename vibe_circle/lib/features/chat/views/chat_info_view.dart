import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../controllers/chat_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../../routes/app_routes.dart';

class ChatInfoView extends StatefulWidget {
  const ChatInfoView({super.key});

  @override
  State<ChatInfoView> createState() => _ChatInfoViewState();
}

class _ChatInfoViewState extends State<ChatInfoView> {
  final ChatController _chatController = Get.find<ChatController>();
  final ProfileController _profileController = Get.find<ProfileController>();

  String _chatId = '';
  String _name = '';
  String _personId = '';
  String? _avatarUrl;

  bool _muted = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _chatId = args?['chatId'] ?? '';
    _name = args?['name'] ?? 'User';
    _personId = args?['personId'] ?? '';
    _avatarUrl = args?['avatarUrl'];
  }

  void _blockUser() {
    if (_personId.isEmpty) {
      Get.defaultDialog(
        title: 'Open profile',
        middleText: 'Open this user\'s profile to block the account.',
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        buttonColor: AppColors.primary,
        onConfirm: () => Get.back(),
      );
      return;
    }

    Get.defaultDialog(
      title: 'Block this user?',
      middleText: 'Messages, calls, suggestions, and visibility will stop.',
      textCancel: 'Cancel',
      textConfirm: 'Block',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.danger,
      onConfirm: () async {
        Get.back();
        await _profileController.reportUser('user', _personId, 'blocked');
        Get.offAllNamed(AppRoutes.MAIN);
      },
    );
  }

  void _reportConversation() {
    Get.bottomSheet(
      Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(20.0),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Report conversation',
                style: TextStyle(color: AppColors.text, fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6.0),
              const Text(
                'Choose a reason for this report. Moderation team will review it.',
                style: TextStyle(color: AppColors.muted, fontSize: 12.0),
              ),
              const SizedBox(height: 16.0),
              ListTile(
                leading: const Icon(Icons.warning_amber, color: AppColors.text),
                title: const Text('Spam or scam', style: TextStyle(color: AppColors.text)),
                onTap: () async {
                  Get.back();
                  await _profileController.reportUser('conversation', _chatId, 'Spam or scam');
                },
              ),
              ListTile(
                leading: const Icon(Icons.gavel, color: AppColors.danger),
                title: const Text('Harassment', style: TextStyle(color: AppColors.danger)),
                onTap: () async {
                  Get.back();
                  await _profileController.reportUser('conversation', _chatId, 'Harassment');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      header: AppHeader(
        title: 'Chat information',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User profile header card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                children: [
                  AppAvatar(
                    name: _name,
                    avatarUrl: _avatarUrl,
                    size: 86.0,
                  ),
                  const SizedBox(height: 12.0),
                  Text(_name, style: AppTextStyles.title),
                  const SizedBox(height: 4.0),
                  const Text(
                    'Connected through VibeCircle',
                    style: TextStyle(color: AppColors.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10.0),

            // Settings options list
            AppCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.notifications_off_outlined, color: AppColors.primary, size: 21.0),
                          SizedBox(width: 12.0),
                          Text('Mute notifications', style: AppTextStyles.body),
                        ],
                      ),
                      Switch(
                        value: _muted,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => setState(() => _muted = val),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border),
                  _buildMenuRow(Icons.search, 'Search conversation', () {}),
                  const Divider(color: AppColors.border),
                  _buildMenuRow(Icons.image_outlined, 'Shared media', () => Get.toNamed(AppRoutes.MEDIA_PREVIEW)),
                  const Divider(color: AppColors.border),
                  _buildMenuRow(Icons.archive_outlined, 'Archive conversation', () {
                    Get.snackbar('Archived', 'This chat has been moved to archives.');
                  }),
                  const Divider(color: AppColors.border),
                  _buildMenuRow(Icons.delete_outline, 'Clear messages', () {
                    Get.snackbar('Success', 'Conversation cleared successfully.');
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            if (_personId.isNotEmpty) ...[
              AppButton(
                title: 'Finish chat & leave a review',
                onPressed: () => Get.toNamed(
                  AppRoutes.SESSION_RATING,
                  arguments: {
                    'sessionId': _chatId,
                    'userId': _personId,
                    'sessionType': 'chat',
                  },
                ),
              ),
              const SizedBox(height: 10.0),
            ],

            AppButton(
              title: 'Block user',
              tone: AppButtonTone.danger,
              onPressed: _blockUser,
            ),
            const SizedBox(height: 10.0),
            AppButton(
              title: 'Report conversation',
              tone: AppButtonTone.secondary,
              onPressed: _reportConversation,
            ),
            const SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuRow(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 21.0),
            const SizedBox(width: 12.0),
            Expanded(child: Text(title, style: AppTextStyles.body)),
            const Icon(Icons.chevron_right, color: AppColors.muted, size: 18.0),
          ],
        ),
      ),
    );
  }
}
