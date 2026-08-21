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
  final String? mediaName;
  final Map<String, String> reactions;
  final String? replyToId;
  final String? replyToText;
  final String? replyToSender;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool mine;
  final bool deleted;
  final bool edited;
  final dynamic attachment;
  final List<String> safetyFlags;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.mediaUrl,
    this.mediaType,
    this.mediaName,
    this.reactions = const {},
    this.replyToId,
    this.replyToText,
    this.replyToSender,
    required this.createdAt,
    this.readAt,
    this.mine = false,
    this.deleted = false,
    this.edited = false,
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

    final bool isDeleted = json['is_deleted'] == true || json['deleted'] == true;
    final bool isEdited = json['is_edited'] == true || json['edited'] == true;

    return Message(
      id: json['id'].toString(),
      chatId: json['conversation_id']?.toString() ?? json['chat_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      text: json['text'] ?? '',
      mediaUrl: json['media_url'],
      mediaType: json['media_type'] ?? json['type'],
      mediaName: json['media_name'],
      reactions: mapReactions,
      replyToId: json['reply_to_id']?.toString(),
      replyToText: json['reply_to_text']?.toString(),
      replyToSender: json['reply_to_sender']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
      mine: isMine,
      deleted: isDeleted,
      edited: isEdited,
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
      'media_name': mediaName,
      'reactions': reactions,
      'reply_to_id': replyToId,
      'reply_to_text': replyToText,
      'reply_to_sender': replyToSender,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'mine': mine,
      'deleted': deleted,
      'edited': edited,
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
    String? mediaName,
    Map<String, String>? reactions,
    String? replyToId,
    String? replyToText,
    String? replyToSender,
    DateTime? createdAt,
    DateTime? readAt,
    bool? mine,
    bool? deleted,
    bool? edited,
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
      mediaName: mediaName ?? this.mediaName,
      reactions: reactions ?? this.reactions,
      replyToId: replyToId ?? this.replyToId,
      replyToText: replyToText ?? this.replyToText,
      replyToSender: replyToSender ?? this.replyToSender,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      mine: mine ?? this.mine,
      deleted: deleted ?? this.deleted,
      edited: edited ?? this.edited,
      attachment: attachment ?? this.attachment,
      safetyFlags: safetyFlags ?? this.safetyFlags,
    );
  }
}

