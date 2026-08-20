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
      id: json['id'].toString(),
      kind: json['kind'] as String,
      uri: json['uri'] as String,
      name: json['name'] as String,
      mimeType: json['mimeType'] as String?,
      size: json['size'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind,
      'uri': uri,
      'name': name,
      'mimeType': mimeType,
      'size': size,
    };
  }
}
