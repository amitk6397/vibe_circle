import 'package:get/get.dart';
import '../models/person.dart';
import '../repositories/discovery_repository.dart';
import '../../profile/repositories/user_repository.dart';
import '../../../core/storage/local_storage.dart';
import '../../community/models/community.dart';

class DiscoveryController extends GetxController {
  final DiscoveryRepository _discoveryRepo = DiscoveryRepository();
  final UserRepository _userRepo = UserRepository();

  final RxList<Person> people = <Person>[].obs;
  final RxList<Person> recommendedPeople = <Person>[].obs;
  final RxString selectedPurpose = 'Talk'.obs;
  final RxBool loading = false.obs;

  // Search results
  final RxList<Person> searchUsers = <Person>[].obs;
  final RxList<Community> searchCommunities = <Community>[].obs;
  final RxList<Map<String, dynamic>> searchPosts = <Map<String, dynamic>>[].obs;

  final RxMap<String, dynamic> searchFilters = <String, dynamic>{
    'purpose': 'Talk',
    'language': 'English',
    'minAge': 18,
    'maxAge': 35,
    'onlineOnly': false,
    'gender': 'Any',
    'city': '',
  }.obs;

  @override
  void onInit() {
    super.onInit();
    selectedPurpose.value = LocalStorage.instance.getSelectedPurpose();
    loadDiscoverPeople();
    loadRecommendedPeople();
  }

  void selectPurpose(String val) {
    selectedPurpose.value = val;
    LocalStorage.instance.setSelectedPurpose(val);
  }

  void setSearchFilters(Map<String, dynamic> filters) {
    searchFilters.addAll(filters);
  }

  Future<void> loadDiscoverPeople() async {
    loading.value = true;
    try {
      final list = await _discoveryRepo.discoverUsers({});
      people.assignAll(list);
    } catch (_) {
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadRecommendedPeople() async {
    loading.value = true;
    try {
      final list = await _discoveryRepo.recommendedPeople();
      recommendedPeople.assignAll(list);
    } catch (_) {
    } finally {
      loading.value = false;
    }
  }

  Future<void> performGlobalSearch(String query) async {
    loading.value = true;
    try {
      final res = await _discoveryRepo.globalSearch(query);

      // Parse users
      final userList = res['users'] as List? ?? [];
      final List<Person> usersParsed = userList.map((item) {
        return Person(
          id: item['id'].toString(),
          name: item['name'] as String? ?? '',
          age: item['age'] as int? ?? 18,
          username: item['username'] as String? ?? '',
          bio: item['bio'] as String? ?? '',
          city: item['city'] as String?,
          languages: (item['languages'] as List? ?? []).map((e) => e.toString()).toList(),
          interests: (item['interests'] as List? ?? []).map((e) => e.toString()).toList(),
          online: item['is_online'] as bool? ?? false,
          avatarUrl: item['avatar_url'] as String?,
          avatarColor: '#6C5DD3',
        );
      }).toList();

      // Parse communities
      final commList = res['communities'] as List? ?? [];
      final List<Community> commsParsed = commList.map((item) {
        return Community.fromJson(Map<String, dynamic>.from(item as Map));
      }).toList();

      // Parse posts
      final postList = res['posts'] as List? ?? [];
      final List<Map<String, dynamic>> postsParsed = postList.map((item) {
        return Map<String, dynamic>.from(item as Map);
      }).toList();

      searchUsers.assignAll(usersParsed);
      searchCommunities.assignAll(commsParsed);
      searchPosts.assignAll(postsParsed);
    } finally {
      loading.value = false;
    }
  }

  Future<Person> fetchPublicProfile(String id) async {
    return await _userRepo.publicProfile(id);
  }

  Future<List<dynamic>> fetchConnections() async {
    return await _userRepo.connections();
  }

  Future<Map<String, dynamic>> followUser(String id) async {
    return await _userRepo.requestConnection(id);
  }

  Future<void> unfollowUser(String connectionId) async {
    await _userRepo.removeConnection(connectionId);
  }
}
