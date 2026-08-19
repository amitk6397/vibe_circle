
class Post {
  final String id;
  final String communityId;
  final String community;
  final String authorId;
  final String authorName;
  final String author;
  final String? authorAvatar;
  final String? authorAvatarUrl;
  final String? authorUsername;
  final String content;
  final String body;
  final List<String> mediaUrls;
  final int likesCount;
  final int likes;
  final int commentsCount;
  final int comments;
  final bool isLiked;
  final bool liked;
  final bool saved;
  final bool mine;
  final bool anonymous;
  final String postType;
  final List<String> pollOptions;
  final Map<String, int> pollResults;
  final String? myVote;
  final dynamic attachment; // Or LocalAttachment
  final DateTime createdAt;
  final String visibility;
  final double coinPrice;
  final bool locked;
  final int tipCount;
  final double tipTotal;
  final bool isBoosted;
  final String? boostedUntil;
  final double boostCost;
  final double bountyAmount;
  final String bountyStatus; // 'none' | 'open' | 'awarded' | 'refunded'
  final String? bountyWinnerCommentId;
  final List<dynamic> gifts;

  Post({
    required this.id,
    required this.communityId,
    required this.community,
    required this.authorId,
    required this.authorName,
    required this.author,
    this.authorAvatar,
    this.authorAvatarUrl,
    this.authorUsername,
    required this.content,
    required this.body,
    this.mediaUrls = const [],
    this.likesCount = 0,
    this.likes = 0,
    this.commentsCount = 0,
    this.comments = 0,
    this.isLiked = false,
    this.liked = false,
    this.saved = false,
    this.mine = false,
    this.anonymous = false,
    this.postType = 'Text',
    this.pollOptions = const [],
    this.pollResults = const {},
    this.myVote,
    this.attachment,
    required this.createdAt,
    this.visibility = 'public',
    this.coinPrice = 0,
    this.locked = false,
    this.tipCount = 0,
    this.tipTotal = 0,
    this.isBoosted = false,
    this.boostedUntil,
    this.boostCost = 0,
    this.bountyAmount = 0,
    this.bountyStatus = 'none',
    this.bountyWinnerCommentId,
    this.gifts = const [],
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'].toString();
    final rawCommId = json['community_id']?.toString() ?? '';
    final rawCommName = json['community_name']?.toString() ?? json['community']?.toString() ?? '';
    final rawAuthId = json['author_id']?.toString() ?? '';
    final rawAuthName = json['author_name'] ?? json['author'] ?? 'User';
    final rawAvatar = json['author_avatar'] ?? json['author_avatar_url'];
    final rawContent = json['content'] ?? json['body'] ?? '';
    final lCount = json['like_count'] ?? json['likes_count'] ?? json['likes'] ?? 0;
    final cCount = json['comment_count'] ?? json['comments_count'] ?? json['comments'] ?? 0;
    final isL = json['is_liked'] ?? json['liked'] ?? false;
    final isS = json['saved'] ?? false;
    final isM = json['mine'] ?? false;
    final isA = json['anonymous'] ?? false;
    final rawType = json['post_type'] ?? json['postType'] ?? 'Text';

    List<String> parsedMediaUrls = [];
    if (json['media_urls'] is List) {
      parsedMediaUrls = (json['media_urls'] as List).map((e) => e.toString()).toList();
    } else if (json['media_url'] != null && json['media_url'].toString().isNotEmpty) {
      parsedMediaUrls = [json['media_url'].toString()];
    }

    return Post(
      id: rawId,
      communityId: rawCommId,
      community: rawCommName.isNotEmpty ? rawCommName : 'Discover',
      authorId: rawAuthId,
      authorName: rawAuthName,
      author: rawAuthName,
      authorAvatar: rawAvatar,
      authorAvatarUrl: rawAvatar,
      authorUsername: json['author_username'] ?? json['authorUsername'] ?? '',
      content: rawContent,
      body: rawContent,
      mediaUrls: parsedMediaUrls,
      likesCount: lCount,
      likes: lCount,
      commentsCount: cCount,
      comments: cCount,
      isLiked: isL,
      liked: isL,
      saved: isS,
      mine: isM,
      anonymous: isA,
      postType: rawType,
      pollOptions: (json['poll_options'] as List?)?.map((e) => e.toString()).toList() ??
          (json['pollOptions'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      pollResults: json['poll_results'] != null
          ? Map<String, int>.from(json['poll_results'] as Map)
          : json['pollResults'] != null
              ? Map<String, int>.from(json['pollResults'] as Map)
              : {},
      myVote: json['my_vote'] ?? json['myVote'],
      attachment: json['attachment'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      visibility: json['visibility'] ?? 'public',
      coinPrice: (json['coin_price'] ?? json['coinPrice'] ?? 0).toDouble(),
      locked: json['locked'] ?? false,
      tipCount: json['tip_count'] ?? json['tipCount'] ?? 0,
      tipTotal: (json['tip_total'] ?? json['tipTotal'] ?? 0).toDouble(),
      isBoosted: json['is_boosted'] ?? json['isBoosted'] ?? false,
      boostedUntil: json['boosted_until'] ?? json['boostedUntil'],
      boostCost: (json['boost_cost'] ?? json['boostCost'] ?? 0).toDouble(),
      bountyAmount: (json['bounty_amount'] ?? json['bountyAmount'] ?? 0).toDouble(),
      bountyStatus: json['bounty_status'] ?? json['bountyStatus'] ?? 'none',
      bountyWinnerCommentId: json['bounty_winner_comment_id'] ?? json['bountyWinnerCommentId'],
      gifts: json['gifts'] as List? ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'community_id': communityId,
      'community': community,
      'author_id': authorId,
      'author_name': authorName,
      'author': author,
      'author_avatar': authorAvatar,
      'author_avatar_url': authorAvatarUrl,
      'author_username': authorUsername,
      'content': content,
      'body': body,
      'media_urls': mediaUrls,
      'likes_count': likesCount,
      'likes': likes,
      'comments_count': commentsCount,
      'comments': comments,
      'is_liked': isLiked,
      'liked': liked,
      'saved': saved,
      'mine': mine,
      'anonymous': anonymous,
      'post_type': postType,
      'poll_options': pollOptions,
      'poll_results': pollResults,
      'my_vote': myVote,
      'attachment': attachment,
      'created_at': createdAt.toIso8601String(),
      'visibility': visibility,
      'coin_price': coinPrice,
      'locked': locked,
      'tip_count': tipCount,
      'tip_total': tipTotal,
      'is_boosted': isBoosted,
      'boosted_until': boostedUntil,
      'boost_cost': boostCost,
      'bounty_amount': bountyAmount,
      'bounty_status': bountyStatus,
      'bounty_winner_comment_id': bountyWinnerCommentId,
      'gifts': gifts,
    };
  }

  Post copyWith({
    String? id,
    String? communityId,
    String? community,
    String? authorId,
    String? authorName,
    String? author,
    String? authorAvatar,
    String? authorAvatarUrl,
    String? authorUsername,
    String? content,
    String? body,
    List<String>? mediaUrls,
    int? likesCount,
    int? likes,
    int? commentsCount,
    int? comments,
    bool? isLiked,
    bool? liked,
    bool? saved,
    bool? mine,
    bool? anonymous,
    String? postType,
    List<String>? pollOptions,
    Map<String, int>? pollResults,
    String? myVote,
    dynamic attachment,
    DateTime? createdAt,
    String? visibility,
    double? coinPrice,
    bool? locked,
    int? tipCount,
    double? tipTotal,
    bool? isBoosted,
    String? boostedUntil,
    double? boostCost,
    double? bountyAmount,
    String? bountyStatus,
    String? bountyWinnerCommentId,
    List<dynamic>? gifts,
  }) {
    return Post(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      community: community ?? this.community,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      author: author ?? this.author,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorUsername: authorUsername ?? this.authorUsername,
      content: content ?? this.content,
      body: body ?? this.body,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      likesCount: likesCount ?? this.likesCount,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      comments: comments ?? this.comments,
      isLiked: isLiked ?? this.isLiked,
      liked: liked ?? this.liked,
      saved: saved ?? this.saved,
      mine: mine ?? this.mine,
      anonymous: anonymous ?? this.anonymous,
      postType: postType ?? this.postType,
      pollOptions: pollOptions ?? this.pollOptions,
      pollResults: pollResults ?? this.pollResults,
      myVote: myVote ?? this.myVote,
      attachment: attachment ?? this.attachment,
      createdAt: createdAt ?? this.createdAt,
      visibility: visibility ?? this.visibility,
      coinPrice: coinPrice ?? this.coinPrice,
      locked: locked ?? this.locked,
      tipCount: tipCount ?? this.tipCount,
      tipTotal: tipTotal ?? this.tipTotal,
      isBoosted: isBoosted ?? this.isBoosted,
      boostedUntil: boostedUntil ?? this.boostedUntil,
      boostCost: boostCost ?? this.boostCost,
      bountyAmount: bountyAmount ?? this.bountyAmount,
      bountyStatus: bountyStatus ?? this.bountyStatus,
      bountyWinnerCommentId: bountyWinnerCommentId ?? this.bountyWinnerCommentId,
      gifts: gifts ?? this.gifts,
    );
  }
}


