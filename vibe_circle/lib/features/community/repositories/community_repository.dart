import '../../../core/network/network_api_service.dart';
import '../../../core/constants/api_urls.dart';
import '../models/community.dart';
import '../models/post.dart';
import '../models/comment.dart';

class CommunityRepository {
  final NetworkApiService _apiService = NetworkApiService.instance;

  Future<List<Community>> listCommunities({String? category}) async {
    final response = await _apiService.get(
      ApiUrls.communities,
      queryParameters: category != null ? {'category': category} : null,
    );
    final list = response.data as List? ?? [];
    return list.map((e) => Community.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Community>> getCommunities({String? category}) => listCommunities(category: category);

  Future<Community> details(String id) async {
    final response = await _apiService.get(ApiUrls.communityDetails(id));
    return Community.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Post>> feed({String? communityId}) async {
    final response = await _apiService.get(
      ApiUrls.feedPosts,
      queryParameters: communityId != null ? {'community_id': communityId} : null,
    );
    final list = response.data as List? ?? [];
    return list.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Post> createPost(Map<String, dynamic> payload) async {
    final response = await _apiService.post(ApiUrls.feedPosts, data: payload);
    return Post.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> likePost(String postId) async {
    await _apiService.post(ApiUrls.likePost(postId));
  }

  Future<List<Comment>> comments(String postId) async {
    final response = await _apiService.get(ApiUrls.postComments(postId));
    final list = response.data as List? ?? [];
    return list.map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Comment> addComment(String postId, String text) async {
    final response = await _apiService.post(ApiUrls.postComments(postId), data: {'text': text});
    return Comment.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Community> createCommunity(Map<String, dynamic> payload) async {
    final response = await _apiService.post(ApiUrls.communities, data: payload);
    return Community.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> joinCommunity(String id) async {
    await _apiService.post(ApiUrls.joinCommunity(id));
  }

  Future<List<dynamic>> members(String communityId) async {
    final response = await _apiService.get(ApiUrls.communityMembers(communityId));
    return response.data as List? ?? [];
  }

  Future<List<dynamic>> joinRequests(String communityId) async {
    final response = await _apiService.get(ApiUrls.communityJoinRequests(communityId));
    return response.data as List? ?? [];
  }

  Future<void> respondJoinRequest(String communityId, String requestId, String action) async {
    await _apiService.post(ApiUrls.communityJoinRequestsAction(communityId, requestId), data: {'action': action});
  }

  Future<void> deletePost(String postId) async {
    await _apiService.delete('/feed/posts/$postId');
  }

  Future<Map<String, dynamic>> vote(String postId, String option) async {
    final response = await _apiService.post('/feed/posts/$postId/vote', data: {'option': option});
    return response.data as Map<String, dynamic>;
  }

  Future<void> toggleSave(String postId) async {
    await _apiService.post('/feed/posts/$postId/save');
  }

  Future<Map<String, dynamic>> unlockPost(String postId) async {
    final response = await _apiService.post('/feed/posts/$postId/unlock');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> boostPost(String postId) async {
    final response = await _apiService.post('/feed/posts/$postId/boost');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendCommunityMessage(String communityId, Map<String, dynamic> payload) async {
    final response = await _apiService.post('/communities/$communityId/messages', data: payload);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> circleInvites() async {
    final response = await _apiService.get('/communities/invitations/me');
    return response.data as List? ?? [];
  }

  Future<Map<String, dynamic>> respondCircleInvite(String inviteId, String action) async {
    final response = await _apiService.patch('/communities/invitations/$inviteId', data: {'action': action});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> tipPost(String postId, int amount) async {
    final response = await _apiService.post(ApiUrls.tipPost(postId), data: {'coins': amount});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendGift(Map<String, dynamic> payload) async {
    final response = await _apiService.post(ApiUrls.sendGift, data: payload);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> awardBounty(String postId, String commentId) async {
    final response = await _apiService.post(ApiUrls.awardBounty(postId), data: {'comment_id': commentId});
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> communityMessages(String communityId) async {
    final response = await _apiService.get('/communities/$communityId/messages');
    return response.data as List? ?? [];
  }
}

