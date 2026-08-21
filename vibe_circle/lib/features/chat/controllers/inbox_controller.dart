import 'package:get/get.dart';
import '../models/chat.dart';
import '../repositories/chat_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../community/models/community.dart';
import '../../community/repositories/community_repository.dart';
import '../../profile/repositories/user_repository.dart';

class InboxController extends GetxController {
  final ChatRepository _chatRepo = ChatRepository();
  final CommunityRepository _communityRepo = CommunityRepository();
  final UserRepository _userRepo = UserRepository();
  final AuthController _authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());

  final RxString inboxTab = 'chats'.obs; // 'chats' | 'groups'
  final RxList<Chat> chats = <Chat>[].obs;
  final RxList<Community> joinedCommunities = <Community>[].obs;

  final RxInt pendingFollowCount = 0.obs;
  final RxInt pendingMsgCount = 0.obs;
  final RxBool hasPaid = false.obs;
  final RxBool hasArchived = false.obs;
  final RxBool loading = false.obs;
  final RxString error = ''.obs;

  int get totalUnreadChats => chats.fold<int>(0, (sum, chat) => sum + chat.unread);

  @override
  void onInit() {
    super.onInit();
    refreshInbox();
  }

  void changeTab(String tab) {
    inboxTab.value = tab;
  }

  final Map<String, dynamic> _profileCache = {};

  Future<void> refreshInbox() async {
    loading.value = true;
    error.value = '';

    final String? currentUserId = _authController.currentUserId.value;

    try {
      // 1. Fetch Conversations
      final rawChats = await _chatRepo.conversations(folder: 'active');
      final List<Chat> parsedChats = [];

      for (final raw in rawChats) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final baseChat = Chat.fromJson(map);

        // Resolve other participant ID
        String personId = '';
        if (currentUserId != null && baseChat.participantIds.isNotEmpty) {
          personId = baseChat.participantIds.firstWhere(
            (id) => id != currentUserId,
            orElse: () => baseChat.participantIds.first,
          );
        }

        String displayName = baseChat.name ?? '';
        String? avatarUrl = baseChat.avatarUrl;
        bool isOnline = baseChat.online;

        if (baseChat.type == 'match_anonymous') {
          displayName = 'Anonymous Connect';
        } else if (personId.isNotEmpty && (displayName.isEmpty || avatarUrl == null)) {
          if (_profileCache.containsKey(personId)) {
            final cached = _profileCache[personId];
            displayName = cached['name'] ?? displayName;
            avatarUrl = cached['avatar_url'] ?? avatarUrl;
            isOnline = cached['is_online'] ?? isOnline;
          } else {
            try {
              final p = await _userRepo.publicProfile(personId);
              _profileCache[personId] = {
                'name': p.name,
                'avatar_url': p.avatarUrl,
                'is_online': p.online,
              };
              displayName = p.name;
              avatarUrl = p.avatarUrl;
              isOnline = p.online;
            } catch (_) {}
          }
        }

        parsedChats.add(baseChat.copyWith(
          name: displayName.isNotEmpty ? displayName : 'VibeCircle Member',
          avatarUrl: avatarUrl,
          online: isOnline,
        ));
      }

      chats.assignAll(parsedChats);

      // 2. Fetch Joined Communities for Groups tab
      try {
        final allComms = await _communityRepo.listCommunities();
        joinedCommunities.assignAll(
          allComms.where((c) => c.isJoined || c.joined || c.isOwner).toList(),
        );
      } catch (_) {}

      // 3. Counts: Follow requests, Message requests, Paid, Archived
      if (currentUserId != null) {
        try {
          final connections = await _userRepo.connections();
          final pendingFollows = connections
              .where(
                (item) =>
                    item['status'] == 'pending' &&
                    item['receiver_id']?.toString() == currentUserId,
              )
              .toList();
          pendingFollowCount.value = pendingFollows.length;
        } catch (_) {}

        try {
          final msgRequests = await _chatRepo.requests();
          final pendingMsgs = msgRequests
              .where((x) => x['status'] == 'pending')
              .toList();
          pendingMsgCount.value = pendingMsgs.length;
        } catch (_) {}

        try {
          final paidList = await _chatRepo.conversations(folder: 'paid');
          hasPaid.value = paidList.isNotEmpty;
        } catch (_) {}

        try {
          final archivedList = await _chatRepo.conversations(
            folder: 'archived',
          );
          hasArchived.value = archivedList.isNotEmpty;
        } catch (_) {}
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }
}
