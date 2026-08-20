class MessageRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String introduction;
  final int durationMinutes;
  final int chatPricePerMinute;
  final int totalPriceCoins;
  final String status;
  final String? conversationId;
  final String createdAt;

  MessageRequest({
    required this.id,
    required this.senderId,
    this.senderName = 'User',
    this.senderAvatar,
    this.introduction = '',
    this.durationMinutes = 0,
    this.chatPricePerMinute = 0,
    this.totalPriceCoins = 0,
    this.status = 'pending',
    this.conversationId,
    this.createdAt = '',
  });

  factory MessageRequest.fromJson(Map<String, dynamic> json) {
    return MessageRequest(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? json['senderId']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? json['senderName']?.toString() ?? 'User',
      senderAvatar: json['sender_avatar']?.toString() ?? json['senderAvatar']?.toString(),
      introduction: json['introduction']?.toString() ?? '',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ??
          (json['durationMinutes'] as num?)?.toInt() ??
          (json['reserved_minutes'] as num?)?.toInt() ??
          0,
      chatPricePerMinute: (json['chat_price_per_minute'] as num?)?.toInt() ??
          (json['chatPricePerMinute'] as num?)?.toInt() ??
          0,
      totalPriceCoins: (json['total_price_coins'] as num?)?.toInt() ??
          (json['chat_price'] as num?)?.toInt() ??
          (json['chatPrice'] as num?)?.toInt() ??
          0,
      status: json['status']?.toString() ?? 'pending',
      conversationId: json['conversation_id']?.toString() ?? json['conversationId']?.toString() ?? json['chat_id']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'introduction': introduction,
      'duration_minutes': durationMinutes,
      'chat_price_per_minute': chatPricePerMinute,
      'total_price_coins': totalPriceCoins,
      'status': status,
      'conversation_id': conversationId,
      'created_at': createdAt,
    };
  }
}
