import '../../core/network/network_api_service.dart';
import '../../core/constants/api_urls.dart';
import '../models/api_user.dart';
import '../models/community.dart';
import '../models/post.dart';

class DiscoveryRepository {
  final NetworkApiService _apiService = NetworkApiService.instance;

  Future<List<ApiUser>> users(Map<String, dynamic>? params) async {
    final response = await _apiService.get(ApiUrls.discoveryUsers, queryParameters: params);
    final list = response.data as List? ?? [];
    return list.map((e) => ApiUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Community>> communities() async {
    final response = await _apiService.get(ApiUrls.communities);
    final list = response.data as List? ?? [];
    return list.map((e) => Community.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Post>> posts() async {
    final response = await _apiService.get(ApiUrls.feedPosts);
    final list = response.data as List? ?? [];
    return list.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> search(String query) async {
    final response = await _apiService.get(ApiUrls.search, queryParameters: {'q': query});
    return response.data as Map<String, dynamic>;
  }

  Future<List<ApiUser>> recommendedPeople({int? page, int? limit}) async {
    final Map<String, dynamic> params = {};
    if (page != null) params['page'] = page;
    if (limit != null) params['limit'] = limit;
    final response = await _apiService.get(ApiUrls.recommendedPeople, queryParameters: params);
    final list = response.data as List? ?? [];
    return list.map((e) => ApiUser.fromJson(e as Map<String, dynamic>)).toList();
  }
}
