import '../../../core/network/network_api_service.dart';
import '../../../core/constants/api_urls.dart';

class ChatRepository {
  final NetworkApiService _apiService = NetworkApiService.instance;

  Future<List<dynamic>> conversations({String folder = 'active'}) async {
    final response = await _apiService.get(
      ApiUrls.conversations,
      queryParameters: {'folder': folder},
    );
    return response.data as List? ?? [];
  }

  Future<List<dynamic>> messages(String chatId) async {
    final response = await _apiService.get(ApiUrls.messages(chatId));
    return response.data as List? ?? [];
  }

  Future<Map<String, dynamic>> sendMessage(String chatId, Map<String, dynamic> payload) async {
    final response = await _apiService.post(ApiUrls.sendPrivateMessage(chatId), data: payload);
    return response.data as Map<String, dynamic>;
  }

  Future<void> reactMessage(String chatId, String messageId, String emoji) async {
    await _apiService.post(ApiUrls.reactMessage(messageId), data: {'emoji': emoji});
  }

  Future<void> deleteMessage(String messageId) async {
    await _apiService.delete(ApiUrls.deleteMessage(messageId));
  }

  Future<List<dynamic>> requests() async {
    final response = await _apiService.get(ApiUrls.messageRequests);
    return response.data as List? ?? [];
  }

  Future<Map<String, dynamic>> respondRequest(String requestId, String action) async {
    final response = await _apiService.post(ApiUrls.messageRequestAction(requestId), data: {'action': action});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendRequest(Map<String, dynamic> payload) async {
    final response = await _apiService.post(ApiUrls.messageRequests, data: payload);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> coinPricing() async {
    final response = await _apiService.get(ApiUrls.coinPricing);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> messageRequests() => requests();
  
  Future<Map<String, dynamic>> messageRequestAction(String requestId, String action) => respondRequest(requestId, action);

  Future<void> markRead(String chatId) async {
    await _apiService.post(ApiUrls.markRead(chatId));
  }

  Future<Map<String, dynamic>> limits({String? conversationId}) async {
    final response = await _apiService.get(
      ApiUrls.chatLimits,
      queryParameters: conversationId != null ? {'conversation_id': conversationId} : null,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> send(String chatId, Map<String, dynamic> payload) => sendMessage(chatId, payload);

  Future<void> react(String messageId, String emoji) async {
    await _apiService.post(ApiUrls.reactMessage(messageId), data: {'emoji': emoji});
  }

  Future<Map<String, dynamic>> sendMessageRequest(String recipientId, String introduction, int durationMinutes) {
    return sendRequest({
      'recipient_id': recipientId,
      'introduction': introduction,
      'duration_minutes': durationMinutes,
    });
  }

  Future<Map<String, dynamic>> createConversation(String personId) async {
    final response = await _apiService.post(ApiUrls.createConversation, data: {'member_id': personId});
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
}
