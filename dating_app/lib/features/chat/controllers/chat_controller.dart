import 'package:get/get.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../repositories/chat_repository.dart';
import '../repositories/call_repository.dart';
import '../../profile/repositories/user_repository.dart';

class ChatController extends GetxController {
  final ChatRepository _chatRepo = ChatRepository();
  final UserRepository _userRepo = UserRepository();
  final CallRepository _callRepo = CallRepository();

  final RxList<Chat> chats = <Chat>[].obs;
  final RxList<Message> messages = <Message>[].obs;
  final RxBool loading = false.obs;
  final RxString error = ''.obs;
  final RxnString apiError = RxnString();

  final RxList<dynamic> messageRequestsList = [].obs;
  final RxList<dynamic> archivedChatsList = [].obs;
  final RxList<dynamic> paidSessionsList = [].obs;

  @override
  void onInit() {
    super.onInit();
    loadConversations();
  }

  Future<void> loadConversations({String folder = 'active'}) async {
    loading.value = true;
    apiError.value = null;
    try {
      final list = await _chatRepo.conversations(folder: folder);
      final parsed = list.map((item) => Chat.fromJson(item as Map<String, dynamic>)).toList();
      chats.assignAll(parsed);
    } catch (e) {
      apiError.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadArchivedConversations() async {
    loading.value = true;
    error.value = '';
    try {
      final list = await _chatRepo.conversations(folder: 'archived');
      final List<dynamic> enriched = [];
      for (var item in list) {
        String name = item.name;
        if (item.personId.isNotEmpty) {
          try {
            final profile = await _userRepo.publicProfile(item.personId);
            name = profile.name;
          } catch (_) {}
        }
        enriched.add({
          'id': item.id,
          'personId': item.personId,
          'name': name,
          'lastMessage': item.preview,
          'avatarUrl': item.avatarUrl,
        });
      }
      archivedChatsList.assignAll(enriched);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadPaidSessions() async {
    loading.value = true;
    error.value = '';
    try {
      final list = await _chatRepo.conversations(folder: 'paid');
      final List<dynamic> enriched = [];
      for (var item in list) {
        String name = item.name;
        if (item.personId.isNotEmpty) {
          try {
            final profile = await _userRepo.publicProfile(item.personId);
            name = profile.name;
          } catch (_) {}
        }
        enriched.add({
          'id': item.id,
          'personId': item.personId,
          'name': name,
          'lastMessage': item.preview,
          'avatarUrl': item.avatarUrl,
        });
      }
      paidSessionsList.assignAll(enriched);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadMessages(String chatId) async {
    loading.value = true;
    apiError.value = null;
    try {
      final list = await _chatRepo.messages(chatId);
      final parsed = list.map((item) => Message.fromJson(item as Map<String, dynamic>)).toList();
      messages.assignAll(parsed);
    } catch (e) {
      apiError.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<Message> sendMessage(String chatId, String text, {String? attachmentId, String? replyToId}) async {
    apiError.value = null;
    try {
      final Map<String, dynamic> payload = {
        'text': text,
        'attachment_id': ?attachmentId,
        'reply_to_id': ?replyToId,
      };
      final res = await _chatRepo.sendMessage(chatId, payload);
      final msg = Message.fromJson(res);
      messages.add(msg);

      // Update last message in conversation list
      final index = chats.indexWhere((c) => c.id == chatId);
      if (index != -1) {
        final c = chats[index];
        chats[index] = c.copyWith(
          lastMessageText: text,
          lastMessageTime: DateTime.now().toIso8601String(),
        );
      }
      return msg;
    } catch (e) {
      apiError.value = e.toString();
      rethrow;
    }
  }

  Future<void> markRead(String chatId) async {
    await _chatRepo.markRead(chatId);
  }

  Future<Map<String, dynamic>> createConversation(String personId) async {
    return await _chatRepo.createConversation(personId);
  }

  Future<Map<String, dynamic>> loadChatLimits(String chatId) async {
    return await _chatRepo.limits(conversationId: chatId);
  }

  Future<void> reactToMessage(String chatId, String messageId, String emoji) async {
    await _chatRepo.reactMessage(chatId, messageId, emoji);
  }

  Future<void> deleteMessage(String messageId) async {
    await _chatRepo.deleteMessage(messageId);
    messages.removeWhere((m) => m.id == messageId);
  }

  // Requests
  Future<void> loadMessageRequests() async {
    loading.value = true;
    try {
      final list = await _chatRepo.requests();
      messageRequestsList.assignAll(list);
    } finally {
      loading.value = false;
    }
  }

  Future<void> respondMessageRequest(String requestId, String action) async {
    await _chatRepo.respondRequest(requestId, action);
    messageRequestsList.removeWhere((item) => item['id']?.toString() == requestId);
  }

  Future<Map<String, dynamic>> sendMessageRequest(String recipientId, String introduction, int durationMinutes) async {
    return await _chatRepo.sendMessageRequest(recipientId, introduction, durationMinutes);
  }

  Future<Map<String, dynamic>> getCoinPricing() async {
    return await _chatRepo.coinPricing();
  }

  Future<Map<String, dynamic>> acceptCall(String callId) async {
    return await _callRepo.action(callId, 'accept');
  }

  Future<Map<String, dynamic>> rejectCall(String callId) async {
    return await _callRepo.action(callId, 'reject');
  }

  Future<Map<String, dynamic>> endCall(String callId) async {
    return await _callRepo.action(callId, 'end');
  }

  Future<Map<String, dynamic>> extendCall(String callId, int minutes) async {
    return await _callRepo.extend(callId, minutes);
  }

  Future<Map<String, dynamic>> loadCallConfig() async {
    return await _callRepo.getConfig();
  }
}
