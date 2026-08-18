import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../controllers/community_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/community.dart';
import '../models/community_message.dart';
import '../../chat/widgets/chat_skeleton.dart';

class CommunityChatView extends StatefulWidget {
  const CommunityChatView({super.key});

  @override
  State<CommunityChatView> createState() => _CommunityChatViewState();
}

class _CommunityChatViewState extends State<CommunityChatView> {
  final CommunityController _communityController = Get.find<CommunityController>();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _textController = TextEditingController();

  Community? _community;
  final List<CommunityMessage> _messages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  void _loadChat() {
    final Map args = Get.arguments ?? {};
    final String? communityId = args['communityId']?.toString();

    if (communityId != null) {
      _community = _communityController.communities.firstWhereOrNull((c) => c.id == communityId);
      final commMsgs = _communityController.communityMessages[communityId] ?? [];
      setState(() {
        _messages.clear();
        _messages.addAll(commMsgs);
      });
    }

    setState(() => _loading = false);
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty || _community == null) return;

    _communityController.sendCommunityMessage(_community!.id, text);
    _textController.clear();
    setState(() {
      _messages.clear();
      _messages.addAll(_communityController.communityMessages[_community!.id] ?? []);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_community == null) {
      return AppScreen(
        header: AppHeader(
          title: 'Community chat',
          onBack: () => Get.back(),
        ),
        child: const AppEmptyState(
          title: 'Community unavailable',
          text: 'Refresh and try again.',
        ),
      );
    }

    final String? myId = _authController.currentUserId.value;

    return AppScreen(
      scroll: false,
      header: AppHeader(
        title: _community!.name,
        subtitle: '${_community!.memberCount} members · Live chat',
        onBack: () => Get.back(),
      ),
      child: Column(
        children: [
          // Safety Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.success, size: 16.0),
                SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Be respectful. Avoid sharing phone numbers or private information.',
                    style: TextStyle(color: Color(0xFF28775A), fontSize: 11.0),
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: _loading
                ? const SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: ChatSkeleton(rows: 5),
                    ),
                  )
                : _messages.isNotEmpty
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        itemCount: _messages.length,
                        itemBuilder: (context, idx) {
                          final msg = _messages[idx];
                          final bool isMine = msg.senderId == myId;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Align(
                              alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                                decoration: BoxDecoration(
                                  color: isMine ? AppColors.primary : AppColors.surface,
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isMine) ...[
                                      Text(
                                        msg.senderName,
                                        style: const TextStyle(color: AppColors.text, fontSize: 11.0, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2.0),
                                    ],
                                    Text(
                                      msg.text,
                                      style: TextStyle(color: isMine ? Colors.white : AppColors.text, fontSize: 13.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : const AppEmptyState(
                        icon: Icons.chat_bubble_outline,
                        title: 'No messages yet',
                        text: 'Be the first to say hello to the group!',
                      ),
          ),

          // Message Composer
          Container(
            padding: const EdgeInsets.all(10.0),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: AppColors.text, fontSize: 14.0),
                      decoration: const InputDecoration(
                        hintText: 'Message the community...',
                        hintStyle: TextStyle(color: AppColors.muted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18.0),
                    onPressed: _send,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
