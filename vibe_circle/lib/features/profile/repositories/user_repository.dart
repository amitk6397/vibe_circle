import '../../../core/network/network_api_service.dart';
import '../../../core/constants/api_urls.dart';
import '../../discovery/models/person.dart';
import '../../auth/models/api_user.dart';

class UserRepository {
  final NetworkApiService _apiService = NetworkApiService.instance;

  Future<Person> publicProfile(String userId) async {
    final response = await _apiService.get(ApiUrls.publicProfile(userId));
    return Person.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<dynamic>> connections() async {
    final response = await _apiService.get(ApiUrls.connections);
    return response.data as List? ?? [];
  }

  Future<Map<String, dynamic>> requestConnection(String userId) async {
    final response = await _apiService.post(ApiUrls.connections, data: {'user_id': userId});
    return response.data as Map<String, dynamic>;
  }

  Future<void> connectionAction(String id, String action) async {
    await _apiService.patch(ApiUrls.connectionAction(id), data: {'action': action});
  }

  Future<void> removeConnection(String id) async {
    await _apiService.delete(ApiUrls.connectionAction(id));
  }

  Future<void> blockUser(String userId) async {
    await _apiService.post('/safety/blocks', data: {'user_id': userId});
  }

  Future<void> unblockUser(String userId) async {
    await _apiService.delete('/safety/blocks/$userId');
  }

  Future<void> updateAvailability(Map<String, dynamic> payload) async {
    await _apiService.patch(ApiUrls.availability, data: payload);
  }

  Future<void> clearAvailability() async {
    await _apiService.delete(ApiUrls.availability);
  }

  Future<List<dynamic>> myReports() async {
    final response = await _apiService.get('/safety/reports/me');
    return response.data as List? ?? [];
  }

  Future<void> submitReport(String targetType, String targetId, String reason, {String details = ''}) async {
    await _apiService.post('/safety/reports', data: {
      'target_type': targetType,
      'target_id': targetId,
      'reason': reason,
      'details': details,
    });
  }

  Future<void> logoutAll() async {
    await _apiService.post('/auth/logout-all');
  }

  Future<void> deleteAccount() async {
    await _apiService.delete('/auth/account');
  }

  Future<Map<String, dynamic>> exportData() async {
    final response = await _apiService.get('/users/me/export');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> activity() async {
    final response = await _apiService.get('/users/me/activity');
    return response.data as Map<String, dynamic>;
  }

  Future<ApiUser> updateProfile(Map<String, dynamic> payload) async {
    final response = await _apiService.patch(ApiUrls.updateProfile, data: payload);
    return ApiUser.fromJson(response.data as Map<String, dynamic>);
  }
}

