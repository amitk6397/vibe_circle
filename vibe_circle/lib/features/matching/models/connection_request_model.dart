class ConnectionRequestItem {
  final String id;
  final String requesterId;
  final String receiverId;
  final String status;
  final String createdAt;
  final String requesterName;
  final String? requesterAvatar;
  final String requesterBio;
  final String? requesterCity;
  final List<String> requesterInterests;

  ConnectionRequestItem({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    this.status = 'pending',
    this.createdAt = '',
    this.requesterName = 'Member',
    this.requesterAvatar,
    this.requesterBio = '',
    this.requesterCity,
    this.requesterInterests = const [],
  });

  factory ConnectionRequestItem.fromJson(Map<String, dynamic> json) {
    List<String> interests = [];
    if (json['requester_interests'] is List) {
      interests = (json['requester_interests'] as List).map((e) => e.toString()).toList();
    } else if (json['interests'] is List) {
      interests = (json['interests'] as List).map((e) => e.toString()).toList();
    }

    return ConnectionRequestItem(
      id: json['id']?.toString() ?? '',
      requesterId: json['requester_id']?.toString() ?? json['requesterId']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? json['receiverId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at']?.toString() ?? '',
      requesterName: json['requester_name']?.toString() ?? json['name']?.toString() ?? 'Member',
      requesterAvatar: json['requester_avatar']?.toString() ?? json['avatar_url']?.toString(),
      requesterBio: json['requester_bio']?.toString() ?? json['bio']?.toString() ?? '',
      requesterCity: json['requester_city']?.toString() ?? json['city']?.toString(),
      requesterInterests: interests,
    );
  }

  ConnectionRequestItem copyWith({
    String? requesterName,
    String? requesterAvatar,
    String? requesterBio,
    String? requesterCity,
    List<String>? requesterInterests,
  }) {
    return ConnectionRequestItem(
      id: id,
      requesterId: requesterId,
      receiverId: receiverId,
      status: status,
      createdAt: createdAt,
      requesterName: requesterName ?? this.requesterName,
      requesterAvatar: requesterAvatar ?? this.requesterAvatar,
      requesterBio: requesterBio ?? this.requesterBio,
      requesterCity: requesterCity ?? this.requesterCity,
      requesterInterests: requesterInterests ?? this.requesterInterests,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requester_id': requesterId,
      'receiver_id': receiverId,
      'status': status,
      'created_at': createdAt,
      'requester_name': requesterName,
      'requester_avatar': requesterAvatar,
      'requester_bio': requesterBio,
      'requester_city': requesterCity,
      'requester_interests': requesterInterests,
    };
  }
}
