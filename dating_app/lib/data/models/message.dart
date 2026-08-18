import 'local_attachment.dart';

class Message {
  final String id;
  final String chatId;
  final String text;
  final bool mine;
  final String time;
  final String? status; // 'sending' | 'sent' | 'delivered' | 'read' | 'failed'
  final LocalAttachment? attachment;
  final String? replyToId;
  final String? replyPreview;
  final Map<String, String>? reactions;
  final bool? deleted;
  final List<String>? safetyFlags;

  Message({
    required this.id,
    required this.chatId,
    required this.text,
    required this.mine,
    required this.time,
    this.status,
    this.attachment,
    this.replyToId,
    this.replyPreview,
    this.reactions,
    this.deleted,
    this.safetyFlags,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'].toString(),
      chatId: (json['chatId'] ?? json['conversation_id'] ?? '').toString(),
      text: json['text'] as String? ?? '',
      mine: json['mine'] as bool? ?? false,
      time: json['time'] as String? ?? json['created_at'] as String? ?? '',
      status: json['status'] as String?,
      attachment: json['attachment'] != null
          ? LocalAttachment.fromJson(json['attachment'] as Map<String, dynamic>)
          : json['media_url'] != null
              ? LocalAttachment(
                  id: json['id'].toString(),
                  kind: json['type'] == 'image' ? 'image' : 'file',
                  uri: json['media_url'] as String,
                  name: json['media_name'] as String? ?? 'Attachment',
                  mimeType: json['mime_type'] as String?,
                )
              : null,
      replyToId: (json['replyToId'] ?? json['reply_to_id'])?.toString(),
      replyPreview: json['replyPreview'] as String? ?? json['reply_preview'] as String?,
      reactions: json['reactions'] != null
          ? Map<String, String>.from(json['reactions'] as Map)
          : null,
      deleted: json['deleted'] as bool?,
      safetyFlags: (json['safetyFlags'] as List? ?? json['safety_flags'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'text': text,
      'mine': mine,
      'time': time,
      'status': status,
      'attachment': attachment?.toJson(),
      'replyToId': replyToId,
      'replyPreview': replyPreview,
      'reactions': reactions,
      'deleted': deleted,
      'safetyFlags': safetyFlags,
    };
  }
}
