import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controllers/chat_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../community/controllers/community_controller.dart';
import '../../discovery/controllers/discovery_controller.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_pill.dart';
import '../../community/widgets/community_card.dart';
import '../../../routes/app_routes.dart';

class InboxView extends StatefulWidget {
  const InboxView({super.key});

  @override
  State<InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends State<InboxView> {
  final AuthController _authController = Get.find<AuthController>();
  final ChatController _chatController = Get.find<ChatController>();
  final CommunityController _communityController = Get.find<CommunityController>();
  final DiscoveryController _discoveryController = Get.find<DiscoveryController>();

  String _inboxTab = 'chats'; // 'chats' | 'groups'
  int _pendingFollowCount = 0;
  int _pendingMsgCount = 0;
  bool _hasPaid = false;
  bool _hasArchived = false;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  void _loadCounts() async {
    final String? currentUserId = _authController.currentUserId.value;
    if (currentUserId == null) return;

    try {
      // 1. Follow Requests
      final connResult = await _discoveryController.fetchConnections();
      final pendingFollows = connResult.where(
        (item) => item['status'] == 'pending' && item['receiver_id'].toString() == currentUserId
      ).toList();

      // 2. Message Requests
      await _chatController.loadMessageRequests();
      final pendingMsgs = _chatController.messageRequestsList.where((x) => x['status'] == 'pending').toList();

      // 3. Paid sessions
      await _chatController.loadPaidSessions();
      
      // 4. Archived
      await _chatController.loadArchivedConversations();

      if (mounted) {
        setState(() {
          _pendingFollowCount = pendingFollows.length;
          _pendingMsgCount = pendingMsgs.length;
          _hasPaid = _chatController.paidSessionsList.isNotEmpty;
          _hasArchived = _chatController.archivedChatsList.isNotEmpty;
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      scroll: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'YOUR CONVERSATIONS',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Inbox',
                      style: AppTextStyles.title,
                    ),
                  ],
                ),
                AppIconButton(
                  icon: Icons.edit_note,
                  onPressed: () => Get.toNamed(AppRoutes.DISCOVER_PEOPLE),
                ),
              ],
            ),
          ),

          // Pills ScrollView
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Obx(() {
              final int totalUnread = _chatController.chats.fold<int>(0, (sum, chat) => sum + chat.unread);
              return Row(
                children: [
                  AppPill(
                    label: totalUnread > 0 ? 'Chats ($totalUnread)' : 'Chats',
                    selected: _inboxTab == 'chats',
                    onPressed: () => setState(() => _inboxTab = 'chats'),
                  ),
                  const SizedBox(width: 8.0),
                  AppPill(
                    label: 'Groups',
                    selected: _inboxTab == 'groups',
                    onPressed: () => setState(() => _inboxTab = 'groups'),
                  ),
                  const SizedBox(width: 8.0),
                  AppPill(
                    label: _pendingFollowCount > 0 ? 'Follow Requests ($_pendingFollowCount)' : 'Follow Requests',
                    selected: false,
                    onPressed: () => Get.toNamed(AppRoutes.CONNECTION_REQUEST),
                  ),
                  const SizedBox(width: 8.0),
                  AppPill(
                    label: _pendingMsgCount > 0 ? 'Msg Requests ($_pendingMsgCount)' : 'Msg Requests',
                    selected: false,
                    onPressed: () => Get.toNamed(AppRoutes.MESSAGE_REQUESTS),
                  ),
                  if (_hasPaid) ...[
                    const SizedBox(width: 8.0),
                    AppPill(
                      label: 'Paid sessions',
                      selected: false,
                      onPressed: () => Get.toNamed(AppRoutes.PAID_SESSIONS),
                    ),
                  ],
                  if (_hasArchived) ...[
                    const SizedBox(width: 8.0),
                    AppPill(
                      label: 'Archived',
                      selected: false,
                      onPressed: () => Get.toNamed(AppRoutes.ARCHIVED_CHATS),
                    ),
                  ],
                ],
              );
            }),
          ),
          const SizedBox(height: 16.0),

          // Content List area
          Expanded(
            child: Obx(() {
              if (_chatController.loading.value && _chatController.chats.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_inboxTab == 'chats') {
                final chatsList = _chatController.chats;
                if (chatsList.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'No chats yet',
                    text: 'Find people in discovery to start a connection.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await _chatController.loadConversations();
                    _loadCounts();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: chatsList.length,
                    itemBuilder: (context, idx) {
                      final chat = chatsList[idx];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: AppCard(
                          onPressed: () => Get.toNamed(
                            AppRoutes.PRIVATE_CHAT,
                            arguments: {
                              'chatId': chat.id,
                              'name': chat.name,
                              'personId': chat.personId,
                              'avatarUrl': chat.avatarUrl,
                            },
                          ),
                          child: Row(
                            children: [
                              AppAvatar(
                                name: chat.name ?? 'User',
                                avatarUrl: chat.avatarUrl,
                                size: 42.0,
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      chat.name ?? 'User',
                                      style: const TextStyle(
                                        color: AppColors.text,
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      chat.preview,
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12.0,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    chat.time,
                                    style: const TextStyle(color: AppColors.muted, fontSize: 10.0),
                                  ),
                                  const SizedBox(height: 4.0),
                                  if (chat.unread > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF3040),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${chat.unread}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              } else {
                final joinedComms = _communityController.communities.where(
                  (c) => _communityController.joinedCommunities.contains(c.id)
                ).toList();

                if (joinedComms.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.groups_outlined,
                    title: 'No group chats',
                    text: 'Join a community to see its group chat here.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: joinedComms.length,
                  itemBuilder: (context, idx) {
                    final comm = joinedComms[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: CommunityCard(
                        community: comm,
                        onPressed: () => Get.toNamed(AppRoutes.COMMUNITY_CHAT, arguments: {'communityId': comm.id}),
                      ),
                    );
                  },
                );
              }
            }),
          ),
        ],
      ),
    );
  }
}
