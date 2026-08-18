import 'package:get/get.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/utils/helpers.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final String? mediaUrl;
  final String? mediaType;
  final Map<String, String> reactions;
  final String? replyToId;
  final DateTime createdAt;
  final bool mine;
  final bool deleted;
  final dynamic attachment;
  final List<String> safetyFlags;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.mediaUrl,
    this.mediaType,
    this.reactions = const {},
    this.replyToId,
    required this.createdAt,
    this.mine = false,
    this.deleted = false,
    this.attachment,
    this.safetyFlags = const [],
  });

  String get time => Helpers.formatRelativeDate(createdAt.toIso8601String());

  factory Message.fromJson(Map<String, dynamic> json) {
    Map<String, String> mapReactions = {};
    if (json['reactions'] is Map) {
      (json['reactions'] as Map).forEach((k, v) {
        mapReactions[k.toString()] = v.toString();
      });
    }

    bool isMine = json['mine'] ?? false;
    if (json['mine'] == null) {
      try {
        final currentUserId = Get.find<AuthController>().currentUserId.value;
        if (currentUserId != null) {
          isMine = json['sender_id']?.toString() == currentUserId;
        }
      } catch (_) {}
    }

    return Message(
      id: json['id'].toString(),
      chatId: json['chat_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      text: json['text'] ?? '',
      mediaUrl: json['media_url'],
      mediaType: json['media_type'],
      reactions: mapReactions,
      replyToId: json['reply_to_id']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      mine: isMine,
      deleted: json['deleted'] ?? false,
      attachment: json['attachment'],
      safetyFlags: (json['safety_flags'] as List?)?.map((e) => e.toString()).toList() ??
          (json['safetyFlags'] as List?)?.map((e) => e.toString()).toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'text': text,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'reactions': reactions,
      'reply_to_id': replyToId,
      'created_at': createdAt.toIso8601String(),
      'mine': mine,
      'deleted': deleted,
      'attachment': attachment,
      'safety_flags': safetyFlags,
    };
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? text,
    String? mediaUrl,
    String? mediaType,
    Map<String, String>? reactions,
    String? replyToId,
    DateTime? createdAt,
    bool? mine,
    bool? deleted,
    dynamic attachment,
    List<String>? safetyFlags,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      reactions: reactions ?? this.reactions,
      replyToId: replyToId ?? this.replyToId,
      createdAt: createdAt ?? this.createdAt,
      mine: mine ?? this.mine,
      deleted: deleted ?? this.deleted,
      attachment: attachment ?? this.attachment,
      safetyFlags: safetyFlags ?? this.safetyFlags,
    );
  }
}

