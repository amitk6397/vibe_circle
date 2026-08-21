class CommunityMessage {
  final String id;
  final String communityId;
  final String senderId;
  final String authorId;
  final String senderName;
  final String authorName;
  final String? senderAvatar;
  final String? authorAvatar;
  final String text;
  final String? mediaUrl;
  final String? mediaName;
  final String? mimeType;
  final bool mine;
  final DateTime createdAt;

  CommunityMessage({
    required this.id,
    required this.communityId,
    required this.senderId,
    required this.authorId,
    required this.senderName,
    required this.authorName,
    this.senderAvatar,
    this.authorAvatar,
    required this.text,
    this.mediaUrl,
    this.mediaName,
    this.mimeType,
    this.mine = false,
    required this.createdAt,
  });

  factory CommunityMessage.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final aId = json['author_id']?.toString() ??
        json['sender_id']?.toString() ??
        json['senderId']?.toString() ??
        '';
    final aName = json['author_name']?.toString() ??
        json['sender_name']?.toString() ??
        json['senderName']?.toString() ??
        'Member';
    final aAvatar = json['author_avatar']?.toString() ??
        json['author_avatar_url']?.toString() ??
        json['sender_avatar']?.toString() ??
        json['senderAvatar']?.toString();

    final isMine = json['mine'] == true || (currentUserId != null && aId == currentUserId);

    return CommunityMessage(
      id: json['id']?.toString() ?? '',
      communityId: json['community_id']?.toString() ?? json['communityId']?.toString() ?? '',
      senderId: aId,
      authorId: aId,
      senderName: aName,
      authorName: aName,
      senderAvatar: aAvatar,
      authorAvatar: aAvatar,
      text: json['text']?.toString() ?? '',
      mediaUrl: json['media_url']?.toString() ?? json['mediaUrl']?.toString(),
      mediaName: json['media_name']?.toString() ?? json['mediaName']?.toString(),
      mimeType: json['mime_type']?.toString() ?? json['mimeType']?.toString(),
      mine: isMine,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'community_id': communityId,
      'author_id': authorId,
      'sender_id': senderId,
      'author_name': authorName,
      'sender_name': senderName,
      'author_avatar': authorAvatar,
      'sender_avatar': senderAvatar,
      'text': text,
      'media_url': mediaUrl,
      'media_name': mediaName,
      'mime_type': mimeType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
