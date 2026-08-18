import 'local_attachment.dart';

class CommunityMessage {
  final String id;
  final String communityId;
  final String authorId;
  final String author;
  final String text;
  final String time;
  final bool? mine;
  final String? role; // 'owner' | 'moderator' | 'member'
  final LocalAttachment? attachment;

  CommunityMessage({
    required this.id,
    required this.communityId,
    required this.authorId,
    required this.author,
    required this.text,
    required this.time,
    this.mine,
    this.role,
    this.attachment,
  });

  factory CommunityMessage.fromJson(Map<String, dynamic> json) {
    return CommunityMessage(
      id: json['id'].toString(),
      communityId: (json['communityId'] ?? json['community_id'] ?? '').toString(),
      authorId: (json['authorId'] ?? json['author_id'] ?? '').toString(),
      author: json['author'] as String? ?? json['author_name'] as String? ?? '',
      text: json['text'] as String? ?? '',
      time: json['time'] as String? ?? json['created_at'] as String? ?? '',
      mine: json['mine'] as bool?,
      role: json['role'] as String?,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'communityId': communityId,
      'authorId': authorId,
      'author': author,
      'text': text,
      'time': time,
      'mine': mine,
      'role': role,
      'attachment': attachment?.toJson(),
    };
  }
}
