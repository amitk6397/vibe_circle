import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_pill.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../routes/app_routes.dart';
import '../../community/widgets/community_card.dart';
import '../controllers/inbox_controller.dart';
import '../models/chat.dart';

class InboxView extends GetView<InboxController> {
  const InboxView({super.key});

  @override
  Widget build(BuildContext context) {
    final InboxController c = Get.isRegistered<InboxController>()
        ? Get.find<InboxController>()
        : Get.put(InboxController());

    return AppScreen(
      scroll: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header Row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR CONVERSATIONS',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    const Text('Inbox', style: AppTextStyles.title),
                  ],
                ),
                AppIconButton(
                  icon: Icons.edit_note,
                  onPressed: () => Get.toNamed(AppRoutes.DISCOVER_PEOPLE),
                ),
              ],
            ),
          ),

          // Action Filter Pills Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Obx(() {
              final int unread = c.totalUnreadChats;
              final int followCount = c.pendingFollowCount.value;
              final int msgCount = c.pendingMsgCount.value;
              final bool hasPaid = c.hasPaid.value;
              final bool hasArchived = c.hasArchived.value;
              final String currentTab = c.inboxTab.value;

              return Row(
                children: [
                  AppPill(
                    label: unread > 0 ? 'Chats ($unread)' : 'Chats',
                    selected: currentTab == 'chats',
                    onPressed: () => c.changeTab('chats'),
                  ),
                  const SizedBox(width: 8.0),
                  AppPill(
                    label: 'Groups',
                    selected: currentTab == 'groups',
                    onPressed: () => c.changeTab('groups'),
                  ),
                  const SizedBox(width: 8.0),
                  AppPill(
                    label: followCount > 0
                        ? 'Follow Requests ($followCount)'
                        : 'Follow Requests',
                    selected: false,
                    onPressed: () async {
                      await Get.toNamed(AppRoutes.CONNECTION_REQUEST);
                      c.refreshInbox();
                    },
                  ),
                  const SizedBox(width: 8.0),
                  AppPill(
                    label: msgCount > 0
                        ? 'Msg Requests ($msgCount)'
                        : 'Msg Requests',
                    selected: false,
                    onPressed: () async {
                      await Get.toNamed(AppRoutes.MESSAGE_REQUESTS);
                      c.refreshInbox();
                    },
                  ),
                  if (hasPaid) ...[
                    const SizedBox(width: 8.0),
                    AppPill(
                      label: 'Paid sessions',
                      selected: false,
                      onPressed: () => Get.toNamed(AppRoutes.PAID_SESSIONS),
                    ),
                  ],
                  if (hasArchived) ...[
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
          const SizedBox(height: 8.0),

          // Main Tab List View
          Expanded(
            child: Obx(() {
              if (c.loading.value &&
                  c.chats.isEmpty &&
                  c.joinedCommunities.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (c.error.value.isNotEmpty && c.chats.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: AppCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c.error.value,
                            style: const TextStyle(color: AppColors.danger),
                          ),
                          const SizedBox(height: 12.0),
                          AppButton(
                            title: 'Try again',
                            tone: AppButtonTone.secondary,
                            onPressed: () => c.refreshInbox(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (c.inboxTab.value == 'chats') {
                return _buildChatsList(c);
              } else {
                return _buildGroupsList(c);
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildChatsList(InboxController c) {
    if (c.chats.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => c.refreshInbox(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80.0),
            AppEmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'No conversations yet',
              text: 'Search for people or start chatting from Discover!',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => c.refreshInbox(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        itemCount: c.chats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8.0),
        itemBuilder: (context, index) {
          final Chat chat = c.chats[index];
          return _buildChatCard(chat);
        },
      ),
    );
  }

  Widget _buildChatCard(Chat chat) {
    return AppCard(
      onPress: () => Get.toNamed(
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
          Stack(
            children: [
              AppAvatar(name: chat.name ?? '', uri: chat.avatarUrl, size: 46.0),
              if (chat.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 13.0,
                    height: 13.0,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2.0),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.name ?? '',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3.0),
                Text(
                  chat.preview.isNotEmpty
                      ? chat.preview
                      : 'Start a conversation',
                  style: TextStyle(
                    color: chat.unread > 0 ? AppColors.text : AppColors.muted,
                    fontSize: 13.0,
                    fontWeight: chat.unread > 0
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                chat.time,
                style: const TextStyle(color: AppColors.muted, fontSize: 11.0),
              ),
              const SizedBox(height: 6.0),
              if (chat.unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7.0,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    '${chat.unread}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const SizedBox(height: 18.0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList(InboxController c) {
    if (c.joinedCommunities.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => c.refreshInbox(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80.0),
            AppEmptyState(
              icon: Icons.people_outline,
              title: 'No group chats',
              text: 'Join a community to see its group chat here.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => c.refreshInbox(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        itemCount: c.joinedCommunities.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10.0),
        itemBuilder: (context, index) {
          final comm = c.joinedCommunities[index];
          return CommunityCard(
            community: comm,
            onPress: () => Get.toNamed(
              AppRoutes.COMMUNITY_CHAT,
              arguments: {'communityId': comm.id, 'community': comm},
            ),
          );
        },
      ),
    );
  }
}
