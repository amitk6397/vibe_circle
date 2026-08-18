import '../../../core/network/network_api_service.dart';
import '../../../core/constants/api_urls.dart';
import '../models/person.dart';

class DiscoveryRepository {
  final NetworkApiService _apiService = NetworkApiService.instance;

  Future<List<Person>> discoverUsers(Map<String, dynamic> filters) async {
    final response = await _apiService.get(ApiUrls.discoveryUsers, queryParameters: filters);
    final list = response.data as List? ?? [];
    return list.map((item) => Person.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> globalSearch(String query) async {
    final response = await _apiService.get(ApiUrls.search, queryParameters: {'q': query});
    return response.data as Map<String, dynamic>;
  }

  Future<List<Person>> recommendedPeople() async {
    final response = await _apiService.get(ApiUrls.recommendedPeople);
    final list = response.data as List? ?? [];
    return list.map((item) => Person.fromJson(item as Map<String, dynamic>)).toList();
  }
}
