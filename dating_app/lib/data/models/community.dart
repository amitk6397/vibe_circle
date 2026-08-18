class Community {
  final String id;
  final String name;
  final String category;
  final String description;
  final int members;
  final bool? joined;
  final String color;
  final String? privacy; // 'public' | 'request' | 'private' | 'premium'
  final double? premiumPrice;
  final List<String>? rules;
  final String? logoUrl;
  final String? coverUrl;
  final List<String>? tags;
  final String? location;
  final String? language;
  final bool? isOwner;
  final bool? joinPending;
  final String? kind; // 'community' | 'circle'
  final int? maxMembers;

  Community({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.members,
    this.joined,
    required this.color,
    this.privacy,
    this.premiumPrice,
    this.rules,
    this.logoUrl,
    this.coverUrl,
    this.tags,
    this.location,
    this.language,
    this.isOwner,
    this.joinPending,
    this.kind,
    this.maxMembers,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      members: json['members'] as int? ?? json['member_count'] as int? ?? 0,
      joined: json['joined'] as bool?,
      color: json['color'] as String? ?? '#D62976',
      privacy: json['privacy'] as String?,
      premiumPrice: (json['premiumPrice'] as num? ?? json['premium_price'] as num?)?.toDouble(),
      rules: (json['rules'] as List?)?.map((e) => e.toString()).toList(),
      logoUrl: json['logoUrl'] as String? ?? json['logo_url'] as String?,
      coverUrl: json['coverUrl'] as String? ?? json['cover_url'] as String?,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList(),
      location: json['location'] as String?,
      language: json['language'] as String?,
      isOwner: json['isOwner'] as bool? ?? json['is_owner'] as bool?,
      joinPending: json['joinPending'] as bool? ?? json['join_pending'] as bool?,
      kind: json['kind'] as String?,
      maxMembers: json['maxMembers'] as int? ?? json['max_members'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'members': members,
      'joined': joined,
      'color': color,
      'privacy': privacy,
      'premiumPrice': premiumPrice,
      'rules': rules,
      'logoUrl': logoUrl,
      'coverUrl': coverUrl,
      'tags': tags,
      'location': location,
      'language': language,
      'isOwner': isOwner,
      'joinPending': joinPending,
      'kind': kind,
      'maxMembers': maxMembers,
    };
  }
}
