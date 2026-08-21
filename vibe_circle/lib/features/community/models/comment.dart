class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorUsername;
  final String? authorAvatar;
  final String text;
  final String body;
  final String? parentId;
  final int likeCount;
  final bool liked;
  final bool mine;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorUsername,
    this.authorAvatar,
    required this.text,
    required this.body,
    this.parentId,
    this.likeCount = 0,
    this.liked = false,
    this.mine = false,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final b = json['body']?.toString() ?? json['text']?.toString() ?? '';
    return Comment(
      id: json['id']?.toString() ?? '',
      postId: json['post_id']?.toString() ?? json['postId']?.toString() ?? '',
      authorId: json['author_id']?.toString() ?? json['authorId']?.toString() ?? '',
      authorName: json['author_name'] ?? json['author'] ?? 'Member',
      authorUsername: json['author_username'] ?? json['authorUsername'],
      authorAvatar: json['author_avatar'] ?? json['author_avatar_url'],
      text: b,
      body: b,
      parentId: json['parent_id']?.toString() ?? json['parentId']?.toString(),
      likeCount: json['like_count'] ?? json['likes'] ?? 0,
      liked: json['liked'] ?? false,
      mine: json['mine'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Comment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? authorUsername,
    String? authorAvatar,
    String? text,
    String? body,
    String? parentId,
    int? likeCount,
    bool? liked,
    bool? mine,
    DateTime? createdAt,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      text: text ?? this.text,
      body: body ?? this.body,
      parentId: parentId ?? this.parentId,
      likeCount: likeCount ?? this.likeCount,
      liked: liked ?? this.liked,
      mine: mine ?? this.mine,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'author_id': authorId,
      'author_name': authorName,
      'author_username': authorUsername,
      'author_avatar': authorAvatar,
      'text': text,
      'body': body,
      'parent_id': parentId,
      'like_count': likeCount,
      'liked': liked,
      'mine': mine,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
