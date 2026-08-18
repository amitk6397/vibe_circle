import '../../core/network/network_api_service.dart';
import '../../core/constants/api_urls.dart';
import '../models/post.dart';
import '../models/comment.dart';

class CommunityRepository {
  final NetworkApiService _apiService = NetworkApiService.instance;

  Future<Post> details(String postId) async {
    final response = await _apiService.get(ApiUrls.postDetails(postId));
    return Post.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Post>> posts({String? communityId, String? before}) async {
    final Map<String, dynamic> params = {};
    if (communityId != null) params['community_id'] = communityId;
    if (before != null) params['before'] = before;
    final response = await _apiService.get(
      ApiUrls.feedPosts,
      queryParameters: params,
    );
    final list = response.data as List? ?? [];
    return list.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> createPost(Map<String, dynamic> payload) async {
    final response = await _apiService.post(ApiUrls.feedPosts, data: payload);
    return response.data as Map<String, dynamic>;
  }

  Future<void> updatePost(String postId, String body) async {
    await _apiService.patch(ApiUrls.postDetails(postId), data: {'body': body});
  }

  Future<void> deletePost(String postId) async {
    await _apiService.delete(ApiUrls.postDetails(postId));
  }

  Future<Map<String, dynamic>> addComment(
    String postId,
    String body, {
    String? parentId,
  }) async {
    final response = await _apiService.post(
      ApiUrls.postComments(postId),
      data: {'body': body, 'parent_id': ?parentId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> toggleCommentLike(String commentId) async {
    await _apiService.post(ApiUrls.commentLike(commentId));
  }

  Future<void> deleteComment(String commentId) async {
    await _apiService.delete(ApiUrls.commentAction(commentId));
  }

  Future<Map<String, dynamic>> vote(String postId, String option) async {
    final response = await _apiService.post(
      ApiUrls.votePost(postId),
      data: {'option': option},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<Comment>> comments(String postId) async {
    final response = await _apiService.get(ApiUrls.postComments(postId));
    final list = response.data as List? ?? [];
    return list
        .map((e) => Comment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> toggleLike(String postId) async {
    await _apiService.post(ApiUrls.likePost(postId));
  }

  Future<void> toggleSave(String postId) async {
    await _apiService.post(ApiUrls.savePost(postId));
  }

  Future<Map<String, dynamic>> unlockPost(String postId) async {
    final response = await _apiService.post(ApiUrls.unlockPost(postId));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createCommunity(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiService.post(ApiUrls.communities, data: payload);
    return response.data as Map<String, dynamic>;
  }

  Future<void> joinCommunity(String id) async {
    await _apiService.post(ApiUrls.joinCommunity(id));
  }

  Future<void> leaveCommunity(String id) async {
    await _apiService.post(ApiUrls.leaveCommunity(id));
  }

  Future<void> deleteCommunity(String id) async {
    await _apiService.delete(ApiUrls.deleteCommunity(id));
  }

  Future<void> shareCommunity(String id, List<String> userIds) async {
    await _apiService.post(
      ApiUrls.shareCommunity(id),
      data: {'user_ids': userIds},
    );
  }

  Future<void> sharePost(String postId, List<String> userIds) async {
    await _apiService.post(
      ApiUrls.sharePost(postId),
      data: {'user_ids': userIds},
    );
  }

  Future<List<dynamic>> circleInvites() async {
    final response = await _apiService.get(ApiUrls.circleInvites);
    return response.data as List? ?? [];
  }

  Future<void> inviteToCircle(String communityId, String userId) async {
    await _apiService.post(
      ApiUrls.inviteToCircle(communityId),
      data: {'user_id': userId},
    );
  }

  Future<void> respondCircleInvite(String inviteId, String action) async {
    await _apiService.patch(
      ApiUrls.circleInviteAction(inviteId),
      data: {'action': action},
    );
  }

  Future<List<dynamic>> communityJoinRequests(String id) async {
    final response = await _apiService.get(ApiUrls.communityJoinRequests(id));
    return response.data as List? ?? [];
  }

  Future<void> respondCommunityJoinRequest(
    String communityId,
    String requestId,
    String action,
  ) async {
    await _apiService.patch(
      ApiUrls.communityJoinRequestsAction(communityId, requestId),
      data: {'action': action},
    );
  }

  Future<Map<String, dynamic>> sendCommunityMessage(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiService.post(
      ApiUrls.sendCommunityMessage(id),
      data: payload,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> communityMessages(String id) async {
    final response = await _apiService.get(ApiUrls.communityMessages(id));
    return response.data as List? ?? [];
  }

  Future<Map<String, dynamic>> communitySubscriptionStatus(
    String communityId,
  ) async {
    final response = await _apiService.get(
      ApiUrls.communitySubscriptionStatus(communityId),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> tipPost(
    String postId,
    double amount, {
    String? message,
  }) async {
    final response = await _apiService.post(
      ApiUrls.tipPost(postId),
      data: {'amount': amount, 'message': ?message},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getPostTips(String postId) async {
    final response = await _apiService.get(ApiUrls.postTips(postId));
    return response.data as List? ?? [];
  }

  Future<Map<String, dynamic>> boostPost(String postId) async {
    final response = await _apiService.post(ApiUrls.boostPost(postId));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> awardBounty(
    String postId,
    String commentId,
  ) async {
    final response = await _apiService.post(
      ApiUrls.awardBounty(postId),
      data: {'comment_id': commentId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBountyStatus(String postId) async {
    final response = await _apiService.get(ApiUrls.postBountyStatus(postId));
    return response.data as Map<String, dynamic>;
  }
}
