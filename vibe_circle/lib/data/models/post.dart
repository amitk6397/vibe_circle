import 'local_attachment.dart';

class Post {
  final String id;
  final String author;
  final String? authorId;
  final String? authorUsername;
  final bool? mine;
  final String community;
  final String body;
  final int likes;
  final int comments;
  final bool? anonymous;
  final String? authorAvatarUrl;
  final bool? liked;
  final bool? saved;
  final String? postType; // 'Text' | 'Question' | 'Poll' | 'Image'
  final List<String>? pollOptions;
  final Map<String, int>? pollResults;
  final String? myVote;
  final LocalAttachment? attachment;
  final String? createdAt;
  final String? visibility; // 'public' | 'private'
  final double? coinPrice;
  final bool? locked;
  final int? tipCount;
  final double? tipTotal;
  final bool? isBoosted;
  final String? boostedUntil;
  final double? boostCost;
  final double? bountyAmount;
  final String? bountyStatus; // 'none' | 'open' | 'awarded' | 'refunded'
  final String? bountyWinnerCommentId;
  final List<dynamic>? gifts;

  Post({
    required this.id,
    required this.author,
    this.authorId,
    this.authorUsername,
    this.mine,
    required this.community,
    required this.body,
    required this.likes,
    required this.comments,
    this.anonymous,
    this.authorAvatarUrl,
    this.liked,
    this.saved,
    this.postType,
    this.pollOptions,
    this.pollResults,
    this.myVote,
    this.attachment,
    this.createdAt,
    this.visibility,
    this.coinPrice,
    this.locked,
    this.tipCount,
    this.tipTotal,
    this.isBoosted,
    this.boostedUntil,
    this.boostCost,
    this.bountyAmount,
    this.bountyStatus,
    this.bountyWinnerCommentId,
    this.gifts,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'].toString(),
      author: json['author'] as String? ?? json['author_name'] as String? ?? '',
      authorId: (json['authorId'] ?? json['author_id'])?.toString(),
      authorUsername: json['authorUsername'] as String? ?? json['author_username'] as String?,
      mine: json['mine'] as bool?,
      community: json['community'] as String? ?? json['community_name'] as String? ?? '',
      body: json['body'] as String? ?? '',
      likes: json['likes'] as int? ?? json['like_count'] as int? ?? 0,
      comments: json['comments'] as int? ?? json['comment_count'] as int? ?? 0,
      anonymous: json['anonymous'] as bool?,
      authorAvatarUrl: json['authorAvatarUrl'] as String? ?? json['author_avatar_url'] as String?,
      liked: json['liked'] as bool?,
      saved: json['saved'] as bool?,
      postType: json['postType'] as String? ?? json['type'] as String?,
      pollOptions: (json['pollOptions'] as List? ?? json['poll_options'] as List?)?.map((e) => e.toString()).toList(),
      pollResults: json['pollResults'] != null
          ? Map<String, int>.from(json['pollResults'] as Map)
          : json['poll_results'] != null
              ? Map<String, int>.from(json['poll_results'] as Map)
              : null,
      myVote: json['myVote'] as String? ?? json['my_vote'] as String?,
      attachment: json['attachment'] != null
          ? LocalAttachment.fromJson(json['attachment'] as Map<String, dynamic>)
          : json['media_url'] != null
              ? LocalAttachment(
                  id: json['id'].toString(),
                  kind: 'image',
                  uri: json['media_url'] as String,
                  name: 'Post image',
                )
              : null,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String?,
      visibility: json['visibility'] as String?,
      coinPrice: (json['coinPrice'] as num? ?? json['coin_price'] as num?)?.toDouble(),
      locked: json['locked'] as bool?,
      tipCount: json['tipCount'] as int? ?? json['tip_count'] as int?,
      tipTotal: (json['tipTotal'] as num? ?? json['tip_total'] as num?)?.toDouble(),
      isBoosted: json['isBoosted'] as bool? ?? json['is_boosted'] as bool?,
      boostedUntil: json['boostedUntil'] as String? ?? json['boosted_until'] as String?,
      boostCost: (json['boostCost'] as num? ?? json['boost_cost'] as num?)?.toDouble(),
      bountyAmount: (json['bountyAmount'] as num? ?? json['bounty_amount'] as num?)?.toDouble(),
      bountyStatus: json['bountyStatus'] as String? ?? json['bounty_status'] as String?,
      bountyWinnerCommentId: (json['bountyWinnerCommentId'] ?? json['bounty_winner_comment_id'])?.toString(),
      gifts: json['gifts'] as List?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      'authorId': authorId,
      'authorUsername': authorUsername,
      'mine': mine,
      'community': community,
      'body': body,
      'likes': likes,
      'comments': comments,
      'anonymous': anonymous,
      'authorAvatarUrl': authorAvatarUrl,
      'liked': liked,
      'saved': saved,
      'postType': postType,
      'pollOptions': pollOptions,
      'pollResults': pollResults,
      'myVote': myVote,
      'attachment': attachment?.toJson(),
      'createdAt': createdAt,
      'visibility': visibility,
      'coinPrice': coinPrice,
      'locked': locked,
      'tipCount': tipCount,
      'tipTotal': tipTotal,
      'isBoosted': isBoosted,
      'boostedUntil': boostedUntil,
      'boostCost': boostCost,
      'bountyAmount': bountyAmount,
      'bountyStatus': bountyStatus,
      'bountyWinnerCommentId': bountyWinnerCommentId,
      'gifts': gifts,
    };
  }
}
