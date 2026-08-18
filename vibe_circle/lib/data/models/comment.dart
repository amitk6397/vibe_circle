class Comment {
  final String id;
  final String postId;
  final String author;
  final String? authorUsername;
  final String body;
  final String time;
  final String? parentId;
  final int? likes;
  final bool? liked;
  final bool? mine;

  Comment({
    required this.id,
    required this.postId,
    required this.author,
    this.authorUsername,
    required this.body,
    required this.time,
    this.parentId,
    this.likes,
    this.liked,
    this.mine,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'].toString(),
      postId: (json['postId'] ?? json['post_id'] ?? '').toString(),
      author: json['author'] as String? ?? json['author_name'] as String? ?? '',
      authorUsername: json['authorUsername'] as String? ?? json['author_username'] as String?,
      body: json['body'] as String? ?? '',
      time: json['time'] as String? ?? json['created_at'] as String? ?? '',
      parentId: (json['parentId'] ?? json['parent_id'])?.toString(),
      likes: json['likes'] as int? ?? json['like_count'] as int? ?? 0,
      liked: json['liked'] as bool?,
      mine: json['mine'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'author': author,
      'authorUsername': authorUsername,
      'body': body,
      'time': time,
      'parentId': parentId,
      'likes': likes,
      'liked': liked,
      'mine': mine,
    };
  }
}
