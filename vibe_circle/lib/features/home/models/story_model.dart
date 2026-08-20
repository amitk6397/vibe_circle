class StoryItem {
  final String id;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String mediaUrl;
  final bool mine;
  bool viewed;
  final int viewCount;
  final String createdAt;
  final String audience;

  StoryItem({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.mediaUrl,
    this.mine = false,
    this.viewed = false,
    this.viewCount = 0,
    this.createdAt = '',
    this.audience = 'public',
  });

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      id: json['id']?.toString() ?? '',
      authorId: json['author_id']?.toString() ?? json['authorId']?.toString() ?? '',
      authorName: json['author_name']?.toString() ?? json['authorName']?.toString() ?? 'User',
      authorAvatarUrl: json['author_avatar_url']?.toString() ?? json['authorAvatarUrl']?.toString(),
      mediaUrl: json['media_url']?.toString() ?? json['mediaUrl']?.toString() ?? '',
      mine: json['mine'] == true,
      viewed: json['viewed'] == true,
      viewCount: (json['view_count'] as num?)?.toInt() ?? (json['viewCount'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '',
      audience: json['audience']?.toString() ?? 'public',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar_url': authorAvatarUrl,
      'media_url': mediaUrl,
      'mine': mine,
      'viewed': viewed,
      'view_count': viewCount,
      'created_at': createdAt,
      'audience': audience,
    };
  }
}

class StoryGroup {
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final bool mine;
  final List<StoryItem> stories;

  StoryGroup({
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.mine = false,
    required this.stories,
  });

  bool get allViewed => stories.every((s) => s.viewed);
}
