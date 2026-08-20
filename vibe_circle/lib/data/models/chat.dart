class Chat {
  final String id;
  final String personId;
  final String name;
  final String preview;
  final String time;
  final int unread;
  final bool? online;
  final String? avatarUrl;

  Chat({
    required this.id,
    required this.personId,
    required this.name,
    required this.preview,
    required this.time,
    required this.unread,
    this.online,
    this.avatarUrl,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'].toString(),
      personId: (json['personId'] ?? json['person_id'] ?? json['member_id'] ?? '').toString(),
      name: json['name'] as String? ?? json['member_name'] as String? ?? '',
      preview: json['preview'] as String? ?? json['last_message'] as String? ?? '',
      time: json['time'] as String? ?? json['updated_at'] as String? ?? '',
      unread: json['unread'] as int? ?? json['unread_count'] as int? ?? 0,
      online: json['online'] as bool? ?? json['is_online'] as bool?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personId': personId,
      'name': name,
      'preview': preview,
      'time': time,
      'unread': unread,
      'online': online,
      'avatarUrl': avatarUrl,
    };
  }
}
