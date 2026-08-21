import 'package:get/get.dart';
import '../models/post.dart';
import '../models/community.dart';
import '../models/comment.dart';
import '../models/community_message.dart';
import '../repositories/community_repository.dart';

class CommunityController extends GetxController {
  final CommunityRepository _communityRepo = CommunityRepository();

  final RxList<Post> posts = <Post>[].obs;
  final RxList<Community> communities = <Community>[].obs;
  final RxList<String> joinedCommunities = <String>[].obs;
  final RxList<String> savedPosts = <String>[].obs;
  final RxMap<String, List<CommunityMessage>> communityMessages = <String, List<CommunityMessage>>{}.obs;

  // Additional states for sub-views
  final RxList<Comment> comments = <Comment>[].obs;
  final RxList<dynamic> membersList = [].obs;
  final RxList<dynamic> joinRequestsList = [].obs;
  final RxList<dynamic> circleInvitesList = [].obs;

  final RxBool loading = false.obs;
  final RxnString apiError = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadCommunities();
    loadFeed();
  }

  Future<void> loadCommunities() async {
    loading.value = true;
    apiError.value = null;
    try {
      final list = await _communityRepo.listCommunities();
      communities.assignAll(list);
      joinedCommunities.assignAll(list.where((item) => item.isJoined == true).map((e) => e.id));
    } catch (e) {
      apiError.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadFeed() async {
    loading.value = true;
    apiError.value = null;
    try {
      final list = await _communityRepo.feed();
      posts.assignAll(list);
    } catch (e) {
      apiError.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<List<Post>> fetchFeed({String? communityId}) async {
    return await _communityRepo.feed(communityId: communityId);
  }

  Future<void> toggleLike(String postId) async {
    try {
      await _communityRepo.likePost(postId);
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final p = posts[index];
        posts[index] = p.copyWith(
          likesCount: p.likesCount + (p.isLiked ? -1 : 1),
          likes: p.likes + (p.isLiked ? -1 : 1),
          isLiked: !p.isLiked,
          liked: !p.liked,
        );
      }
    } catch (e) {
      apiError.value = e.toString();
      rethrow;
    }
  }

  Future<void> toggleSave(String postId) async {
    try {
      await _communityRepo.toggleSave(postId);
      if (savedPosts.contains(postId)) {
        savedPosts.remove(postId);
      } else {
        savedPosts.add(postId);
      }
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final p = posts[index];
        posts[index] = p.copyWith(saved: !p.saved);
      }
    } catch (e) {
      apiError.value = e.toString();
      rethrow;
    }
  }

  Future<void> vote(String postId, String option) async {
    try {
      final res = await _communityRepo.vote(postId, option);
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final p = posts[index];
        posts[index] = p.copyWith(
          pollResults: res['poll_results'] != null ? Map<String, int>.from(res['poll_results'] as Map) : p.pollResults,
          myVote: res['option'] as String?,
        );
      }
    } catch (e) {
      apiError.value = e.toString();
      rethrow;
    }
  }

  Future<void> unlockPost(String postId) async {
    try {
      final res = await _communityRepo.unlockPost(postId);
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final p = posts[index];
        posts[index] = p.copyWith(
          body: res['body'] as String? ?? p.body,
          content: res['body'] as String? ?? p.content,
          pollOptions: (res['poll_options'] as List?)?.map((e) => e.toString()).toList() ?? p.pollOptions,
          pollResults: res['poll_results'] != null ? Map<String, int>.from(res['poll_results'] as Map) : p.pollResults,
          myVote: p.myVote,
          attachment: res['media_url'] != null
              ? {
                  'id': p.id,
                  'kind': 'image',
                  'uri': res['media_url'] as String,
                  'name': 'Post image',
                }
              : p.attachment,
          locked: false,
        );
      }
    } catch (e) {
      apiError.value = e.toString();
      rethrow;
    }
  }

  Future<void> boostPost(String postId) async {
    try {
      final res = await _communityRepo.boostPost(postId);
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final p = posts[index];
        posts[index] = p.copyWith(
          isBoosted: res['is_boosted'] as bool? ?? true,
          boostedUntil: res['boosted_until'] as String?,
          boostCost: (res['boost_cost'] as num?)?.toDouble() ?? p.boostCost,
        );
      }
    } catch (e) {
      apiError.value = e.toString();
      rethrow;
    }
  }

  Future<void> tipPost(String postId, int amount) async {
    try {
      final res = await _communityRepo.tipPost(postId, amount);
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final p = posts[index];
        posts[index] = p.copyWith(
          tipCount: (res['tip_count'] as num?)?.toInt() ?? (p.tipCount + 1),
          tipTotal: (res['tip_total'] as num?)?.toDouble() ?? (p.tipTotal + amount),
        );
      }
    } catch (e) {
      apiError.value = e.toString();
      rethrow;
    }
  }

  Future<void> sendGiftToPost(String postId, Map<String, dynamic> gift, String recipientId) async {
    try {
      final giftId = gift['id']?.toString() ?? gift['gift_id']?.toString() ?? 'gift_heart';
      await _communityRepo.sendGift({
        'gift_id': giftId,
        'recipient_id': recipientId,
        'target_type': 'post',
        'target_id': postId,
      });
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final p = posts[index];
        final updatedGifts = List<dynamic>.from(p.gifts)..add(gift);
        final coins = (gift['coin_price'] ?? gift['coins'] ?? 0) as num;
        posts[index] = p.copyWith(
          gifts: updatedGifts,
          tipTotal: p.tipTotal + coins.toDouble(),
          tipCount: p.tipCount + 1,
        );
      }
    } catch (e) {
      apiError.value = e.toString();
      rethrow;
    }
  }

  Future<void> awardBounty(String postId, String commentId) async {
    try {
      final res = await _communityRepo.awardBounty(postId, commentId);
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final p = posts[index];
        posts[index] = p.copyWith(
          bountyStatus: res['bounty_status'] as String? ?? 'awarded',
          bountyWinnerCommentId: commentId,
        );
      }
    } catch (e) {
      apiError.value = e.toString();
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _communityRepo.deletePost(postId);
      posts.removeWhere((p) => p.id == postId);
    } catch (e) {
      apiError.value = e.toString();
      rethrow;
    }
  }

  Future<void> sendCommunityMessage(String communityId, String text, {String? attachmentId}) async {
    try {
      final Map<String, dynamic> payload = {
        'text': text,
        'attachment_id': ?attachmentId,
      };
      final res = await _communityRepo.sendCommunityMessage(communityId, payload);
      final msg = CommunityMessage.fromJson(res);
      final currentList = List<CommunityMessage>.from(communityMessages[communityId] ?? []);
      currentList.add(msg);
      communityMessages[communityId] = currentList;
    } catch (e) {
      apiError.value = e.toString();
      rethrow;
    }
  }

  Future<void> loadCommunityMessages(String communityId) async {
    try {
      final list = await _communityRepo.communityMessages(communityId);
      final parsed = list.map((item) => CommunityMessage.fromJson(item as Map<String, dynamic>)).toList();
      communityMessages[communityId] = parsed;
    } catch (e) {
      apiError.value = e.toString();
    }
  }

  Future<void> updatePost(String postId, String body) async {
    try {
      final updated = await _communityRepo.updatePost(postId, body);
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        posts[index] = posts[index].copyWith(body: updated.body, content: updated.body);
      }
    } catch (e) {
      apiError.value = e.toString();
      rethrow;
    }
  }

  // Comments
  Future<void> loadComments(String postId) async {
    loading.value = true;
    try {
      final list = await _communityRepo.comments(postId);
      comments.assignAll(list);
    } catch (_) {
    } finally {
      loading.value = false;
    }
  }

  Future<void> addComment(String postId, String text, {String? parentId}) async {
    try {
      final c = await _communityRepo.addComment(postId, text, parentId: parentId);
      comments.add(c);
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final p = posts[index];
        posts[index] = p.copyWith(
          commentsCount: p.commentsCount + 1,
          comments: p.comments + 1,
        );
      }
    } catch (e) {
      apiError.value = e.toString();
      rethrow;
    }
  }

  Future<void> toggleCommentLike(String commentId) async {
    try {
      final res = await _communityRepo.toggleCommentLike(commentId);
      final idx = comments.indexWhere((c) => c.id == commentId);
      if (idx != -1) {
        comments[idx] = comments[idx].copyWith(
          liked: res['liked'] == true,
          likeCount: (res['like_count'] as num?)?.toInt() ??
              (comments[idx].likeCount + (res['liked'] == true ? 1 : -1)),
        );
      }
    } catch (e) {
      apiError.value = e.toString();
      rethrow;
    }
  }

  Future<void> deleteComment(String commentId, String postId) async {
    try {
      await _communityRepo.deleteComment(commentId);
      comments.removeWhere((c) => c.id == commentId);
      final index = posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final p = posts[index];
        posts[index] = p.copyWith(
          commentsCount: (p.commentsCount - 1).clamp(0, 999999),
          comments: (p.comments - 1).clamp(0, 999999),
        );
      }
    } catch (e) {
      apiError.value = e.toString();
      rethrow;
    }
  }

  // Post & Community Creation
  Future<void> createPost(Map<String, dynamic> payload) async {
    loading.value = true;
    try {
      await _communityRepo.createPost(payload);
      await loadFeed();
    } finally {
      loading.value = false;
    }
  }

  Future<Community> createCommunity(Map<String, dynamic> payload) async {
    loading.value = true;
    try {
      final c = await _communityRepo.createCommunity(payload);
      await loadCommunities();
      return c;
    } finally {
      loading.value = false;
    }
  }

  Future<void> joinCommunity(String id) async {
    try {
      await _communityRepo.joinCommunity(id);
      if (!joinedCommunities.contains(id)) {
        joinedCommunities.add(id);
      }
    } catch (e) {
      apiError.value = e.toString();
      rethrow;
    }
  }

  Future<Community> fetchCommunityDetails(String id) async {
    final c = await _communityRepo.details(id);
    final idx = communities.indexWhere((x) => x.id == id);
    if (idx != -1) {
      communities[idx] = c;
    } else {
      communities.add(c);
    }
    if (c.isJoined && !joinedCommunities.contains(id)) {
      joinedCommunities.add(id);
    }
    return c;
  }

  Future<void> leaveCommunity(String id) async {
    try {
      await _communityRepo.leaveCommunity(id);
      joinedCommunities.remove(id);
      final idx = communities.indexWhere((c) => c.id == id);
      if (idx != -1) {
        communities[idx] = communities[idx].copyWith(
          isJoined: false,
          joined: false,
          memberCount: (communities[idx].memberCount - 1).clamp(0, 999999),
        );
      }
    } catch (e) {
      apiError.value = e.toString();
      rethrow;
    }
  }

  Future<void> deleteCommunity(String id) async {
    try {
      await _communityRepo.deleteCommunity(id);
      communities.removeWhere((c) => c.id == id);
      joinedCommunities.remove(id);
    } catch (e) {
      apiError.value = e.toString();
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchSubscriptionStatus(String communityId) async {
    try {
      return await _communityRepo.subscriptionStatus(communityId);
    } catch (_) {
      return null;
    }
  }

  // Members & Join Requests
  Future<void> loadMembers(String communityId) async {
    loading.value = true;
    try {
      final list = await _communityRepo.members(communityId);
      membersList.assignAll(list);
    } catch (_) {
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadJoinRequests(String communityId) async {
    loading.value = true;
    try {
      final list = await _communityRepo.joinRequests(communityId);
      joinRequestsList.assignAll(list);
    } catch (_) {
    } finally {
      loading.value = false;
    }
  }

  Future<void> respondJoinRequest(String communityId, String requestId, String action) async {
    try {
      await _communityRepo.respondJoinRequest(communityId, requestId, action);
      joinRequestsList.removeWhere((item) => item['id']?.toString() == requestId);
    } catch (e) {
      apiError.value = e.toString();
      rethrow;
    }
  }

  // Circles
  Future<void> loadCircleInvites() async {
    loading.value = true;
    try {
      final list = await _communityRepo.circleInvites();
      circleInvitesList.assignAll(list);
    } catch (_) {
    } finally {
      loading.value = false;
    }
  }

  Future<void> respondCircleInvite(String inviteId, String action) async {
    try {
      await _communityRepo.respondCircleInvite(inviteId, action);
      circleInvitesList.removeWhere((item) => item['id']?.toString() == inviteId);
    } catch (e) {
      apiError.value = e.toString();
      rethrow;
    }
  }

  Future<void> inviteToCircle(String communityId, String personId) async {
    await _communityRepo.inviteMember(communityId, personId);
  }
}
