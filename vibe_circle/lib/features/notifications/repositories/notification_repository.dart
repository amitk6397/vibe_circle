import '../../../core/network/network_api_service.dart';
import '../../../core/constants/api_urls.dart';

class NotificationRepository {
  final NetworkApiService _apiService = NetworkApiService.instance;

  Future<List<dynamic>> list() async {
    final response = await _apiService.get(ApiUrls.notifications);
    return response.data as List? ?? [];
  }

  Future<void> markAllRead() async {
    await _apiService.post(ApiUrls.notificationsMarkAllRead);
  }

  Future<void> markRead(String id) async {
    await _apiService.post(ApiUrls.notificationMarkRead(id));
  }

  Future<void> remove(String id) async {
    await _apiService.delete(ApiUrls.notificationDelete(id));
  }

  Future<void> registerDeviceToken(String token) async {
    await _apiService.post(ApiUrls.registerDeviceToken, data: {'token': token});
  }
}
