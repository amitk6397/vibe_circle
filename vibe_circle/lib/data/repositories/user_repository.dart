import '../../core/network/network_api_service.dart';
import '../../core/constants/api_urls.dart';
import '../models/api_user.dart';

class UserRepository {
  final NetworkApiService _apiService = NetworkApiService.instance;

  Future<ApiUser> publicProfile(String id) async {
    final response = await _apiService.get(ApiUrls.publicProfile(id));
    return ApiUser.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ApiUser> updateProfile(Map<String, dynamic> payload) async {
    final response = await _apiService.patch(ApiUrls.updateProfile, data: payload);
    return ApiUser.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ApiUser> updatePreferences(Map<String, dynamic> payload) async {
    final response = await _apiService.patch(ApiUrls.updatePreferences, data: payload);
    return ApiUser.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updatePrivacy(Map<String, dynamic> payload) async {
    await _apiService.patch(ApiUrls.updatePrivacy, data: payload);
  }

  Future<void> updateNotificationPreferences(Map<String, bool> payload) async {
    await _apiService.patch(ApiUrls.updateNotificationPreferences, data: payload);
  }

  Future<ApiUser> setAvailability(String status, int durationMinutes) async {
    final response = await _apiService.patch(ApiUrls.availability, data: {
      'status': status,
      'duration_minutes': durationMinutes,
    });
    return ApiUser.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> clearAvailability() async {
    await _apiService.delete(ApiUrls.availability);
  }

  Future<List<dynamic>> connections() async {
    final response = await _apiService.get(ApiUrls.connections);
    return response.data as List? ?? [];
  }

  Future<Map<String, dynamic>> requestConnection(String userId) async {
    final response = await _apiService.post(ApiUrls.connections, data: {'user_id': userId});
    return response.data as Map<String, dynamic>;
  }

  Future<void> connectionAction(String connectionId, String action) async {
    await _apiService.patch(ApiUrls.connectionAction(connectionId), data: {'action': action});
  }

  Future<void> removeConnection(String connectionId) async {
    await _apiService.delete(ApiUrls.connectionAction(connectionId));
  }

  Future<Map<String, dynamic>> activity() async {
    final response = await _apiService.get(ApiUrls.activity);
    return response.data as Map<String, dynamic>;
  }
}
