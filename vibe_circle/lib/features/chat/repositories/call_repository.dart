import '../../../core/network/network_api_service.dart';
import '../../../core/constants/api_urls.dart';

class CallRepository {
  final NetworkApiService _apiService = NetworkApiService.instance;

  Future<Map<String, dynamic>> getConfig() async {
    final res = await _apiService.get(ApiUrls.callsConfig);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCall(String id) async {
    final res = await _apiService.get(ApiUrls.callGet(id));
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> action(String id, String actionName) async {
    final res = await _apiService.post(ApiUrls.callAction(id, actionName));
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> extend(String id, int minutes) async {
    final res = await _apiService.post(ApiUrls.callExtend(id), data: {'minutes': minutes});
    return res.data as Map<String, dynamic>;
  }
}
