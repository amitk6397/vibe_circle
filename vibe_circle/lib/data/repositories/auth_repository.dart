import '../../core/network/network_api_service.dart';
import '../../core/constants/api_urls.dart';
import '../models/api_user.dart';

class AuthRepository {
  final NetworkApiService _apiService = NetworkApiService.instance;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiService.post(ApiUrls.login, data: {
      'email': email,
      'password': password,
      'device_name': 'Flutter Mobile',
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final response = await _apiService.post(ApiUrls.register, data: payload);
    return response.data as Map<String, dynamic>;
  }

  Future<ApiUser?> restore() async {
    try {
      final response = await _apiService.get(ApiUrls.restore);
      if (response.data == null) return null;
      return ApiUser.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout(String refreshToken) async {
    await _apiService.post(ApiUrls.logout, data: {'refresh_token': refreshToken});
  }

  Future<void> forgotPassword(String email) async {
    await _apiService.post(ApiUrls.forgotPassword, data: {'email': email});
  }

  Future<Map<String, dynamic>> requestVerification() async {
    final response = await _apiService.post(ApiUrls.requestVerification);
    return response.data as Map<String, dynamic>;
  }

  Future<void> verifyEmail(String otp) async {
    await _apiService.post(ApiUrls.verifyEmail, data: {'token': otp});
  }

  Future<Map<String, dynamic>> getReferralInfo() async {
    final response = await _apiService.get(ApiUrls.referralInfo);
    return response.data as Map<String, dynamic>;
  }
}
