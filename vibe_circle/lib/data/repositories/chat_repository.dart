import '../../core/network/network_api_service.dart';
import '../../core/constants/api_urls.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/community_message.dart';

class ChatRepository {
  final NetworkApiService _apiService = NetworkApiService.instance;

  Future<Map<String, dynamic>> createConversation(String userId) async {
    final response = await _apiService.post(ApiUrls.createConversation, data: {'member_id': userId});
    return response.data as Map<String, dynamic>;
  }

  Future<List<Chat>> conversations({String folder = 'active'}) async {
    final response = await _apiService.get(ApiUrls.conversations, queryParameters: {'folder': folder});
    final list = response.data as List? ?? [];
    return list.map((e) => Chat.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Message>> messages(String conversationId, {int limit = 100, String? before}) async {
    final Map<String, dynamic> params = {'limit': limit};
    if (before != null) params['before'] = before;
    final response = await _apiService.get(ApiUrls.messages(conversationId), queryParameters: params);
    final list = response.data as List? ?? [];
    return list.map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CommunityMessage>> communityMessages(String communityId, {int limit = 100}) async {
    final response = await _apiService.get(ApiUrls.communityMessages(communityId), queryParameters: {'limit': limit});
    final list = response.data as List? ?? [];
    return list.map((e) => CommunityMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markRead(String conversationId) async {
    await _apiService.post(ApiUrls.markRead(conversationId));
  }

  Future<Map<String, dynamic>> send(String conversationId, Map<String, dynamic> payload) async {
    final response = await _apiService.post(ApiUrls.sendPrivateMessage(conversationId), data: payload);
    return response.data as Map<String, dynamic>;
  }

  Future<void> react(String messageId, String emoji) async {
    await _apiService.post(ApiUrls.reactMessage(messageId), data: {'emoji': emoji});
  }

  Future<void> deleteMessage(String messageId) async {
    await _apiService.delete(ApiUrls.deleteMessage(messageId));
  }

  Future<Map<String, dynamic>> limits({String? conversationId}) async {
    final Map<String, dynamic> params = {};
    if (conversationId != null) params['conversation_id'] = conversationId;
    final response = await _apiService.get(ApiUrls.chatLimits, queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> messageRequests() async {
    final response = await _apiService.get(ApiUrls.messageRequests);
    return response.data as List? ?? [];
  }

  Future<Map<String, dynamic>> sendMessageRequest(String recipientId, String introduction, int durationMinutes) async {
    final response = await _apiService.post(ApiUrls.messageRequests, data: {
      'recipient_id': recipientId,
      'introduction': introduction,
      'duration_minutes': durationMinutes,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> messageRequestAction(String requestId, String action) async {
    final response = await _apiService.patch(ApiUrls.messageRequestAction(requestId), data: {'action': action});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unlockConversation(String conversationId) async {
    final response = await _apiService.post(ApiUrls.unlockConversation(conversationId));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deductChatMinute(String conversationId) async {
    final response = await _apiService.post(ApiUrls.deductChatMinute(conversationId));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> coinPricing() async {
    final response = await _apiService.get(ApiUrls.coinPricing);
    return response.data as Map<String, dynamic>;
  }
}
