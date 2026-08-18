import 'message.dart';
import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/utils/helpers.dart';

class Chat {
  final String id;
  final String type; // 'private' | 'group'
  final String? name;
  final String? avatarUrl;
  final List<String> participantIds;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;
  final bool online;

  Chat({
    required this.id,
    required this.type,
    this.name,
    this.avatarUrl,
    required this.participantIds,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
    this.online = false,
  });

  int get unread => unreadCount;
  String get preview => lastMessage?.text ?? '';
  String get time => Helpers.formatRelativeDate(updatedAt.toIso8601String());

  Chat copyWith({
    String? id,
    String? type,
    String? name,
    String? avatarUrl,
    List<String>? participantIds,
    Message? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
    bool? online,
    String? lastMessageText,
    String? lastMessageTime,
  }) {
    Message? updatedLastMsg = lastMessage;
    if (lastMessageText != null) {
      updatedLastMsg = (lastMessage ?? Message(
        id: '',
        chatId: this.id,
        senderId: '',
        text: '',
        createdAt: DateTime.now(),
      )).copyWith(text: lastMessageText);
    }
    return Chat(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      participantIds: participantIds ?? this.participantIds,
      lastMessage: updatedLastMsg ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? (lastMessageTime != null ? (DateTime.tryParse(lastMessageTime) ?? this.updatedAt) : this.updatedAt),
      online: online ?? this.online,
    );
  }

  String get personId {
    try {
      final currentUserId = Get.find<AuthController>().currentUserId.value;
      if (currentUserId != null) {
        return participantIds.firstWhere((id) => id != currentUserId, orElse: () => participantIds.isNotEmpty ? participantIds.first : '');
      }
    } catch (_) {}
    return participantIds.isNotEmpty ? participantIds.first : '';
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'].toString(),
      type: json['type'] ?? 'private',
      name: json['name'],
      avatarUrl: json['avatar_url'],
      participantIds: (json['participant_ids'] as List?)?.map((e) => e.toString()).toList() ?? [],
      lastMessage: json['last_message'] != null ? Message.fromJson(json['last_message']) : null,
      unreadCount: json['unread_count'] ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      online: json['online'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'avatar_url': avatarUrl,
      'participant_ids': participantIds,
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'updated_at': updatedAt.toIso8601String(),
      'online': online,
    };
  }
}

