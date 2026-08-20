class CommunityMessage {
  final String id;
  final String communityId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String text;
  final DateTime createdAt;

  CommunityMessage({
    required this.id,
    required this.communityId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.text,
    required this.createdAt,
  });

  factory CommunityMessage.fromJson(Map<String, dynamic> json) {
    return CommunityMessage(
      id: json['id']?.toString() ?? '',
      communityId: json['community_id']?.toString() ?? json['communityId']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? json['senderId']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? json['senderName']?.toString() ?? 'User',
      senderAvatar: json['sender_avatar']?.toString() ?? json['senderAvatar']?.toString(),
      text: json['text']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'community_id': communityId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'text': text,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
