class LocalAttachment {
  final String id;
  final String kind; // 'image' | 'file'
  final String uri;
  final String name;
  final String? mimeType;
  final int? size;

  LocalAttachment({
    required this.id,
    required this.kind,
    required this.uri,
    required this.name,
    this.mimeType,
    this.size,
  });

  factory LocalAttachment.fromJson(Map<String, dynamic> json) {
    return LocalAttachment(
      id: json['id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'image',
      uri: json['uri']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? json['mimeType']?.toString(),
      size: json['size'] is int ? json['size'] as int : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind,
      'uri': uri,
      'name': name,
      'mime_type': mimeType,
      'size': size,
    };
  }
}
